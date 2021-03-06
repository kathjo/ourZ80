// EMACS settings: -*-  tab-width: 5; indent-tabs-mode: t -*-
// vim: tabstop=3:shiftwidth=3:noexpandtab
// kate: tab-width 3; replace-tabs off; indent-width 3;
//
// Company           :   tud                      
// Author            :   kajo17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   CPU_Control.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Sat May 20 16:27:50 2017 
// Last Change       :   $Date: 2017-07-24 15:25:14 +0200 (Mon, 24 Jul 2017) $
// by                :   $Author: kajo17 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module CPU_Control (
				mreq,
				rd,
				m1,
				data_in,
				data_out,
				reg_pc,
				current_state,
				address_bus,
				reg_read_1,
				reg_read_2,
				reg_write,
				reg_write_op,
				reg_out_1,
				reg_out_2,
				reg_out_flags,
				reg_in,
				reg_pc_inc,
				reg_flags_write_en,

				alu_opcode,
				alu_res,
				alu_op_a,
				alu_op_b,

				next_cycle,
				clk,
				reset,
				wr,
				iorq
				);

`include "parameter.v"

   //input	[7:0]	current_state;

   input	[7:0]	data_in;

   input [15:0] 	reg_pc;
   input 			clk;
   input 			reset;


   input [7:0] 	reg_out_1;
   input [7:0] 	reg_out_2;
   input [7:0] 	reg_out_flags;

   input [7:0] 	alu_res;

   //output to tb
   output [15:0] 	address_bus;
   output 		mreq;
   output 		rd;
   output 		m1;
   output 		wr;
   output 		iorq;

   output [7:0] 	data_out;

   //output to ALU
   output [7:0] 	alu_opcode;

   output [7:0] 	alu_op_a;
   output [7:0] 	alu_op_b;

   //output to FSM
   //output	[7:0]	next_cycle;


   //output to register
   output [9:0] 	reg_read_1;
   output [9:0] 	reg_read_2;
   output [9:0] 	reg_write;
   output [1:0] 	reg_write_op;
   output 		reg_pc_inc;
   output [7:0] 	reg_flags_write_en;

   output [7:0] 	reg_in;

   //---------------------------------------------------------------------------------------------

   //reg 	[7:0]	next_cycle; //I am not sure about this, maybe put this reg into the FSM?
   reg 			mreq;
   reg 			rd;
   reg 			wr;
   reg 			m1;

   reg [15:0] 		address_bus;

   //register for read/write adress
   reg [15:0] 		data_adr;//this should propably be deprecated, this is bullshit

   //register for preopcode
   reg [2:0] 		pre_op;

   //data target: 00-> instr 01-> temp1 10-> temp2

   //data_target needs temp_2 as target because data aquired via IF timing is writen at risign edge, therefore we need a
   //second register that writes at rising edge apart from the instruction register
   reg [2:0] 		data_target;


   reg [9:0] 		reg_read_1;
   reg [9:0] 		reg_read_2;
   reg [9:0] 		reg_write;
   reg [1:0] 		reg_write_op;
   reg [7:0] 		reg_in;
   reg [1:0] 		data_in_case;
   reg [1:0] 		data_out_case;

   reg [7:0] 		alu_opcode;
   reg [7:0] 		alu_op_a;
   reg [7:0] 		alu_op_b;



   //for negedge ctrl signals
   reg 			mreq_pos;
   reg 			rd_pos;
   reg 			m1_pos;
   reg 			wr_pos;
   reg 			iorq_pos;

   reg 			wr_neg;
   reg 			mreq_neg;
   reg 			rd_neg;
   reg 			m1_neg;
   reg 			iorq_neg;

   reg 			mreq_ff_pos;
   reg 			rd_ff_pos;
   reg 			m1_ff_pos;
   reg 			wr_ff_pos;
   reg 			iorq_ff_pos;

   reg 			wr_ff_neg;
   reg 			mreq_ff_neg;
   reg 			rd_ff_neg;
   reg 			m1_ff_neg;
   reg 			iorq_ff_neg;


   wire 			latch;
   reg 			latch1;
   reg 			latch2;
   reg 			reg_pc_inc_int;



   //regs for data
   reg [7:0] 		instr;
   reg [7:0] 		temp_1;
   reg [7:0] 		temp_2;

   reg 			instr_en;
   reg 			temp_1_en;
   reg 			temp_2_en;
   reg 			data_adr_en;

   //signals for data selection
   reg [2:0] 		reg_in_sel;
   reg [2:0] 		alu_op_a_sel;
   reg [2:0] 		alu_op_b_sel;
   reg [2:0] 		data_out_sel;
   reg [2:0] 		address_bus_sel;
   reg [3:0] 		t_state;


   //reg to catch unwanted defaults
   reg [8:0] 		catch_default;
   reg 			catch_up;
   always @ * begin
	 if(reset == 1) begin
	    catch_default = 8'h00;
	 end
	 else if(catch_up == 1) begin
	    catch_default = catch_default + 1;
	 end
   end


   //select muxes for output
   always @ * begin
	 case(reg_in_sel) 
	   
	   0: reg_in = alu_res;

	   1: reg_in = reg_out_1;

	   2: reg_in = reg_out_2;

	   3: reg_in = temp_1;
	   
	   4: reg_in = temp_2;

	 endcase
   end

   //select muxes for output
   always @ * begin
	 case(alu_op_a_sel) 
	   
	   0:  alu_op_a = alu_res; 

	   1:  alu_op_a = reg_out_1;

	   2:  alu_op_a = reg_out_2;

	   3:  alu_op_a = temp_1;
	   
	   4:  alu_op_a = temp_2;

	 endcase
   end

   //select muxes for output
   always @ * begin
	 case(alu_op_b_sel) 
	   
	   0: alu_op_b = alu_res;

	   1: alu_op_b = reg_out_1;

	   2: alu_op_b = reg_out_2;

	   3: alu_op_b = temp_1;
	   
	   4: alu_op_b = temp_2;

	 endcase
   end

   always @ * begin
	 case(address_bus_sel) 
	   
	   0: address_bus = reg_pc;
	   
	   1: address_bus = {reg_out_2, reg_out_1};
	   
	   2: address_bus = data_adr;
	   
	 endcase
   end
   

   //select muxes for output
   always @ * begin
	 case(data_out_sel) 
	   
	   0: data_out = alu_res;

	   1: data_out = reg_out_1;

	   2: data_out = reg_out_2;

	   3: data_out = temp_1;
	   
	   4: data_out = temp_2;

	 endcase
   end



   always @ (posedge clk) begin
	 if (instr_en) begin
	    instr <= data_in;
	 end
   end

   always @ (negedge clk) begin
	 if (temp_1_en) begin
	    temp_1 <= data_in;
	 end
   end

   always @ (posedge clk) begin
	 if (temp_2_en) begin
	    temp_2 <= data_in;
	 end
   end
   



   always @ (posedge clk) begin
	 mreq_ff_pos 	<= mreq_pos;
	 rd_ff_pos 	<= rd_pos;
	 m1_ff_pos 	<= m1_pos;
	 wr_ff_pos	<= wr_pos;
	 iorq_ff_pos	<= iorq_pos;
	 
	 latch1		<= !latch1;
   end

   always @ (negedge clk) begin
	 mreq_ff_neg 	<= mreq_neg;
	 rd_ff_neg 	<= rd_neg;
	 m1_ff_neg 	<= m1_neg;
	 wr_ff_neg	<= wr_neg;
	 iorq_ff_neg	<= iorq_ff_neg;
	 
	 latch2		<= !latch2;
   end


   always @ (negedge reset) begin
	 latch1 <= 1'b0;
	 latch2 <= 1'b0;
	 
	 mreq_pos = 1'b0;
	 rd_pos = 1'b0;
	 m1_pos = 1'b0;
	 wr_pos = 1'b0;
	 iorq_pos = 1'b0;

	 wr_neg = 1'b0;
	 mreq_neg = 1'b0;
	 rd_neg = 1'b0;
	 m1_neg = 1'b0;
	 iorq_neg = 1'b0;
   end

   assign latch = !(latch1 ^ latch2);

   always @ *
	begin
	   if(latch == 1'b1)
		begin
		   mreq	= mreq_pos;
		   rd	= rd_ff_pos ;
		   m1	= m1_ff_pos ;
		   wr	= wr_ff_pos;
		   iorq	= iorq_ff_pos;
		end
	   else 
		begin
		   mreq	= mreq_neg;
		   rd	= rd_ff_neg ;
		   m1	= m1_ff_neg ;
		   wr	= wr_ff_neg;
		   iorq	= iorq_ff_neg;
		end
	end	




   always @ (posedge clk) begin

      instr_en 	<= 1'b0;
      temp1_en 	<= 1'b0;
      data_target <= 2'b00;


      //to detect unwanted case defaults
      catch_up <= 0;
      
      case(instr[7:0])// start decode case 
	   
	   CB:	begin
		 case(t_state) 
		   t1: IF1;
		   t2: begin
			 IF2;
			 case(pre_op) 
			   DD: pre_op <= DDCB;
			   FD: pre_op <= FDCB;
			   default: pre_op <= CB;
			 endcase
		   end
		 endcase
		 
	   end
	   
	   DD:	begin
		 
		 case(t_state)
		   
		   t1: IF1;
		   t2: begin
			 IF2;
			 pre_op <= DD;
		   end
		 endcase
		 
	   end
	   
	   ED:	begin
		 
		 case(t_state) 
		   
		   t1: IF1;
		   t2: begin
			 IF2;
			 pre_op <= ED;
		   end
		 endcase
		 
	   end
	   
	   FD:	begin
		 
		 case(t_state) 
		   
		   t1: IF1;
		   t2: begin
			 IF2;
			 pre_op <= FD;
		   end
		 endcase
		 
	   end	
	   
	   default: begin
		 case(pre_op) 
		   
		   NO:	begin
			 case(`X_DECODE) 
			   
			   0:	begin 
				 case(`Z_DECODE) 
				   
				   0:	begin 
					 case(`Y_DECODE) 
					   
					   0:	begin//NOP
						 case(t_state) 
						   t1: IF1;
						   t2: IF2;	
						 endcase
					   end
					   
					   1:	begin//EX AF,AF'
						 case(t_state) 
						   t1: ;
						   t2: ;
						   default: catch_up <= 1;
						 endcase
					   end	//also offensichtlich kriegt man eine simplen exchange auch in 2 takten hin ohne eine besondere funtktion im Registerblock bereitzustellen
					   //aber wegen dem EXX befehl ist es wohl trotzdem ntig
					   
					   //das hier ist alt und falsch
					   
					   2:	;//DJNZ e
					   
					   3:	begin//JR e
						 case(t_state) 
						   
						   t1: begin
							 IF1;//get discplacement
						   end
						   
						   t2: begin
							 IF2_immediate;//get discplacement
							 
						   end
						   
						   t3: begin
							 reg_read_1 <= PCL;
							 
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 3;
							 alu_opcode <= ADD;
							 
							 reg_flags_en <= 8'b1000_0000;
							 
							 reg_write <= PCL;
							 reg_write_op <= 1;
							 reg_in_sel <= 0;
							 
						   end
						   
						   t4: begin
							 
							 reg_read_1 <= PCH;
							 reg_read_2 <= NULL;
							 
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 2;
							 alu_opcode <= ADD_ci;
							 
							 reg_write <= PCH;
							 reg_write_op <= 1;
							 reg_in_sel <= 0;
						   end
						   
						   t5: begin
							 IF1;
							 
						   end
						   
						   t6: begin
							 IF2;
							 
						   end
						   default:catch_up <= 1;
						 endcase
					   end
					   //Y
					   default:;//JR cc[y-4], d
					 endcase
				   end
				   //Z
				   1: begin	
					 case(`Q_DECODE) 
					   0: begin	//LD dd, nn
						 case(t_state) 
						   t1: begin
							 IF1;
						   end
						   t2: begin
							 IF2_immediate;
						   end
						   t3: begin
							 IF1;
							 //write first 8bits
							 case(`Q_DECODE) 
							   0: reg_write <= C;
							   1: reg_write <= E;
							   2: reg_write <= L;
							   3: reg_write <= P;
							 endcase
							 reg_in_sel <= 4;
						   end
						   t4: begin
							 IF2_immediate;
							 
						   end
						   t5: begin
							 //write second 8bits
							 case(`Q_DECODE) 
							   0: reg_write <= B;
							   1: reg_write <= D;
							   2: reg_write <= H;
							   3: reg_write <= S;
							 endcase
							 reg_in_sel <= 4;
							 FINISH;
						   end
						   default:catch_up <= 1;
						 endcase
					   end
					   
					   1:	;//ADD HL, rp[p]
					   //Q	
					 endcase
				   end
				   //Z
				   2:	begin
					 case(`Q_DECODE) 	//LD...
					   
					   0:	begin
						 case(`P_DECODE)
						   
						   0: begin					// LD (BC), A
							 case(t_state)
							   t1: begin
								 reg_read_1 <= B;
								 reg_read_2 <= C;
								 reg_out_1 <= A;
							   end
							   t2: begin
								 MW1;
								 address_bus_sel <= 1;
								 data_out_sel <= 1;
							   end
							   t3: MW2;
							   t4: MW3;
							   t5: IF1;
							   t6: begin
								 IF2;
								 FINISH;
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   
						   1: begin
							 case(t_state) 
							   t1: begin				// LD (DE), A
								 reg_read_1 <= D;
								 reg_read_2 <= E;
								 reg_out_1 <= A;
							   end
							   t2: begin
								 MW1;
								 address_bus_sel <= 1;
								 data_out_sel <= 1;
							   end
							   t3: MW2;
							   t4: MW3;
							   t5: IF1;
							   t6: begin
								 IF2;
								 FINISH;
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   
						   2: begin
							 case(t_state) 
							   t1: begin
								 
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   
						   3: begin
							 case(t_state) 
							   t1: begin
								 
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   
						   //P					
						 endcase
					   end
					   
					   //Q
					   1:	begin 
						 case(`P_DECODE) 
						   
						   0: begin				//LD A, (BC)
							 case(t_state) 
							   t1: begin
								 reg_read_1 <= B;
								 reg_read_2 <= C;
							   end
							   t2: begin
								 MR1;
								 address_bus_sel <= 1;
							   end
							   t3: begin
								 MR2;
							   end
							   t4: begin
								 MR3;
								 reg_write <= A;
								 reg_in_sel <= 3;
							   end
							   t5: begin
								 IF1;
							   end
							   
							   t6: begin
								 IF2;
								 FINISH;
							   end
							   default:catch_up <= 1;
							 endcase
						   end			
						   1: begin				//LD A, (DE)
							 case(t_state) 
							   t1: begin
								 reg_read_1 <= D;
								 reg_read_2 <= E;
							   end
							   t2: begin
								 MR1;
								 address_bus_sel <= 1;
							   end
							   t3: begin
								 MR2;
							   end
							   t4: begin
								 MR3;
								 reg_write <= A;
								 reg_in_sel <= 3;
							   end
							   t5: begin
								 IF1;
							   end
							   
							   t6: begin
								 IF2;
								 FINISH;
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   2: begin				//LD HL, (nn)
							 case(t_state) 
							   t1: begin
								 IF1;
							   end
							   t2: begin
								 IF2_immediate;
							   end
							   t3: begin
								 IF1;
							   end
							   t4: begin
								 IF2_immediate;
								 data_adr[7:0] <= temp_2;
							   end
							   t5: begin
								 
							   end
							   t7: begin
								 MR1;
								 data_adr[15:8] <= temp_2;
								 address_bus_sel <= 2;
							   end
							   t8: begin
								 MR2;
							   end
							   t9: begin
								 MR3;
								 reg_write <= L;		//Speicherinhalt von Adresse (nn) in L
								 reg_in_sel <= 4;		//Speicherinhalt von Adresse (nn+1) in H, fehlt noch
							   end
							   t5: begin
								 IF1;
								 
							   end
							   
							   t6: begin
								 IF2;
								 
							   end
							   default:catch_up <= 1;
							 endcase
						   end			
						   3: begin				// LD A, (nn)
							 case(t_state) 
							   t1: begin
								 IF1;
							   end
							   t2: begin
								 IF2_immediate;
							   end
							   t3: begin
								 IF1;
							   end
							   t4: begin
								 IF2_immediate;
								 data_adr[7:0] <= temp_2;
							   end
							   t5: begin
								 
							   end
							   t7: begin
								 MR1;
								 data_adr[15:8] <= temp_2;
								 address_bus_sel <= 2;
							   end
							   t8: begin
								 MR2;
							   end
							   t9: begin
								 MR3;
								 reg_write <= A;
								 reg_in_sel <= 4;
							   end
							   t5: begin
								 IF1;
							   end
							   
							   t6: begin
								 IF2;
								 FINISH;
							   end
							   default:catch_up <= 1;
							 endcase
						   end
						   //P
						 endcase
					   end 
					   
					   //Q	
					 endcase
				   end
				   //Z
				   3:	begin
					 case(`Q_DECODE) 
					   //INC rp[p]
					   0:begin	
						 case(t_states)
						   t1: begin
							 IF1;
							 
							 case(`P_DECODE) 
							   0:reg_read_1 <= C;
							   1:reg_read_1 <= E;
							   2:reg_read_1 <= L;
							   3:reg_read_1 <= P;
							 endcase 
							 
							 reg_read_2 <= ONE;
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 2;
							 alu_opcode <= ADD;
							 
							 reg_flags_en <= 8'b0000_0001;
							 
							 case(`P_DECODE) 
							   0:reg_write <= C;
							   1:reg_write <= E;
							   2:reg_write <= L;
							   3:reg_write <= P;
							 endcase
							 reg_in_sel <= 0;
							 reg_write_op <= 1;
						   end
						   
						   t2: begin
							 IF2;
							 
							 case(`P_DECODE) 
							   0:reg_read_1 <= B;
							   1:reg_read_1 <= D;
							   2:reg_read_1 <= H;
							   3:reg_read_1 <= S;
							 endcase
							 reg_read_2 <= NULL;
							 
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 2;
							 alu_opcode <= ADD_ci;
							 reg_flags_en <= 8'b0000_0000;
							 case(`P_DECODE) 
							   0:reg_write <= B;
							   1:reg_write <= D;
							   2:reg_write <= H;
							   3:reg_write <= S;
							 endcase
							 reg_in_sel <= 0;
							 reg_write_op <= 1;
							 FINISH;
						   end
						   default:catch_up <= 1;
						 endcase
					   end // case: 0
					   
					   //DEC rp[p]
					   1:begin
						 case(t_state) 
						   t1: begin
							 IF1;
							 
							 case(`P_DECODE) 
							   0:reg_read_1 <= C;
							   1:reg_read_1 <= E;
							   2:reg_read_1 <= L;
							   3:reg_read_1 <= P;
							 endcase
							 reg_read_2 <= ONE;
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 2;
							 alu_opcode <= SUB;
							 
							 reg_flags_en <= 8'b0000_0001;
							 
							 case(`P_DECODE) 
							   0:reg_write <= C;
							   1:reg_write <= E;
							   2:reg_write <= L;
							   3:reg_write <= P;
							 endcase
							 reg_in_sel <= 0;
							 reg_write_op <= 1;
						   end
						   
						   t2: begin
							 IF2;
							 
							 case(`P_DECODE) 
							   0:reg_read_1 <= B;
							   1:reg_read_1 <= D;
							   2:reg_read_1 <= H;
							   3:reg_read_1 <= S;
							 endcase
							 reg_read_2 <= NULL;
							 
							 alu_op_a_sel <= 1;
							 alu_op_b_sel <= 2;
							 alu_opcode <= SUB_16;
							 reg_flags_en <= 8'b0000_0000;
							 case(`P_DECODE) 
							   0:reg_write <= B;
							   1:reg_write <= D;
							   2:reg_write <= H;
							   3:reg_write <= S;
							 endcase
							 reg_in_sel <= 0;
							 reg_write_op <= 1;
							 FINISH;
						   end
						   default:catch_up <= 1;
						   //Q
						 endcase // case (t_state)
					   end // case: 1
					 endcase // case (`Q_DECODE)
					 
				   end // case: 3
				   
				   //Z
				   4:	begin//INC r[y]
					 case(t_state) 
					   
					   t1:	begin
						 IF1;
						 reg_read_1 <= {5'b00,`Y_DECODE};
						 reg_read_2 <= ONE;
						 
						 alu_op_a_sel <= 1;		//nimm reg_out_1 und reg_out_2 als operanden fr die alu
						 alu_op_b_sel <= 2;
						 
						 alu_opcode <= ADD;
						 
						 reg_flags_en <= 8'b1111_1110;	//alle condition bits werden geschrieben, auer C
						 
						 reg_write <= {5'b00,`Y_DECODE};		//wohin soll geschrieben werden
						 
						 reg_in_sel   <= 0;		//schreib das ergebniss aus der alu
						 reg_write_op <= 1;
						 
					   end
					   
					   t2: begin
						 IF2; 
						 FINISH;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   //Z
				   5:	begin//DEC r[y]
					 case(t_state)
					   t1:	begin
						 IF1;
						 reg_read_1 <= {5'b00,`Y_DECODE};
						 reg_read_2 <= ONE;
						 
						 alu_op_a_sel <= 1;//nimm reg_out_1 und reg_out_2 als operanden fr die alu
						 alu_op_b_sel <= 2;
						 
						 alu_opcode <= SUB;
						 
						 reg_flags_en <= 8'b1111_1110;//alle condition bits werden geschrieben, auer C
						 
						 reg_write <= {5'b00,`Y_DECODE};//wohin soll geschrieben werden
						 
						 reg_in_sel   <= 0;//schreib das ergebniss aus der alu
						 reg_write_op <= 1;
						 
					   end
					   
					   t2: 	begin
						 IF2; 
						 FINISH;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   
				   6:	begin//LD r[y], n		
					 case(t_state) 
					   
					   t1:begin	
						 IF1;
					   end
					   
					   t2:begin	
						 IF2_immediate;
					   end
					   
					   t3:begin	
						 IF1;
						 reg_in_sel <= 4;		//data from temp2 to reg
						 reg_write <= {5'b00,`Y_DECODE};
						 reg_write_op <= 1;
					   end
					   
					   t4: begin	
						 IF2; 
						 FINISH;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   //Z
				   7:	begin
					 case(`Y_DECODE) 
					   
					   0: ;	//RLCA
					   
					   1: ;	//RRCA
					   
					   2: ;	//RLA
					   
					   3: ;	//RRA
					   
					   4: ;	//DAA
					   
					   5: ;	//CPL
					   
					   6: ;	//SCF
					   
					   7: ;	//CCF
					 endcase
				   end	
				 endcase // case (`Z_DECODE)
			   end // case: 0
			   
			   //X
			   1:	begin
				 case(`Z_DECODE) 
				   
				   6:	 ;//HALT
				   
				   default: begin		//LD r,r' 
					 //hier fehlt noch der check fr LD (HL)!
					 case(t_state) 
					   
					   t1: begin
						 IF1;
						 reg_read_1 <= {5'b00,`Z_DECODE};
						 reg_write  <= {5'b00,`Y_DECODE};
						 reg_in_sel <= 1;
						 reg_write_op <= 1;						
						 
					   end
					   
					   t2: begin
						 IF2;						
						 
					   end			
					   default:catch_up <= 1;
					 endcase
				   end
				 endcase // case (`Z_DECODE)
			   end 
			   
			   //X
			   2:	;//alu[y] r[z]

			   //X
			   3: begin
				 case(`Z_DECODE) 
				   
				   0:  begin							//RET cc 
					 ;
				   end
				   //Z
				   1: begin
					 case(`Q_DECODE)
					   0: begin 					// POP qq
						 ;
					   end
					   1: begin
						 case (`P_DECODE)
						   1:  begin			// RET
							 ;
						   end
						   2: begin			// EXX
							 ;
						   end
						   3: begin			// JP HL
							 ;
						   end
						   4: begin			// LD SP, HL
							 ;
						   end
						 endcase
					   end
					 endcase
				   end
				   //Z
				   2: begin							// JP cc, nn
					 ;
				   end
				   //Z
				   3: begin
					 case(`Y_DECODE) 
					   0: begin					// JP nn
						 ;
					   end
					   
					   1: catch_up <= 1;// darf nicht passieren, CB Prefix
					   
					   2: begin					// OUT (n), A
						 ;
					   end
					   
					   3: begin					// IN A, (n)
						 ;
					   end
					   
					   4: begin					// EX (SP),HL
						 ;
					   end
					   
					   5: begin					// EX DE, HL
						 ;
					   end
					   
					   6: begin					// DI
						 ;
					   end
					   
					   7: begin					// EI
						 ;
					   end
					   //Y	
					 endcase
				   end
				   //Z
				   4: begin							// CALL cc, nn
					 ;
				   end
				   
				   //Z
				   5: begin
					 case(`Q_DECODE)  
					   0: begin					// PUSH qq
						 ;
					   end
					   
					   1: begin
						 case(`P_DECODE) 
						   0: begin			// CALL nn
							 ;
						   end
						   //1:darf nicht passieren, DD Prefix
						   //2:darf nicht passieren, ED Prefix
						   //3:darf nicht passieren, FD Prefix
						   default:catch_up <= 1;
						 endcase
					   end
					 endcase
				   end
				   
				   //Z
				   6: begin							// alu[y], n
					 ;
				   end
				   
				   //Z
				   7: begin							// RST      (restart)
					 ;
				   end
				   //Z
				 endcase
				 
			   end // case: 3
			   
			   //X	
			 endcase // case (`X_DECODE)
		   end // case: NO
		   
		   //pre_op	
		   CB: begin
			 case(`X_DECODE) 
			   0: begin							//RLC r
				 ;
			   end
			   
			   1: begin							// BIT b, r
				 ;
			   end
			   
			   2: begin							// RES b, r
				 ;
			   end
			   
			   3: begin							// SET b, r
				 ;
			   end
			   //X
			 endcase
		   end // case: endcase...
		   
		   
		   //pre_op
		   ED: begin
			 case(`X_DECODE) 
			   1: begin
				 case(`Z_DECODE)
				   0: begin
					 case(`Y_DECODE)
					   6: begin 				// IN A, (n)   (4,3,4) 
						 case(t_state) 
						   t1: begin
							 reg_read_1 <= C;
							 reg_read_2 <= B;
						   end
						   t2: begin
							 IN1;
							 address_bus_sel <= 2;		//nur untere 8 bit werden zur Bestimmung des Ports benutzt
						   end
						   
						   t3: begin
							 IN2;
						   end
						   
						   
						   t4: begin
							 IN3;
							 data_target <= temp_1_op;
							 A <= temp_1;
							 FINISH;		//1 Byte vom ausgewhlten Port auf Datenleitung und dann in Accu (Reg A)
						   end
						   default:catch_up <= 1;
						 endcase
					   end
					   default: begin				//IN r (C) (4,4,4) r: A,B,C,D,E,F,H,L
						 case(t_state) 
						   t1: begin
							 reg_read_1 <= C;
							 reg_read_2 <= B;
						   end
						   t2: begin
							 IN1;
							 address_bus_sel <= 2; 	  //nur untere 8 bit werden zur Bestimmung des Ports benutzt
						   end
						   
						   t3: begin
							 IN2;
						   end
						   
						   t4: begin
							 IN3;
							 reg_write <= {2'b00,`Y_DECODE};
							 reg_in_sel <= 3;
							 FINISH;
						   end
						   default:catch_up <= 1;
						 endcase
					   end
					   //Y
					 endcase
				   end
				   //Z
				   1: begin
					 case(`Y_DECODE) 
					   default: begin				//OUT (C),r
						 case(t_state) 
						   t1: begin
							 reg_read_1 <= C;
							 reg_read_2 <= B;
						   end
						   t2: begin
							 OUT1;
							 address_bus_sel <= 2;	      //nur untere 8 bit werden zur Bestimmung des Ports benutzt
						   end
						   
						   t3: begin
							 OUT2;
						   end
						   
						   
						   t4: begin
							 OUT3;
							 reg_write <= {2'b00,`Y_DECODE};
							 data_out <= reg_out_1;
							 FINISH;
						   end
						   default:catch_up <= 1;
						 endcase
						 
					   end
					   
					   6: begin				//OUT (n), A
						 case(t_state) 
						   t1: begin
							 OUT1;
							 address_bus_sel <= 2;		//n soll angelegt werden
						   end
						   
						   t2: begin
							 OUT2;
						   end
						   
						   
						   t3: begin
							 OUT3;
							 reg_write <= address_bus[7:0];
							 data_out <= alu_res;		//nur untere 8 bit werden zur Bestimmung des Ports benutzt
							 FINISH;
						   end
						   default:catch_up <= 1;
						 endcase
					   end
					   //Y
					 endcase
				   end
				   //Z
				   2: begin
					 case(`Q_DECODE) 
					   0: begin				//SBC HL, ss
						 ;
					   end
					   
					   1: begin				//ADC HL, ss
						 ;
					   end
					   //Q
					 endcase
				   end
				   //Z	
				   3: begin
					 case(`Q_DECODE) 
					   0: begin				//LD (nn),dd   dd: (BC,DE,HL,SP)
						 ;
					   end
					   
					   1: begin				//LD dd,(nn)   dd: (BC,DE,HL,SP)
						 ;
					   end
					   //Q
					 endcase
				   end
				   //Z
				   4: begin						//NEG
					 ;
				   end
				   //Z	
				   5: begin
					 case(`Y_DECODE) 
					   1: begin				//RETI
						 
					   end
					   default: begin				//RETN
						 ;
					   end
					   //Y
					 endcase
					 
				   end
				   //Z	
				   6: begin						//IM 0, 1 oder 2   Interrupt Mode
					 ;
				   end
				   //Z
				   7: begin
					 case(`Y_DECODE) 
					   0: begin				//LD I, A
						 ;
					   end
					   
					   1: begin				//LD R, A
						 ;
					   end
					   
					   2: begin				//LD A, I
						 ;
					   end
					   
					   3: begin				//LD A, R
						 ;
					   end
					   
					   4: begin				//RRD
						 ;
					   end
					   
					   5: begin				//RLD
						 ;
					   end
					   
					   6: begin				//NOP
						 ;
					   end
					   
					   7: begin				//NOP
						 ;
					   end
					   //Y
					 endcase
				   end
				   //Z
				 endcase // case (`Z_DECODE)
			   end // case: 1
			   
			   2: begin
				 if(`Z_DECODE <= 3) begin
				    if(`Y_DECODE >= 4) begin
					  ;
				    end
				 end	
			   end 
			   //X
			 endcase // case (`X_DECODE)
		   end // case: ED
		   

		   default: ;//invalid instruction (NONI)
		   //X
		 endcase // case (pre_op)
	   end
	   //pre_op
	   DD:;
	   //pre_op
	   FD:;
	   //pre_op
	   DDCB: begin
		 case(`X_DECODE) 
		   
		   //X
		   0: begin
			 case(`Z_DECODE) 
			   1: begin
				 case(`Y_DECODE)
				   4: begin				//LD IX, nn
					 ;
				   end
				   
				   default:catch_up <= 1;
				   
				 endcase
				 
				 case(`Q_DECODE) 
				   1: begin				//ADD IX,pp
					 ;
				   end
				   
				   default:catch_up <= 1;
				   
				 endcase
			   end
			   //Z
			   2: begin
				 case(`Y_DECODE) 
				   4: begin				//LD (nn),IX
					 ;
				   end
				   
				   5: begin				//LD IX,nn
					 ;
				   end
				   
				   default:catch_up <= 1;
				   
				 endcase
			   end
			   //Z
			   3: begin
				 case(`Y_DECODE) 
				   4: begin				//INC IX
					 ;
				   end
				   
				   5: begin				//DEC IX
					 ;
				   end
				   default:catch_up <= 1;
				 endcase
			   end
			   //Z
			   4: begin
				 case(`Y_DECODE) 
				   6: begin				//INC (IX+d)
					 ;
				   end
				   default:catch_up <= 1;
				 endcase
			   end
			   //Z
			   5: begin
				 case(`Y_DECODE) 	
				   6: begin			// DEC (IX+d)
					 ;
				   end
				   default:catch_up <= 1;	
				 endcase
			   end
			   //Z
			   6: begin
				 case(`Y_DECODE) 
				   6: begin				//LD (LX+d),n
					 ;
				   end
				   default:catch_up <= 1;
				   
				 endcase
			   end
			   //X
			   1: begin
				 case(`Z_DECODE)	
				   6: begin					//LD r, (IX+d)
					 case(t_state) 
					   t1: begin				// d laden
						 IF1;
					   end
					   t2: begin
						 IF2_immediate;
					   end						
					   t3: begin
						 reg_read_1 <= IXL;
						 alu_op_a_sel <= 1;		//IXL
						 alu_op_b_sel <= 4;		//d
						 alu_opcode <= ADD;
						 data_adr [7:0] <= alu_res;
					   end
					   t4: begin
						 reg_read_1 <= IXH;
						 reg_read_2 <= NULL;//nur carry wird aufaddiert
						 alu_op_a_sel <= 1;
						 alu_op_b_sel <= 2;
						 alu_opcode <= ADD_ci;
						 data_adr [15:0] <= alu_res;
					   end
					   t5: begin
						 MR1;
						 address_bus_sel <= 2;				
					   end
					   t6: begin
						 MR2;
					   end
					   
					   t7: begin
						 MR3;
						 reg_write <= {2'b00,`Y_DECODE};
						 reg_in_sel <= 3;
						 FINISH;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1; 
				 endcase
				 case(`Y_DECODE) 
				   6: begin					// LD (IX+d),r
					 case(t_state) 
					   t1: begin				// d laden
						 IF1;
					   end
					   t2: begin
						 IF2_immediate;
					   end						
					   t3: begin
						 reg_read_1 <= IXL;
						 alu_op_a_sel <= 1;		//IXL
						 alu_op_b_sel <= 4;		//d
						 alu_opcode <= ADD;
						 data_adr [7:0] <= alu_res;
					   end
					   t4: begin
						 reg_read_1 <= IXH;
						 reg_read_2 <= NULL;//{7'b0000000,alu_flags[0]}
						 alu_op_a_sel <= 1;
						 alu_op_b_sel <= 2;
						 alu_opcode <= ADD_ci;
						 data_adr [15:0] <= alu_res;
					   end
					   t5: begin
						 MW1;
						 address_bus_sel <= 2;
						 reg_read_1 <= {2'b00,`Z_DECODE};				
					   end
					   t6: begin
						 MW2;
						 data_out_sel <= 1;					
					   end
					   
					   t7: begin
						 MW3;
						 FINISH;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase	
			   end
			   //X
			   2: begin
				 case(`Z_DECODE)	
				   6: begin
					 case(`Y_DECODE) 
					   
					   1: begin			//ADC A, (IX+d) und ADD IX, pp
						 ;
					   end
					   
					   2: begin			//SUB (IX+d)
						 ;
					   end
					   
					   3: begin			//SBC A, (IX+d)
						 ;
					   end
					   
					   4: begin			//AND (IX+d)
						 ;
					   end
					   
					   5: begin			//XOR (IX+d)
						 ;
					   end
					   
					   6: begin			//OR (IX+d)
						 ;
					   end
					   
					   7: begin			//CP (IX+d)
						 ;
					   end
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase
			   end
			   //X
			   3: begin
				 case(`Z_DECODE) 
				   
				   1: begin	
					 case(`Y_DECODE) 
					   
					   4: begin					// POP IX
						 ;
					   end
					   
					   5: begin					// JP (IX)
						 ;
					   end
					   
					   7: begin					// LD SP, IX
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   
				   3: begin
					 case(`Y_DECODE) 
					   
					   1: begin					// RLC, BIT, SET b,(IX+d)
						 ;
					   end
					   
					   4: begin					// EX (SP), IX
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   
				   5: begin
					 case(`Y_DECODE) 
					   4: begin					//PUSH IX
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase // case (`Z_DECODE)
			   end // case: 3
			   
			   default:catch_up <= 1;	
			   
			 endcase // case (`X_DECODE)
			 
		   end // case: DDCB
		   
		   //pre_op
		   FDCB: begin
			 case(`X_DECODE)
			   
			   //X
			   0: begin
				 case(`Z_DECODE)
				   1: begin
					 case(`Y_DECODE) 
					   4: begin				//LD IY, nn
						 ;
					   end
					   
					   //												  pp1: begin				//ADD IY,pp	hier fehlt noch decoder struktur
					   //													  
					   //												  end
					   
					 endcase
				   end
				   2: begin
					 case(`Y_DECODE) 
					   4: begin				//LD (nn),IY
						 ;
					   end
					   
					   5: begin				//LD IY,nn
						 ;
					   end
					   default:catch_up <= 1;
					 endcase // case (`Y_DECODE)
				   end
				   3: begin
					 case(`Y_DECODE) 
					   4: begin				//INC IY
						 ;
					   end
					   
					   5: begin				//DEC IY
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   4: begin
					 case(`Y_DECODE) 
					   6: begin				//INC (IY+d)
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   5: begin
					 case(`Y_DECODE) 	
					   6: begin			// DEC (IY+d)
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   6: begin
					 case(`Y_DECODE) 
					   6: begin				//LD (LY+d),n
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase
			   end
			   //X
			   1: begin
				 case(`Z_DECODE)	
				   6: begin					//LD r, (IY+d)
					 ;
				   end
				   default:catch_up <= 1;
				 endcase
				 case(`Y_DECODE) 
				   6: begin					// LD (IY+d),r
					 ;
				   end
				   default:catch_up <= 1;
				 endcase	
			   end // case: 1
			   //X
			   2: begin
				 case(`Z_DECODE)	
				   6: begin
					 case(`Y_DECODE) 
					   
					   1: begin			//ADC A, (IY+d) und ADD IY, pp
						 ;
					   end
					   
					   2: begin			//SUB (IY+d)
						 ;
					   end
					   
					   3: begin			//SBC A, (IY+d)
						 ;
					   end
					   
					   4: begin			//AND (IY+d)
						 ;
					   end
					   
					   5: begin			//XOR (IY+d)
						 ;
					   end
					   
					   6: begin			//OR (IY+d)
						 ;
					   end
					   
					   7: begin			//CP (IY+d)
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase
			   end
			   //X
			   3: begin
				 case(`Z_DECODE) 
				   
				   1: begin	
					 case(`Y_DECODE) 
					   
					   4: begin					// POP IY
						 ;
					   end
					   
					   5: begin					// JP (IY)
						 ;
					   end
					   
					   7: begin					// LD SP, IY 
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   
				   3: begin
					 case(`Y_DECODE) 
					   
					   1: begin					// RLC, BIT, SET b,(IY+d) ....
						 ;
					   end
					   
					   4: begin					// EX (SP), IY
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   
				   5: begin
					 case(`Y_DECODE) 
					   
					   4: begin					//PUSH IY
						 ;
					   end
					   default:catch_up <= 1;
					 endcase
				   end
				   default:catch_up <= 1;
				 endcase // case (`Z_DECODE)
			   end
			   default:catch_up <= 1;
			 endcase // case (`X_DECODE)
			 
		   end
		   default:catch_up <= 1;
		 endcase // case (`X_DECODE)

	   end // always @ (posedge clk)
	   
	   
	 endcase

	 t_state <= t_state + 1;				

   end // UNMATCHED !!







endmodule



//
//reg_read_1 <= ???;
//reg_read_2 <= ???;
//
//alu_op_a_sel <= 1;//nimm reg_out_1 und reg_out_2 als operanden fr die alu
//alu_op_b_sel <= 2;
//
//alu_opcode <= ???;
//
//reg_flags_en <= 8'b0000_0000;
//
//reg_write <= ???;//wohin soll geschrieben werden
//	  
//reg_in_sel   <= 0;//schreib das ergebniss aus der alu
//reg_write_op <= 1;
//









