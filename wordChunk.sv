`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kelvin Shi
// 
// Create Date: 03/12/2024 09:13:25 PM
// Design Name: 
// Module Name: wordChunk
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


module wordChunk(
    input [13:0] address,
    output reg [55:0] fourAddress
    );
    
    always @(*) begin
        fourAddress = {address[13:2], 2'b00, address[13:2], 2'b01, address[13:2], 2'b10, address[13:2], 2'b11};
    end
    
endmodule
