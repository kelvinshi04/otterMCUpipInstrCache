`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CPE 333
// Engineer: Kelvin Shi
// 
// Create Date: 11/03/2023 12:03:00 AM
// Design Name: 
// Module Name: BRANCH_COND_GEN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: If given a branch instruction, it will evaluate the condition and output the necessary signals to perform the branch. If branch not taken, this does nothing
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module BRANCH_COND_GEN(
    input [31:0] rs,
    input [31:0] rt,
    input [6:0] opcode,
    input [2:0] func3,
    input interrupt,
    input [31:0] B_TYPE,
    input [31:0] PC_COUNT,
    output reg [2:0] pcSource,
    output reg branSig,
    output [31:0] bran_val
    );
   
    typedef enum logic [6:0] {
        BRANCH = 7'b1100011
    } opcode_t;
    opcode_t OPCODE; //- define variable of new opcode type
    assign OPCODE = opcode_t'(opcode); //- Cast input enum
    
    typedef enum logic [2:0] {
        //BRANCH labels
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
     } func3_BRANCH_t;  
    func3_BRANCH_t FUNC3_BRANCH; //- define variable of new opcode type
    assign FUNC3_BRANCH = func3_BRANCH_t'(func3); //- Cast input enum 
    
    assign bran_val = (PC_COUNT) + B_TYPE;

    always @ (*) begin
        if (interrupt) begin
            pcSource = 3'b100;
            branSig = 1'b1;
        end
        else if (opcode == 7'b1110011 && func3 == 3'b000) begin //mret instruction
            pcSource = 3'b101;
            branSig = 1'b1;
        end
        else begin
            case (OPCODE)
                BRANCH: begin
                    case (FUNC3_BRANCH)
                        BEQ: begin
                            pcSource = (rs == rt ? 3'b010 : 3'b000);
                            branSig = (rs == rt ? 1'b1 : 1'b0);
                        end
                            
                        BNE: begin
                            pcSource = (rs != rt ? 3'b010 : 3'b000);
                            branSig = (rs != rt ? 1'b1 : 1'b0);
                        end
                            
                        BLT: begin
                            pcSource = ($signed(rs) < $signed(rt) ? 3'b010 : 3'b000);
                            branSig = ($signed(rs) < $signed(rt) ? 1'b1 : 1'b0);
                        end
                        
                        BGE: begin
                            pcSource = ($signed(rs) >= $signed(rt) ? 3'b010: 3'b000);
                            branSig = ($signed(rs) >= $signed(rt) ? 1'b1 : 1'b0);
                        end
                        
                        BLTU: begin
                            pcSource = (rs < rt ? 3'b010 : 3'b000);
                            branSig = (rs < rt ? 1'b1 : 1'b0);
                        end
                        
                        BGEU: begin
                            pcSource = (rs >= rt ? 3'b010 : 3'b000);
                            branSig = (rs >= rt ? 1'b1 : 1'b0);
                        end
                        default: begin
                            pcSource = 3'b000;
                            branSig = 1'b0;
                        end
                    endcase
                end
                    
                default: begin
                    pcSource = 3'b000;
                    branSig = 1'b0;
                end
            endcase
        end    
    end
    
    
endmodule
