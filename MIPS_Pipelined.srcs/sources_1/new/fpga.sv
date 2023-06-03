`timescale 1ns / 1ps

module display_controller(
    input logic clk,
    input logic [3:0] in3, in2, in1, in0,
    output logic [6:0]seg, output logic dp,
    output logic [3:0] an
);

localparam N = 18;

localparam ZERO = 7'b100_0000; // 0
localparam ONE = 7'b111_1001; // 1
localparam TWO = 7'b010_0100; // 2
localparam THREE = 7'b011_0000; // 3
localparam FOUR = 7'b001_1001; //4
localparam FIVE = 7'b001_0010; // 5
localparam SIX = 7'b000_0010; // 6
localparam SEVEN = 7'b111_1000; // 7
localparam EIGHT = 7'b000_0000; // 8
localparam NINE = 7'b001_0000; // 9
localparam TEN = 7'b000_1000;// A
localparam ELEVEN = 7'b000_0011; // B -> represented as small b
localparam TWELVE = 7'b100_0110 ; // C
localparam THIRTEEN = 7'b010_0001 ; // D -> represented as small d
localparam FOURTEEN = 7'b000_0110 ; // E
localparam FIFTEEN = 7'b000_1110 ; // F 

logic [N-1:0] count = {N{1'b0}};
always@ (posedge clk)
count <= count + 1;

logic [4:0]digit_val;

logic [3:0]digit_en;
always@ (*)

begin
digit_en = 4'b1111;
digit_val = in0;

case(count[N-1:N-2])

2'b00 :	//select first 7Seg.

begin
digit_val = {1'b0, in0};
digit_en = 4'b1110;
end

2'b01:	//select second 7Seg.

begin
digit_val = {1'b0, in1};
digit_en = 4'b1101;
end

2'b10:	//select third 7Seg.

begin
digit_val = {1'b0, in2};
digit_en = 4'b1011;
end

2'b11:	//select forth 7Seg.

begin
digit_val = {1'b0, in3};
digit_en = 4'b0111;
end
endcase
end

//Convert digit number to LED vector. LEDs are active low.

logic [6:0] sseg_LEDs;
always @(*)
begin
sseg_LEDs = 7'b1111111; //default
case( digit_val)
5'd0 : sseg_LEDs = ZERO; //to display 0
5'd1 : sseg_LEDs = ONE; //to display 1
5'd2 : sseg_LEDs = TWO; //to display 2
5'd3 : sseg_LEDs = THREE; //to display 3
5'd4 : sseg_LEDs = FOUR; //to display 4
5'd5 : sseg_LEDs = FIVE; //to display 5
5'd6 : sseg_LEDs = SIX ; //to display 6
5'd7 : sseg_LEDs = SEVEN  ; //to display 7
5'd8 : sseg_LEDs = EIGHT; //to display 8
5'd9 : sseg_LEDs = NINE; //to display 9
5'd10: sseg_LEDs = TEN; //to display a
5'd11: sseg_LEDs = ELEVEN; //to display b
5'd12: sseg_LEDs = TWELVE; //to display c
5'd13: sseg_LEDs = THIRTEEN; //to display d
5'd14: sseg_LEDs = FOURTEEN; //to display e
5'd15: sseg_LEDs =FIFTEEN ; //to display f
5'd16: sseg_LEDs = 7'b0110111; //to display "="
default : sseg_LEDs = 7'b0111111; //dash 
endcase
end

assign an = digit_en;

assign seg = sseg_LEDs;
assign dp = 1'b1; //turn dp off

endmodule

//module pulse_controller(
//	input CLK, sw_input, clear,
//	output reg clk_pulse );

//	 reg [2:0] state, nextstate;
//	 reg [27:0] CNT; 
//	 wire cnt_zero; 

//	always @ (posedge CLK, posedge clear)
//	   if(clear)
//	    	state <=3'b000;
//	   else
//	    	state <= nextstate;

//	always @ (sw_input, state, cnt_zero)
//          case (state)
//             3'b000: begin if (sw_input) nextstate = 3'b001; 
//                           else nextstate = 3'b000; clk_pulse = 0; end	     
//             3'b001: begin nextstate = 3'b010; clk_pulse = 1; end
//             3'b010: begin if (cnt_zero) nextstate = 3'b011; 
//                           else nextstate = 3'b010; clk_pulse = 1; end
//             3'b011: begin if (sw_input) nextstate = 3'b011; 
//                           else nextstate = 3'b100; clk_pulse = 0; end
//             3'b100: begin if (cnt_zero) nextstate = 3'b000; 
//                           else nextstate = 3'b100; clk_pulse = 0; end
//            default: begin nextstate = 3'b000; clk_pulse = 0; end
//          endcase

//	always @(posedge CLK)
//	   case(state)
//		3'b001: CNT <= 100000000;
//		3'b010: CNT <= CNT-1;
//		3'b011: CNT <= 100000000;
//		3'b100: CNT <= CNT-1;
//	   endcase

////  reduction operator |CNT gives the OR of all bits in the CNT register	
//	assign cnt_zero = ~|CNT;

//endmodule

module debouncer(
    input logic CLK,
    input logic in,
    output logic debounced,
    input logic reset
    );
    
    typedef enum logic[2:0] {S0, S1, S2} State;
    State currentState, nextState;
    
    always_ff @(posedge CLK)
        if(reset) currentState <= S0;
        else currentState <= nextState;
    
    always_comb
        case(currentState)
        S0: if(in) nextState <= S1;
            else nextState <= currentState;
        S1: if(in) nextState <= S2;
            else nextState <= S0;
        S2: if(in) nextState <= currentState;
            else nextState <= S0;
        default nextState <= S0;       
        endcase
    
    assign debounced = currentState == S1? 1 : 0;
      
endmodule


module fpga(
    input logic CLK100MHZ,
    input logic resetBtn, nextBtn,
    output logic MemWriteD, RegWriteD,
    output logic [6:0] seg, output logic dp,
    output logic [3:0] an
);


    logic debouncedreset, debouncedstep;
//    pulse_controller  resetDebounce(CLK100MHZ, resetBtn, 0, debouncedreset);
//    pulse_controller  stepDebounce(CLK100MHZ, nextBtn, debouncedreset, debouncedstep);
    debouncer resetDebounce(CLK100MHZ, resetBtn, debouncedreset, 0);
    debouncer stepDebounce(CLK100MHZ, nextBtn, debouncedstep, debouncedreset);
    

    logic [31:0] instrF, PC, PCF;
    logic PCSrcD;
    logic MemToRegD, ALUSrcD, BranchD, RegDstD, JalD;
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
    logic [3:0] in3, in2, in1, in0;
////    module top_mips (input  logic        clk, reset,
////             output  logic[31:0]  instrF,
////             output logic[31:0] PC, PCF,
////             output logic PcSrcD,
////             output logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
////             output logic [2:0]  alucontrol,
////             output logic [31:0] instrD, 
////             output logic [31:0] ALUOutE, WriteDataE,
////             output logic [1:0] ForwardAE, ForwardBE,
////                 output logic ForwardAD, ForwardBD);

    Processor uut(CLK100MHZ, debouncedreset, instrF, PC, PCF, PCSrcD , MemWriteD , MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
        JalD, alucontrol, instrD, ALUOutE, WriteDataE, ForwardAE, ForwardBE, ForwardAD, ForwardBD,
        instrE, instrM, instrW,
        SrcAE, SrcBE, SrcBEforwarded, ALUControlE,
        RegWriteW, MemToRegW, ResultW, WriteRegW, rf, debouncedstep);

    assign in3 = PC[7:4];
    assign in2 = PC[3:0];
    assign in1 = ResultW[7:4];
    assign in0 = ResultW[3:0];
    display_controller  display(CLK100MHZ, in3, in2, in1, in0, seg, dp, an);


endmodule

