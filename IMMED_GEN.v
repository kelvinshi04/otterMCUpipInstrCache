`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2023 11:38:39 AM
// Design Name: 
// Module Name: IMMED_GEN
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


module IMMED_GEN(
    input [31:0] ir,
    output [31:0] U_TYPE,
    output [31:0] I_TYPE,
    output [31:0] S_TYPE,
    output [31:0] J_TYPE,
    output [31:0] B_TYPE
    );
    
    assign U_TYPE = {ir[31:12], {12{1'b0}}};
    assign I_TYPE = {{21{ir[31]}}, ir[30:25], ir[24:20]};
    assign S_TYPE = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign J_TYPE = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
    assign B_TYPE = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};
    
endmodule
