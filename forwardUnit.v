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
// Description: If there are data dependencies between instructions, this module will detect and forward the correc data
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module forwardUnit(
    input logic [6:0] opcodeCurr,
    input [6:0] opcodePrev,
    input [6:0] opcodePrevPrev,
    input logic load,
    input [4:0] ADDR_RS,
    input [4:0] ADDR_RT,
    input [4:0] EX_MEM_RD,
    input [4:0] MEM_WB_RD,
    output reg [1:0] FORWARDA,
    output reg [1:0] FORWARDB,
    output reg [1:0] FORWARD_STORE,
    output reg STALL
    );
    
    typedef enum logic [6:0] {
        LUI    = 7'b0110111,
        AUIPC  = 7'b0010111,
        JAL    = 7'b1101111,
        JALR   = 7'b1100111,
        BRANCH = 7'b1100011,
        LOAD   = 7'b0000011,
        STORE  = 7'b0100011,
        OP_IMM = 7'b0010011,
        OP_RG3 = 7'b0110011,
        CSR    = 7'b1110011
    } opcode_t;
    opcode_t OPCODEC; //- define variable of new opcode type
    assign OPCODEC = opcode_t'(opcodeCurr); //- Cast input enum 

    always @(*) begin 
        STALL = 1'b0; FORWARDA = 2'b00; FORWARDB = 2'b00; FORWARD_STORE = 2'b00;
        case (OPCODEC)
            JALR, LOAD, OP_IMM, CSR: begin //only need to forward rs1 if needed
                if ((ADDR_RS == EX_MEM_RD) && (EX_MEM_RD != 5'b00000) && (opcodePrev != STORE) && (opcodePrev != BRANCH)) begin //if curr_rs == to prev_rd != x0
                    if (load) //if load instruction
                        STALL = 1'b1; // stall for one clock cycle
                    else
                        FORWARDA = 2'b10; //forward from the ex_mem_pip
                end
                
                if ((ADDR_RS == MEM_WB_RD) && (MEM_WB_RD != EX_MEM_RD) && (MEM_WB_RD != 5'b00000)&& (opcodePrevPrev != STORE) && (opcodePrevPrev != BRANCH)) // if curr_rs == prevprev_rd != 0 != prev_rd
                    FORWARDA = 2'b01; //forward from mem_wb_pip
            end
            
            BRANCH, OP_RG3: begin // need to forward rs and rt
                if ((ADDR_RS == EX_MEM_RD) && (EX_MEM_RD != 5'b00000) && (opcodePrev != STORE) && (opcodePrev != BRANCH)) begin // if curr_rs == prev_rd != x0
                    if (load) // if load instruction
                        STALL = 1'b1; // stall for one clock cycle
                    else
                        FORWARDA = 2'b10; // forward data from ex_mem_pip
                end
                
                if ((ADDR_RT == EX_MEM_RD) && (EX_MEM_RD != 5'b00000) && (opcodePrev != STORE) && (opcodePrev != BRANCH)) begin //if curr_rt == prev_rd != 0
                    if (load) // if load instruction
                        STALL = 1'b1; // stall for one clock cycle
                    else
                        FORWARDB = 2'b10; // forward from ex_mem_pip
                end
                
                if ((ADDR_RS == MEM_WB_RD) && (MEM_WB_RD != EX_MEM_RD) && (MEM_WB_RD != 5'b00000) && (opcodePrevPrev != STORE) && (opcodePrevPrev != BRANCH)) // if curr_rs == prevprev_rd != 0 and prevprev_rd!= prev_rd
                    FORWARDA = 2'b01; // forward from mem_wb_pip
                    
                if ((ADDR_RT == MEM_WB_RD) && (MEM_WB_RD != EX_MEM_RD) && (MEM_WB_RD != 5'b00000) && (opcodePrevPrev != STORE) && (opcodePrevPrev != BRANCH)) begin// if curr_rt == prevprev_rd != 0 and prevprev_rd!= prev_rd
                    FORWARDB = 2'b01;// forward from mem_wb_pip
                end  
            end
            
            
            STORE: begin
                if ((ADDR_RS == EX_MEM_RD) && (EX_MEM_RD != 5'b00000) && (opcodePrev != STORE) && (opcodePrev != BRANCH)) begin // if curr_rs == prev_rd != x0
                    if (load) // if load instruction
                        STALL = 1'b1; // stall for one clock cycle
                    else
                        FORWARDA = 2'b10; // forward data from em_mem_pip
                end
                
                if ((ADDR_RS == MEM_WB_RD) && (MEM_WB_RD != EX_MEM_RD) && (MEM_WB_RD != 5'b00000) && (opcodePrevPrev != STORE) && (opcodePrevPrev != BRANCH)) // if curr_rs ==  prevprev_rd !=0 and prevprev_rd != prev_rd
                    FORWARDA = 2'b01; // forward from mem_wb_pip
                    
                if ((ADDR_RT == EX_MEM_RD) && (EX_MEM_RD != 5'b00000) && (opcodePrev != STORE) && (opcodePrev != BRANCH)) begin // if curr_rt == prev_rd != x0
                    if (load) // if load insturction
                        STALL = 1'b1; // stall for one clock cycle
                    else
                        FORWARD_STORE = 2'b10; // get the right data to rt data from ex_mem_pip
                end
                
                if ((ADDR_RT == MEM_WB_RD) && (MEM_WB_RD != EX_MEM_RD) && (MEM_WB_RD != 5'b00000) && (opcodePrevPrev != STORE) && (opcodePrevPrev != BRANCH)) // if curr_rt == prevprev_rd != x0 and prev_rd!= prevprev_rd
                    FORWARD_STORE = 2'b01; // forward from mem_wb_pip
            end
            
            default: begin
                FORWARDA = 2'b00;
                FORWARDB = 2'b00;
                FORWARD_STORE = 2'b00;
            end
        endcase      
    end

endmodule
