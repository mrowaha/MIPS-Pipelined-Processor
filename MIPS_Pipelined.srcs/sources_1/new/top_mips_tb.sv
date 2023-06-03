`timescale 1ns / 1ps


module top_mips_tb();

    logic clk;
    logic reset;
    logic [31:0] instrF, PC, PCF;
    logic PCSrcD;
    logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD, JalD;
    logic [2:0] alucontrol;
    logic [31:0] instrD;
    logic [31:0] ALUOutE, WriteDataE;
    logic [1:0] ForwardAE, ForwardBE;
    logic ForwardAD, ForwardBD;
    
    logic [31:0] instrE, instrM, instrW;
    logic [31:0] SrcAE, SrcBE, SrcBEforwarded;
    logic [2:0] ALUControlE;
    logic RegWriteW, MemToRegW;
    logic [31:0] ResultW;
    logic [4:0] WriteRegW;
    
    logic [31:0] rf [31:0];
//    module top_mips (input  logic        clk, reset,
//             output  logic[31:0]  instrF,
//             output logic[31:0] PC, PCF,
//             output logic PcSrcD,
//             output logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
//             output logic [2:0]  alucontrol,
//             output logic [31:0] instrD, 
//             output logic [31:0] ALUOutE, WriteDataE,
//             output logic [1:0] ForwardAE, ForwardBE,
//                 output logic ForwardAD, ForwardBD);

    Processor uut(clk, reset, instrF, PC, PCF, PCSrcD , MemWriteD , MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
        JalD, alucontrol, instrD, ALUOutE, WriteDataE, ForwardAE, ForwardBE, ForwardAD, ForwardBD,
        instrE, instrM, instrW,
        SrcAE, SrcBE, SrcBEforwarded, ALUControlE,
        RegWriteW, MemToRegW, ResultW, WriteRegW, rf, 1);

    
    initial begin
        clk = 1;
        reset = 1;
        #4;
        reset = 0;    
    end

    always #2 clk = ~clk;
    

endmodule
