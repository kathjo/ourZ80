// Company           :   tud                      
// Author            :   kajo17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   CPU_ALU.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Sat May 20 16:30:04 2017 
// Last Change       :   $Date: 2017-07-24 10:23:34 +0200 (Mon, 24 Jul 2017) $
// by                :   $Author: zuer17 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module CPU_ALU (
		alu_op_a,
		alu_op_b,
		alu_opcode,
		reg_out_flags,
		alu_res,
		alu_flags
		);


input [7:0]  alu_op_a;
input [7:0]  alu_op_b;
input [7:0]  alu_opcode;
input [7:0]  reg_out_flags;


output [7:0] alu_res;
output [7:0] alu_flags;

reg [7:0] alu_res;
reg [7:0] alu_flags;
reg [3:0] dummy;

wire	carry_in;

reg [15:0]	address_bus;
reg [15:0]	reg_pc;
reg		mreq_pos;
reg		mreq_neg;
reg		rd_pos;
reg		rd_neg;
reg		m1_pos;
reg		m1_neg;
reg [1:0]	data_target;
reg		instr_en;
reg		reg_pc_inc;
reg		wr_pos;
reg		wr_neg;
reg		iorq_pos;
reg		iorq_neg;
reg		temp_en;
reg [4:0]	pre_op;
reg [3:0]	t_state;

parameter NO = 1'b0;
`include "parameter.v"


//generates halfcarry flag for add
function generate_half_carry_add;
	input [7:0] a;
	input [7:0] b;
	reg [3:0] dummy;
	begin
		{generate_half_carry_add, dummy[3:0]} = a[3:0] + b[3:0];
	end 
endfunction

//generates halfcarry flag for sub
function generate_half_carry_sub;
	input [7:0] a;
	input [7:0] b;
	reg [3:0] dummy;
	begin
		{generate_half_carry_sub, dummy[3:0]} = a[3:0] - b[3:0];
	end 
endfunction

   
   
always @(alu_op_a or alu_op_b or alu_opcode)
begin


	case(alu_opcode)
	ADD: begin
			//actual addition and carry-out generation
			{alu_flags[0], alu_res[7:0]} = alu_op_a[7:0] + alu_op_b[7:0];
			
			alu_flags[1] = 0;//add-flag (N)
			
			alu_flags[4] = generate_half_carry_add(alu_op_a[7:0], alu_op_b[7:0]);
			
			//overflow for add
			if((alu_op_a[7] == alu_op_b[7]) && (alu_op_a[7] != alu_res[7]) && (alu_op_b[7] != alu_res[7]))
				alu_flags[2] = 1'b1;
			else
				alu_flags[2] = 1'b0;
			
		end
		
		
		
		
		
	ADD_ci: begin
			{alu_flags[0], alu_res[7:0], dummy} = {alu_op_a[7:0], 1'b1} + {alu_op_b[7:0], carry_in};
			
			alu_flags[1] = 0;
												//add-flag
			alu_flags[4] = generate_half_carry_add(alu_op_a[7:0], alu_op_b[7:0]);
			//overflow for add
			
			if((alu_op_a[7] == alu_op_b[7]) && (alu_op_a[7] != alu_res[7]) && (alu_op_b[7] != alu_res[7])) begin
				alu_flags[2] = 1'b1;
				end
				else begin
				alu_flags[2] = 1'b0;
			end
		end
		
	SUB: begin
			{alu_flags[0], alu_res[7:0]} = alu_op_a[7:0] - alu_op_b[7:0];
			
			alu_flags[1] = 1;//sub-flag (N)
			
			alu_flags[4] = generate_half_carry_sub(alu_op_a[7:0], alu_op_b[7:0]);
			
			//overlow for sub
			if((alu_op_a[7] != alu_op_b[7]) && (alu_op_a[7] != alu_res[7])) begin
				alu_flags[2] = 1'b1;
				end
				else begin
				alu_flags[2] = 1'b0;
			end
		end
	//dieser Befehl geht davon aus, dass er als Subtrahenden den zweiten Teil eines 16bit Operanden erhält,
	//bei dem der erste Teil schon korrekt mit carry-in invertiert wurde. Der zweite Teil wird also nur noch ohne carry-in invertiert
	//und dann mit dem carry-out aus dem ersten Teil der Subtraktion addiert
	
	//fast alle flags sind am ende einer 2-phasen 16bit subtrahierung ohne weiteres zutun korrekt gesetzt, 
	//vorrausgesetzt sie überschreiben die flags aus der ersten phase 
	
	//das zero flag muss allerding mit seinem vorgänger flag verundet werden: zero_out = (result == 0000_0000) && zero_in 
	SUB_16: begin
			{alu_flags[0], alu_res[7:0], dummy} = {alu_op_a[7:0], 1'b1} + {(~alu_op_b[7:0]), carry_in};
			alu_flags[1] = 1;//sub-flag
			alu_flags[4] = generate_half_carry_sub(alu_op_a[7:0], alu_op_b[7:0]);
			//overlow for sub
			if((alu_op_a[7] != alu_op_b[7]) && (alu_op_a[7] != alu_res[7])) begin
				alu_flags[2] = 1'b1;
				end
				else begin
				alu_flags[2] = 1'b0;
			end
		end
	//nur zu testzwecken, flags sind noch nicht korrekt erstellt
	SUB_ci: begin
			{alu_flags[0], alu_res[7:0]} = (alu_op_a[7:0] - alu_op_b[7:0]) - {7'b000_0000,carry_in};
			
			alu_flags[1] = 1;//sub-flag (N)
			
			alu_flags[4] = generate_half_carry_sub(alu_op_a[7:0], alu_op_b[7:0]);
			
			//overlow for sub
			if((alu_op_a[7] != alu_op_b[7]) && (alu_op_a[7] != alu_res[7])) begin
				alu_flags[2] = 1'b1;
				end
				else begin
				alu_flags[2] = 1'b0;
			end
		end
		
	AND: begin
		alu_res = alu_op_a & alu_op_b;
		alu_flags[4] = 1;
		if((alu_op_a[7] == alu_op_b[7]) && (alu_op_a[7] == alu_res[7]) && (alu_op_b[7] == alu_res[7])) begin
			alu_flags[2] = 1'b1;
		end
		else begin
			alu_flags[2] = 1'b0;
		end
		alu_flags[1] = 0;
		alu_flags[0] = 0;
	end
	OR: begin
		alu_res = alu_op_a | alu_op_b;
		alu_flags[4] = 0;				//H
		if((alu_op_a[7] == alu_op_b[7]) && (alu_op_a[7] != alu_res[7]) && (alu_op_b[7] != alu_res[7])) begin
			alu_flags[2] = 1'b1;
		end
		else begin
			alu_flags[2] = 1'b0;
		end
		alu_flags[1] = 0;				//N
		alu_flags[0] = 0;				//C
	end
	XOR: begin
		alu_res = alu_op_a ^ alu_op_b;
		alu_flags[4] = 0;
		//overlow for xor, ist gesetzt, wenn das Ergebnis gerade (Parität gerade) ist
		if(alu_res[0]^alu_res[1]^alu_res[2]^alu_res[3]^alu_res[4]^alu_res[5]^alu_res[6]^alu_res[7]) begin
			alu_flags[2] = 1'b1;
		end
		else begin
			alu_flags[2] = 1'b0;
		end
		alu_flags[1] = 0;
		alu_flags[0] = 0;
	end
	CP: begin
		if(alu_op_a == alu_op_b) begin
			alu_flags[7] = 1;
		end
		else begin
			alu_flags[7] = 0;
		end
		alu_flags[4] = generate_half_carry_add(alu_op_a[7:0], alu_op_b[7:0]);
		//overlow for xor, ist gesetzt, wenn einer der beiden Operanden negativ ist
		if((alu_op_a[7] == alu_op_b[7]) && (alu_op_a[7] != alu_res[7]) && (alu_op_b[7] != alu_res[7])) begin
			alu_flags[2] = 1'b1;
		end
		else begin
			alu_flags[2] = 1'b0;
		end
		alu_flags[1] = 1;
		if(alu_op_a < alu_op_b) begin
			alu_flags[0] = 1;
		end
		else begin
			alu_flags[0] = 0;
		end
	end
	endcase
	//sign flag
	if((alu_res[7] == 1) && (alu_opcode != CP)) begin
			alu_flags[7] = 1;
	end
	else begin
			alu_flags[7] = 0;
	end
	
	//zero flag
	if(alu_res[7:0] == 8'h00) begin
			alu_flags[6] = 1;
	end
	else begin
			alu_flags[6] = 0;
	end

end	
   
endmodule
