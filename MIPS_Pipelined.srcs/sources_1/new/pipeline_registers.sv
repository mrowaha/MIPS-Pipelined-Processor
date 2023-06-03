`timescale 1ns / 1ps

/**
    Pipeline Register Writeback -> Fetch with aync RESET
*/
module PipeWtoF(input logic[31:0] PC,
                input logic EN, clk, reset,		// ~StallF will be connected as this EN
                output logic[31:0] PCF,
                input logic step);

    always_ff @(posedge clk) begin
//        $display("Enable in PipeWtoF is ", EN);
        if(reset) begin
//            $display("In Reset PipeWtoF");
            PCF <= 0;
        end else if (EN && step)
            PCF <= PC;
    end
    
endmodule

/**
    Pipeline Register Fetch -> Decode with async RESET
    Pipes:
    InstrF -> InstrD
    PcPlus4F -> PcPlus4D
*/
module PipeFtoD(input logic[31:0] instrF, PcPlus4F,
                input logic EN, CLR, clk, reset, // ~StallD will be connected as EN
                output logic[31:0] instrD, PcPlus4D,
                input logic step);

    always_ff @(posedge clk) begin
        if (CLR || reset) begin
            instrD <= {32{1'b0}};
            PcPlus4D <= {32{1'b0}};
        end else if (EN && step) begin
            PcPlus4D <= PcPlus4F;
            instrD <= instrF;               
        end
    end
    
         
endmodule

/**
    Pipeline Register Decode -> Execute with async RESET
    Pipes:
    RD1 -> RD1E
    RD2 -> RD2E
    RsD -> RsE
    RtD -> RtE
    RdD -> RdE
    SignImmD -> SignImmE
    
    And the relevant control signals
*/
module PipeDtoE(input logic[31:0] RD1, RD2, SignImmD,
                input logic[4:0] RsD, RtD, RdD,
                input logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD,
                input logic[2:0] ALUControlD,
                input logic CLR, clk, reset, // FlushE is CLR
                output logic[31:0] RD1E, RD2E, SignImmE,
                output logic[4:0] RsE, RtE, RdE, 
                output logic RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE,
                output logic[2:0] ALUControlE,
                input logic [31:0] instrD,
                output logic [31:0] instrE,
                input logic [31:0] PcPlus4D,
                output logic [31:0] PcPlus4E,
                input logic JalD,
                output logic JalE,
                input logic step
                );

    always_ff @(posedge clk) begin
      if(reset || CLR)
            begin
            // Control signals
            RegWriteE <= 0;
            MemtoRegE <= 0;
            MemWriteE <= 0;
            ALUControlE <= {3{1'b0}};
            ALUSrcE <= 0;
            RegDstE <= 0;
                
            // Data
            RD1E <= {32{1'b0}};
            RD2E <= {32{1'b0}};
            RsE <= {5{1'b0}};
            RtE <= {5{1'b0}};
            RdE <= {5{1'b0}};
            SignImmE <= {32{1'b0}};
            
            instrE <= {32{1'b0}};
            PcPlus4E  <= {32{1'b0}};
            JalE <= 1'b0;
            end
        else if (step)
            begin
            // Control signals
            RegWriteE <= RegWriteD;
            MemtoRegE <= MemtoRegD;
            MemWriteE <= MemWriteD;
            ALUControlE <= ALUControlD;
            ALUSrcE <= ALUSrcD;
            RegDstE <= RegDstD;
                
            // Data
            RD1E <= RD1;
            RD2E <= RD2;
            RsE <= RsD;
            RtE <= RtD;
            RdE <= RdD;
            SignImmE <= SignImmD;
            
            instrE <= instrD;
            PcPlus4E <= PcPlus4D;
            JalE <= JalD;
            end
    end
endmodule

/**
    Pipeline Register Execute -> Memory with async RESET
    Pipes:
    ALUOutE -> ALUOutM
    WriteDataE -> WriteDataM
    WriteRegE -> WriteRegM
    
    And the relevant control signals
*/
module PipeEtoM(input logic [31:0] ALUOutE, WriteDataE,
                input logic [4:0] WriteRegE,
                input logic RegWriteE, MemtoRegE, MemWriteE,
                input logic clk, reset, 
                output logic [31:0] ALUOutM, WriteDataM,
                output logic [4:0] WriteRegM,
                output logic RegWriteM, MemtoRegM, MemWriteM,
                input logic [31:0] instrE,
                output logic [31:0] instrM,
                input logic [31:0] PcPlus4E,
                output logic [31:0] PcPlus4M,
                input logic JalE,
                output logic JalM,
                input logic step 
                 );
                  
    always_ff @(posedge clk) begin
        if (reset) begin
            // Control signals
            RegWriteM <= 0;
            MemtoRegM <= 0;
            MemWriteM <= 0;
            
            // Data buses
            ALUOutM <= {32{1'b0}};
            WriteDataM <= {32{1'b0}};
            WriteRegM <= {5{1'b0}};
            
            instrM <= {32{1'b0}};      
            PcPlus4M <= {32{1'b0}};
            JalM <= 1'b0;
        end else if (step) begin
            // Control Signals
            RegWriteM <= RegWriteE;
            MemtoRegM <= MemtoRegE;
            MemWriteM <= MemWriteE;
            
            // Data buses
            ALUOutM <= ALUOutE;
            WriteDataM <= WriteDataE;
            WriteRegM  <= WriteRegE;
        
            instrM <= instrE;
            PcPlus4M <= PcPlus4E;
            JalM <= JalE;
        end

    end                  
endmodule

/**
    Pipeline Register Memory -> Writeback with async RESET
    Pipes:
    RegWriteM -> RegWriteW |
    MemtoRegM -> MemtoRegW | Control Signals
    ReadDataM -> ReadDataW |
    ALUOutM -> ALUOutW
    WriteRegM -> WriteRegW
*/
module PipeMtoW(input logic RegWriteM, MemtoRegM,
                input logic [31:0] ReadDataM, ALUOutM,
                input logic [4:0] WriteRegM,
                input logic clk, reset,
                output logic RegWriteW, MemtoRegW,
                output logic [31:0] ReadDataW, ALUOutW,
                output logic [4:0] WriteRegW,
                input logic [31:0] instrM,
                output logic [31:0] instrW,
                input logic [31:0] PcPlus4M,
                output logic [31:0] PcPlus4W,
                input logic JalM,
                output logic JalW,
                input logic step
                );

    always_ff @(posedge clk) begin
        if (reset) begin
            // Control Signals
            RegWriteW  <= 0;
            MemtoRegW  <= 0;
            
            // Data buses
            ReadDataW <= {32{1'b0}};
            ALUOutW  <= {32{1'b0}};
            WriteRegW <= {5{1'b0}};
            
            instrW <= {32{1'b0}};
            PcPlus4W <= {32{1'b0}};
            JalW <= 1'b0;
        end else if (step) begin
            RegWriteW <= RegWriteM;
            MemtoRegW  <= MemtoRegM ;
            
            ReadDataW <= ReadDataM ;
            ALUOutW  <= ALUOutM ;
            WriteRegW  <= WriteRegM ; 
        
            instrW <= instrM;
            PcPlus4W  <= PcPlus4M;
            JalW <= JalM;
        end
    end
endmodule