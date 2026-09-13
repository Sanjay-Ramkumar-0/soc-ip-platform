# SoC-IP Platform — Shallow DMA Streaming Engine

This version is intentionally kept shallow for functional simulation.

Main path:

Descriptor Manager -> DMA Read -> AXI-Stream Register Slice -> DMA Write -> Destination RAM

## Run the main simulation

From the project root:

```bash
chmod +x run_sim.sh
./run_sim.sh
```

Or manually:

```bash
mkdir -p sim
iverilog -g2012 -s tb_data_streaming_engine -o sim/data_streaming_engine.vvp $(cat rtl_files.f) tb/tb_data_streaming_engine.v
vvp sim/data_streaming_engine.vvp
```

The testbench transfers eight 32-bit words (32 bytes) from source RAM address `0x100` to destination RAM address `0x200`, then checks every destination word.

A VCD named `tb_data_streaming_engine.vcd` is generated in the project root.

## Fixes in this version

- `dma_descriptor_manager.v`: `descriptor_valid_out` is combinationally gated by `!descriptor_clear`. This prevents a one-cycle window after `transfer_active` drops (while the registered valid is still high) from re-asserting `start_transfer` and starting a second unwanted DMA.
- `data_streaming_engine.v`: RAM address muxes include `start_transfer` so the source/destination RAMs see the DMA address on the same cycle the engines present it (eliminates a 1-cycle mux lag).
- `dma_read_engine.v`: synchronous RAM read latency is handled explicitly (WAIT1/WAIT2).
- `dma_write_engine.v`: AXI-Stream handshake directly controls the RAM write.
- All internal nets declared before module instances.
- Testbench and file list cleaned for Icarus Verilog.

The arbiter, broadcaster, switch and AXI FIFO remain as independent building blocks; they are not forced into the shallow DMA datapath yet.
