module simple_mem (
    input clk,
    input mem_we,
    input [31:0] write_addr, write_data,
    input [3:0]  write_strb,
    input [31:0] read_addr,
    output [31:0] in_data
);
    reg [31:0] mem [0:255];

    assign in_data = mem[read_addr[9:2]];     // combinational read, word-aligned

    always @(posedge clk) begin
        if (mem_we) begin
            if (write_strb[0]) mem[write_addr[9:2]][7:0]   <= write_data[7:0];
            if (write_strb[1]) mem[write_addr[9:2]][15:8]  <= write_data[15:8];
            if (write_strb[2]) mem[write_addr[9:2]][23:16] <= write_data[23:16];
            if (write_strb[3]) mem[write_addr[9:2]][31:24] <= write_data[31:24];
        end
    end
endmodule