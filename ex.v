`include "defines.v"

module ex(

	input wire rst,
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] inst_i,
	
	input wire[`RegBus] hi_i,
	input wire[`RegBus] lo_i,
	
	input wire[`RegBus] wb_hi_i,
	input wire[`RegBus] wb_lo_i,
	input wire wb_whilo_i,
	
	input wire[`RegBus] mem_hi_i,
	input wire[`RegBus] mem_lo_i,
	input wire mem_whilo_i,
	
	input wire[`DoubleRegBus] hilo_temp_i,
	input wire[1:0] cnt_i,
	
	input wire[`RegBus] link_address_i,
	input wire is_in_delayslot_i,
	
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	output reg[`RegBus] hi_o,
	output reg[`RegBus] lo_o,
	output reg whilo_o,
	
	output reg[`DoubleRegBus] hilo_temp_o,
	output reg[1:0] cnt_o,
	
	output wire[`AluOpBus] aluop_o,
	output wire[`RegBus] mem_addr_o,
	output wire[`RegBus] reg2_o,
	
	output reg stallreq

);

reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] moveres;
reg[`RegBus] arithmeticres;
reg[`DoubleRegBus] mulres;
reg[`RegBus] HI;
reg[`RegBus] LO;
wire[`RegBus] reg2_i_mux;
wire[`RegBus] reg1_i_not;
wire[`RegBus] result_sum;
wire ov_sum;
wire reg1_eq_reg2;
wire reg1_lt_reg2;
wire[`RegBus] opdata1_mult;
wire[`RegBus] opdata2_mult;
wire[`DoubleRegBus] hilo_temp;
reg[`DoubleRegBus] hilo_temp1;

assign aluop_o = aluop_i;
assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
assign reg2_o = reg2_i;

always @ (*) begin
	if(rst == `RstEnable) begin
		logicout <= `ZeroWord;
	end else begin
		case(aluop_i)
			`EXE_OR_OP:
				logicout <= reg1_i | reg2_i;
			`EXE_AND_OP:
				logicout <= reg1_i & reg2_i;
			`EXE_NOR_OP:
				logicout <= ~(reg1_i |reg2_i);
			`EXE_XOR_OP:
				logicout <= reg1_i ^ reg2_i;
			default:
				logicout <= `ZeroWord;
		endcase
	end
end

assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) || (aluop_i == `EXE_SLT_OP)) ? (~reg2_i) + 1 : reg2_i;
assign result_sum = reg1_i + reg2_i_mux;
assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) || ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));
assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ? ((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31])) : (reg1_i < reg2_i);
assign reg1_i_not = ~reg1_i;

always @ (*) begin
	if(rst == `RstEnable)
		arithmeticres <= `ZeroWord;
	else begin
		case(aluop_i)
		`EXE_ADD_OP, `EXE_ADDI_OP, `EXE_SUB_OP:
			arithmeticres <= result_sum;
		default:
			arithmeticres <= `ZeroWord;
		endcase
	end
end

always @ (*) begin
	if(rst == `RstEnable)
		mulres <= {`ZeroWord,`ZeroWord};
	else
		mulres <= hilo_temp;
end

always @ (*) begin
	if(rst == `RstEnable)
		{HI,LO} <= {`ZeroWord,`ZeroWord};
	else if(mem_whilo_i == `WriteEnable)
		{HI,LO} <= {mem_hi_i,mem_lo_i};
	else if(wb_whilo_i == `WriteEnable)
		{HI,LO} <= {wb_hi_i,wb_lo_i};
	else
		{HI,LO} <= {hi_i,lo_i};
end	

always @ (*) begin
	if(rst == `RstEnable) begin
		hilo_temp_o <= {`ZeroWord,`ZeroWord};
		cnt_o <= 2'b00;
	end else begin
		case(aluop_i)
			default: begin
				hilo_temp_o <= {`ZeroWord,`ZeroWord};
				cnt_o <= 2'b00;
			end
		endcase
	end
end	

always @ (*) begin
	wd_o <= wd_i;
	if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1))
	 	wreg_o <= `WriteDisable;
	else
		wreg_o <= wreg_i;
	case(alusel_i)
		`EXE_RES_LOGIC:
			wdata_o <= logicout;
		`EXE_RES_SHIFT:
			wdata_o <= shiftres;
	 	`EXE_RES_MOVE:
			wdata_o <= moveres;
	 	`EXE_RES_ARITHMETIC:
	 		wdata_o <= arithmeticres;
	 	`EXE_RES_JUMP_BRANCH:
	 		wdata_o <= link_address_i;
		default:
			wdata_o <= `ZeroWord;
	endcase
end	

always @ (*) begin
	if(rst == `RstEnable) begin
		whilo_o <= `WriteDisable;
		hi_o <= `ZeroWord;
		lo_o <= `ZeroWord;		
	end begin
		whilo_o <= `WriteDisable;
		hi_o <= `ZeroWord;
		lo_o <= `ZeroWord;
	end
end
endmodule