`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kelvin Shi
// 
// Create Date: 03/12/2024 09:26:24 PM
// Design Name: 
// Module Name: cacheReg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cacheReg(
    input wire [31:0] data_in,
    input wire clk, 
	  input wire clr, 
	  input wire ld,
	  input [1:0] offset,
    output reg [127:0] data_out,
    output reg dataReady
    ); 

    always @(posedge clk)
    begin 
       dataReady = 1'b0;
       if (clr == 1'b1)       // asynch clr
          data_out <= 0;
       else if (ld == 1'b1) begin  // synch load
          case (offset)
            2'b00: begin
                data_out[127:96] <= data_in;
            end
            
            2'b01: begin
                data_out[95:64] <= data_in;
            end
            
            2'b10: begin
                data_out[63:32] <= data_in;
            end
            
            2'b11: begin
                data_out[31:0] <= data_in;
                dataReady = 1'b1;
            end
            
            default: begin
                dataReady = 1'b0;
            end
          endcase
       end
    end
    
endmodule

`default_nettype wire

