`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CPE 333
// Engineer: Kelvin Shi
// 
// Create Date: 02/19/2024 02:15:11 AM
// Design Name: 
// Module Name: hazardDetectUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: If branch is taken, it will flush out instructions since branch is assumed not taken.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module hazardDetectUnit(
    input BRANCH_VALID,
    input stalled,
    output reg FLUSH
    );

    always@(*) begin
        if (BRANCH_VALID == 1'b1)
            if (stalled == 1'b0) 
                FLUSH = 1'b1;
            else
                FLUSH = 1'b0;
        else
            FLUSH = 1'b0;
    end
endmodule
