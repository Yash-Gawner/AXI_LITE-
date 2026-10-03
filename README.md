# AXI_LITE-
AXI4-Lite Master-Slave RTL design in Verilog with memory interface, read/write transactions, VALID/READY handshaking, WSTRB support, and simulation

# AXI4-Lite Master-Slave Memory Interface

A Verilog RTL implementation of an **AXI4-Lite Master and Slave interface** connected to a simple 32-bit memory.

This project was built to understand how AXI4-Lite transactions work at RTL level, including **VALID/READY handshakes, write transactions, read transactions, response channels, WSTRB byte enables, and master/slave FSMs**.

---

## Project Overview

The project contains:

* AXI4-Lite Master
* AXI4-Lite Slave
* 32-bit simple memory
* Top-level module connecting all components
* Testbench for verifying the AXI4-Lite Master

The basic architecture is:

```text
             AXI4-Lite Interface
                    |
                    v
          +-------------------+
          |    AXI Master     |
          |                   |
          | Write / Read FSM  |
          +---------+---------+
                    |
        AXI4-Lite Signals
                    |
                    v
          +-------------------+
          |    AXI Slave      |
          |                   |
          | Write / Read FSM  |
          +---------+---------+
                    |
              Memory Interface
                    |
                    v
          +-------------------+
          |    Simple RAM     |
          |   32-bit × 256    |
          +-------------------+
```

---

# AXI4-Lite Channels

AXI4-Lite uses five independent channels.

## Write Channels

### 1. Write Address Channel

Signals:

```text
AWADDR
AWVALID
AWREADY
```

The master places the address on `AWADDR` and asserts `AWVALID`.

The slave asserts `AWREADY` when it is ready to accept the address.

A handshake occurs when:

```text
AWVALID && AWREADY
```

---

### 2. Write Data Channel

Signals:

```text
WDATA
WSTRB
WVALID
WREADY
```

`WDATA` contains the data to be written.

`WSTRB` determines which bytes of the 32-bit data should actually be written.

For example:

```text
WSTRB = 4'b1111
```

means all four bytes are written.

```text
WSTRB = 4'b0001
```

means only the lowest byte is written.

The write-data handshake occurs when:

```text
WVALID && WREADY
```

---

### 3. Write Response Channel

Signals:

```text
BRESP
BVALID
BREADY
```

After accepting the write transaction, the slave generates a response.

The response codes used are:

```text
00 = OKAY
01 = EXOKAY
10 = SLVERR
11 = DECERR
```

The response handshake occurs when:

```text
BVALID && BREADY
```

---

# Read Channels

### 4. Read Address Channel

Signals:

```text
ARADDR
ARVALID
ARREADY
```

The master sends the address that it wants to read.

The handshake occurs when:

```text
ARVALID && ARREADY
```

---

### 5. Read Data Channel

Signals:

```text
RDATA
RRESP
RVALID
RREADY
```

The slave returns the requested data using `RDATA`.

`RRESP` indicates the result of the read transaction.

The read-data handshake occurs when:

```text
RVALID && RREADY
```

---

# Master FSM

The AXI Master uses the following states:

```text
IDLE
WRITE_ADDR
WRITE_DATA
WRITE_RESP
READ_ADDR
READ_DATA
```

### Write transaction

```text
IDLE
  |
  v
WRITE_ADDR
  |
  | AWVALID && AWREADY
  v
WRITE_DATA
  |
  | WVALID && WREADY
  v
WRITE_RESP
  |
  | BVALID && BREADY
  v
IDLE
```

### Read transaction

```text
IDLE
  |
  v
READ_ADDR
  |
  | ARVALID && ARREADY
  v
READ_DATA
  |
  | RVALID && RREADY
  v
IDLE
```

---

# Slave FSM

The slave also uses a state machine:

```text
IDLE
WRITE_ADDR
WRITE_DATA
WRITE_RESP
READ_ADDR
READ_DATA
```

The slave generates the appropriate `READY` and `VALID` signals depending on its current state.

For example:

```text
WRITE_ADDR  -> AWREADY = 1
WRITE_DATA  -> WREADY  = 1
WRITE_RESP  -> BVALID  = 1
READ_ADDR   -> ARREADY = 1
READ_DATA   -> RVALID  = 1
```

---

# Memory

The project uses a simple:

```text
32-bit × 256 word
```

memory.

```verilog
reg [31:0] mem [0:255];
```

The memory uses word-aligned addresses:

```text
Address bits [9:2]
```

to select one of the 256 memory locations.

For example:

```text
0x00000000 -> memory[0]
0x00000004 -> memory[1]
0x00000008 -> memory[2]
...
```

The memory has a combinational read:

```text
read_addr -> in_data
```

and a clocked write.

---

# WSTRB Byte Enable

`WSTRB` allows individual bytes of a 32-bit word to be written.

The 32-bit data is divided into four bytes:

```text
WDATA[31:24] -> WSTRB[3]
WDATA[23:16] -> WSTRB[2]
WDATA[15:8]  -> WSTRB[1]
WDATA[7:0]   -> WSTRB[0]
```

For example:

```text
WDATA = 32'h12345678
WSTRB = 4'b1111
```

writes:

```text
12 34 56 78
```

If:

```text
WSTRB = 4'b0001
```

only:

```text
78
```

is written.

---

# Master Input and Status Signals

The master provides a simple interface to outside logic:

```text
in_address
in_data
in_strb
start
write_en
```

### `start`

Starts a transaction.

### `write_en`

```text
1 = Write
0 = Read
```

### `in_address`

Address used for the AXI transaction.

### `in_data`

Data used for a write transaction.

### `in_strb`

Byte-enable information for the write.

---

# Transaction Status Outputs

The master provides:

```text
busy
read_done
write_done
read_resp
write_resp
error
```

### `busy`

Indicates that the master is currently performing a transaction.

```text
busy = 1 -> transaction active
busy = 0 -> master is idle
```

### `read_done`

One-clock pulse indicating that a read transaction has completed.

### `write_done`

One-clock pulse indicating that a write transaction has completed.

### `read_resp`

Contains the AXI read response:

```text
00 = OKAY
01 = EXOKAY
10 = SLVERR
11 = DECERR
```

### `write_resp`

Contains the AXI write response.

### `error`

Indicates whether the most recent completed AXI transaction returned a non-OKAY response.

---

# Project Files

The project can be organized as:

```text
AXI4-Lite/
│
├── AXI_master.v
├── AXI_slave.v
├── simple_mem.v
├── AXI_top_module.v
├── AXI_master_tb.v
│
└── README.md
```

### `AXI_master.v`

Implements the AXI4-Lite master FSM and generates AXI transactions.

### `AXI_slave.v`

Receives AXI transactions and connects them to the memory interface.

### `simple_mem.v`

Implements the 32-bit × 256 memory.

### `AXI_top_module.v`

Connects:

```text
AXI Master
    |
AXI Slave
    |
Simple Memory
```

### `AXI_master_tb.v`

Testbench used to verify AXI Master write and read transactions.

---

# Write Transaction

A typical write transaction follows:

```text
1. External logic asserts start
2. Master captures address, data and WSTRB
3. Master enters WRITE_ADDR
4. Master asserts AWVALID
5. Slave asserts AWREADY
6. Address handshake occurs
7. Master enters WRITE_DATA
8. Master asserts WVALID
9. Slave asserts WREADY
10. Data handshake occurs
11. Slave generates BVALID
12. Master asserts BREADY
13. Write response handshake occurs
14. write_done is generated
15. Master returns to IDLE
```

---

# Read Transaction

A typical read transaction follows:

```text
1. External logic asserts start
2. Master captures the address
3. Master enters READ_ADDR
4. Master asserts ARVALID
5. Slave asserts ARREADY
6. Address handshake occurs
7. Slave accesses memory
8. Slave enters READ_DATA
9. Slave asserts RVALID
10. Master asserts RREADY
11. Read data handshake occurs
12. Master captures RDATA and RRESP
13. read_done is generated
14. Master returns to IDLE
```

---

# Important AXI4-Lite Concept

The most important concept implemented in this project is the:

```text
VALID / READY handshake
```

A transfer happens only when both signals are HIGH on the same clock edge.

For example:

```text
AWVALID && AWREADY
```

means the write address transfer has happened.

Similarly:

```text
WVALID && WREADY
BVALID  && BREADY
ARVALID && ARREADY
RVALID  && RREADY
```

represent successful transfers on the corresponding channels.

The master or slave must keep `VALID` asserted until the other side asserts `READY`.

---

# Verification

The testbench verifies:

* Write address transfer
* Write data transfer
* Write response
* Read address transfer
* Read data transfer
* VALID/READY handshakes
* AXI FSM state transitions

Waveforms can be generated using:

```text
$dumpfile("axi_master_tb.vcd");
$dumpvars(0, AXI_master_tb);
```

and viewed using GTKWave.

---

# Tools Used

* Verilog HDL
* Icarus Verilog
* GTKWave
* VS Code
* Git / GitHub

---

# What I Learned

Through this project, I learned:

* AXI4-Lite architecture
* AXI read and write channels
* VALID/READY handshake protocol
* AXI response channels
* `BRESP` and `RRESP`
* `WSTRB` byte enables
* Master and slave FSM design
* Capturing transaction inputs using registers
* Connecting multiple Verilog modules
* Creating a top-level RTL design
* Connecting an AXI interface to memory
* Writing a Verilog testbench
* Debugging transactions using simulation waveforms

---

# Future Improvements

Possible improvements to this project include:

* Add support for multiple outstanding transactions
* Improve error generation in the slave
* Add address decoding
* Add multiple AXI4-Lite slaves
* Add register-mapped peripherals
* Add configurable memory size
* Add more comprehensive assertions
* Add SystemVerilog Assertions (SVA)
* Create a more complete AXI4-Lite verification environment
* Extend the project toward AXI4-Stream

---

## Project Goal

The main goal of this project is to understand **how an AXI4-Lite interface is implemented from scratch in RTL**, rather than treating AXI as a black-box IP.

This project forms a foundation for learning more advanced interfaces such as:

```text
AXI4-Lite
   ↓
AXI4-Stream
   ↓
AXI4
   ↓
UVM / Advanced Verification
```
AUTHOR : YASH RAJENDRA GAWNER
