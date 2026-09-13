#!/bin/bash
set -e
mkdir -p sim
iverilog -g2012 -s tb_data_streaming_engine -o sim/data_streaming_engine.vvp $(cat rtl_files.f) tb/tb_data_streaming_engine.v
vvp sim/data_streaming_engine.vvp
