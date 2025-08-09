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

## ⚙ Features
- **Pipelined FFT Architecture** optimized for 500MHz operation  
- **Headroom-Based Scaling** to prevent overflow while minimizing resource usage  
- **Configurable Data Widths** for different fixed-point precisions  
- **MATLAB Reference Model** for algorithm-to-RTL verification  
- **ASIC & FPGA Ready** for both prototyping and tape-out

---

> 💡 *본 프로젝트는 Modeling -> RTL → Verification → Synthesis → Gate Simulation & BitStream 순으로 진행됩니다.*
