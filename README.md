# SoC-IP Platform — High-Throughput Data Streaming Engine

A modular RTL-based SoC IP platform implementing a configurable data streaming engine with AXI4-Stream interfaces, DMA-based data movement, buffering, memory access, and synthesis/physical-design support.

The project is developed with a hardware-first methodology, progressing from synthesizable RTL and functional simulation to logic synthesis and ASIC physical implementation using an OpenLane/SKY130-based flow.

---

## Overview

The **SoC-IP Platform** is a reusable digital hardware subsystem designed around a high-throughput data movement and streaming architecture.

The central component is a **Data Streaming Engine** that connects memory-oriented DMA functionality with streaming data paths. The design is decomposed into independent RTL modules for:

- AXI4-Stream data transport
- Stream arbitration
- Stream broadcasting
- Stream switching
- Stream buffering
- Register slicing
- DMA address generation
- DMA descriptor management
- DMA read operations
- DMA write operations
- Synchronous FIFO buffering
- Single-port RAM access

The architecture is intentionally modular so that individual components can be verified, synthesized, optimized, and reused independently.

The repository also contains simulation testbenches, synthesis scripts, generated synthesis artifacts, and an OpenLane configuration for ASIC-oriented implementation.

---

## Key Features

### Streaming Infrastructure

- AXI4-Stream compatible data-path components
- Stream arbitration
- Stream broadcasting
- Stream switching
- Register slicing for pipeline timing and throughput improvement
- FIFO-based buffering
- Modular streaming datapath architecture

### DMA Subsystem

- DMA address generation
- DMA descriptor management
- DMA read engine
- DMA write engine
- Memory-to-stream and stream-to-memory data movement architecture
- Decoupled control and data-path organization

### Memory Subsystem

- Synchronous FIFO implementation
- Single-port RAM implementation
- Memory access abstraction for the streaming engine
- Buffering between memory and streaming interfaces

### Verification

- Dedicated RTL testbenches
- FIFO verification
- RAM verification
- Data streaming engine verification
- File-list based simulation flow
- Functional simulation support

### Synthesis

- Yosys synthesis flow
- Synthesized RTL/netlist output
- Dedicated synthesis scripts
- RTL-to-gate-level design progression

### ASIC Implementation

- OpenLane-based physical implementation
- SKY130-oriented configuration
- ASIC synthesis and implementation flow
- Physical-design collateral generated through OpenLane

---

# Architecture

The overall architecture can be viewed as a layered data-movement system:

```text
                         +----------------------+
                         |   Control / Config   |
                         |     Interface        |
                         +----------+-----------+
                                    |
                                    v
                     +----------------------------+
                     |    DMA Descriptor Manager  |
                     +-------------+--------------+
                                   |
                                   v
                     +----------------------------+
                     |    DMA Address Generator   |
                     +-------------+--------------+
                                   |
                    +--------------+--------------+
                    |                             |
                    v                             v
          +-------------------+         +-------------------+
          |   DMA Read Engine |         |  DMA Write Engine |
          +---------+---------+         +---------+---------+
                    |                             ^
                    |                             |
                    v                             |
             +------------+                 +------------+
             |   Memory   |                 |   Memory   |
             |   / RAM    |                 | Interface  |
             +------+-----+                 +------+-----+
                    |                              ^
                    |                              |
                    v                              |
          +-----------------------------------------------+
          |              AXI-Stream Data Path             |
          |                                               |
          |  +--------+   +---------+   +-------------+  |
          |  | Arbiter|-->| Switch  |-->| Register    |  |
          |  +--------+   +---------+   | Slice       |  |
          |                              +-------------+  |
          |                                      |       |
          |                              +-------v-----+ |
          |                              | Stream FIFO | |
          |                              +-------------+ |
          |                                      |       |
          |                              +-------v-----+ |
          |                              | Broadcaster | |
          |                              +-------------+ |
          +-----------------------------------------------+
