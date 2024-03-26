`timescale 1ns / 1ps

module L1instr_cache(
    input [13:0] address,
    input [127:0] dataFromMM,
    input logic fromMM,
    input logic dataReady,
    input clk,
    output reg [63:0] correctData,
    output reg miss
    );
    
    reg [9:0] tag;
    reg [1:0] setOffset, wordOffset, LRUholder;
    int setOff, blockCount, hitBlock, numData;
    //4 sets, 4 blocks, cache line: 2 bit LRU, valid bit, tag, 4 words * 32 bits -> 141 bits
    reg [3:0][3:0][140:0] fullCache;
    reg hit, dataWritten;
    
    // clear the cache when starting
    // in each set --> {LRU, valid, tag, 4 word data}
    initial begin
      for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
          fullCache[i][j] = 141'b0;
        end
      end
    end

    always @(posedge clk) begin
      tag = address[13:4];
      setOffset = address[3:2];
      wordOffset = address[1:0];
      
      setOff = 0;
      $display(setOffset);
      case (setOffset)
          2'b00: 
            setOff = 0;    
          2'b01:
            setOff = 1;
          2'b10:
            setOff = 2;
          2'b11:
            setOff = 3;
          default:
            $display("Error in set Index");
      endcase
      $display("addy: %d", address);
      $display("setoff: %d", setOff);
      
      // if in updating cache mode
      $display(fromMM);
      if (fromMM == 1'b1 && (miss == 1'b1)) begin
        $display("hey how yall doing?");
        $display(dataReady);
        // if data is ready to be stored
        if (dataReady) begin
          dataWritten = 1'b0;
          blockCount = 0;

        // loop through each entry in the set to check the number of data in the set
          for (int i = 0; i < 4; i++) begin
              // check the valid bit
              $display("datafromMM" + dataFromMM);
              if (fullCache[setOff][i][138] == 1'b1) begin
                    blockCount++;
              end
          end
          $display("blockCount: %d", blockCount);
          // if all blocks are full, use LRU to choose 
          if (blockCount == 4) begin
            for (int i = 0; i < 4; i++) begin
              // if LRU is 2'b11, replace it with the new data!
              if (fullCache[setOff][i][140:139] == 2'b11) begin
                  fullCache[setOff][i] = {2'b00, 1'b1, tag, dataFromMM};
              end
              // increment all other LRU by incrementing by 1
              else 
                  fullCache[setOff][i][140:139] = (fullCache[setOff][i][140:139]) + 1;
            end
          end
          
          // there is an open slot!
          else begin
            //find first open slot
            for (int i = 0; i < 4; i++) begin
              $display("valid bit: %d, dataWritten: %d", fullCache[setOff][i][138], dataWritten);
              if ((fullCache[setOff][i][138] == 1'b0) && (dataWritten == 1'b0)) begin
                $display("inside block %d", i);
                fullCache[setOff][i] = {2'b00, 1'b1, tag, dataFromMM};
                dataWritten = 1'b1;
                $display("after: valid bit: %d, dataWritten: %d", fullCache[setOff][i][138], dataWritten);
              end
              //update LRU of existing data
              else begin
                if (fullCache[setOff][i][138] == 1'b1)
                    fullCache[setOff][i][140:139] = (fullCache[setOff][i][140:139]) + 1;
              end
            end
          end
          // cache is updated; get the correct data out!
          case (wordOffset)
                  2'b00:
                      correctData = {16'b0, address, 2'b00, dataFromMM[127:96]};
                  2'b01:
                      correctData = {16'b0, address, 2'b00, dataFromMM[95:64]};
                  2'b10:
                      correctData = {16'b0, address, 2'b00, dataFromMM[63:32]};
                  2'b11:
                      correctData = {16'b0, address, 2'b00, dataFromMM[31:0]};
          endcase
          // release PC counter!
          miss = 1'b0;
        end
      // if data not ready, don't do anything yet!
      end

      // normal operations
      else begin
        hit = 1'b0;
        hitBlock = 0;
        numData = 0;

      // go through each block in the set
      for (int i = 0; i < 4; i++) begin
        //check the valid bit
        if (fullCache[setOff][i][138] == 1'b1) begin
          // get total number of data inside
          numData++;
          // check tag index
          if ((fullCache[setOff][i][137:128] == tag)) begin
            // data is a hit! get corresponding word
            hit = 1'b1;
            // get the right word in the set
            case (wordOffset)
              2'b00: begin
                correctData = {16'b0, address, 2'b00, fullCache[setOff][i][127:96]};
                hitBlock = 0;
              end
              2'b01: begin
                correctData = {16'b0, address, 2'b00, fullCache[setOff][i][95:64]};
                hitBlock = 1;
              end
              2'b10: begin
                correctData = {16'b0, address, 2'b00, fullCache[setOff][i][63:32]};
                hitBlock = 2;
              end
              2'b11: begin
                correctData = {16'b0, address, 2'b00, fullCache[setOff][i][31:0]};
                hitBlock = 3;
              end
            endcase
          end
        end
      end

      // if miss, raise a miss and stall the pipeline
      if (hit == 1'b0) begin
        miss = 1'b1;
      end
      
      else begin
        LRUholder = 2'b00;
        // if the hit block LRU is not zero, need to update the LRU's
        if (fullCache[setOff][hitBlock][140:139] != 2'b00) begin
            // get current LRU of hit block
            LRUholder = fullCache[setOff][hitBlock][140:139];
            for (int i = 0; i < 4; i++) begin
              // if is the hit block --> set LRU to 0
              if (i == hitBlock)
                  fullCache[setOff][hitBlock][140:139] = 2'b00;
              // if LRU status is lower than hit block, add one!
              else if ((fullCache[setOff][i][140:139] < LRUholder) && fullCache[setOff][i][140:139]) 
                  fullCache[setOff][i][140:139] = fullCache[setOff][i][140:139] + 1;

            end
        end
      end
      end
    end
endmodule
