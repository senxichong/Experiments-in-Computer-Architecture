`timescale 10 ns / 1 ns

`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_file(
	input                       clk,
	input  [`ADDR_WIDTH - 1:0]  waddr,
	input  [`ADDR_WIDTH - 1:0]  raddr1,
	input  [`ADDR_WIDTH - 1:0]  raddr2,
	input                       wen,
	input  [`DATA_WIDTH - 1:0]  wdata,
	output [`DATA_WIDTH - 1:0]  rdata1,
	output [`DATA_WIDTH - 1:0]  rdata2
);
//定义对应的32位寄存器；连接两读一写端口，使能信号，时钟信号
	reg [`DATA_WIDTH-1:0] rf[31:0];
	wire clk;
	wire wen;
	wire [`DATA_WIDTH-1:0]wdata;
	wire [`ADDR_WIDTH-1:0]raddr1;
	wire [`ADDR_WIDTH-1:0]raddr2;
	wire [`ADDR_WIDTH-1:0]waddr;
	wire [`DATA_WIDTH-1:0]rdata1;
	wire [`DATA_WIDTH-1:0]rdata2;
//上升沿，当使能信号为一，写入地址不为零，非阻塞赋值给相对应的地址
	always @(posedge clk ) begin
		if(wen&&waddr!=0)
		rf[waddr]<=wdata;
	end
//从寄存器中读取费全零地址的值
	assign rdata1=(raddr1==32'b0)?32'b0:rf[raddr1];
	assign rdata2=(raddr2==32'b0)?32'b0:rf[raddr2];
	// TODO: Please add your logic design here
	
endmodule
