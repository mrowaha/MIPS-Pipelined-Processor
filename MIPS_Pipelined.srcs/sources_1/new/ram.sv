`timescale 1ns / 1ps

module dmem (input  logic        clk, we,
             input  logic[31:0]  a, wd,
             output logic[31:0]  rd);

   logic  [31:0] RAM[63:0];
  
    initial begin
        for (int i=0; i<64; i++) RAM[i] = {32{1'b0}};
    end
  
   assign rd = RAM[a[31:2]];    // word-aligned  read (for lw)

   always_ff @(posedge clk)
     if (we)
       RAM[a[31:2]] <= wd;      // word-aligned write (for sw)

endmodule

module imem ( input logic [5:0] addr, output logic [31:0] instr);

// imem is modeled as a lookup table, a stored-program byte-addressable ROM
	always_comb
	   case ({addr,2'b00})		   	// word-aligned fetch

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
// ---------Sample Program with No Hazard-------        
//        8'h00: instr = 32'h20080005;    // addi $t0, $zero, 5                 
//        8'h04: instr = 32'h2009000c;    // addi $t1, $zero, 12
//        8'h08: instr = 32'h200a0006;    // addi $t2, $zero, 6
//        8'h0c: instr = 32'h210bfff7;    // addi $t3, $t0, -9    
//        8'h10: instr = 32'h01288025;    // or $s0, $t1, $t0
//        8'h14: instr = 32'h012a8824;    // and $s1, $t1, $t2
//        8'h18: instr = 32'h010b9020;    // add $s2, $t0, $t3
//        8'h1c: instr = 32'h010a202a;    // slt $a0, $t0, $t2
//        8'h20: instr = 32'h02112820;    // add $a1, $s0, $s1
//        8'h24: instr = 32'h02493022;    // sub $a2, $s2, $t1
//        8'h28: instr = 32'had320074;    // sw $s2, 0x74($t1)
//        8'h2c: instr = 32'h8c020080;    // lw $v0, 0x80($zero)
//*******************************************
//------Sample Program with Compute-Use Hazard-----
//        8'h00: instr = 32'h20080005; // addi $t0, $0, 5
//        8'h04: instr = 32'h21090007; // addi $t1, $t0, 7
//        8'h08: instr = 32'h210a0002; // addi $t2, $t0, 2
//        8'h0c: instr = 32'h012a5025; // or $t2, $t1, $t2
//        8'h10: instr = 32'h01498024; // and $s0, $t2, $t1
//        8'h14: instr = 32'h01108820; // add $s2, $t0, $s0
//        8'h18: instr = 32'h0151902a; // slt $s2, $t2, $s1
//        8'h1c: instr = 32'h02318820; // add $s1, $s1, $s1
//        8'h20: instr = 32'h02329822; // sub $s3, $s1, $s2
//        8'h24: instr = 32'had330074; // sw $s3, 0x74($t1)
//        8'h28: instr = 32'h8c020080; // lw $v0, 0x80($0) 
//*******************************************
//------Sample Program with Load-use Hazard------
//*******************************************
//        8'h00: instr = 32'h20080005; // addi $t0, $0, 5
//        8'h04: instr = 32'hac080060; // sw $t0, 0x60($0)
//        8'h08: instr = 32'h8c090060; // lw $t1, 0x60($0)
//        8'h0c: instr = 32'h212a0004; // addi $t2, $t1, 4
//        8'h10: instr = 32'h212b0003;// addi $t3, $t1, 3
//        8'h14: instr = 32'h8d6b0058; // lw $t3, 0x58($t3)
//        8'h18: instr = 32'h014b5022; // sub $t2, $t2, $t3
//        8'h1c: instr = 32'hac0a0070; // sw $t2, 0x70($0)
//        8'h20: instr = 32'h8c080070; // lw $t0, 0x70($0)
//        8'h24: instr = 32'h8d09006c; // lw $t1, 0x6c($t0)
//        8'h28: instr = 32'h01094820; // add $t1, $t0, $t1
//*******************************************
//-----Sample Program with Branch Hazard-------
//*******************************************
//        8'h00: instr = 32'h20080005; // addi $t0, $0, 5 
//        8'h04: instr = 32'h20090003; // addi $t1, $0, 3
//        8'h08: instr = 32'h11090002; // beq $t0, $t1, 2
//        8'h0c: instr = 32'h01285020; // add $t2, $t1, $t0
//        8'h10: instr = 32'h01094022; // sub $t0, $t0, $t1
//        8'h14: instr = 32'h2129ffff; // addi $t1, $t1, -1
//        8'h18: instr = 32'h11280002;  // beq $t1, $t0, 2
//        8'h1c: instr = 32'hac0a0050; // sw $t2, 0x50($0)
//        8'h20: instr = 32'h01284025; // or $t0, $t1, $t0
//        8'h24: instr = 32'h0128482a; // slt $t1, $t1, $t0
//        8'h28: instr = 32'h11200002; // beq $t1, $0, 2
//        8'h2c: instr = 32'h8c0b0050; // lw $t3, 0x50($0)
//        8'h30: instr = 32'h01284024; // and $t0, $t1, $t0
//        8'h34: instr = 32'h1108ffff; // beq $t0, $t0, -1       
        
//------Sample JAL Program---------
        	8'h00: instr = 32'h2014fff6;  	// disassemble, by hand 
        	8'h04: instr = 32'h20090007;  	// or with a program,
        	8'h08: instr = 32'h22820003;  	// to find out what
        	8'h0c: instr = 32'h01342025;  	// this program does!
        	8'h10: instr = 32'h00822824;
        	8'h14: instr = 32'h00a42820;
        	8'h18: instr = 32'h1045003d;
        	8'h1c: instr = 32'h0054202a;
        	8'h20: instr = 32'h10040001;
        	8'h24: instr = 32'h00002820;
        	8'h28: instr = 32'h0289202a;
        	8'h2c: instr = 32'h00853820;
        	8'h30: instr = 32'h00e23822;
        	8'h34: instr = 32'hac470057;
        	8'h38: instr = 32'h8c020050; // comment in for default lw
        	8'h3c: instr = 32'h2014fff6;
        	8'h40: instr = 32'h20020001;
        	8'h44: instr = 32'h2282005a;
            8'h48: instr = 32'h0c000014; // jal 0x50
            8'h4c: instr = 32'h201f0005; // addi $ra, $zero, 5
            8'h50: instr = 32'h23ff0004; // addi $ra, $ra, 4
            8'h54: instr = 32'h20080005; // addi $t0, $0, 5
            8'h58: instr = 32'h1108ffff; // beq $t0, $t0, -1       

       default:  instr = {32{1'bx}};	// unknown address
	   endcase
endmodule