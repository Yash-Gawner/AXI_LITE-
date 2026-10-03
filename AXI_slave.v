module AXI_slave(

    input clk,
    input reset,

    input [31:0]AWADDR,
    input AWVALID,
    output reg AWREADY,

    input [31:0]WDATA,
    input WVALID,
    output reg WREADY,

    output reg [1:0]BRESP,
    output reg BVALID ,
    input BREADY,

    input [31:0]ARADDR,
    input ARVALID,
    output reg ARREADY,

    output reg [31:0]RDATA,
    output reg RVALID ,
    input RREADY,

    output reg [1:0]RRESP,

    input [3:0] WSTRB,

    output reg [31:0]read_addr,
    output reg [31:0]write_addr,
    output reg [31:0]write_data,
    output reg mem_we, // 1-cycle pulse: write_addr/write_data valid
    //it's the write-enable strobe that tells your memory/register block "write_addr
    //and write_data are valid right now, do the write," so the write happens exactly once
    //instead of on every clock.
    input [31:0]in_data,  // combinational read of memory at read_addr
    output reg [3:0] write_strb  // this will go into memory and 
);

parameter IDLE       = 3'b000,
          WRITE_ADDR = 3'b001,
          WRITE_DATA = 3'b010,
          WRITE_RESP = 3'b011,
          READ_ADDR  = 3'b100,
          READ_DATA  = 3'b101;

reg [2:0] state , next_state;
//reg [3:0] write_strb;

always @(posedge clk or posedge reset)begin

    if(reset)begin

        state <= IDLE;

    end

    else begin

        state <= next_state;

    end
end

always @(*)begin

    AWREADY = 0;
    WREADY  = 0;
    BRESP   = 0;
    BVALID  = 0;
    ARREADY = 0;
    RVALID  = 0;
    RRESP   = 0;
    RDATA   = in_data;  // valid whenever RVALID is high

    case(state)

    WRITE_ADDR : AWREADY = 1;

    WRITE_DATA : WREADY = 1;

    WRITE_RESP : BVALID = 1;

    READ_ADDR : ARREADY = 1;

    READ_DATA : RVALID = 1;

    default : ;

    endcase
end

always @(posedge clk or posedge reset)begin

    if(reset) begin

        read_addr  <= 0;
        // RDATA   <= 0;
        write_addr <= 0;
        write_data <= 0;
        mem_we     <= 0;
        write_strb <= 0;

    end

    else begin
        mem_we <= 0;  // default: 1-cycle pulse

        if(AWVALID && AWREADY)
            write_addr <= AWADDR;

        if(WVALID && WREADY)begin
            write_data <= WDATA;
            write_strb <= WSTRB;   // new output reg [3:0]
            mem_we <= 1;
        end
        
        // this goes into memory
        // // in memory: mem is the memory
        // else if (mem_we) begin
        //     if (write_strb[0]) mem[write_addr][7:0]   <= write_data[7:0]; 
        //     //If byte 0 is enabled, write the lowest 8 bits.
        //     if (write_strb[1]) mem[write_addr][15:8]  <= write_data[15:8];
        //     //If byte 1 is enabled, write bits 15:8.
        //     if (write_strb[2]) mem[write_addr][23:16] <= write_data[23:16];
        //     //If byte 2 is enabled, write bits 23:16.
        //     if (write_strb[3]) mem[write_addr][31:24] <= write_data[31:24];
        //     //If byte 3 is enabled, write the upper 8 bits.
        // end

        if(ARVALID && ARREADY)
            read_addr <= ARADDR;
        
        // else if(RVALID && RREADY)
        //     RDATA <= in_data;
        //that line loads RDATA at the same edge where the master reads it,so the master sees the old value;
        //driving RDATA = in_data combinationally keeps it already valid while RVALID is high.
            
    end
end

always @(*) begin

    next_state = state;

    case(state)

    IDLE : begin

        if(AWVALID)
            next_state = WRITE_ADDR;
        
        else if(ARVALID)
            next_state = READ_ADDR;
        
        else 
            next_state = IDLE;
    end

    WRITE_ADDR : begin

        next_state = (AWREADY && AWVALID) ? WRITE_DATA : WRITE_ADDR;

    end

    WRITE_DATA : begin

        next_state = (WVALID && WREADY) ? WRITE_RESP : WRITE_DATA;

    end

    WRITE_RESP : begin

        next_state = (BVALID && BREADY) ? IDLE : WRITE_RESP;

    end

    READ_ADDR : begin

        next_state = (ARVALID && ARREADY) ? READ_DATA : READ_ADDR;

    end

    READ_DATA : begin

        next_state = (RVALID && RREADY) ? IDLE : READ_DATA;

    end

    default : next_state = IDLE;

    endcase

end


endmodule 