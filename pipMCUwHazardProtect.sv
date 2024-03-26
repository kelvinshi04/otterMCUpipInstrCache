`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CPE 333
// Engineer: Kelvin Shi
// 
// Create Date: 02/22/2024 01:53:19 AM
// Design Name: 
// Module Name: pipMCUwHazardProtect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: RISC V Otter with pipeline and the abiltity to detect hazards
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pipMCUwHazardProtect(
    input clk,
    input INTR,
    input RESET,
    input [31:0] IOBUS_IN,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR,
    output IOBUS_WR
    );
     
     wire [31:0] pcIN, pcOUT, memData;
     wire [63:0] if_dec_pip, ir;
     wire [2:0] pcSourceMUX, pcSourceDCDR, pcSourceBCG;
     wire [31:0] rs, rt, uType, iType, jType, sType, bType, rtData;
     wire [3:0] alu_fun;
     wire [2:0] alu_srcB;
     wire [1:0] alu_srcA;
     wire [1:0] rf_wr_sel;
     wire regWrite, memRdEn, memWrEn, csrWE, mret_ex, missClr;
     wire [31:0] alu_A, alu_B, csrRD, aluAin, aluBin;
     wire [202:0] dec_ex_pip;
     wire [31:0] result, jal, jalr, branch;
     wire zero, branSig, dataReady;
     wire [164:0] ex_mem_pip;
     wire [31:0] mtvec, mepc;
     wire mstatus, flush, stall, jump, stallJ;
     wire [162:0] mem_wb_pip;
     wire [31:0] regDataIn, rsGoodData;
     wire [1:0] forwardA, forwardB, forwardS, forwardJ;
     wire dataDone, miss, instrRead, load, dataGood;
     wire [31:0] cacheInstruction;
     wire [1:0] wordSel;
     wire [13:0] partAddy;
     wire [55:0] fourAddress;
     wire [127:0] fourData;
     wire missMEM, missStore, updateMM;
     wire [127:0] cacheLine, fouraddys, loadData;
     
     wire loadDone, storeDone, dirtyDealt, loadAddyGen;
     wire [1:0] wordSelect;
     wire [31:0] storeAddy, intoMemAddy, intoMemData, loadAddy;
     
//////////////// Instruction Fetch //////////////// 

     mux_2t1_nb  #(.n(3)) pcSourceMUXX( //takes care of jump/branch
        .SEL   (branSig), 
        .D0    (pcSourceDCDR), 
        .D1    (pcSourceBCG), 
        .D_OUT (pcSourceMUX)
        );  

     mux_8t1_nb  #(.n(32)) pcMUX( 
        .SEL   (pcSourceMUX), 
        .D0    (pcOUT + 4), 
        .D1    (jalr), 
        .D2    (branch), 
        .D3    (jal),
        .D4    (mtvec),
        .D5    (mepc),
        .D6    (32'h0000_0000),
        .D7    (32'h0000_0000),
        .D_OUT (pcIN) 
        );  

     reg_neg #(.n(32)) myPC(
        .data_in  (pcIN), 
        .ld       ((~stall) && (~stallJ) && (~miss)),
        .clk      (clk), 
        .clr      (RESET), // clear sig
        .data_out (pcOUT)
        );  
        
     ////////////////////////////////////////////////
     
     L1instr_cache myInstrCache(
        .address        (pcOUT[15:2]),
        .dataFromMM     (fourData),
        .fromMM         (dataGood),
        .dataReady      (dataGood),
        .clk            (clk),
        .correctData    (ir),
        .miss           (miss)
        );
     
     cacheReg myCacheReg(
        .data_in        (cacheInstruction),
        .clk            (clk),
        .clr            (RESET),
        .ld             (miss),
        .offset         (wordSel),
        .data_out       (fourData),
        .dataReady      (dataReady)
     );
     
     
     wordChunk myAddressGen(
        .address        (pcOUT[15:2]),
        .fourAddress    (fourAddress)
        );
     
     mux_4t1_nb  #(.n(14)) cacheMux (
        .SEL            (wordSel), 
        .D0             (fourAddress[55:42]), 
        .D1             (fourAddress[41:28]), 
        .D2             (fourAddress[27:14]), 
        .D3             (fourAddress[13:0]),
        .D_OUT          (partAddy)
        );
        
     fsm_control myFSM(
        .miss           (miss),
        .reset          (RESET),
        .clk            (clk),
        .wordSel        (wordSel),
        .load           (load),
        .dataGood       (dataGood)
        );

     Memory OTTER_MEMORY(
        .MEM_CLK   (clk),
        .MEM_RDEN1 (1'b1), 
        .MEM_RDEN2 (ex_mem_pip[128]), 
        .MEM_WE2   (ex_mem_pip[129]),
        .MEM_ADDR1 (partAddy),
        .MEM_ADDR2 (ex_mem_pip[31:0]),
        .MEM_DIN2  (ex_mem_pip[63:32]),  
        .MEM_SIZE  (ex_mem_pip[77:76]),
        .MEM_SIGN  (ex_mem_pip[78]),
        .IO_IN     (IOBUS_IN),
        .IO_WR     (IOBUS_WR),
        .MEM_DOUT1 (cacheInstruction),
        .MEM_DOUT2 (memData)  
        ); 
  
        
     reg_nb_sclr #(.n(64)) IF_DEC_REG(
        .data_in  (ir),      // PC -> [63:32], Instruction -> [31:0]
        .ld       ((~stall) && (~stallJ) && (~miss)),
        .clk      (clk), 
        .clr      ((flush && ~(miss)) || RESET || (jump && ~(miss))), // clear sig
        .data_out (if_dec_pip)
        ); 
        
//////////////// Instruction Decode //////////////// 

     RegFile my_regfile(
        .wd   (regDataIn),
        .clk  (clk), 
        .en   (mem_wb_pip[128]),
        .adr1 (if_dec_pip[19:15]),
        .adr2 (if_dec_pip[24:20]),
        .wa   (mem_wb_pip[75:71]),
        .rs1  (rs), 
        .rs2  (rt)  
        );
    
     IMMED_GEN myGen(
        .ir (if_dec_pip[31:0]),
        .U_TYPE (uType),
        .I_TYPE (iType),
        .S_TYPE (sType),
        .J_TYPE (jType),
        .B_TYPE (bType)
        );
        
     CU_DCDR_pip myDCDR(
        .opcode    (if_dec_pip[6:0]),     //-  ir[6:0]
        .func7     (if_dec_pip[30]),      //-  ir[30]
        .func3     (if_dec_pip[14:12]),   //-  ir[14:12] 
        .alu_fun   (alu_fun),
        .alu_srcA  (alu_srcA),
        .alu_srcB  (alu_srcB), 
        .rf_wr_sel (rf_wr_sel),
        .regWrite  (regWrite),
        .memWrEn   (memWrEn),
        .memRdEn   (memRdEn),
        .csr_we    (csrWE),  
        .mret_ex   (mret_ex),
        .jump      (jump),
        .pcSource  (pcSourceDCDR)
        );
        
     mux_4t1_nb  #(.n(32)) alu_A_mux(
        .SEL   (alu_srcA), 
        .D0    (rs), 
        .D1    (uType), 
        .D2    (~rs), 
        .D3    (32'h0000_0000),
        .D_OUT (alu_A)
        );
        
     mux_8t1_nb  #(.n(32)) alu_B_mux(
        .SEL   (alu_srcB), 
        .D0    (rt), 
        .D1    (iType), 
        .D2    (sType), 
        .D3    (if_dec_pip[63:32]),
        .D4    (csrRD),  // need to fix
        .D5    (32'h0000_0000),
        .D6    (32'h0000_0000),
        .D7    (32'h0000_0000),
        .D_OUT (alu_B)
        );
        
     jumpGen my_jump_gen(
        .I_TYPE    (iType),
        .J_TYPE    (jType),
        .rs        (rsGoodData),
        .PC_COUNT  (if_dec_pip[63:32]),
        .JAL       (jal),
        .JALR      (jalr)
        );  
        
     jumpForwardUnit myJumpFor(
        .rsAddy         (if_dec_pip[19:15]),
        .curOp          (if_dec_pip[6:0]),
        .if_ex_rd       (dec_ex_pip[139:135]),
        .ieOp           (dec_ex_pip[134:128]),
        .ex_mem_rd      (ex_mem_pip[75:71]),
        .emOp           (ex_mem_pip[70:64]),
        .mem_wb_rd      (mem_wb_pip[75:71]),
        .mwOp           (mem_wb_pip[70:64]),
        .rsSelect       (forwardJ),
        .stallJump      (stallJ)
        );
        
     mux_4t1_nb  #(.n(32)) jumpMux(
        .SEL   (forwardJ), 
        .D0    (rs), 
        .D1    (regDataIn), 
        .D2    (ex_mem_pip[31:0]), 
        .D3    (result),
        .D_OUT (rsGoodData)
        );   
        
             
     reg_nb_sclr #(.n(203)) DEC_EX_REG (
        .data_in  ({rf_wr_sel, regWrite, memWrEn, memRdEn, csrWE, mret_ex, alu_fun, if_dec_pip, rt, alu_A, alu_B, bType}),
        .ld       (~stall && ~miss),
        .clk      (clk), 
        .clr      ((flush && ~(miss)) || RESET), // clear sig
        .data_out (dec_ex_pip)
        ); 
        
     hazardDetectUnit myBranDetect(
        .BRANCH_VALID   (branSig),
        .stalled        (stall),
        .FLUSH          (flush)
        );
        
 //////////////// Execute //////////////// 

     mux_4t1_nb  #(.n(32)) alusrcAin  (
        .SEL   (forwardA), 
        .D0    (dec_ex_pip[95:64]), 
        .D1    (regDataIn), 
        .D2    (ex_mem_pip[31:0]), 
        .D3    (32'h0000_0000),
        .D_OUT (aluAin) );  
        
     mux_4t1_nb  #(.n(32)) alusrcBin  (
        .SEL   (forwardB), 
        .D0    (dec_ex_pip[63:32]), 
        .D1    (regDataIn), 
        .D2    (ex_mem_pip[31:0]), 
        .D3    (32'h0000_0000),
        .D_OUT (aluBin) );  

     alu myALU(
        .alu_fun   (dec_ex_pip[195:192]),
        .srcA      (aluAin),
        .srcB      (aluBin),
        .result    (result),
        .zero      (zero)
         );
         
        
     BRANCH_COND_GEN myBranchCon(
        .rs          (aluAin),
        .rt          (aluBin),
        .opcode      (dec_ex_pip[134:128]),
        .func3       (dec_ex_pip[142:140]),
        .interrupt   (INTR & mstatus),
        .B_TYPE      (dec_ex_pip[31:0]),
        .PC_COUNT    (dec_ex_pip[191:160]),
        .bran_val    (branch),
        .branSig     (branSig),
        .pcSource    (pcSourceBCG)
        );
        
     forwardUnit myForwarding(
        .opcodeCurr       (dec_ex_pip[134:128]),
        .opcodePrev       (ex_mem_pip[70:64]),
        .opcodePrevPrev   (mem_wb_pip[70:64]),
        .load             (ex_mem_pip[128]),
        .ADDR_RS          (dec_ex_pip[147:143]),
        .ADDR_RT          (dec_ex_pip[152:148]),
        .EX_MEM_RD        (ex_mem_pip[75:71]),
        .MEM_WB_RD        (mem_wb_pip[75:71]),
        .FORWARDA         (forwardA),
        .FORWARDB         (forwardB),
        .FORWARD_STORE    (forwardS),
        .STALL            (stall)
        );
        
        
     mux_4t1_nb  #(.n(32)) rtDataMUX  (
        .SEL   (forwardS), 
        .D0    (dec_ex_pip[127:96]), 
        .D1    (regDataIn), 
        .D2    (ex_mem_pip[31:0]), 
        .D3    (32'h0000_0000),
        .D_OUT (rtData) );  
     
        
////////////////// CSR //////////////////////
      
     CSR my_csr(
        .CLK        (clk),
        .RST        (RESET),
        .MRET_EXEC  (dec_ex_pip[196]),
        .INT_TAKEN  (INTR & mstatus),
        .ADDR       (dec_ex_pip[159:148]),
        .PC         (dec_ex_pip[191:160]),
        .WD         (result),
        .WR_EN      (dec_ex_pip[197]),
        .RD         (csrRD),
        .CSR_MEPC   (mepc),
        .CSR_MTVEC  (mtvec),
        .CSR_MSTATUS_MIE (mstatus)    );
/////////////////////////////////////////////
        
     reg_nb_sclr #(.n(165)) EX_MEM_REG(
        .data_in  ({csrRD, dec_ex_pip[202:198], dec_ex_pip[191:160], dec_ex_pip[159:128], rtData, result}),
        .ld       (~miss), // caution
        .clk      (clk), 
        .clr      (RESET), // clear sig
        .data_out (ex_mem_pip)
        );
        
 //////////////// Memory //////////////// 
     wire [31:0] dataOut;
    // Look at memory module in instruction fetch stage 
     reg_nb_sclr #(.n(163)) MEM_WB_REG(
        .data_in  ({ex_mem_pip[164:130], ex_mem_pip[127:96], ex_mem_pip[95:64], memData, ex_mem_pip[31:0]}),
        .ld       (~miss), // caution
        .clk      (clk), 
        .clr      (RESET), // clear sig
        .data_out (mem_wb_pip)
        );
        
     assign IOBUS_ADDR = ex_mem_pip[31:0];
     assign IOBUS_OUT = ex_mem_pip[63:32];
     
     /*
     L1memCache myMemCache(
        .address        (ex_mem_pip[31:0]),
        .dataFromMM     (loadData),
        .dataToStore    (ex_mem_pip[63:32]),
        .dataSize       (ex_mem_pip[77:76]),
        .sign           (ex_mem_pip[78]),
        .fromMM         (loadDone),
        .dataReady      (loadDone),
        .store          (ex_mem_pip[129]),
        .load           (ex_mem_pip[128]),
        .dataStoredAway (dirtyDealt),
        .dataUpdatedLoad(storeDone),
        .clk            (clk),
        .correctData    (dataOut),
        .miss           (missMEM),
        .missStore      (missStore),
        .updateMM       (updateMM), //dirty 
        .cacheLine      (cacheLine)
        );
        
     
     fsm_memcache myFSMmem(
        .clk            (clk),
        .reset          (RESET),
        .miss           (missMEM),
        .missStore      (missStore),
        .dirty          (updateMM),
        .wordSel        (wordSelect),
        .load           (loadAddyGen),
        .dataGood       (loadDone),
        .dataStoreSel   (dirtyDealt),
        .dataStored     (storeDone)
        
        );
        
     mux_4t1_nb  #(.n(32)) wordGetter(
        .SEL            (wordSelect), 
        .D0             (fouraddys[127:96]), 
        .D1             (fouraddys[95:64]), 
        .D2             (fouraddys[63:32]), 
        .D3             (fouraddys[31:0]),
        .D_OUT          (loadAddy)
        );
        
     mux_4t1_nb  #(.n(32)) storeBreaker(
        .SEL            (wordSelect), 
        .D0             (cacheLine[127:96]), 
        .D1             (cacheLine[95:64]), 
        .D2             (cacheLine[63:32]), 
        .D3             (cacheLine[31:0]),
        .D_OUT          (storeAddy)
        );
     
     cacheReg myCacheRegMEM(
        .data_in        (memData),
        .clk            (clk),
        .clr            (RESET),
        .ld             (loadAddyGen),
        .offset         (wordSelect),
        .data_out       (loadData),
        .dataReady      ()
     );
     
     addyGenMEM myAddressGenMEM(
        .address        (ex_mem_pip[31:0]),
        .fourAddress    (fouraddys)
        );
     
     mux_2t1_nb  #(.n(32)) addrMEM( 
        .SEL   (updateMM), 
        .D0    (loadAddy), 
        .D1    (ex_mem_pip[31:0]), 
        .D_OUT (intoMemAddy)
        );  
     
     mux_2t1_nb  #(.n(32)) dataMEM( 
        .SEL   (updateMM), 
        .D0    (storeAddy), 
        .D1    (ex_mem_pip[63:32]), 
        .D_OUT (intoMemData)
        );  
   */  
     
 //////////////// Writeback ////////////////
     
     mux_4t1_nb  #(.n(32)) rf_wr_mux(
        .SEL   (mem_wb_pip[130:129]), 
        .D0    (mem_wb_pip[127:96] + 4), 
        .D1    (mem_wb_pip[162:131]),  //need to fix 
        .D2    (mem_wb_pip[63:32]), 
        .D3    (mem_wb_pip[31:0]),
        .D_OUT (regDataIn) ); 

     // Look at regfile in instruction decode

    
endmodule
