`timescale 1ns/10ps


/*
Main Register Set
	a, f,		//Accumulator und Flag
	b, c,		//General Purpose Register
	d, e,		//General Purpose Register
	h, l,		//General Purpose Register
	//Alternate Register Set
	a', f',		//Accumulator und Flag
	b', c',		//General Purpose Register
	d', e',		//General Purpose Register
	h', l',		//General Purpose Register
	//Special Purpose Register
	i,		//Interrupt Vector
	r,		//Memory Refresh
	ix, iy,		//Index Register
	sp,		//Stack Pointer
	pc		//Program Counter
*/


module CPU_Register (
	clk,
	reg_read_1,
	reg_read_2,	//register that should be read from
	reg_write,	//register that should be writen to
	reg_write_op,	// 01->write, 10->exchange 11->load
	reg_flags_write_en,
	reg_in,	//data input
	reg_out_1,
	reg_out_2,	 //data output
	reg_pc,
	reset,
	alu_flags,
	reg_pc_inc			
);



input 		clk;
input		reset;

input		reg_pc_inc;

//register auswahl
input [4:0]	reg_read_1;
input [4:0]	reg_read_2;
input [4:0]	reg_write;

//register schreibe operationen
input [1:0] 	reg_write_op;
input [7:0]	reg_flags_write_en;

//eingang in den Registerblock
input [7:0] 	reg_in;
input [7:0] 	alu_flags;

//ausgabe aus dem Registerblock
output	[7:0] 	reg_out_1;
output	[7:0] 	reg_out_2;
output	[15:0] 	reg_pc;//pc wird momentan noch nicht komplet unterstütz weil es kein 16bit reg in gibt

output 	[15:0]	reg_out_flags;


reg [7:0] reg_main[31:0];
reg [7:0] reg_alternate[31:0];

`include "parameter.v"



//read

assign	reg_out_1 = reg_main[reg_read_1[4:0]];
assign	reg_out_2 = reg_main[reg_read_2[4:0]];
assign	reg_pc = {reg_main[PCH],reg_main[PCL]};
assign	reg_out_flags = reg_main[F];

	

always@(posedge clk or negedge reset)
begin	
	if(reset == 0) begin
		reg_main[NULL] 	<= 8'h00;
		reg_main[ONE] 	<= 8'h01;
		
		for(i=5'b00000; i<5'b11000; i=i+1) reg_main[i] <=8'h00;
		for(i=5'b00000; i<5'b11000; i=i+1) reg_alternate[i] <=8'h00;
	end	
	else begin
		reg_main[NULL] 	<= 8'h00;
		reg_main[ONE] 	<= 8'h01;

		//hier wird der reg_flags_write_en Eingang verwendet um das schreiben auf das Flagregister von der ALU aus selektiv zu bestimmen 
		if(reg_flags_write_en[0]) reg_main[F][0] <= alu_flags[0];
		if(reg_flags_write_en[1]) reg_main[F][1] <= alu_flags[0];
		if(reg_flags_write_en[2]) reg_main[F][2] <= alu_flags[0];
		if(reg_flags_write_en[4]) reg_main[F][4] <= alu_flags[0];
		if(reg_flags_write_en[6]) reg_main[F][6] <= alu_flags[0];
		if(reg_flags_write_en[7]) reg_main[F][7] <= alu_flags[0];

		case(reg_write_op)
			IDLE: begin
			end
			WRITE: begin
				if(reg_write != NULL) reg_main[reg_write[4:0]] <= reg_in[7:0];
			end
			EX: begin
			//das hier hat schon relevanz, aber das muss nochmal anders gelöst werden
			end
		endcase

		if(reg_pc_inc) begin
			{reg_main[PCH],reg_main[PCL]} <= {reg_main[PCH],reg_main[PCL]} + 1;
		end

	end//else
	
end


endmodule


