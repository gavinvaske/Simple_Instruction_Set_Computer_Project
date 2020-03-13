// ECE:3350 SISC processor project
// main SISC module, part 1
// Name: Gavin Vaske

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);
	// Declare module inputs here	
  input clk, rst_f;
  input [31:0] ir;

	// PART #1 internal Wires
	wire wb_sel;
	wire rf_we;
	wire [3:0] stat_in;
	wire [3:0] stat_out;
  wire       stat_en;

  wire [31:0] mux32_in_b;
	wire        mux32_sel;
	wire [31:0] mux32_out;

	wire [3:0] mux4_in_a;
  wire [3:0] mux4_in_b; 
	wire [3:0] mux4_out;

	wire [1:0] alu_op;
  wire [31:0] rsa;
	wire [31:0] rsb;
	wire [31:0] alu_result;

	// PART #2 internal Wires
	wire [15:0] pc_out;
	wire [15:0] pc_inc;
	wire [15:0] branch_address;

	// PART #2 control signals
	wire pc_sel;
	wire pc_write;
	wire pc_rst;
	wire br_sel;
	wire ir_load;
	wire rb_sel;

	/* 
			[START] PART #2 
	*/

	// INSTRUCTION MEMORY
	im my_im(
		.read_addr (pc_out[15:0]), // (16 bits): The address of the instruction to read.
		.read_data (ir[31:0])	 		 // (32 bits): The instruction specified by address read_addr.
	);

	// BRANCH ADDRESS CALCULATOR
	br my_br(
		.pc_inc (pc_inc[15:0]), 				// (16 bits)
		.imm (ir[15:0]), 								// (16 bits)
		.br_sel (br_sel), 							// (1 bit)
		.br_addr (branch_address[15:0]) // (16 bits)
	);

	// INSTRUCTION REGISTER
	ir my_ir(
		.clk (clk), 				    // Internal Clock
		.ir_load (ir_load), 		// (1 bit): if ir_load is = 1, the IR is loaded with read_data
		.read_data (ir[31:0]),  // (32 bits): the 32 bit instruction from instruction memory
		.instr (ir[31:0])				// (32 bits): the 32 bit saved instruction
	);

	// PROGRAM COUNTER
	pc my_pc(
		.clk (clk), 	  								  // Internal Clock
		.br_addr (branch_address[15:0]), 	// (16 bits) br output signal
		.pc_sel (pc_sel), 								// (1 bit) ctrl output signal
		.pc_write (pc_write), 						// (1 bit) ctrl output signal
		.pc_rst (pc_rst), 								// (1 bit) ctrl output signal
		.pc_out (pc_out[15:0])						// (16 bits) pc output signal
	);

	/* 
			[START] PART #1
	*/

	// 4-BIT-MUX
  mux4 my_mux4(
		.in_a (ir[15:12]), 
		.in_b (ir[23:20]), 
		.sel (1'b0), 
		.out (mux4_out[3:0])
		);

	// 32-BIT-MUX
	mux32 my_mux32(
		.in_a (alu_result[31:0]), 
		.in_b (32'h00000000), 
		.sel (wb_sel), 
		.out (mux32_out[31:0])
	);

	// ALU
	alu my_alu (
		.clk (clk), 
		.rsa (rsa[31:0]), 
		.rsb (rsb[31:0]), 
		.imm (ir[15:0]), 
		.alu_op (alu_op[1:0]), 
		.alu_result (alu_result[31:0]), 
		.stat (stat_in[3:0]), 
		.stat_en (stat_en)
	);

	// REGISTER FILE
	rf my_rf (
		.clk (clk), 
		.read_rega (ir[19:16]), 
		.read_regb (mux4_out[3:0]), 
		.write_reg (ir[23:20]), 
		.write_data (mux32_out[31:0]), 
		.rf_we (rf_we), 
		.rsa (rsa[31:0]), 
		.rsb (rsb[31:0])
	);

	// STATUS REGISTER
	statreg my_statreg (
		.clk (clk), 
		.in (stat_in[3:0]), 
		.enable (stat_en), 
		.out (stat_out[3:0])
	);

	// CONTROL
	ctrl my_ctrl (
		.clk (clk), 
		.rst_f (rst_f), 
		.opcode (ir[31:28]), 
		.mm (ir[27:24]), 
		.stat (stat_out[3:0]), 
		.rf_we (rf_we),
		.alu_op (alu_op[1:0]), 
		.wb_sel (wb_sel),
		.br_sel (br_sel),	     // Part #2 control signal 
		.pc_rst (pc_rst),      // Part #2 control signal 
		.pc_write (pc_write),  // Part #2 control signal 
		.pc_sel (pc_sel),      // Part #2 control signal 
		.rb_sel (rb_sel),      // Part #2 control signal 
		.ir_load (ir_load)     // Part #2 control signal 
	);


  initial begin
		// PART #2 MONITOR STATEMENT
		$monitor($time,,,"IR: %h, R0: %h, R1: %h, R2: %h,  R3: %h,  R4: %h,  R5: %h, ALU_OP : %h, PC : %h, br_sel : %h, pc_write : %h, pc_sel : %h",
			ir, 						         // IR
			my_rf.ram_array[0],      // R0
			my_rf.ram_array[1],      // R1
			my_rf.ram_array[2],      // R2
			my_rf.rf.ram_array[3],   // R3
			my_rf.rf.ram_array[4],   // R4
			my_rf.rf.ram_array[5],   // R5
			alu_op,					         // ALU_OP
			pc_out,									 // PC (value of program counter)
			br_sel,									 // BR_SEL
			pc_write,								 // PC_WRITE
			pc_sel									 // PC_SEL
		);

		// PART #1 MONITOR STATEMENT
/*
		$monitor($time,,,"IR: %h, R0: %h, R1: %h, R2: %h,  R3: %h,  R4: %h,  R5: %h, R6: %h, R12 : %h R13 : %h R14 : %h, R15 : %h, ALU_OP : %h, WB_SEL : %h, RF_WE : %h, STAT : %h,  MM : %h, ALU_Result : %h, MUX32_OUTPUT : %h, MUX4_OUTPUT : %h, PC : %h, br_sel : %h, pc_write : %h, pc_sel : %h",
			ir, 						         // IR
			my_rf.ram_array[0],      // R0
			my_rf.ram_array[1],      // R1
			my_rf.ram_array[2],      // R2
			my_rf.rf.ram_array[3],   // R3
			my_rf.rf.ram_array[4],   // R4
			my_rf.rf.ram_array[5],   // R5
			my_rf.rf.ram_array[6],   // R6
			my_rf.rf.ram_array[12],  // R12
			my_rf.rf.ram_array[13],  // R13
			my_rf.rf.ram_array[14],  // R14
			my_rf.rf.ram_array[15],  // R15
			alu_op,					         // ALU_OP
			wb_sel, 	               // WB_SEL
			rf_we,	                 // RF_WE
			stat_in,	               // STAT
			ir[27:24],						   // MM
			alu_result[31:0],				 // ALU Result
      mux32_out[31:0],				 // MUX32 OUTPUT
      mux4_out[3:0],					 // MUX4 OUTPUT
			pc_out,									 // PC (value of program counter)
			br_sel,									 // BR_SEL
			pc_write,								 // PC_WRITE
			pc_sel									 // PC_SEL
		);
*/

	end
endmodule


