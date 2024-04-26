`timescale 10ns / 1ns

module simple_cpu(
	input             clk,
	input             rst,

	output [31:0]     PC,
	input  [31:0]     Instruction,

	output [31:0]     Address,
	output            MemWrite,
	output [31:0]     Write_data,
	output [ 3:0]     Write_strb,

	input  [31:0]     Read_data,
	output            MemRead
);

	// THESE THREE SIGNALS ARE USED IN OUR TESTBENCH
	// PLEASE DO NOT MODIFY SIGNAL NAMES
	// AND PLEASE USE THEM TO CONNECT PORTS
	// OF YOUR INSTANTIATION OF THE REGISTER FILE MODULE
	wire			RF_wen;
	wire [4:0]		RF_waddr;
	wire [31:0]		RF_wdata;

	// TODO: PLEASE ADD YOUR CODE BELOW
	
	//divide the Instructions into parts
	wire[5:0]opcode,func;
	wire[4:0]rs,rt,rd,shamt;
	wire[15:0]immediate;
	wire[25:0]target_addr;
	wire RegDst,ALUSrc,MemtoReg,Branch,RFtoALU;//MemRead,MemWrite,
	assign {opcode,rs,rt,rd,shamt,func}=Instruction[31:0];
	assign immediate=Instruction[15:0];
	assign target_addr=Instruction[25:0];
	wire[31:0]Load_WL,Load_WR;
	wire [7:0] Load_B;
	wire [15:0] Load_H;
	//declare for the reg_file
	wire[31:0] Readdata1,Readdata2;
	
	//实例化
	reg_file SM_reg_file(
		.clk(clk),
		.waddr(RF_waddr),
		.raddr1(rs),
		.raddr2(rt),
		.rdata1(Readdata1),
		.rdata2(Readdata2),
		.wen(RF_wen),
		.wdata(RF_wdata)

	);
	
	//declare the needed wire
	wire[31:0] result,ALU_B;
	wire[2:0]ALUop;
	wire Zero;
	wire [31:0]Wdata_IR;
	//alu
	alu SM_alu(
		.A(Readdata1),
		.B(ALU_B),
		.ALUop(ALUop),
		.Overflow(),//Don't need these two wire
		.CarryOut(),
		.Zero(Zero),
		.Result(result)
	);
	assign ALU_B=RFtoALU?Readdata2:(
		{32{Itype_r||Itype_w||opcode==6'b001001||opcode[5:1]==5'b00101}}&{{16{Instruction[15]}},Instruction[15:0]}|
		//IType_w,IType_r,addiu,slti,sltiu
		{32{opcode[5:2]==4'b0011&&(~opcode[1]|~opcode[0])}}&{16'd0,Instruction[15:0]}|
		//andi,ori,xori
		{32{opcode==6'b001111}}&({16'd0,Instruction[15:0]}<<16)
		//lui
		
	);
	//shifter
	wire[31:0] Shifter_Result;
	wire[1:0]Shiftop;
	wire[4:0]Shifter_B;
	shifter SM_Shifter(
		.A(Readdata2),
		.B(Shifter_B),
		.Shiftop(Shiftop),
		.Result(Shifter_Result)
	);
	
	//define different instrcutions
	assign Rtype = (opcode == 6'b000000);
	assign REGIMM = (opcode == 6'b000001);
	assign Jtype = (opcode[5:1] == 5'b00001);
	assign Itype_branch = (opcode[5:2] == 4'b0001);
	assign Itype_calc = (opcode[5:3] == 3'b001);
	assign Itype_r = (opcode[5:3] == 3'b100);
	assign Itype_w = (opcode[5:3] == 3'b101);
	assign Itype=Itype_branch|Itype_calc|Itype_r|Itype_w;
	
	//reg_file
	assign RF_waddr=Jtype?5'b11111:(({5{RegDst}}&rd)|{5{~{RegDst}}}&rt);
	assign RF_wdata=(
		{32{(Rtype&func[5])||(Itype_calc)}}&result|
		//RType-calc or IType-calc
		{32{(Rtype&&func[5:3]==3'b000)}}&Shifter_Result|
		//RType-shift
		{32{Rtype&&{func[5:3],func[1]}==4'b0010||Jtype}}&(PC+32'd8)|
		//RType-jump
		{32{Rtype&&{func[5:3],func[1]}==4'b0011}}&Readdata1|
		//RType-move
		{32{Itype_r}}&Wdata_IR
		//IType-r
	);
	wire[15:0]SignEX_lh;
	wire[23:0]SignEX_lb;
	assign SignEX_lh=(opcode[2]?16'b0:{16{Load_H[15]}});
	assign SignEX_lb=(opcode[2]?24'b0:{24{Load_B[7]}});
	assign Wdata_IR=(
		{32{opcode[1:0]==2'b00}}&{SignEX_lb,Load_B}|
		//lbu,lb
		{32{opcode[1:0]==2'b01}}&{SignEX_lh,Load_H}|
		//lhu,lh
		{32{opcode[1:0]==2'b10}}&(opcode[2]?Load_WR:Load_WL)|
		//lwr,lwl
		{32{opcode[1:0]==2'b11}}&Read_data
		//lw
		
	);
	
	assign Load_B=Read_data[{result[1:0],3'd0}+:8];
	assign Load_H=Read_data[{result[1],4'd0}+:16];
	assign Load_WL=(
		{32{result[1:0]==2'b00}}&{Read_data[7:0],Readdata2[23:0]}|
		{32{result[1:0]==2'b01}}&{Read_data[15:0],Readdata2[15:0]}|
		{32{result[1:0]==2'b10}}&{Read_data[23:0],Readdata2[7:0]}|
		{32{result[1:0]==2'b11}}&Read_data
	);
	assign Load_WR=(
		{32{result[1:0]==2'b00}}&Read_data |
		{32{result[1:0]==2'b01}}&{Readdata2[31:24],Read_data[31:8]}|
		{32{result[1:0]==2'b10}}&{Readdata2[31:16],Read_data[31:16]}|
		{32{result[1:0]==2'b11}}&{Readdata2[31:8],Read_data[31:24]}
	);

	assign RF_wen=((Rtype&&func[5:0]!=6'b001000&&func[5:1]!=5'b00101)|(Rtype&&func[5:1] == 5'b00101&&(|Readdata2)==func[0]))|(Jtype&&(opcode[0]))|Itype_calc|Itype_r;

	//shifter
	assign Shiftop=func[1:0];
	assign Shifter_B=func[2]?Readdata1:Instruction[10:6];


	//PC
	wire[31:0]PC4;
	reg [31:0] PC;
	assign PC4=PC+32'd4;
	always @(posedge clk) begin
		if(rst!=1'b0)begin
				PC<=32'b0;
			//resert
		end
		else begin
			if(Rtype&&({func[3],func[1]}==2'b10))begin
				PC<=Readdata1;
				//jr,jalr
			end
			else if((Zero^(REGIMM&~Instruction[16]|Itype_branch&(opcode[0]^(opcode[1]&|Readdata1))))&Branch)
				begin
					PC<=(PC+32'd4)+({{16{Instruction[15]}},Instruction[15:0]}<<2);
				end
				//bltz,begz,beq,bne,blez,bgtz
			else if(Jtype)begin
					PC<={PC4[31:28],Instruction[25:0],2'b00};
				//j,jal
			end
			else
				PC<=PC4;
		end
	end
	
	//Instruction Decode
	
	
	assign RegDst=Rtype;
	
	assign ALUSrc=Itype_branch|REGIMM;
	assign RFtoALU=(Rtype&&func[5]==1||Itype_branch);
	assign Branch = REGIMM | Itype_branch;
	assign MemtoReg=Itype_r;
	
	assign MemWrite=opcode[5]&opcode[3];
	
	assign MemRead=opcode[5]&(~opcode[3]);

	assign ALUop= (
		({3{Rtype}}&(
			{3{func[3:2]==2'b00}}&{func[1],2'b10}|
			//add,addu,sub,subu
			{3{func[3:2]==2'b01}}&{func[1],1'b0,func[0]}|
			//and,or,xor
			{3{func[3:2]==2'b10}}&{~func[0],2'b11}
			//slt,sltu
		))|
		({3{Itype_calc}}&(
			{3{opcode[2:1]==2'b00}}&{opcode[1],2'b10}|
			//addi,addiu
			{3{opcode[2]==1'b1&&opcode!=6'b001111}}&{opcode[1],1'b0,opcode[0]}|
			//andi,ori,xori
			{3{opcode[2:1]==2'b01}}&{~opcode[0],2'b11}|
			//slti,sltiu
			{3{opcode==6'b001111}}&{3'b001}

		))|
		({3{Itype_r|Itype_w}}&3'b010)|
		({3{Itype_branch}}&(({3{opcode[2:1]==2'b11}}&3'b111)|({3{opcode[2:1]==2'b10}}&3'b110)))|
		({3{REGIMM}}&3'b111)
	);
	//write back
	assign Address={result[31:2],2'b00};
	assign Write_data={32{opcode[1]==0}}&Readdata2<<{result[1:0],3'd0}|
			{32{opcode[1:0]==2'b11}}&Readdata2|
			{32{opcode[1:0]==2'b10}}&(opcode[2]?SWR_data:SWL_data);
	wire[31:0]SWL_data,SWR_data;
	assign SWL_data=(
		{32{result[1:0]==2'b11}}&Readdata2|
		{32{result[1:0]==2'b00}}&{24'b0,Readdata2[31:24]}|
		{32{result[1:0]==2'b01}}&{16'b0,Readdata2[31:16]}|
		{32{result[1:0]==2'b10}}&{8'b0,Readdata2[31:8]}
	);
	assign SWR_data=(
		{32{result[1:0]==2'b00}}&Readdata2|
		{32{result[1:0]==2'b01}}&{Readdata2[23:0],8'b0}|
		{32{result[1:0]==2'b10}}&{Readdata2[15:0],16'b0}|
		{32{result[1:0]==2'b11}}&{Readdata2[7:0],24'b0}
	);
	
	assign Write_strb=(
		{4{opcode[1:0]==2'b00}}&(4'd1<<result[1:0])|
		//sb 
		{4{opcode[1:0]==2'b01}}&(4'd3<<result[1:0])|
		//sh
		{4{opcode[1:0]==2'b11}}&4'd15|
		//sw
		{4{opcode[1:0]==2'b10}}&(opcode[2]?(4'd15<<result[1:0]):~(4'd14<<result[1:0]))
	);
	
	
	
	
endmodule
