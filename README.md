# UART Transmitter/Receiver in Verilog (Loopback Verified)

## Overview
This project implements a fully synthesizable **UART (Universal Asynchronous Receiver/Transmitter)** in Verilog.  
It includes a transmitter, receiver, baud-rate generator, and a self-checking testbench that verifies correct serial communication through a **TX→RX loopback**.

UART is a common hardware interface used in SoCs, embedded systems, FPGA designs, and debug/boot paths — making this a strong real-world RTL block to showcase.

---

## Features
- Parameterized for `CLK_HZ` and `BAUD`
- Standard UART frame format:
  - **1 start bit (0)**
  - **8 data bits, LSB-first**
  - **1 stop bit (1)**
- Dedicated TX/RX finite state machines (FSMs)
- Baud tick generator for precise bit timing
- **Loopback verification** using Icarus Verilog + GTKWave
- Stable handshake (`tx_valid/tx_ready`, `rx_valid/rx_ready`)

---

## File Structure
baud_gen.sv // generates baud_tick / half_tick
uart_tx.sv // UART transmitter FSM
uart_rx.sv // UART receiver FSM + mid-bit sampling
tb_uart.sv // self-checking loopback testbench
dump.vcd // waveform output (simulation)


---

## How It Works (High Level)
1. **baud_gen.sv** divides the system clock to generate ticks at the UART bit rate.
2. **uart_tx.sv** waits for `tx_valid`, latches `tx_data`, and transmits:
   idle → start → 8 data bits → stop.
3. **uart_rx.sv** detects the start bit, then samples each data bit at the **center of its bit period** for robustness.
4. **tb_uart.sv** sends 4 known bytes and checks they are received correctly via loopback.

---

## Simulation
Run the following in PowerShell inside the project folder:

```bash
iverilog -g2012 -o sim baud_gen.sv uart_tx.sv uart_rx.sv tb_uart.sv
vvp sim
gtkwave dump.vcd

## Expected terminal output:
RX got 55 ...
RX got A3 ...
RX got 00 ...
RX got FF ...
PASS ✅ UART loopback works
