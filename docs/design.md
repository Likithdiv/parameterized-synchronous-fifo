# FIFO design explanation

[Back to README](../README.md) · [Simulation guide](simulation.md)

## What the FIFO does

A FIFO stores values in the order they arrive. The oldest unread value is the next value returned. This design has one shared clock for reads and writes.

For example, writing 11, 22, and 33 creates the logical queue:

```text
Next to read → [11] [22] [33] ← Next write joins here
```

The queue is implemented using an array, two circular pointers, and an occupancy counter, rather than physically shifting all stored values.

## Parameters

| Parameter | Default | Meaning |
|---|---:|---|
| `DATA_WIDTH` | 8 | Number of bits per stored value |
| `DEPTH` | 16 | Number of values the FIFO can hold |

Both parameters must be positive integers. Pointer width is `max(1, $clog2(DEPTH))`; counter width is `max(1, $clog2(DEPTH + 1))`. The counter must represent both zero and the full depth.

Pointers explicitly wrap to zero at `DEPTH - 1`, so the RTL is intended to support non-power-of-two depths too. Only the 8-bit, 16-entry configuration is demonstrated by the checked-in testbench and screenshot; other configurations need their own tests.

## Interface

| Signal | Direction | Meaning |
|---|---|---|
| `clk` | Input | Operations occur on the rising edge |
| `rst_n` | Input | Active-low synchronous reset |
| `wr_en` | Input | Request to store `wr_data` |
| `rd_en` | Input | Request to retrieve the oldest entry |
| `wr_data[DATA_WIDTH-1:0]` | Input | Value to store |
| `rd_data[DATA_WIDTH-1:0]` | Output | Registered result of the last accepted read |
| `full` | Output | No free entries: `count == DEPTH` |
| `empty` | Output | No unread entries: `count == 0` |
| `overflow` | Output | Write requested while already full |
| `underflow` | Output | Read requested while already empty |

Almost-full and almost-empty flags are not implemented.

## Internal connections

```text
wr_data ──accepted write──> mem[wr_ptr]
                                 │
                   mem[rd_ptr] ──accepted read──> rd_data

wr_ptr: next location to write
rd_ptr: oldest unread location
count:  number of valid unread entries
            ├── count == 0     → empty
            └── count == DEPTH → full
```

The pointers can coincide in both the empty and full states. The occupancy counter distinguishes those states.

## One rising clock edge

First check reset. If `rst_n = 0`, reset takes priority over all requests.

Otherwise, decide which requests are allowed using the flags from before this edge:

```text
write_ok = wr_en AND NOT full
read_ok  = rd_en AND NOT empty
```

For an accepted write, store the input at the write pointer and advance that pointer. For an accepted read, load the addressed memory value into `rd_data` and advance the read pointer.

Update occupancy once, based on accepted operations:

| Accepted write | Accepted read | Counter change |
|---|---|---|
| No | No | Hold |
| Yes | No | Add one |
| No | Yes | Subtract one |
| Yes | Yes | Hold |

The RTL uses nonblocking assignments, so the register updates take effect after the clock event.

## Read-output timing

`rd_data` is registered, not a continuously visible view of the oldest memory entry. Writing alone does not update it. A rejected read leaves it unchanged.

After reading the last entry, `empty` becomes high while `rd_data` still holds that successfully read entry. The flag describes remaining queue occupancy, not whether the previous read result should disappear.

There is no separate read-valid output. A consumer can determine whether a read will be accepted from `rd_en && !empty` before the edge, with reset inactive.

## Simultaneous requests

With one queued entry, reading 55 while writing 66 returns 55 and leaves 66 queued. Occupancy stays at one.

At the boundaries, this design uses a conservative policy:

| State before edge | Accepted operation | Result |
|---|---|---|
| Empty; both requested | Write only | One entry stored; underflow asserted; read output held |
| Partially occupied; both requested | Read and write | Oldest entry returned; new entry stored; occupancy held |
| Full; both requested | Read only | One entry removed; overflow asserted; input write rejected |

A read freeing space at a full FIFO does not make the simultaneous write eligible. A write arriving at an empty FIFO does not make the simultaneous read eligible. These decisions are made before the edge, not after the other operation.

## Error protection

Rejected writes do not modify memory or advance the write pointer. Rejected reads do not advance the read pointer or overwrite `rd_data`. Any separately accepted operation on that edge still proceeds.

The error flags are registered indications, not sticky history bits. They are recomputed each non-reset edge. A continuously invalid request can keep its error flag high across multiple cycles; removing the invalid request clears it on the next rising edge.

## Reset

On a rising edge with `rst_n = 0`, both pointers, occupancy, `rd_data`, and error flags become zero. The resulting status is empty and not full.

The array is not erased. Old bits may remain in memory, but zero occupancy makes them invalid queue entries. Reads after reset must wait for newly accepted writes.

Asserting reset between rising edges does not immediately reset the registers. Reset with queued data is specified by the RTL but is not covered by the current directed testbench.

## Hardware evidence

[View the schematic and device screenshots](device-views.md). Storage mapping depends on synthesis decisions and the target FPGA; no specific BRAM inference, area, maximum frequency, or timing result is claimed here.
