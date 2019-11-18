.PHONY: all clean synthesis run deploy

BITSTREAM := impl/pnr/M5Stack_TangNano.fs
SRCS := $(wildcard src/*.v) $(wildcard src/*.sv) $(wildcard src/*.cst) $(wildcard src/*.sdc) src/synthesize.cfg

all: synthesis

$(BITSTREAM): $(SRCS)
	gw_sh ./project.tcl

synthesis: $(BITSTREAM)

run: $(BITSTREAM)
	if lsmod | grep ftdi_sio; then sudo modprobe -r ftdi_sio; fi
	programmer_cli --device GW1N-1 --run 2 --fsFile $(abspath $(BITSTREAM))

deploy: $(BITSTREAM)
	if lsmod | grep ftdi_sio; then sudo modprobe -r ftdi_sio; fi
	programmer_cli --device GW1N-1 --run 6 --fsFile $(abspath $(BITSTREAM))

clean:
	-@$(RM) -rf impl
