`timescale 1ns / 1ps

module HazardUnit(input logic reset,
                input logic RegWriteW, BranchD,
                input logic [4:0] WriteRegW, WriteRegE,
                input logic RegWriteM, MemToRegM,
                input logic [4:0] WriteRegM,
                input logic RegWriteE,MemToRegE,
                input logic [4:0] rsE,rtE,
                input logic [4:0] rsD,rtD,
                output logic [1:0] ForwardAE,ForwardBE,
                output logic FlushE, StallD,  StallF,
                output logic ForwardAD, ForwardBD
                 ); 
                 
    logic lwstall, branchstall;
    
    always_comb begin
        if (reset) begin
            StallD = 1'b0;
            StallF = 1'b0;
            FlushE = 1'b0;
            ForwardAD  = 1'b0;
            ForwardBD  = 1'b0;
            ForwardAE  = 2'b00;
            ForwardBE  = 2'b00; 
        end else begin
            if (rsE != 0 && rsE == WriteRegM && RegWriteM) ForwardAE = 2'b10;
            else if (rsE != 0 && rsE == WriteRegW && RegWriteW) ForwardAE = 2'b01;
            else ForwardAE = 2'b00;
            
            if (rtE != 0 && rtE == WriteRegM && RegWriteM) ForwardBE = 2'b10;
            else if (rtE != 0 && rtE == WriteRegW  && RegWriteW ) ForwardBE = 2'b01;
            else ForwardBE = 2'b00;
        
            ForwardAD = (rsD != 0) && (rsD == WriteRegM) && RegWriteM;
            ForwardBD = (rtD != 0) && (rtD == WriteRegM) && RegWriteM;
            
            lwstall = ((rsD == rtE) || (rtD == rtE)) && MemToRegE;
            branchstall = (BranchD && RegWriteE && (WriteRegE == rsD || WriteRegE == rtD)) || 
                          (BranchD && MemToRegM && (WriteRegM == rsD || WriteRegM == rtD));
            FlushE = lwstall || branchstall;
            StallD = lwstall || branchstall;
            StallF = lwstall || branchstall; 
        end
    end
  
endmodule

