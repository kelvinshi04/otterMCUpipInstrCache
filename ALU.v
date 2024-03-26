`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CPE 333
// Engineer: Kelvin Shi
// 
// Create Date: 10/15/2023 12:20:50 AM
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The main logic unit that performs various arithmetic operations
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input [3:0] alu_fun, 
    input [31:0] srcA,
    input [31:0] srcB,
    output reg [31:0] result,
    output reg zero
    );
    
    wire [31:0] set = 32'hFFFF_FFFF;
    
    always @(*)
    begin
        case(alu_fun)
            4'b0000: //add operation
                result = srcA + srcB;
            4'b0001: //left shift operation
                result = srcA << srcB[4:0];
            4'b0010: //set if less than operation
                begin
                    if ($signed(srcA) < $signed(srcB)) //sets if less than
                        result = 32'h0000_0001;
                    else //otherwise clears register
                        result = 32'h0000_0000; 
                end
            4'b0011: //set if less than function unsigned
                begin
                    if (srcA < srcB) // set if srcA is less than srcB unsigned
                        result = 32'h0000_0001;
                    else
                        result = 32'h0000_0000;
                end
            4'b0100: // xor function
                result = srcA ^ srcB;
            4'b0101: // shift right function
                result = srcA >> srcB[4:0];
            4'b0110: // or function
                result  = srcA | srcB;
            4'b0111: // and function
                result = srcA & srcB;
            4'b1000: //subtraction function
                result = $signed(srcA) - $signed(srcB);
            4'b1001: //load upper immediate function
                result = srcA;
            4'b1101: //shift right arithmetic function
                result = $signed(srcA) >>> $signed(srcB[4:0]);
            default: 
                result = 32'hDEAD_BEEF;
        endcase
        
        if (result == 32'h0000_0000)
            zero = 1'b0;
        else
            zero = 1'b0;
            
    end
                
    
endmodule
