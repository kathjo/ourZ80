`timescale 1ns/10ps

module CPU_Top (
	clk,		//Taktfrequenz= 4MHz, siehe timescale
	power,		// +5V Power Supply
	gnd,		//Masse
	reset,		//Reset, setzt interrupt enable ff, leert den PC und Register I, R und setzt interrupt status zu 0
	nmi,		//Nonmaskable Interrupt, höhere Priorität als INT, immer am Ende von Befehl, befiehlt CPU an Adresse 0066h neuzustarten
	int,		//Interrupt Request, durch I/O generiert	
	halt,		//CPU hat halt ausgeführt und wartet auf nonmaskable oder maskable interrupt
	wr,		//Write, gibt an das CPU gültige Daten beinhaltet, welche an der adressierten Speicheradresse oder I/O gespeichert werden können
	rd,		//Read, CPU will Daten von I/O Gerät lesen
	iorq,		//Input/Output Request, untere hälfte von address bus besitzt gültige I/O Adresse
	mreq,		//Memory Request, gibt an das der address bus eine gültige Adresse besitzt
	m1,		//Machine Cycle One, gibt zusammen mit MREQ an das momentaner Maschinenzyklus ist der op code fetch eines Ausführungsbefehls
	address_bus,
	data		//8-bit bidirektionaler Datenpfad
);

input clk;
input power;
input gnd;
input reset;
input nmi;
input int;

output [15:0] address_bus;
output halt;
output wr;
output rd;
output mreq;
output iorq;
output m1;

input [7:0] data_in;
output [7:0] data_out;


//output to register
wire	[9:0]	reg_read_1;
wire	[9:0]	reg_read_2;
wire	[9:0]	reg_write;
wire	[1:0]	reg_write_op;
wire	[15:0]	reg_pc;
wire	[7:0]	current_state;
wire	[7:0]	next_cycle;
wire 	[7:0] 	alu_res;
wire 	[7:0] 	alu_flags;
wire	[7:0] 	alu_op_a;
wire	[7:0] 	alu_op_b;
wire	[7:0]	alu_opcode;
wire	[7:0]	reg_in;
wire	[7:0]	reg_out_1;
wire	[7:0]	reg_out_2;
wire	[7:0]	reg_out_flags;
wire		reg_flags_write_en;
wire		reg_pc_inc;

    
CPU_Control CPU_Control_i (
	//out of top_unit				    
	.clk(clk),					    
	.reset(reset),					    
	//.current_state(current_state),			    
	//.next_cycle(next_cycle),			    
	.mreq(mreq),					    
	.rd(rd),					    
	.m1(m1),
	.wr(wr),
	.iorq(iorq),					    
	.reg_pc(reg_pc),				    
	.data_in(data_in),				    
	.data_out(data_out),				    
	.address_bus(address_bus),			    
	//buses to alu					    
		//ctrl					    
		.alu_opcode(alu_opcode),		    
		//data					    
		.alu_op_a(alu_op_a),			    
		.alu_op_b(alu_op_b),			    
		.alu_res(alu_res),
	//buses to register block			    
		//ctrl					    
		.reg_read_1(reg_read_1),		    
		.reg_read_2(reg_read_2),		    
		.reg_write(reg_write),
		.reg_write_op(reg_write_op),		    
		.reg_flags_write_en(reg_flags_write_en),
		.reg_pc_inc(reg_pc_inc),
		//data					    
		.reg_in(reg_in),			    
		.reg_out_1(reg_out_1),
		.reg_out_2(reg_out_2),
		.reg_out_flags(reg_out_flags)
);



CPU_ALU CPU_ALU_i (
	.alu_op_a(alu_op_a),
	.alu_op_b(alu_op_b),
	.alu_opcode(alu_opcode),
	.reg_out_flags(reg_out_flags),
	.alu_res(alu_res),
	.alu_flags(alu_flags)
);

CPU_Register CPU_Register_i (
	.clk(clk),
	.reg_read_1(reg_read_1),
	.reg_read_2(reg_read_2),	//register that should be read from
	.reg_write(reg_write),		//register that should be writen to
	.reg_write_op(reg_write_op),	// 01->write, 10->exchange 11->load
	.reg_flags_write_en(reg_flags_write_en),//which flags can be written to
	.reg_in(reg_in),
	.alu_flags(alu_flags),		//data input
	.reg_out_1(reg_out_1),
	.reg_out_2(reg_out_2),  	//data output
	.reg_out_flags(reg_out_flags),
	.reg_pc(reg_pc),
	.reset(reset)
);

//CPU_FSM CPU_FSM_i (
//	.clk(clk),
//	.reset(reset),
//	.next_cycle(next_cycle),
//	.current_state(current_state)
//);

endmodule
