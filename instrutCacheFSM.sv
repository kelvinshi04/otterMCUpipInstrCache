`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Ratner Surf Designs
// Engineer:  James Ratner
// 
// Create Date: 07/07/2018 08:05:03 AM
// Design Name: 
// Module Name: fsm_template
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generic FSM model with both Mealy & Moore outputs. 
//    Note: data widths of state variables are not specified 
//
// Dependencies: 
// 
// Revision:
// Revision 1.00 - File Created (07-07-2018) 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_control (clk, reset, miss, wordSel, load, dataGood); 
    input miss, reset, clk;
    output reg [1:0] wordSel;
    output reg load, dataGood;
     
    //- next state & present state variables
    reg [2:0] NS, PS; 
    //- bit-level state representations
    parameter [2:0] idle = 3'b000, getWordOne= 3'b001, getWordTwo = 3'b010, getWordThree = 3'b011, getWordFour = 3'b100, dataDone = 3'b101; 
    //- model the state registers
    always @ (negedge reset, posedge clk)
       if (reset == 1) 
          PS <= idle; 
       else
          PS <= NS; 
    
    
    //- model the next-state and output decoders
    always @ (posedge clk)
    begin   
       wordSel = 2'b00;
       dataGood = 1'b0;
       case(PS)
          idle:
          begin        
             wordSel = 2'b00;
             load = 1'b0;
             dataGood = 1'b0;
             if (miss)
                NS = getWordOne;
             else
                NS = idle;
          end
          
          getWordOne:
          begin
             wordSel = 2'b00;
             load = 1'b1;
             dataGood = 1'b0;
             NS = getWordTwo;       
          end
             
          getWordTwo:
          begin
             wordSel = 2'b01;
             load = 1'b1;
             dataGood = 1'b0;
             NS = getWordThree;   
          end
          
          getWordThree:
          begin
             wordSel = 2'b10;
             load = 1'b1;
             dataGood = 1'b0;
             NS = getWordFour;   
          end
          
          getWordFour:
          begin
             wordSel = 2'b11;
             load = 1'b1;
             dataGood = 1'b0;
             NS = dataDone;   
          end
          
          dataDone:
          begin
            wordSel = 2'b11;
            load = 1'b0;
            dataGood = 1'b1;
            NS = idle;
          end
             
          default: NS = idle; 
           
       endcase
    end              
endmodule


