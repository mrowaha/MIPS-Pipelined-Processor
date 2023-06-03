`timescale 1ns / 1ps

module Processor (input  logic        clk, reset,
             output  logic[31:0]  instrF,
             output logic[31:0] PC, PCF,
             output logic PCSrcD,
             output logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD, JalD,
             output logic [2:0]  ALUControlD,
             output logic [31:0] instrD, 
             output logic [31:0] ALUOutE, WriteDataE,
             output logic [1:0] ForwardAE, ForwardBE,
             output logic ForwardAD, ForwardBD,
             output logic [31:0] instrE, instrM, instrW,
             output logic [31:0] SrcAE, SrcBE, SrcBEforwarded,
             output logic [2:0] ALUControlE,
             output logic RegWriteW, MemToRegW,
             output logic [31:0] ResultW,
             output logic [4:0] WriteRegW,
             output logic [31:0] rftemp [31:0],
             input logic step);


    Controller CU(instrD[31:26], instrD[5:0], MemToRegD, MemWriteD, ALUSrcD, RegDstD, RegWriteD, ALUControlD, BranchD, JalD);
    
    Datapath DP(clk, reset, ALUControlD, RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD, JalD,
        instrF, instrD, instrE, instrM, instrW, 
        PC, PCF, PCSrcD,
        ALUOutE, WriteDataE, 
        ForwardAE, ForwardBE, ForwardAD, ForwardBD, SrcAE, SrcBE, SrcBEforwarded, ALUControlE,
        RegWriteW, MemToRegW,
        ResultW, WriteRegW, rftemp, step );

endmodule