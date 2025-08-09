# FFT Project

## 📌 Overview
This project implements a **Fast Fourier Transform (FFT)** hardware architecture using a pipelined structure and headroom-based scaling.  
The workflow includes **MATLAB modeling**, **SystemVerilog RTL design**, **Synopsys VCS/Verdi verification**, **Design Compiler synthesis**, and **FPGA implementation with Vivado**.

---

## 🛠 Development Environment

| Stage                | Tool / Language        | Description |
|----------------------|------------------------|-------------|
| **Modeling**         | MATLAB                 | Algorithm design, fixed-point simulation |
| **RTL Design**       | SystemVerilog          | Hardware description and module implementation |
| **Verification**     | Synopsys VCS + Verdi   | RTL simulation, debugging, and waveform analysis |
| **Synthesis**        | Synopsys Design Compiler | ASIC synthesis, area/timing optimization |
| **FPGA Implementation** | Xilinx Vivado      | FPGA synthesis, place & route, bitstream generation |

---

## 📂 Directory Structure


---

## ⚙ Features
- **Pipelined FFT Architecture** optimized for high-frequency operation  
- **Headroom-Based Scaling** to prevent overflow while minimizing resource usage  
- **Configurable Data Widths** for different fixed-point precisions  
- **MATLAB Reference Model** for algorithm-to-RTL verification  
- **ASIC & FPGA Ready** for both prototyping and tape-out

---

## 🚀 How to Run

### 1. RTL Simulation (VCS + Verdi)
```bash
cd project/systemverilog
vcs -full64 -sverilog *.sv tb_top.sv -debug_access+all
./simv
verdi -ssf wave.fsdb
