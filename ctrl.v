// ECE:3350 SISC computer project
// finite state machine

`timescale 1ns/100ps

// module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel);	// PART #1 
module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, 
							br_sel, pc_rst, pc_write, pc_sel, rb_sel, ir_load);	// PART #2 additions

  /* Declare the ports listed above as inputs or outputs.  Note that
     you will add signals for parts 2, 3, and 4. */
  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel;
  output reg [1:0] alu_op;

	/* PART #2 outputs */
	output reg br_sel;   // br_sel
	output reg pc_rst;	 // pc_rst
	output reg pc_write; // pc_write
	output reg pc_sel;	 // pc_sel
	output reg rb_sel;	 // rb_sel
	output reg ir_load;	 // ir_load
  
  // state parameter declarations
  
  parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
   
  // opcode paramenter declarations
  
  parameter NOOP = 0, LOD = 1, STR = 2, SWP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7, ALU_OP = 8, HLT=15;

  // addressing modes
  
  parameter AM_IMM = 8;

  // state register and next state value
  
  reg [2:0]  present_state, next_state;

  // Initialize present state to 'start0'.
  
  initial
    present_state = start0;

  /* Clock procedure that progresses the fsm to the next state on the positive 
     edge of the clock, OR resets the state to 'start1' on the negative edge
     of rst_f. Notice that the computer is reset when rst_f is low, not high. */

  always @(posedge clk, negedge rst_f)
  begin
    if (rst_f == 1'b0)
      present_state <= start1;
    else
      present_state <= next_state;
  end
  
  /* Combinational procedure that determines the next state of the fsm. */

  always @(present_state, rst_f)
  begin
    case(present_state)
      start0:
        next_state = start1;
      start1:
	if (rst_f == 1'b0) 
          next_state = start1;
	else
          next_state = fetch;
      fetch:
        next_state = decode;
      decode:
        next_state = execute;
      execute:
        next_state = mem;
      mem:
        next_state = writeback;
      writeback:
        next_state = fetch;
      default:
        next_state = start1;
    endcase
  end
  
  /* TODO: Generate the rf_we, alu_op, wb_sel outputs based on the FSM states 
     and inputs. For Parts 2, 3 and 4 you will add the new control signals here. */
	
	/* [START] MY CODE (3/1/2020)
		(1) [WB_SEL] (1 Bit): 
					Selects which input propagates to output.
		(2) [ALU_OP] (2 bits): 
 					 This control line allows the control unit to override the
           usual function of the ALU to perform specific operations. When bit 1 is set
           to 1, the control unit is telling the ALU that the instruction being
           executed is not an arithmetic operation, and thus, the status code should
           not be saved to the status register. For loads and stores, though, the ALU
           may still be needed. When bit 0 is set to 1, the immediate value is used
           as the second operand to the adder, rather than RB.
		(3) [RF_WE] (1 bit): 
					 Write enable. When this is set to 1, the data on write_data
           is copied into register write_reg.
	*/
	
		// [START] MY NEW CODE (3/1/2020)
	always @(present_state) begin
		case (present_state)
	
			// RESET
			start1: begin
				wb_sel <= 0;
				rf_we <= 0;
        alu_op <= 2'b00;
			end

			// FETCH (retrieve instruction from memory)
			fetch: begin
				$display("In FETCH case");
				rf_we <= 0;
				wb_sel <= 0;
        alu_op <= 2'b00;
			end

			// DECODE (Interpret instruction)
			decode: begin
				$display("in DECODE case");
				if(opcode == ALU_OP) begin
					if(mm == 4'b1000) 
						alu_op <= 2'b01;
					else
						alu_op <= 2'b00;
				end
  	    rf_we <= 0;
			end

			// EXECUTE
			execute: begin
				$display("in EXECUTE case");
        if(opcode == ALU_OP) begin
					if(mm == 4'b1000) 
						alu_op <= 2'b01;
					else
						alu_op <= 2'b00;
        end
			end

			// MEMORY
			mem: begin
				$display("in MEM case");
				if(opcode == ALU_OP) begin
					rf_we <= 1;
				end
				if(opcode == LOD) begin
						wb_sel <= 1;
					end
			end

			// WRITEBACK
			writeback: begin
				$display("in WRITEBACK case");
				if(opcode == LOD) begin
						rf_we <= 1;
				end
			end

			// DEFAULT
			default: begin 
				$display("in DEFAULT case");
			end

		endcase
	end

  /* TODO: Generate the rf_we, alu_op, wb_sel outputs based on the FSM states 
   //  and inputs. For Parts 2, 3 and 4 you will add the new control signals here. 
always @(posedge clk)
  begin
    if (opcode == NOOP)
	  	begin
	    	rf_we <= 1'b0;
        alu_op <= 2'b00;
        wb_sel <= 1'b0;
      end
  // fetch
  	if(present_state == fetch)
  		begin
  			$display("in FETCH case");
	    	if(opcode == ALU_OP)
	      	begin
	        	rf_we <= 0;
            wb_sel <= 0;
	        	alu_op <= 0;
	    	if(mm == 4'b1000)
	      	begin
		    		// DO SOMETHING
         		alu_op <= 2'b01;
          end
	    	else 
	      	begin
		    		// DO SOMETHING
	    		end
	  		end
    	end
    
  // decode
    else if(present_state == decode)
    	begin
    		$display("in DECODE case");
  	    if(opcode == ALU_OP)
  	    	begin
  	    		rf_we <= 0;
      		end
      end

  // execute
    else if(present_state == execute)
    	begin
    		$display("in EXECUTE case");
    		if(opcode == ALU_OP)
    			begin
    				if(mm == 4'b1000)
    					begin
    						alu_op <= 2'b01;
    					end
    				else
    					begin
    						alu_op <= 2'b00;
    					end
    			end
    	end	
  // mem
    else if(present_state == mem)
    	begin
    		$display("in MEM case");
    		if(opcode == ALU_OP)
    			begin
    				rf_we <= 1;
    			end
      end
  // write back
    else if(present_state == writeback)
    	begin
    		$display("in WRITEBACK case");
      end
  end
*/


	// [END] MY CODE (3/1/2020)
	

// Halt on HLT instruction
  always @(opcode)
  begin
    if (opcode == HLT)
    begin 
      #5 $display ("Halt."); //Delay 5 ns so $monitor will print the halt instruction
      $stop;
    end
  end
    
  
endmodule
