`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module alu(
	input  [`DATA_WIDTH - 1:0]  A,
	input  [`DATA_WIDTH - 1:0]  B,
	input  [              2:0]  ALUop,
	output                      Overflow,
	output                      CarryOut,
	output                      Zero,
	output [`DATA_WIDTH - 1:0]  Result
);//定义所需常量
	//采用拼接后，不用使用这两个常量
	// `define ALL_ONE {32{1'b1}}
	// `define ALL_ZERO 32'b0
	`define ADD 3'b010
	`define AND 3'b000
	`define SUB 3'b110
	`define SLT 3'b111

	`define OR 3'b001
	`define XOR 3'b100
	`define NOR 3'b101 
	`define SLTU 3'b011
 //提前定义各种操作状态，减少对于三目运算符的使用
//减少冗余，改用拼接
	
	wire[`DATA_WIDTH-1:0] ADD_ ={32{ALUop==`ADD}};
	wire[`DATA_WIDTH-1:0] AND_ ={32{ALUop==`AND}};
	wire[`DATA_WIDTH-1:0] SUB_ ={32{ALUop==`SUB}};
	wire[`DATA_WIDTH-1:0] SLT_ ={32{ALUop==`SLT}};
	wire[`DATA_WIDTH-1:0] OR_ ={32{ALUop==`OR}};
	wire[`DATA_WIDTH-1:0] XOR_={32{ALUop==`XOR}};
	wire[`DATA_WIDTH-1:0]NOR_={32{ALUop==`NOR}};
	wire[`DATA_WIDTH-1:0]SLTU_={32{ALUop==`SLTU}};
//定义加法器，供加减比较三种运算使用
	wire cin,Cout;
	wire[31:0]a;
	wire[31:0]b;

	wire[`DATA_WIDTH-1:0]sum;
	assign {Cout,sum}=a+b+cin;
//对结果进行赋值
	assign a=A;
	assign b=(ADD_&B)|(SUB_&~B)|(SLT_&~B)|(SLTU_&~B);//与和或运算时，不用到加法器内运算
	assign cin=	((ALUop==`SUB)&1)|
			((ALUop==`SLT)&1)|
			((ALUop==`SLTU)&1);
	assign Result=	(AND_&(A&B))|
			(OR_&(A|B))|
			(ADD_&sum)|
			(SUB_&sum)|
			{32{ALUop==`SLT}}&{31'b0,(Overflow^sum[`DATA_WIDTH-1])}|
			({32{(ALUop==`XOR)}}&((A&~B)|(~A&B)))|
			({32{(ALUop==`NOR)}}&~(A|B))|//使用门电路实现
			({32{ALUop==`SLTU}}&{31'b0,(~Cout)});//无符号数相比较。有进位时则A>B，否则相反
	//assign CarryOut=(A[31]&~B[31])|(A[31]&~Result[31])|(~B[31]&~Result[31]);
	assign CarryOut=(ALUop==`SUB)?(B?~Cout:0):Cout;
	assign Zero=(Result==32'b0)?1:0;
	//溢出信号，使用一位判断
	assign Overflow=(ALUop==`ADD)?(A[31]==B[31]?((~sum[31]==A[31])?1:0):0):((A[31]==B[31])?0:((sum[31]==~A[31])?1:0));


	// TODO: Please add your logic design here

endmodule

