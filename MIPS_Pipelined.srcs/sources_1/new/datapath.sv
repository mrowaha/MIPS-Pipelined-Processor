`timescale 1ns / 1ps

module Datapath (input  logic clk, reset,
                input  logic[2:0]  ALUControlD,
                input logic RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD, JalD,
                 output logic [31:0] instrF,		
                 output logic [31:0] instrD, instrE, instrM, instrW, 
                 output logic [31:0] PC, PCF,
                output logic PCSrcD,                 
                output logic [31:0] ALUOutE, WriteDataE,
                output logic [1:0] ForwardAE, ForwardBE,
                 output logic ForwardAD, ForwardBD,
                 output logic [31:0] SrcAE, SrcBE, SrcBEforwarded,
                 output logic [2:0] ALUControlE,
                 output logic RegWriteW, MemToRegW,
                 output logic [31:0] ResultW,
                 output logic [4:0] WriteRegW,
                 output logic [31:0] rftemp [31:0],
                 input logic step
                 );

  	// Hazard logic
  	logic StallF, StallD, FlushE;
  	
    // Decode Stage Logic
    logic [31:0] PCSrcA, PCSrcB;
    logic [31:0] PCBranchD, PCPlus4F;	
  	logic [31:0] RD1, RD2;
    logic [31:0] PCPlus4D;
  	logic [31:0] BranchRD1, BranchRD2;
  	logic [31:0] SignImmD, ShiftedImmD;

    // Execute Stage Logic
    logic[31:0] RD1E, RD2E, SignImmE, PcPlus4E;
  	logic[4:0] RsE, RtE, RdE;
  	logic RegWriteE, MemToRegE, MemWriteE, ALUSrcE, RegDstE, JalE;
//  	logic[2:0] ALUControlE;
//    logic [31:0] SrcAE, SrcBEforwarded, SrcBE;
    logic [4:0] WriteRegE;
    logic zero;
    
    // Memory Stage Logic
    logic [31:0] ALUOutM, WriteDataM, PcPlus4M;
    logic [4:0] WriteRegM;
    logic RegWriteM, MemToRegM, MemWriteM, JalM;
    logic [31:0] ReadDataM;

    // Writeback Stage logic
//    logic RegWriteW, MemToRegW;
//    logic [31:0] ResultW;
  	logic [31:0] ReadDataW, ALUOutW, PcPlus4W, WriteRegWTemp;
  	logic JalW;
//  	logic [4:0] WriteRegW;

    // Fetch Stage
    PipeWtoF pipeWtoF(PC, ~StallF, clk, reset, PCF, step);
  
    assign PCPlus4F = PCF + 4;
    assign PCSrcB = PCBranchD;
	assign PCSrcA = PCPlus4F;
	logic [31:0] PCTemp;
  	mux2 #(32) pc_mux1(PCSrcA, PCSrcB, PCSrcD, PCTemp);
  	logic [31:0] JalAddress;
  	assign JalAddress = {PCPlus4D[31:28], instrD[25:0], 2'b00};
  	mux2 #(32) pc_mux2(PCTemp, JalAddress, JalD, PC);
    imem im1(PCF[7:2], instrF);
    // *************************************
    
    // Decode Stage
    PipeFtoD pipeFtoD(instrF , PCPlus4F , ~StallD, PCSrcD | JalD, clk, reset, instrD, PCPlus4D, step);
      
  	regfile rf(~clk, reset, RegWriteW, instrD[25:21], instrD[20:16], WriteRegW, ResultW, RD1, RD2, rftemp);
  	signext se(instrD[15:0], SignImmD);
  	
  	sl2 shiftimm(SignImmD, ShiftedImmD);
  	adder branchadd(PCPlus4D, ShiftedImmD, PCBranchD);
  	// Hazard Logic in Decode Stage
  	mux2 #(32) branchRD1mux(RD1, ALUOutM, ForwardAD, BranchRD1);
    mux2 #(32) branchRD2mux(RD2, ALUOutM, ForwardBD, BranchRD2);
  	assign PCSrcD = BranchD & (BranchRD1 == BranchRD2); 
    // **********************************
  
  	// Execute Stage
    PipeDtoE pipeDtoE(RD1,  RD2, SignImmD, instrD[25:21], instrD[20:16], instrD[15:11], RegWriteD, 
                      MemToRegD, MemWriteD, ALUSrcD, RegDstD, ALUControlD, FlushE, clk, reset,    
                      RD1E, RD2E, SignImmE, RsE, RtE, RdE, RegWriteE, MemToRegE, MemWriteE, ALUSrcE, RegDstE, 
                      ALUControlE, instrD, instrE, PCPlus4D, PcPlus4E, JalD, JalE,   
                      step
                      );

  	mux4 #(32) forwardAEMux(RD1E, ResultW, ALUOutM, {32{1'bx}}, ForwardAE, SrcAE);
  	mux4 #(32) fowardBEMux(RD2E, ResultW, ALUOutM, {32{1'bx}}, ForwardBE, SrcBEforwarded);
  	assign WriteDataE = SrcBEforwarded;
  	mux2 #(32) srcBMux(SrcBEforwarded , SignImmE, ALUSrcE, SrcBE);
 
  	alu alu(SrcAE, SrcBE, ALUControlE, ALUOutE, zero);
  	mux2 #(5) wrMux(RtE, RdE, RegDstE, WriteRegE);


  	// Memory Stage
  	PipeEtoM pipeEtoM(ALUOutE, WriteDataE, WriteRegE, RegWriteE, MemToRegE, MemWriteE, clk, reset, ALUOutM,
  	                  WriteDataM, WriteRegM, RegWriteM, MemToRegM, MemWriteM, instrE, instrM,  
  	                   PcPlus4E, PcPlus4M, JalE, JalM, step);
  	
  	dmem DM(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);

  	// Writeback Stage
    PipeMtoW pipeMtoW(RegWriteM, MemToRegM, ReadDataM, ALUOutM, WriteRegM, clk, reset, RegWriteW, MemToRegW,
                       ReadDataW, ALUOutW, WriteRegWTemp, instrM, instrW ,
                       PcPlus4M, PcPlus4W, JalM, JalW, step 
     );
    
    mux2 #(5) writeRegMux(WriteRegWTemp, 5'b11111, JalW, WriteRegW);
    logic [31:0] ResultWTemp;    
  	mux2 #(32) wbmux1(ALUOutW, ReadDataW, MemToRegW, ResultWTemp);
  	mux2 #(32) wbmux2(ResultWTemp, PcPlus4W, JalW, ResultW);
  	
  	
  	// Replace the code below with HazardUnit
  	HazardUnit hazardUnit(reset, RegWriteW, BranchD, WriteRegW, WriteRegE, RegWriteM, MemToRegM,
  	                     WriteRegM, RegWriteE, MemToRegE, RsE, RtE, instrD[25:21], instrD[20:16], ForwardAE, ForwardBE, 
  	                     FlushE, StallD, StallF,
  	                     ForwardAD, ForwardBD);

endmodule

module regfile (input    logic clk, reset, we3, 
                input    logic[4:0]  ra1, ra2, wa3, 
                input    logic[31:0] wd3, 
                output   logic[31:0] rd1, rd2,
                output logic [31:0] rf [31:0]);

//  logic [31:0] rf [31:0];

  always_ff @(negedge clk) begin
    rd1 <= (ra1 != 0) ? rf[ra1] : 0;
    rd2 <= (ra2 != 0) ? rf[ra2] : 0;
  end

  always_ff @(posedge clk, posedge reset) begin
     if (reset)
        for (int i=0; i<32; i++) rf[i] = 32'b0;
     else if (we3)
        // blocking write
        rf[wa3] <= wd3;        
   end

endmodule

module alu(input  logic [31:0] a, b, 
           input  logic [2:0]  alucont, 
           output logic [31:0] result,
           output logic zero);
    
    always_comb begin
        case(alucont)
            3'b010: 
            begin
            result = a + b;
            $display("Adding ", a, " And ", b);
            end
            3'b110: 
            begin
            result = a - b;
            end
            3'b000: 
            begin
            result = a & b;
            end
            3'b001: 
            begin
            result = a | b;
            end
            3'b111: 
            begin
            result = (a < b) ? 1 : 0;
            end
            default: 
            begin
            result = {32{1'b0}};
            end
        endcase
    end
    assign zero = (result == 0) ? 1'b1 : 1'b0;
    
endmodule

module adder (input  logic[31:0] a, b,
              output logic[31:0] y);
     
     assign y = a + b;
endmodule

module sl2 (input  logic[31:0] a,
            output logic[31:0] y);
     
     assign y = {a[29:0], 2'b00}; // shifts left by 2
endmodule

module signext (input  logic[15:0] a,
                output logic[31:0] y);
              
  assign y = {{16{a[15]}}, a};    // sign-extends 16-bit a
endmodule

// paramaterized 2-to-1 MUX
module mux2 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1,  
              input  logic s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s ? d1 : d0; 
endmodule

// paramaterized 4-to-1 MUX
module mux4 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1, d2, d3,
              input  logic[1:0] s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s[1] ? ( s[0] ? d3 : d2 ) : (s[0] ? d1 : d0); 
endmodule
