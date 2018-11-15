/*******************************************************************
*
* Module: I2C_Master.v
* Project: I2C Master
* Author: Ahmed Refaay - refaay@aucegypt.edu
* Description: I2C Master full circuit
*
* Change history: 02/21/18 – Created module
*                 02/23/18 – Finished module
*
**********************************************************************/

`include "src/global_numerics.v"

module I2C_Master(clk, rst, En, RW, ADDR, DataIn, DataOut, SCL, iSDA, oSDA);
    input wire [0:0] clk; // global clock
    input wire [0:0] rst; // global reset
    
    input wire [0:0] En; // The master responds to R/W if and only if En is 1
    input wire [0:0] RW; // Read (1)/Write (0) control
    input wire [1:0] ADDR; // input address for register manipulation
    input wire [7:0] DataIn; // input data
    output reg [7:0] DataOut; // output data

    output wire [0:0] SCL; // the I2C clock signal for the slaves
	//inout SDA; // inout data signal for slaves -> didn't work on CloudV
    
	input wire [0:0] iSDA; // the I2C data input signal from the slaves
    output reg [0:0] oSDA; // the I2C data output signal for the slaves
    reg [6:0] AU; // address 00: AU register (write only); 8 bits
    reg [7:0] DU; // address 01: DU register (write only); 8 bits
    reg [0:0] GO; // address 10: GO (write only); 1 bit
    reg [1:0] STATUS; // address 11: STATUS (read only); 2 bits; bit 0: done, bit 1: success
    
    reg [4:0] counter; // to count up to 8 cycles

    assign SCL = ((counter >= 5'd20) || (counter <= 5'd1))? 1'b1 :  !clk;
    //assign SDA = ((counter == 5'd10) || (counter == 5'd19))? 1'bz : oSDA;
	//assign iSDA = ((counter == 5'd10) || (counter == 5'd19))? SDA : 1'bz;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            AU <= 7'd0;
            DU <= 8'd0;
            GO <= 1'd0;
            STATUS <= 2'd0;
            DataOut <= 8'd0;
            counter <= 5'd0;
            oSDA <= 1'd1;
        end
        else begin
            if(En == 1'b1) begin
                STATUS <= STATUS;
                counter <= counter;
                oSDA <= 1'd1;
                case(ADDR)
                    2'b00: begin
                        if(RW == 1'b0) AU <= DataIn[6:0];
                        else AU <= AU;
                        DU <= DU;
                        GO <= GO;
                        DataOut <= DataOut;
                    end
                    2'b01: begin
                        AU <= AU;
                        if(RW == 1'b0) DU <= DataIn;
                        else DU <= DU;
                        GO <= GO;
                        DataOut <= DataOut;
                    end
                    2'b10: begin
                        AU <= AU;
                        DU <= DU;
                        if(RW == 1'b0) GO <= DataIn[0];
                        else GO <= GO;
                        DataOut <= DataOut;
                    end
                    default: begin
                        AU <= AU;
                        DU <= DU;
                        GO <= GO;
                        if(RW == 1'b1) DataOut <= {6'd0, STATUS};
                        else DataOut <= DataOut;
                    end
                endcase
            end
            else begin
                AU <= AU;
                DU <= DU;
                DataOut <= DataOut;
                GO <= 1'd0;
                if(GO == 1'b1)begin
                    counter <= 5'd1;
                    STATUS <= 2'd0;
                    oSDA <= 1'd0;
                end
                else begin
                    if(counter == 5'd0) begin // if not enabled or no GO yet, keep everything as it is
                        counter <= counter;
                        STATUS <= 2'd0;
                        oSDA <= 1'd1;
                    end
                    else if(counter <= 5'd7) begin // sending 7-bit address
                        counter <= counter + 5'd1;
                        STATUS <= 2'd0;
                        oSDA <= AU[5'd6-(counter-5'd1)];
                    end
                    else if(counter == 5'd8) begin // sending R/W
                        counter <= counter + 5'd1;
                        STATUS <= 2'd0;
                        oSDA <= 1'd0; // since we only write in this module
                    end
                    else if(counter == 5'd9) begin // receiving acknowledgement
                        counter <= counter + 5'd1;
                        STATUS <= {iSDA, 1'd0}; // acknowledgement is a part of success
                        oSDA <= 1'd0; // output not used
                    end
                    else if(counter <= 5'd17) begin // sending 8-bit data
                        counter <= counter + 5'd1;
                        STATUS <= STATUS;
                        oSDA <= DU[5'd6-(counter-5'd11)];
                    end
                    else if(counter == 5'd18) begin // receiving acknowledgement
                        counter <= counter + 5'd1;
                        STATUS <= {(iSDA & STATUS[1]), 1'd0}; // all acknowledgements make success
                        oSDA <= 1'd0; // output not used
                    end
                    else if(counter == 5'd19) begin // STOP
                        counter <= counter + 5'd1;
                        STATUS <= {STATUS[1], 1'd1}; // sending done
                        oSDA <= 1'd1;
                    end
                    else begin // default
                        counter <= counter;
                        STATUS <= STATUS;
                        oSDA <= 1'd1;
                    end
                end
            end
        end
    end
endmodule