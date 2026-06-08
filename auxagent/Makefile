# auxagent - build & test
#
# Host targets (run on your Mac/Linux):
#   make test     build and run the unit tests for the protocol layer
#   make clean    remove build artifacts
#
# The agent binary itself is compiled ON the target A/UX machine (m68k COFF,
# gcc 2.7.2.3), not here -- see README "Build & bootstrap" and install/bootstrap.sh.
# `make agent-host` builds it locally only as a compile sanity-check.

CC      ?= cc
CFLAGS  ?= -O -Wall
SRC      = src
TESTS    = tests

.PHONY: test clean agent-host

test: $(TESTS)/test_aap
	./$(TESTS)/test_aap

$(TESTS)/test_aap: $(TESTS)/test_aap.c $(SRC)/aap.c $(SRC)/aap.h
	$(CC) $(CFLAGS) -I$(SRC) $(TESTS)/test_aap.c $(SRC)/aap.c -o $@

# Local compile check of the full agent (won't run usefully off A/UX, just
# confirms it compiles with a modern toolchain).
agent-host: $(SRC)/auxagent.c $(SRC)/aap.c
	$(CC) $(CFLAGS) -I$(SRC) $(SRC)/auxagent.c $(SRC)/aap.c -o auxagent.host

clean:
	rm -f $(TESTS)/test_aap auxagent.host
