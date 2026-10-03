module AXI_tb;

reg clk = 0;
reg reset = 1;
reg [31:0]in_data = 0;
reg [31:0]in_address = 0;
reg start = 0;
reg write_en = 0;
reg [3:0]in_strb = 0;

wire [31:0]read_data;
wire [1:0]read_resp;
wire read_done, write_done;
wire [1:0]write_resp;
wire error;
wire busy;

AXI_top_module uut(

    .clk(clk),
    .reset(reset),
    .in_data(in_data),
    .in_address(in_address),
    .start(start),
    .write_en(write_en),
    .in_strb(in_strb),
    .read_data(read_data),
    .read_resp(read_resp),
    .read_done(read_done),
    .write_done(write_done),
    .write_resp(write_resp),
    .error(error),
    .busy(busy)

);

always #5 clk = ~clk;

task write(input [31:0]address , input [31:0]data, input [3:0]strb);

begin
    @(negedge clk)
    in_address = address; in_data = data; in_strb = strb;

    @(negedge clk)
    write_en = 1; start = 1;

    @(negedge clk)
    start = 0;

    @(negedge clk)
    wait(write_done);

    @(negedge clk);

end

endtask

task read(input [31:0]address , input [31:0] expected);

begin
    @(negedge clk);
    in_address = address; write_en = 0; start = 1;

    @(negedge clk);
    start = 0;

    @(negedge clk);
    wait(read_done);

    if(read_data === expected)
    $display ("pass: %h = %h", address , expected);

    else 
    $display("fail: addr = %h , read_data = %h , expected = %h ", address , read_data , expected);

    @(negedge clk);

end

endtask

initial begin
  $dumpfile("AXI_tb.vcd");
  $dumpvars(0, AXI_tb);

  #10 reset = 0;

    write(32'h10, 32'h12345678, 4'b1111);
    read (32'h10, 32'h12345678);

    write(32'h10, 32'hAABBCCDD, 4'b0011);   // only lower 2 bytes change
    read (32'h10, 32'h1234CCDD);

    write(32'h20, 32'hDEADBEEF, 4'b1111);   // different address
    read (32'h20, 32'hDEADBEEF);
    read (32'h10, 32'h1234CCDD);            // old data still intact

   #50 $finish;
end

endmodule