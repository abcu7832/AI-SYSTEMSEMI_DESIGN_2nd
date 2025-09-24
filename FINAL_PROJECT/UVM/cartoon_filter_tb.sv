`timescale 1ns / 1ps

// ============================================================
// 1) Write-stream 인터페이스 (VGA_Cartoon DUT 포트에 매칭)
// ============================================================
interface vga_wr_intf;
    logic        clk;
    logic        reset;  // active-high
    // to DUT (camera write stream)
    logic        we_in;
    logic [16:0] wAddr_in;
    logic [15:0] wData_in;  // RGB565
    // from DUT (to frame buffer)
    logic        we_out;
    logic [16:0] wAddr_out;
    logic [15:0] wData_out;
endinterface

// ============================================================
// 2) Transaction : 1클럭 단위 write beat
// ============================================================
class wr_txn;
    rand bit        we;
    rand bit [16:0] addr;
    rand bit [15:0] data;
    // 디버깅용
    int             idx;  // 0..(W*H-1)
endclass

// ============================================================
// 3) Generator : 320x240 균일 프레임 (중간회색 0x7BEF)
//    - 엣지/포스터라이즈 영향 0, 블러 불변 → 입력=출력
// ============================================================
class generator;
    mailbox #(wr_txn) gen2drv_mbox;

    localparam int W = 320;
    localparam int H = 240;
    localparam int N = W * H;

    // 간단 단일 프레임
    localparam int FRAMES_TO_RUN = 1;

    function new(mailbox#(wr_txn) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task put(bit we, bit [16:0] a, bit [15:0] d, int i);
        wr_txn t = new();
        t.we   = we;
        t.addr = a;
        t.data = d;
        t.idx  = i;
        gen2drv_mbox.put(t);
    endtask

    task run();
        // 프레임 루프
        for (int f = 0; f < FRAMES_TO_RUN; f++) begin
            // 한 프레임: 0..N-1 순차 주소, 고정 픽셀 0x7BEF
            for (int i = 0; i < N; i++) begin
                put(1'b1, 17'(i), 16'h7BEF, i);
            end
            // 프레임 종료 후 몇 클럭 쉬어줌(we=0)
            for (int k = 0; k < 50; k++) put(1'b0, '0, '0, -1);
        end
    endtask
endclass

// ============================================================
// 4) Driver : negedge에 구동 → posedge에서 DUT 샘플
// ============================================================
class driver;
    virtual vga_wr_intf vif;
    mailbox #(wr_txn)   gen2drv_mbox;

    function new(mailbox#(wr_txn) gen2drv_mbox, virtual vga_wr_intf vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.vif          = vif;
    endfunction

    task run();
        wr_txn tr;
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge vif.clk);
            vif.we_in    <= tr.we;
            vif.wAddr_in <= tr.addr;
            vif.wData_in <= tr.data;
            @(posedge vif.clk);
        end
    endtask
endclass

// ============================================================
// 5) Monitor : 입력/출력 동시 샘플링 → SB로 보냄
//    (여기선 입력만 큐에 저장하고 출력은 SB가 직접 읽음)
// ============================================================
class monitor;
    virtual vga_wr_intf vif;
    mailbox #(wr_txn)   mon2scb_mbox;

    function new(mailbox#(wr_txn) mon2scb_mbox, virtual vga_wr_intf vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.vif          = vif;
    endfunction

    task run();
        wr_txn tr;
        forever begin
            @(posedge vif.clk);
            tr = new();
            tr.we = vif.we_in;
            tr.addr = vif.wAddr_in;
            tr.data = vif.wData_in;
            tr.idx = -1;
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// ============================================================
// 6) Scoreboard : 파이프라인 3클럭 정렬 후 비교
//    - 균일 프레임 + 포스터/엣지 무력화 → out == in (데이터)
//    - 주소/WE도 3클럭 지연 일치 확인
// ============================================================
class scoreboard;
    virtual vga_wr_intf vif;
    mailbox #(wr_txn)   mon2scb_mbox;

    // 간단 지연라인(딜레이 파이프) 3단
    typedef struct packed {
        bit we;
        bit [16:0] a;
        bit [15:0] d;
    } beat_t;
    beat_t q[3];  // q[0]가 최신 입력, [2]가 기대 출력 타이밍

    int total_checks, total_mismatch;

    function new(mailbox#(wr_txn) mon2scb_mbox, virtual vga_wr_intf vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.vif          = vif;
    endfunction

    task run();
        wr_txn        tr;

        // ---- 모든 지역 변수 선언을 맨 위로 ----
        beat_t        exp;
        bit           we_s;
        bit    [16:0] a_s;
        bit    [15:0] d_s;

        total_checks = 0;
        total_mismatch = 0;

        // 초기화
        q[0] = '{we: 0, a: '0, d: '0};
        q[1] = '{we: 0, a: '0, d: '0};
        q[2] = '{we: 0, a: '0, d: '0};

        forever begin
            mon2scb_mbox.get(tr);

            // 파이프 시프트
            q[2] = q[1];
            q[1] = q[0];
            // 일부 툴 호환 위해 필드명 지정 대신 위치 지정도 가능: '{tr.we, tr.addr, tr.data}
            q[0] = '{we: tr.we, a: tr.addr, d: tr.data};

            // 기대치: 3클럭 뒤
            exp  = q[2];

            // DUT 출력 샘플 (동일 posedge)
            we_s = vif.we_out;
            a_s  = vif.wAddr_out;
            d_s  = vif.wData_out;

            if (exp.we) begin
                total_checks++;

                if (we_s !== 1'b1) begin
                    total_mismatch++;
                    $display("**WE MISMATCH** got=%0b exp=1 (time=%0t)", we_s,
                             $time);
                end
                if (a_s !== exp.a) begin
                    total_mismatch++;
                    $display("**ADDR MISMATCH** got=%0d exp=%0d (time=%0t)",
                             a_s, exp.a, $time);
                end
                if (d_s !== exp.d) begin
                    total_mismatch++;
                    $display(
                        "**DATA MISMATCH** got=0x%04h exp=0x%04h (time=%0t)",
                        d_s, exp.d, $time);
                end
            end
        end
    endtask

endclass

// ============================================================
// 7) Environment : gen/driver/monitor/scoreboard 연결
// ============================================================
class environment;
    generator           gen;
    driver              drv;
    monitor             mon;
    scoreboard          scb;
    mailbox #(wr_txn)   gen2drv_mbox;
    mailbox #(wr_txn)   mon2scb_mbox;
    virtual vga_wr_intf vif;

    function new(virtual vga_wr_intf vif);
        this.vif = vif;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox);
        drv = new(gen2drv_mbox, vif);
        mon = new(mon2scb_mbox, vif);
        scb = new(mon2scb_mbox, vif);
    endfunction

    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask
endclass

// ============================================================
// 8) Top TB : DUT(VGA_Cartoon) + 클럭/리셋 + env 구동
// ============================================================
module tb_vga_cartoon_uvmstyle;
    vga_wr_intf vif ();
    environment env;

    // DUT 파라미터: 포스터/엣지 무력화 → 균일 프레임 시 입력=출력
    VGA_Cartoon #(
        .IMG_WIDTH(320),
        .IMG_HEIGHT(240),
        .KEEP_RB_MSBS(5),
        .KEEP_G_MSBS(6),
        .EDGE_THR(1023)  // 충분히 커서 엣지 오버레이 발생 안 함
    ) dut (
        .clk      (vif.clk),
        .reset    (vif.reset),
        .we_in    (vif.we_in),
        .wAddr_in (vif.wAddr_in),
        .wData_in (vif.wData_in),
        .we_out   (vif.we_out),
        .wAddr_out(vif.wAddr_out),
        .wData_out(vif.wData_out)
    );

    // Clock
    localparam real CLK_PERIOD_NS = 20.0;  // 50 MHz
    initial vif.clk = 1'b0;
    always #(CLK_PERIOD_NS / 2.0) vif.clk = ~vif.clk;

    // Reset & run
    initial begin
        // 초기값
        vif.reset    = 1'b1;
        vif.we_in    = 1'b0;
        vif.wAddr_in = '0;
        vif.wData_in = '0;

        // 리셋
        repeat (8) @(posedge vif.clk);
        vif.reset = 1'b0;
        repeat (4) @(posedge vif.clk);

        // Env run
        env = new(vif);
        env.run();

        // 타임아웃
        repeat (200000) @(posedge vif.clk);
        $display("\n[TB] Timeout finish");
        $finish;
    end

    // VCD
    initial begin
        $dumpfile("tb_vga_cartoon_uvmstyle.vcd");
        $dumpvars(0, tb_vga_cartoon_uvmstyle);
    end
endmodule
