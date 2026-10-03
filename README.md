# Parameterized Synchronous FIFO

A single-clock FIFO written in Verilog, with configurable data width and depth, registered read data, and protection against invalid reads and writes. Built incrementally as an RTL-design and verification portfolio project.

**Demonstrated configuration:** 8-bit data, 16 entries.  
**Workflow:** AMD Vivado / XSim behavioral simulation.

## Features

- Parameterized `DATA_WIDTH` and `DEPTH`.
- Active-low, synchronous reset.
- Full and empty flags derived from an occupancy counter.
- Overflow and underflow indicators; rejected requests do not advance the corresponding pointer.
- Simultaneous read/write when neither empty nor full.
- Explicit circular-pointer wrap at `DEPTH - 1`.
- Self-checking directed testbench with an error count and final result.

Almost-full and almost-empty flags are intentionally outside this project's scope.

## Repository layout

```text
.
├── README.md
├── .gitignore
├── rtl/
│   └── sync_fifo.v
├── tb/
│   └── sync_fifo_tb.v
└── docs/
    ├── design.md
    ├── simulation.md
    ├── device-views.md
    └── images/
        ├── fifo-simulation-waveform.png
        ├── fifo-schematic.png
        ├── fifo-device-overview.png
        └── fifo-device-detail.png
```

RTL, verification code, and portfolio evidence are kept separate. Vivado-generated project files are not required in the repository; the source files can be added to a fresh project.

## Run in Vivado

1. Create an RTL project and select the FPGA part or board you use.
2. Add `rtl/sync_fifo.v` as a **Design Source**; set `sync_fifo` as the design top.
3. Add `tb/sync_fifo_tb.v` as a **Simulation Source**; set `sync_fifo_tb` as the simulation top.
4. Select **Run Simulation → Run Behavioral Simulation** and run until `$finish`.
5. Confirm the console reports `All tests passed`, with no earlier failures.

[Simulation and waveform guide](docs/simulation.md) · [Design explanation](docs/design.md)

## Verification evidence

The saved Vivado waveform shows `errors = 0` for the directed 8-bit, 16-entry test sequence:

- Reset and initial flags.
- Four queued writes and ordered reads.
- Empty-read rejection, output hold, and underflow recovery.
- Fill to full, rejected extra write, and overflow recovery.
- Complete ordered drain, also exercising pointer wrap.
- Simultaneous read/write with one queued entry, followed by reading the replacement entry.

![Vivado behavioral simulation waveform](docs/images/fifo-simulation-waveform.png)

Hexadecimal display: `10` = decimal 16, `63` = decimal 99, and `42` = decimal 66.

## Design behavior

A successful read updates `rd_data` after the rising edge; otherwise it holds its previous value. Reset clears logical occupancy and control registers, not the memory array.

Both requests are evaluated using the state before the edge:

| Starting state | Both enables asserted |
|---|---|
| Empty | Write accepted; read rejected with underflow |
| Neither empty nor full | Both accepted; occupancy unchanged |
| Full | Read accepted; write rejected with overflow |

The boundary behavior is intentional: this FIFO does not bypass a new write to an empty read, or accept a replacement write on the same edge that reads a full FIFO.

## Scope and remaining work

This is a directed behavioral-verification milestone, not an exhaustive verification or board-validation claim. Simultaneous requests at full/empty boundaries, reset with queued data, randomized traffic, and other parameter configurations remain to be tested.

The [schematic and device captures](docs/device-views.md) document design exploration. Timing closure, implementation success, FPGA resource totals, and board operation are not established by these screenshots. No board-specific pin or timing constraints are supplied.
