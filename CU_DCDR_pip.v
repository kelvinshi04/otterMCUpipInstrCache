`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CPE 333
// Engineer: Kelvin Shi
// 
// Create Date: 01/29/2019 04:56:13 PM
// Design Name: 
// Module Name: CU_Decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The main control unit that sends out the control signals for each instruction
// 
// Dependencies:
// 
// CU_DCDR my_cu_dcdr(
//   .br_eq     (), 
//   .br_lt     (), 
//   .br_ltu    (),
//   .opcode    (),    //-  ir[6:0]
//   .func7     (),    //-  ir[30]
//   .func3     (),    //-  ir[14:12] 
//   .alu_fun   (),
//   .pcSource  (),
//   .alu_srcA  (),
//   .alu_srcB  (), 
//   .rf_wr_sel ()   );
//
// 
// Revision:
// Revision 1.00 - File Created (02-01-2020) - from Paul, Joseph, & Celina
//          1.01 - (02-08-2020) - removed unneeded else's; fixed assignments
//          1.02 - (02-25-2020) - made all assignments blocking
//          1.03 - (05-12-2020) - reduced func7 to one bit
//          1.04 - (05-31-2020) - removed misleading code
//          1.05 - (05-01-2023) - reindent and fix formatting
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CU_DCDR_pip(
    input [6:0] opcode,   //-  ir[6:0]
    input func7,          //-  ir[30]
    input [2:0] func3,    //-  ir[14:12] 
    output logic [3:0] alu_fun,
    output logic [1:0] alu_srcA,
    output logic [2:0] alu_srcB, 
    output logic [1:0] rf_wr_sel,
    output logic regWrite,
    output logic memWrEn,
    output logic memRdEn,
    output logic csr_we,  
    output logic mret_ex,
    output logic jump,
    output logic [2:0] pcSource
       );
    
    //- datatypes for RISC-V opcode types
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
    opcode_t OPCODE; //- define variable of new opcode type
  
    assign OPCODE = opcode_t'(opcode); //- Cast input enum 

    //- datatype for func3Symbols tied to values
    typedef enum logic [2:0] {
        //OP_IMM labels
        ADDI = 3'b000,
        SLTI = 3'b010,
        SLTIU = 3'b011,
        ORI = 3'b110,
        XORI = 3'b100,
        ANDI = 3'b111,
        SLLI = 3'b001,
        SHIFT_RIGHT_I = 3'b101
     } func3_IMM_t;    
     
    typedef enum logic [2:0] {
        //BRANCH labels
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
     } func3_BRANCH_t;    
    
    typedef enum logic [2:0] {
        //OP_REG labels
        ADDER = 3'b000,
        SLL = 3'b001,
        SLT = 3'b010,
        SLTU = 3'b011,
        XORR = 3'b100,
        SHIFT_RIGHT = 3'b101,
        ORR = 3'b110,
        ANDR = 3'b111
     }func3_REG_t;
     
     typedef enum logic [2:0] {
        CSRRW  = 3'b001,
        CSRRC  = 3'b011,
        CSRRS  = 3'b010,
        MRET   = 3'b000
    } func3_csr_t;
    
    func3_csr_t FUNC3_CSR;
    func3_IMM_t FUNC3_IMM; //- define variable of new opcode type
    func3_BRANCH_t FUNC3_BRANCH; //- define variable of new opcode type
    func3_REG_t FUNC3_REG; //- define variable of new opcode type
    
    typedef enum logic {
        SRLI = 1'b0,
        SRAI = 1'b1
    } func7_IMM_t;
    
    typedef enum logic {
        ADD = 1'b0,
        SUB = 1'b1
    } func7_REG_t;
        
    typedef enum logic {
        SRL = 1'b0,
        SRA = 1'b1 
    } func7_SHIFT_t;
    
    func7_IMM_t FUNC7_IMM; //- define variable of new opcode type
    func7_SHIFT_t FUNC7_SHIFT; //- define variable of new opcode type
    func7_REG_t FUNC7_REG; //- define variable of new opcode type
    
    assign FUNC3_CSR = func3_csr_t'(func3); //- Cast input enum 
    assign FUNC3_IMM = func3_IMM_t'(func3); //- Cast input enum 
    assign FUNC3_BRANCH = func3_BRANCH_t'(func3); //- Cast input enum 
    assign FUNC3_REG = func3_REG_t'(func3); //- Cast input enum
    
    assign FUNC7_IMM = func7_IMM_t'(func7);
    assign FUNC7_REG = func7_REG_t'(func7);
    assign FUNC7_SHIFT = func7_SHIFT_t'(func7);
       
    always_comb begin 
        //- schedule all values to avoid latch
        alu_srcB = 3'b000;  rf_wr_sel = 2'b00;    regWrite = 1'b0;  memWrEn = 1'b0;  pcSource = 3'b000;
        alu_srcA = 2'b00;   alu_fun  = 4'b0000;   memRdEn = 1'b0;   csr_we = 1'b0;   mret_ex = 1'b0; jump = 1'b0;
        
        case(OPCODE)
            LUI: begin
                alu_fun = 4'b1001; 
                alu_srcA = 2'b01; 
                rf_wr_sel = 2'b11; 
                regWrite = 1'b1;
            end
            
            AUIPC: begin
                alu_srcA = 2'b01;
                alu_srcB = 3'b011; 
                rf_wr_sel = 2'b11;
                regWrite = 1'b1;
            end
            
            BRANCH: begin
                case(FUNC3_BRANCH)
                    BEQ: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0010; //subtraction
                    end
                    
                    BNE: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0010; //subtraction
                    end
                    
                    BLT: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0010; //set if less than signed
                    end
                    
                    BGE: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0010; //set if less than signed
                    end
                    
                    BLTU: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0011; //set if less than unsigned
                    end
                    
                    BGEU: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0011; //set if less than unsigned
                    end
                
                    default: begin
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        alu_fun = 4'b0000; //set if less than unsigned
                    end         
                endcase
            end
            
            JAL: begin
                pcSource = 3'b011;
                regWrite = 1'b1;
                jump = 1'b1;
            end
            
            JALR: begin
                pcSource = 3'b001;
                regWrite = 1'b1;
                jump = 1'b1;
            end
            
            LOAD: begin
                alu_srcB = 3'b001;
                rf_wr_sel = 2'b10; 
                memRdEn = 1'b1;
                regWrite = 1'b1; 
            end
            
            STORE: begin 
                alu_srcB = 3'b010;
                memWrEn = 1'b1; 
            end
            
            CSR: begin
                regWrite = 1'b1;
                case(FUNC3_CSR)
                    CSRRW: begin
                        rf_wr_sel = 2'b01;
                        alu_fun = 4'b1001;
                    end
                    
                    CSRRC: begin
                        rf_wr_sel = 2'b01;
                        alu_fun = 4'b0111;
                        alu_srcA = 2'b10;
                    end
                    
                    CSRRS: begin 
                        rf_wr_sel = 2'b01;
                        alu_fun = 4'b0110;
                    end
                    
                    MRET: begin
                        mret_ex = 1'b1;
                        regWrite = 1'b0;
                    end
                default: begin
                        alu_srcB = 3'b000;  
                        rf_wr_sel = 2'b00;    
                        regWrite = 1'b0;  
                        memWrEn = 1'b0;  
                        alu_srcA = 2'b00;   
                        alu_fun  = 4'b0000;   
                        memRdEn = 1'b0;
                        csr_we = 1'b0;   
                        mret_ex = 1'b0;
                    end
                endcase
            end
            
            OP_IMM: begin
                alu_srcB = 3'b001;
                rf_wr_sel = 2'b11;
                regWrite = 1'b1;
                case(FUNC3_IMM)
                    ADDI: begin
                        alu_fun = 4'b0000;
                    end
                    
                    SLTI: begin
                        alu_fun = 4'b0010;
                    end
                    
                    SLTIU: begin
                        alu_fun = 4'b0011;
                    end
                    
                    ORI: begin
                        alu_fun = 4'b0110;
                    end
                    
                    XORI: begin
                        alu_fun = 4'b0100;
                    end
                    
                    ANDI: begin
                        alu_fun = 4'b0111;
                    end
                    
                    SLLI: begin
                        alu_fun = 4'b0001;
                    end
                    
                    SHIFT_RIGHT_I:
                        case(FUNC7_SHIFT)
                            SRLI: begin
                                alu_fun = 4'b0101;
                            end
                            
                            SRAI: begin
                                alu_fun = 4'b1101;
                            end
                            
                            default: begin
                                alu_fun = 4'b0000;
                            end
                        endcase
                    
                    default: begin
                        alu_fun = 4'b0000;
                        alu_srcA = 2'b00; 
                        alu_srcB = 3'b000; 
                        rf_wr_sel = 2'b00; 
                    end
                endcase
        end
        
        OP_RG3: begin
            regWrite = 1'b1;
            rf_wr_sel = 2'b11;
            case(FUNC3_REG)
                ADDER: begin
                    case(FUNC7_REG)
                        ADD: begin
                            alu_fun = 4'b0000;
                        end
                        
                        SUB: begin
                            alu_fun = 4'b1000;
                        end
                        
                        default: begin
                            alu_fun = 4'b0000;
                            alu_srcA = 2'b00; 
                            alu_srcB = 3'b000; 
                            rf_wr_sel = 2'b00;
                        end
                    endcase       
                end
                
                SLL: begin
                    alu_fun = 4'b0001;
                end
                
                SLT: begin
                    alu_fun = 4'b0010;
                end
                
                SLTU: begin
                    alu_fun = 4'b0011;                        
                end
                
                XORR: begin
                    alu_fun = 4'b0100;
                end
                
                SHIFT_RIGHT:
                    case(FUNC7_IMM)
                        SRL: begin
                            alu_fun = 4'b0101;
                        end
                            
                        SRA: begin
                            alu_fun = 4'b1101;
                        end
                        
                        default: begin
                            alu_fun = 4'b0000;
                            alu_srcA = 2'b00; 
                            alu_srcB = 3'b000; 
                            rf_wr_sel = 2'b00;
                        end
                    endcase
                
                ORR: begin
                    alu_fun = 4'b0110;
                end
                
                ANDR: begin
                    alu_fun = 4'b0111;
                end
                
                default: begin
                    alu_fun = 4'b0000;
                    alu_srcA = 2'b00; 
                    alu_srcB = 3'b000; 
                    rf_wr_sel = 2'b00;
                end
            endcase
        end
            
            default: begin
                 alu_srcB = 3'b000; 
                 rf_wr_sel = 2'b00; 
                 alu_srcA = 2'b00; 
                 alu_fun = 4'b0000;
            end
        endcase
        end
endmodule