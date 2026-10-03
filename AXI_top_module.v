module AXI_top_module(

    input       clk,
    input       reset,
    input       start,
    input       write_en,
    input [31:0]in_data,
    input [31:0]in_address,
    input [3:0] in_strb,

    output [31:0]read_data,
    output [1:0] read_resp,
    output       read_done,
    output       write_done,
    output [1:0] write_resp,
    output       error,
    output       busy

);

wire [31:0]AWADDR,WDATA,ARADDR,RDATA;
wire [1:0] BRESP, RRESP;
wire [3:0] WSTRB;
wire AWVALID ,AWREADY,WVALID,WREADY,BVALID,BREADY,ARVALID,ARREADY,RVALID,RREADY;

wire [31:0]mem_write_addr, mem_write_data, mem_read_addr, mem_read_data;
wire [3:0]mem_write_strb;
wire mem_we;

AXI_master M1(

    .clk(clk),
    .reset(reset),
    .busy(busy),
    .in_data(in_data),
    .in_address(in_address),
    .start(start),
    .write_en(write_en),
    .in_strb(in_strb),
    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),
    .BRESP(BRESP),
    .BREADY(BREADY),
    .BVALID(BVALID),
    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RVALID(RVALID),
    .RDATA(RDATA),
    .RREADY(RREADY),
    .RRESP(RRESP),
    .WSTRB(WSTRB),
    .read_data(read_data),
    .read_resp(read_resp),
    .read_done(read_done),
    .write_done(write_done),
    .write_resp(write_resp),
    .error(error)

);

AXI_slave S1(

    .clk(clk),
    .reset(reset),
    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),
    .BRESP(BRESP),
    .BREADY(BREADY),
    .BVALID(BVALID),
    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RVALID(RVALID),
    .RDATA(RDATA),
    .RREADY(RREADY),
    .RRESP(RRESP),
    .WSTRB(WSTRB),

    .read_addr(mem_read_addr),
    .write_addr(mem_write_addr),
    .write_data(mem_write_data),
    .write_strb(mem_write_strb),
    .mem_we(mem_we),
    .in_data(mem_read_data)
);

simple_mem SM(

    .clk(clk),
    .mem_we(mem_we),
    .write_addr(mem_write_addr),
    .write_data(mem_write_data),
    .write_strb(mem_write_strb),
    .read_addr(mem_read_addr),
    .in_data(mem_read_data)
);

endmodule 