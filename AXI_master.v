module AXI_master(
    
    input clk,
    input reset,
    output busy,

    input [31:0]in_data,
    input [31:0]in_address,
    input start, // start the transaction
    input write_en, // 1 == write , 0 == read
    input [3:0] in_strb, // to write which data to change in addr 

    output reg [31:0]AWADDR, // write address
    output reg AWVALID, // tells slave that address is valid = address valid 
    input AWREADY, // slave tells it is ready to take an address = addr write ready
    // when AWVALID && AWREADY = 1 the HANDSHAKE happens and slave recives tthe address

    output reg [31:0]WDATA, //write data
    output reg WVALID, // tells slave that data is valid = write valid 
    input WREADY, // slave tells it is ready to take an data = write ready
    // when WVALID && WREADY = 1 the HANDSHAKE happens and slave recives tthe address

    input [1:0]BRESP, // by this slave tells master it has succesfully written the data 
    // 00-->okay, 01-->exokay, 10-->slverr, 11-->DECERR
    input BVALID, // slave also needs to tell us when BRESP is actually valid
    output reg BREADY, // by tbis master tells slave it is ready to receive his response  "
    // I am ready to receive your write response.

    output reg [31:0]ARADDR, // READ ADDRESS
    output reg ARVALID, // address read valid 
    input ARREADY, // slave is ready to recaive the address 
    // when ARVALID && ARREADY = 1 the HANDSHAKE happens and slave recives tthe address
    
    input RVALID,
    input [31:0] RDATA, // READ DATA
    input [1:0]RRESP, // same as BRESP
    output reg RREADY, //I am ready to receive the read data.

    output reg [31:0] read_data, // give us the data that master read 
    output reg [1:0]  read_resp, // tells if the data is compleat and correct 

    output reg [3:0] WSTRB, //WSTRB tells the slave which bytes of WDATA are valid and should actually be written.
    //which bytes of that data should be written 
    
    // tells the outside logic that transaction has compleate 
    output reg read_done,
    output reg write_done,
    output reg [1:0] write_resp, // checks the BRESP if the data is transfered correctly
    output reg error
    
);

parameter IDLE       = 3'b000,
          WRITE_ADDR = 3'b001,
          WRITE_DATA = 3'b010,
          WRITE_RESP = 3'b011,
          READ_ADDR  = 3'b100,
          READ_DATA  = 3'b101;
          //READ_RESP  = 3'b110;

reg [2:0]state, next_state ;
reg [31:0] addr_r, data_r;
reg [3:0]strb_r;

assign busy = (state != IDLE);

always @(posedge clk or posedge reset)begin

    if(reset)
       state <= IDLE;
    
    else 
       state <= next_state;
end

//You are using in_address and in_data directly throughout the transaction
//If they change while the transaction is running, the master may send the wrong address/data; so we save
//them in addr_r and data_r when start occurs.

always @(posedge clk or posedge reset) begin

    if(reset) begin
        addr_r <= 0;
        data_r <= 0;
        strb_r <= 0;
    end

    else if(state == IDLE && start) begin
        addr_r <= in_address;
        data_r <= in_data;
        strb_r <= in_strb;
    end

end

always @(*) begin
    // defaults: every output assigned on every path
    AWADDR  = addr_r;
    WDATA   = data_r;
    ARADDR  = addr_r;
    ARVALID = 0; 
    AWVALID = 0;
    WVALID  = 0;
    BREADY  = 0;
    RREADY  = 0;
    WSTRB   = strb_r;

    case (state)
        WRITE_ADDR : AWVALID = 1;
        WRITE_DATA : WVALID = 1;
        WRITE_RESP : BREADY = 1;
        READ_ADDR  : ARVALID = 1;   
        READ_DATA  : RREADY = 1;
        default    : ;
    endcase
end

// Your AWVALID, WVALID, etc. are registered, so they change one clock later than the FSM state.
// Because of this, VALID can remain HIGH for one extra cycle after the handshake, which may cause a second handshake.
// because of this the aboue always block is written

// always @(posedge clk or posedge reset)begin

//     if(reset)begin

//         //state <= IDLE;
//         AWADDR  <= 0;
//         AWVALID <= 0;
//         WDATA   <= 0;
//         WVALID  <= 0;
//         BREADY  <= 0;
//         RREADY  <= 0;
//         ARADDR  <= 0;
//         ARVALID <= 0;

//     end
        
//     else begin

//         AWVALID <= 0;
//         WVALID  <= 0;
//         BREADY  <= 0;
//         RREADY  <= 0;
//         WSTRB   <= 0;

//         if(state == WRITE_ADDR)begin

//            AWADDR <= in_address;
//            AWVALID <= 1;

//         end

//         else if(state == WRITE_DATA)begin

//            WDATA <= in_data;
//            WSTRB <= 4'b1111;
//            WVALID <= 1;

//         end

//         else if(state == WRITE_RESP)begin
        
//            BREADY <= 1;
    
//         end

//         else if(state == READ_ADDR)begin

//             ARADDR <= in_address;
//             ARVALID <= 1;

//         end

//         else if(state == READ_DATA)begin

//             RREADY <= 1;

//         end

//     end

// end

always @(posedge clk or posedge reset) begin

    if (reset) begin

        //state      <= IDLE;
        read_data  <= 32'b0;
        read_resp  <= 2'b0;
        read_done  <= 0;
        write_done <= 0;
        write_resp <= 2'b00;
        error      <= 0;

    end

    else begin

        //state <= next_state;
        read_done  <= 0;
        write_done <= 0;
        write_resp <= 2'b00;

        if (RVALID && RREADY) begin
            read_data <= RDATA;
            read_resp <= RRESP;

            read_done <= 1;
        end

        if(BVALID && BREADY) begin
            
            write_resp <= BRESP;
            write_done <= 1;

        end
        
        // this will tell if the error is occured 
        if (BVALID && BREADY) error <= (BRESP != 2'b00);
        if (RVALID && RREADY) error <= (RRESP != 2'b00);

    end
    
end

always @(*) begin

    next_state = state;

    case(state)

    IDLE : begin

        if(start)
            next_state = write_en ? WRITE_ADDR : READ_ADDR;
    
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