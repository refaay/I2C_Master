// file: I2C_Master_tb.v
// author: @refaay
// Testbench for I2C_Master

`timescale 1ns/1ns

module I2C_Master_tb;

	//Inputs
	reg [0: 0] clk;
	reg [0: 0] rst;
	reg [0: 0] En;
	reg [0: 0] RW;
	reg [1: 0] ADDR;
	reg [7: 0] DataIn;
	reg [0: 0] iSDA;

	//Outputs
	wire [7: 0] DataOut;
	wire [0:0] SCL;
	wire [0: 0] oSDA;

    //Testbench
    reg [16:0] mem;
    reg err;
    reg [6:0] AU; // address
    reg [7:0] DU; // data
    
	//Instantiation of Unit Under Test
	I2C_Master uut (
		.clk(clk),
		.rst(rst),
		.En(En),
		.RW(RW),
		.ADDR(ADDR),
		.DataIn(DataIn),
		.iSDA(iSDA),
		.DataOut(DataOut),
		.SCL(SCL),
		.oSDA(oSDA)
	);

    always #5 clk = !clk;

	initial begin
	//Inputs initialization
		clk = 0;
		rst = 0;
		En = 0;
		RW = 0;
		ADDR = 0;
		DataIn = 0;
		iSDA = 0;
		mem = 0;
		err = 0;
		AU = $random % 7'd100; // address
		DU = $random % 7'd100; // data
		
		#10; //send address
		rst = 1;
		En = 1;
		RW = 0;
		DataIn = AU;
		
		#10; // send data
		ADDR = 1;
		DataIn = DU;
		
		#10; // send GO
		ADDR = 2;
		DataIn = 1;
		
		#10; // let it work
		ADDR = 2;
		DataIn = 0;
		En = 0;
		
		#50; // acknowledge all
		iSDA = 1;
		
        #200; // read STATUS
        ADDR = 3;
        En = 1;
        RW = 1;
        
        #10; // stop reading
        En = 0;
	end
    
    initial begin // store all sent bits and compare to original
        repeat (18) begin
            @(negedge SCL)
            mem = {mem[15:0], oSDA};
        end
        err = mem != {AU, 2'd0, DU};
    end
    
endmodule