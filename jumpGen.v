`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2024 09:01:33 PM
// Design Name: 
// Module Name: jumpGen
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


module jumpGen(
    input [31:0] J_TYPE,
    input [31:0] I_TYPE,
    input [31:0] rs,
    input [31:0] PC_COUNT,
    output [31:0] JAL,
    output [31:0] JALR
    );
    
    assign JAL = (PC_COUNT) + J_TYPE;
    assign JALR = rs + I_TYPE;

endmodule
