`timescale 1ns / 1ps

// Define pipes that exist in the PipelinedDatapath. 
// The pipes between Writeback (W) and Fetch (F), as well as Decode (D) and Execute (E) are given to you.
// Create the rest of the pipes where inputs follow the naming conventions in the book.
module PipeFtoD(input logic[31:0] instr, PcPlus4F,
                input logic EN, clear, clk, reset, // ~StallD will be connected as EN
                output logic[31:0] instrD, PcPlus4D);

    always_ff @(posedge clk, posedge reset) begin
        if (clear || reset) begin
            instrD <= 31'b0000_0000_0000_0000_0000_0000_0000_0000;
            PcPlus4D  <= 31'b0000_0000_0000_0000_0000_0000_0000_0000;
        end
    
        if (EN) begin
            PcPlus4D <= PcPlus4F;
            instrD <= instr;    
            
        end
    end
                
endmodule

// The pipe between Writeback (W) and Fetch (F) is given as follows.
module PipeWtoF(input logic[31:0] PC,
                input logic EN, clk, reset,		// ~StallF will be connected as this EN
                output logic[31:0] PCF);

    always_ff @(posedge clk, posedge reset) begin
        if(reset)
            PCF <= 0;
        else if(EN)
            PCF <= PC;
    end
    
endmodule

module PipeDtoE(input logic[31:0] RD1, RD2, SignImmD,
                input logic[4:0] RsD, RtD, RdD,
                input logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD,
                input logic[2:0] ALUControlD,
                input logic clear, clk, reset,
                output logic[31:0] RsData, RtData, SignImmE,
                output logic[4:0] RsE, RtE, RdE, 
                output logic RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE,
                output logic[2:0] ALUControlE);

        always_ff @(posedge clk, posedge reset)
          if(reset || clear)
                begin
                // Control signals
                RegWriteE <= 0;
                MemtoRegE <= 0;
                MemWriteE <= 0;
                ALUControlE <= 0;
                ALUSrcE <= 0;
                RegDstE <= 0;
                
                // Data
                RsData <= 0;
                RtData <= 0;
                RsE <= 0;
                RtE <= 0;
                RdE <= 0;
                SignImmE <= 0;
                end
            else
                begin
                // Control signals
                RegWriteE <= RegWriteD;
                MemtoRegE <= MemtoRegD;
                MemWriteE <= MemWriteD;
                ALUControlE <= ALUControlD;
                ALUSrcE <= ALUSrcD;
                RegDstE <= RegDstD;
                
                // Data
                RsData <= RD1;
                RtData <= RD2;
                RsE <= RsD;
                RtE <= RtD;
                RdE <= RdD;
                SignImmE <= SignImmD;
                end

endmodule

module PipeEtoM(input logic [31:0] ALUOutE, WriteDataE,
                input logic [4:0] WriteRegE,
                input logic RegWriteE, MemtoRegE, MemWriteE,
                input logic clk, reset, 
                output logic [31:0] ALUOutM, WriteDataM,
                output logic [4:0] WriteRegM,
                output logic RegWriteM, MemtoRegM, MemWriteM
                 );
                  
    localparam ZERO = 31'b0000_0000_0000_0000_0000_0000_0000_0000; 
    
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            // Control signals
            RegWriteM <= 0;
            MemtoRegM <= 0;
            MemWriteM <= 0;
            
            // Data buses
            ALUOutM <= ZERO;
            WriteDataM <= ZERO;
            WriteRegM <= 5'b00000;      
        end else begin
            // Control Signals
            RegWriteM <= RegWriteE;
            MemtoRegM <= MemtoRegE;
            MemWriteM <= MemWriteE;
            
            // Data buses
            ALUOutM <= ALUOutE;
            WriteDataM <= WriteDataE;
            WriteRegM  <= WriteRegE;
        end
    
    
    end                  
endmodule

module PipeMtoW(input logic RegWriteM, MemtoRegM,
                input logic [31:0] ReadDataM, ALUOutM,
                input logic [4:0] WriteRegM,
                input logic clk, reset,
                output logic RegWriteW, MemtoRegW,
                output logic [31:0] ReadDataW, ALUOutW,
                output logic [4:0] WriteRegW
                );

    localparam ZERO = 31'b0000_0000_0000_0000_0000_0000_0000_0000;
    
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            // Control Signals
            RegWriteW  <= 0;
            MemtoRegW  <= 0;
            
            // Data buses
            ReadDataW <= ZERO;
            ALUOutW  <= ZERO;
            WriteRegW <= 5'b00000;
        end else begin
            RegWriteW <= RegWriteM;
            MemtoRegW  <= MemtoRegM ;
            
            ReadDataW <= ReadDataM ;
            ALUOutW  <= ALUOutM ;
            WriteRegW  <= WriteRegM ; 
        end
    end
endmodule



// *******************************************************************************
// End of the individual pipe definitions.
// ******************************************************************************

// *******************************************************************************

module datapath (input  logic clk, reset,
                input  logic[2:0]  ALUControlD,
                input logic RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD,
                 output logic [31:0] instrF,		
                 output logic [31:0] instrD, PC, PCF,
                output logic PcSrcD,                 
                output logic [31:0] ALUOutE, WriteDataE,
                output logic [1:0] ForwardAE, ForwardBE,
                 output logic ForwardAD, ForwardBD); // Add or remove input-outputs if necessary

	// ********************************************************************
	// Here, define the wires that are needed inside this pipelined datapath module
	// ********************************************************************
  
  	//* We have defined a few wires for you
    logic [31:0] PcSrcA, PcSrcB, PcBranchD, PcPlus4F;	
  	logic [31:0] SignImmD, ShiftedImmD;
  	logic [31:0] ResultW;
  	logic [4:0] WriteRegW;
  	logic [31:0] RD1, RD2;
  	logic [31:0] SrcBE;
  	logic [31:0] ReadDataM;
    
  
	//* You should define others down below (you might want to rename some of the wires above while implementing the pipeline)
  
  	//* We have provided you with a single-cycle datapath
  	//* You should convert it to a pipelined datapath, changing the connections between modules as necessary
    
  	// Replace with PipeWtoF
//    flopr #(32) pcreg(clk, reset, PC, PCF);
    PipeWtoF pipeWtoF(PC, ~stallF, clk, reset, PCF);
  
  	// Do some operations
    assign PcPlus4F = PCF + 4;
    assign PcSrcB = PcBranchD;
	assign PcSrcA = PcPlus4F;
  	mux2 #(32) pc_mux(PcSrcA, PcSrcB, PcSrcD, PC);

    imem im1(PCF[7:2], instrF);
    
  	// Replace the code below with PipeFtoD
//  	assign instrD = instrF;
    logic [31:0] PcPlus4D;
    PipeFtoD pipeFtoD(instrF , PcPlus4F , ~stallD, FlushE , clk, reset, instrD, PcPlus4D);
      
  	// Decode stage
  	regfile rf(clk, reset, RegWriteD, instrD[25:21], instrD[20:16], WriteRegW, ResultW, RD1, RD2);
  	signext se(instrD[15:0], SignImmD);
  	
  	sl2 shiftimm(SignImmD, ShiftedImmD);
  	adder branchadd(PcPlus4D, ShiftedImmD, PcBranchD);
  	// Hazard Logic
  	logic [31:0] BranchRD1, BranchRD2;
  	assign BranchRD1 = ForwardAD ? ALUOutM  : RD1;
  	assign BranchRD2 = ForwardBD ? ALUOutM : RD2;
  	assign PcSrcD = BranchD & (BranchRD1 == BranchRD2); 
  
  	// Instantiate PipeDtoE here
  	logic[31:0] RsData, RtData, SignImmE;
  	logic[4:0] RsE, RtE, RdE;
  	logic RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE;
  	logic[2:0] ALUControlE;
    PipeDtoE pipeDtoE(RD1,  RD2, SignImmD, instrD[25:21], instrD[20:16], instrD[15:11], RegWriteD, 
                      MemToRegD, MemWriteD, ALUSrcD, RegDstD, ALUControlD, clear, clk, reset,    
                      RsData, RtData, SignImmE, RsE, RtE, RdE, RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE, 
                      ALUControlE      
                   );
  
  	// Execute stage
  	logic [31:0] SrcAE, SrcBEforwarded;
  	mux4 #(32) forwardAEMux(RsData, ResultW, ALUOutM, 0, ForwardAE, SrcAE);
  	mux4 #(32) fowardBEMux(RtData, ResultW, ALUOutM, 0, ForwardBE, SrcBEforwarded);
  	mux2 #(32) srcBMux(SrcBEforwarded , SignImmD, ALUSrcD, SrcBE);
  	
  	alu alu(srcAE, SrcBE, ALUControlD, ALUOutE);
  	logic [4:0] WriteRegE;
  	mux2 #(5) wrMux(RtE, RdE, RegDstE, WriteRegE);


  	// Replace the code below with PipeEtoM
    logic [31:0] ALUOutM, WriteDataM;
    logic [4:0] WriteRegM;
    logic RegWriteM, MemtoRegM, MemWriteM;
  	PipeEtoM pipeEtoM(ALUOutE, WriteDataE, WriteRegE, RegWriteE, MemtoRegE, MemWriteE, clk, reset, ALUOutM,
  	                  WrteDataM, WriteRegM, RegWriteM, MemtoRegM, MemWriteM    
  	                     );
  	
  	// Memory stage
  	dmem DM(clk, MemWriteD, ALUOutE, WriteDataE, ReadDataM);

  	// Instantiate PipeMtoW
  	logic RegWriteW, MemtoRegW;
  	logic [31:0] ReadDataW, ALUOutW;
  	logic [4:0] WriteRegW;
    PipeMtoW pipeMtoW(RegWriteM, MemtoRegM, ReadDataM, ALUOutM, WriteRegM, clk, reset, RegWriteW, MemtoRegW,
                       ReadDataW, ALUOutW, WriteRegW  
     );
    
  	// Writeback stage
  	mux2 #(32) wbmux(ALUOutE, ReadDataM, MemToRegD, ResultW);
  	
  	// Replace the code below with HazardUnit
  	logic StallF, StallD, FlushE;
  	HazardUnit hazardUnit(RegWriteM, BranchD, WriteRegW, WriteRegE, RegWriteM, MemtoRegM,
  	                     WriteRegM, RegWriteE, MemtoRegE, RsE, RtE, RsD, RtD, ForwardAE, ForwardBE, ForwardAD, ForwardBD);

endmodule

module HazardUnit( input logic RegWriteW, BranchD,
                input logic [4:0] WriteRegW, WriteRegE,
                input logic RegWriteM,MemtoRegM,
                input logic [4:0] WriteRegM,
                input logic RegWriteE,MemtoRegE,
                input logic [4:0] rsE,rtE,
                input logic [4:0] rsD,rtD,
                output logic [1:0] ForwardAE,ForwardBE,
                output logic FlushE,StallD,StallF,ForwardAD, ForwardBD
                 ); // Add or remove input-outputs if necessary
       
	// ********************************************************************
	// Here, write equations for the Hazard Logic.
	// If you have troubles, please study pages ~420-430 in your book.
	// ********************************************************************
    logic lwstall, branchstall;
    always begin
        if (rsE != 0 && rsE == WriteRegM && RegWriteM) ForwardAE <= 2'b10;
        else if (rsE != 0 && rsE == WriteRegW && RegWriteW) ForwardAE <= 2'b01;
        else ForwardAE <= 2'b00;
        
        if (rtE != 0 && rtE == WriteRegM && RegWriteM) ForwardBE <= 2'b10;
        else if (rtE != 0 && rtE == WriteRegW  && RegWriteW ) ForwardBE <= 2'b01;
        else ForwardBE <= 2'b00;
    
        ForwardAD <= (rsD != 0) && (rsD == WriteRegM) && RegWriteM;
        ForwardBD <= (rtD != 0) && (rtD == WriteRegM ) && RegWriteM;
        
        lwstall <= ((rsD == rtE) || (rsD == rsE)) && MemtoRegE;
        branchstall <= (BranchD && RegWriteE && (WriteRegE == rsD || WriteRegE == rtD)) || 
                       (BranchD && MemtoRegM && (WriteRegM == rsD || WriteRegM == rtD));
        FlushE <= lwstall || branchstall;
        StallD <= lwstall || branchstall;
        StallF <= lwstall || branchstall; 
    end
  
endmodule


// You can add some more logic variables for testing purposes
// but you cannot remove existing variables as we need you to output 
// these values on the waveform for grading
module top_mips (input  logic        clk, reset,
             output  logic[31:0]  instrF,
             output logic[31:0] PC, PCF,
             output logic PcSrcD,
             output logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
             output logic [2:0]  alucontrol,
             output logic [31:0] instrD, 
             output logic [31:0] ALUOutE, WriteDataE,
             output logic [1:0] ForwardAE, ForwardBE,
                 output logic ForwardAD, ForwardBD);


    controller CU(instrD[31:26], instrD[5:0], MemToRegD, MemWriteD, ALUSrcD, RegDstD, RegWriteD, alucontrol, BranchD);
    
    datapath DP(clk, reset, alucontrol, RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD, 
        instrF, instrD, 
        PC, PCF, PcSrcD,
        ALUOutE, WriteDataE, 
        ForwardAE, ForwardBE, ForwardAD, ForwardBD); // Add or remove input-outputs as necessary
  
  
  
endmodule


// External instruction memory used by MIPS
// processor. It models instruction memory as a stored-program 
// ROM, with address as input, and instruction as output
// Modify it to test your own programs.

module imem ( input logic [5:0] addr, output logic [31:0] instr);

// imem is modeled as a lookup table, a stored-program byte-addressable ROM
	always_comb
	   case ({addr,2'b00})		   	// word-aligned fetch
//
// 	***************************************************************************
//	Here, you can paste your own test cases that you prepared for the part 1-e.
//  An example test program is given below.        
//	***************************************************************************
//
//		address		instruction
//		-------		-----------
//    8'h00: instr = 32'h20080005;
//    8'h04: instr = 32'hac080060;
//    8'h08: instr = 32'h8c090060;
//    8'h0c: instr = 32'h212a0004;
//    8'h10: instr = 32'h212b0003;
//    8'h14: instr = 32'h8d6b0058;
//    8'h18: instr = 32'h014b5022;
//    8'h1c: instr = 32'hac0a0070;
//    8'h20: instr = 32'h8c080070;
//    8'h24: instr = 32'h8d09006c;
//    8'h28: instr = 32'h01094820;
        8'h00: instr = 32'h20080005;    // addi $t0, $zero, 5                 
        8'h04: instr = 32'h2009000c;    // addi $t1, $zero, 12
        8'h08: instr = 32'h200a0006;    // addi $t2, $zero, 6
        8'h0c: instr = 32'h210bfff7;    // addi $t3, $t0, -9    
        8'h10: instr = 32'h01288025;    // or $s0, $t1, $t0
        8'h14: instr = 32'h012a8824;    // and $s1, $t1, $t2
        8'h18: instr = 32'h010b9020;    // add $s2, $t0, $t3
        8'h1c: instr = 32'h010a202a;    // slt $a0, $t0, $t2
        8'h20: instr = 32'h02112820;    // add $a1, $s0, $s1
        8'h24: instr = 32'h02493022;    // sub $a2, $s2, $t1
        8'h28: instr = 32'had320074;    // sw $s2, 0x74($t1)
        8'h2c: instr = 32'h8c020080;    // lw $v0, 0x80($zero)

       default:  instr = {32{1'bx}};	// unknown address
	   endcase
endmodule


// 	***************************************************************************
//	Below are the modules that you should modify to add more instructions to the CPU
//	***************************************************************************

module controller(input  logic[5:0] op, funct,
                  output logic     memtoreg, memwrite,
                  output logic     alusrc,
                  output logic     regdst, regwrite,
                  output logic[2:0] alucontrol,
                  output logic branch);

   logic [1:0] aluop;

  maindec md (op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, aluop);

   aludec ad (funct, aluop, alucontrol);

endmodule

// External data memory used by MIPS single-cycle processor

module dmem (input  logic        clk, we,
             input  logic[31:0]  a, wd,
             output logic[31:0]  rd);

   logic  [31:0] RAM[63:0];
  
   assign rd = RAM[a[31:2]];    // word-aligned  read (for lw)

   always_ff @(posedge clk)
     if (we)
       RAM[a[31:2]] <= wd;      // word-aligned write (for sw)

endmodule

module maindec (input logic[5:0] op, 
	              output logic memtoreg, memwrite, branch,
	              output logic alusrc, regdst, regwrite,
	              output logic[1:0] aluop );
  logic [7:0] controls;

   assign {regwrite, regdst, alusrc, branch, memwrite,
                memtoreg,  aluop} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 8'b11000010; // R-type
      6'b100011: controls <= 8'b10100100; // LW
      6'b101011: controls <= 8'b00101000; // SW
      6'b000100: controls <= 8'b00010001; // BEQ
      6'b001000: controls <= 8'b10100000; // ADDI
      default:   controls <= 8'bxxxxxxxx; // illegal op
    endcase
endmodule

module aludec (input    logic[5:0] funct,
               input    logic[1:0] aluop,
               output   logic[2:0] alucontrol);
  always_comb
    case(aluop)
      2'b00: alucontrol  = 3'b010;  // add  (for lw/sw/addi)
      2'b01: alucontrol  = 3'b110;  // sub   (for beq)
      default: case(funct)          // R-TYPE instructions
          6'b100000: alucontrol  = 3'b010; // ADD
          6'b100010: alucontrol  = 3'b110; // SUB
          6'b100100: alucontrol  = 3'b000; // AND
          6'b100101: alucontrol  = 3'b001; // OR
          6'b101010: alucontrol  = 3'b111; // SLT
          default:   alucontrol  = 3'bxxx; // ???
        endcase
    endcase
endmodule

module regfile (input    logic clk, reset, we3, 
                input    logic[4:0]  ra1, ra2, wa3, 
                input    logic[31:0] wd3, 
                output   logic[31:0] rd1, rd2);

  logic [31:0] rf [31:0];

  always_ff @(negedge clk) begin
    rd1 <= (ra1 != 0) ? rf[ra1] : 0;
    rd2 <= (ra2 != 0) ? rf[ra2] : 0;
  end

  always_ff @(posedge clk)
     if (reset)
        for (int i=0; i<32; i++) rf[i] = 32'b0;
     else if (we3)
        rf[wa3] <= wd3;

endmodule

module alu(input  logic [31:0] a, b, 
           input  logic [2:0]  alucont, 
           output logic [31:0] result,
           output logic zero);
    
    always_comb
        case(alucont)
            3'b010: result = a + b;
            3'b110: result = a - b;
            3'b000: result = a & b;
            3'b001: result = a | b;
            3'b111: result = (a < b) ? 1 : 0;
            default: result = {32{1'bx}};
        endcase
    
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

// parameterized register
module flopr #(parameter WIDTH = 8)
              (input logic clk, reset,
	       input logic[WIDTH-1:0] d, 
               output logic[WIDTH-1:0] q);

  always_ff@(posedge clk, posedge reset)
    if (reset) q <= 0; 
    else q <= d;
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
