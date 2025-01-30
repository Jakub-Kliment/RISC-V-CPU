export HERE = $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))


SHELL   := /usr/bin/bash
NULL    := >/dev/null 2>&1

TOOL    ?= verilator
TSCALE  := 1ns/1ns
FLIST   := $(HERE)/flist.vc

OUT_DIR := $(HERE)/out
OUT_MT  ?= 12

SIM_DIR := $(HERE)/sim
SIM_MT  ?= 4

.PHONY: out clean

all: out

$(OUT_DIR):
	mkdir -p $@

out: $(OUT_DIR)
	cd $(OUT_DIR) && verilator -j $(OUT_MT) --threads $(SIM_MT) --timescale $(TSCALE) --top-module tb --cc --exe --build --assert --x-initial-edge --timing --trace --trace-underscore -Wno-WIDTH -Wno-UNSIGNED -Wno-UNOPTTHREADS -O2 -LDFLAGS -lcppdap -LDFLAGS -ldw -LDFLAGS -lelf -CFLAGS -std=c++20 -f $(FLIST)

clean:
	rm -rf $(OUT_DIR) $(SIM_DIR)
