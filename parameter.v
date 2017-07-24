//FSM:

parameter IDLE		= 8'd0;
parameter IF_t1		= 8'd1;
parameter IF_t2		= 8'd2;
parameter IF_t3		= 8'd3;
parameter IF_t4		= 8'd4;
parameter MR_t1		= 8'd5;
parameter MR_t2		= 8'd6;
parameter MR_t3		= 8'd7;
parameter MW_t1		= 8'd8;
parameter MW_t2		= 8'd9;
parameter MW_t3		= 8'd10;
parameter IN_t1		= 8'd11;
parameter IN_t2		= 8'd12;
parameter IN_t3		= 8'd13;
parameter OUT_t1	= 8'd14;
parameter OUT_t2	= 8'd15;
parameter OUT_t3	= 8'd16;

//cycles
parameter IF		= 8'd17;
parameter MR		= 8'd18;
parameter MW		= 8'd19;
parameter IN		= 8'd20;
parameter OUT		= 8'd21;

parameter t0		= 4'd0;
parameter t1		= 4'd1;
parameter t2		= 4'd2;
parameter t3		= 4'd3;
parameter t4		= 4'd4;
parameter t5		= 4'd5;
parameter t6		= 4'd6;
parameter t7		= 4'd7;
parameter t8		= 4'd8;
parameter t9		= 4'd9;
parameter t10		= 4'd010;


//CONTROL
parameter data_in_alu_op_a	= 3'b000;
parameter data_in_alu_op_b	= 3'b001;
parameter data_in_reg_in	= 3'b010;
parameter data_out_alu_res	= 3'b011;
parameter data_out_reg_out_1	= 3'b100;
parameter data_out_reg_out_2	= 3'b101;

parameter NOP	= 8'b00000000; // No Operation
parameter ADD_r	= 8'b00000001; // ADD A,r
parameter LD_r	= 8'b00000010; // LD r,r'

//REGISTER:

//die reinfolge hier folgt der codierung aus ADD A, r
//hier braucht man wahrscheinlich doch was anderes
parameter B	= 5'b00000;
parameter C 	= 5'b00001;
parameter D 	= 5'b00010;
parameter E 	= 5'b00011;
parameter H 	= 5'b00100;
parameter L 	= 5'b00101;
parameter F 	= 5'b00110;
parameter A 	= 5'b00111;

parameter X 	= 5'b11111;
		

parameter I  	= 5'b01000;
parameter R	= 5'b01001;
parameter IXL 	= 5'b01010;
parameter IXH 	= 5'b01011;
parameter IYL 	= 5'b01100;
parameter IYH 	= 5'b01101;
parameter SPL 	= 5'b01110;
parameter SPH 	= 5'b01111;
parameter PCL 	= 5'b10000;
parameter PCH 	= 5'b10001;

parameter NULL	= 5'b11000;
parameter ONE	= 5'b11001;


//reg_write_op

parameter READ	= 2'd0;
parameter WRITE	= 2'd1;
parameter EX	= 2'd2;
parameter LOAD	= 2'd3;

//ALU

parameter ADD 	= 8'b00000000;
parameter SUB 	= 8'b00000001;
parameter ADD_ci= 8'b00000010;
parameter SUB_ci= 8'b00000011;
parameter SUB_16= 8'b00000100;
parameter AND 	= 8'b00000101;
parameter OR 	= 8'b00000110;
parameter XOR 	= 8'b00000111;
parameter CP 	= 8'b00001000;


//macros for controll


	
`define X_DECODE inst[7:6]

`define Y_DECODE inst[5:3]

`define Z_DECODE inst[2:0]

`define P_DECODE inst[5:4]

`define Q_DECODE inst[3]

task IF1; begin
	address_bus = reg_pc;
	mreq_pos = 1'b0;
	rd_pos = 1'b0;
	m1_pos = 1'b1;
	mreq_neg = 1'b1;
	rd_neg = 1'b1;
	m1_neg = 1'b1;
	end
endtask



task	IF2; begin
			data_target = 2'b00;
			instr_en = 1'b1;
			reg_pc_inc = 1'b1;
			mreq_pos = 1'b1;
			rd_pos = 1'b1;
		end endtask
		

task	IF2_immediate; begin
			data_target = 2'b10;
			instr_en = 1'b1;
			reg_pc_inc = 1'b1;
			mreq_pos = 1'b1;
			rd_pos = 1'b1;
		end  endtask


//data address is for ad-hoc computed addresses
task	MR1; begin
 			//address_bus = data_adr;
			mreq_pos = 1'b0;
			rd_pos = 1'b0;
			wr_pos = 1'b0;
			mreq_neg = 1'b1;
			rd_neg = 1'b1;
			wr_neg = 1'b0;
 	 	 end  endtask

task	MR2; begin
 			mreq_pos = 1'b1;
			rd_pos = 1'b1;
			
 	 	 end endtask 


task	MR3; begin
 			mreq_neg = 1'b0;
			rd_neg = 1'b0;
			temp_en = 1'b1;
			data_target = 2'b01;
			
 	 	 end  endtask

task	MW1; begin
			//address_bus = data_adr;
			mreq_pos = 1'b0;
			rd_pos = 1'b0;
 			mreq_neg = 1'b1;
			rd_neg = 1'b0;
		end endtask 


task	MW2; begin
 			mreq_pos = 1'b1;
			wr_neg = 1'b1;
 	 	 end endtask 


task	MW3; begin
			wr_neg = 1'b0;
			mreq_neg = 1'b0;
 	 	 end endtask
		 
task IN1; begin
			temp_en = 1'b0;
			iorq_pos = 1'b0;
			rd_pos = 1'b0;
		end endtask
		
task IN2; begin
			iorq_pos = 1'b1;
			rd_pos = 1'b1;
			iorq_neg = 1'b1;
			rd_neg = 1'b1;
		end endtask
		
task IN3; begin
			iorq_neg = 1'b0;
			rd_neg = 1'b0;
			temp_en = 1'b1;
			data_target = 2'b01;
		end endtask
		
task OUT1; begin
			temp_en = 1'b0;
			iorq_pos = 1'b0;
			wr_pos = 1'b0;
		end endtask
		
task OUT2; begin
			iorq_pos = 1'b1;
			wr_pos = 1'b1;
			iorq_neg = 1'b1;
			wr_neg = 1'b1;
		end endtask
		
task OUT3; begin
			iorq_neg = 1'b0;
			wr_neg = 1'b0;
		end endtask

task END; begin
			pre_op = NO;
			t_state = 0;
		end endtask
