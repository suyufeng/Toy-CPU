`include "defines.v"

module id(

	input wire rst,
	input wire[`InstAddrBus] pc_i,
	input wire[`InstBus] inst_i,
	input wire[`AluOpBus] ex_aluop_i,
	
	input wire ex_wreg_i,
	input wire[`RegBus]	ex_wdata_i,
	input wire[`RegAddrBus]	ex_wd_i,
	
	input wire mem_wreg_i,
	input wire[`RegBus]	mem_wdata_i,
	input wire[`RegAddrBus]	mem_wd_i,
	
	input wire[`RegBus]	reg1_data_i,
	input wire[`RegBus]	reg2_data_i,
	
	input wire is_in_delayslot_i,
	
	output reg reg1_read_o,
	output reg reg2_read_o,
	output reg[`RegAddrBus] reg1_addr_o,
	output reg[`RegAddrBus] reg2_addr_o,
	
	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output wire[`RegBus] inst_o,
	
	output reg next_inst_in_delayslot_o,
	
	output reg branch_flag_o,
	output reg[`RegBus] branch_target_address_o,
	output reg[`RegBus] link_addr_o,
	output reg is_in_delayslot_o,
	
	output wire stallreq
);

wire[5:0] op = inst_i[31:26];
wire[4:0] op2 = inst_i[10:6];
wire[5:0] op3 = inst_i[5:0];
wire[4:0] op4 = inst_i[20:16];
reg[`RegBus] imm;
reg instvalid;
wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_sll2_signedext;

reg stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;
wire pre_inst_is_load;
  
assign pc_plus_8 = pc_i + 8;
assign pc_plus_4 = pc_i +4;
assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

assign inst_o = inst_i;

always @ (*) begin
	if (rst == `RstEnable) begin
		aluop_o <= `EXE_NOP_OP;
		alusel_o <= `EXE_RES_NOP;
		wd_o <= `NOPRegAddr;
		wreg_o <= `WriteDisable;
		instvalid <= `InstValid;
		reg1_read_o <= 1'b0;
		reg2_read_o <= 1'b0;
		reg1_addr_o <= `NOPRegAddr;
		reg2_addr_o <= `NOPRegAddr;
		imm <= 32'h0;	
		link_addr_o <= `ZeroWord;
		branch_target_address_o <= `ZeroWord;
		branch_flag_o <= `NotBranch;
		next_inst_in_delayslot_o <= `NotInDelaySlot;
	end else begin
		aluop_o <= `EXE_NOP_OP;
		alusel_o <= `EXE_RES_NOP;
		wd_o <= inst_i[15:11];
		wreg_o <= `WriteDisable;
		instvalid <= `InstInvalid;
		reg1_read_o <= 1'b0;
		reg2_read_o <= 1'b0;
		reg1_addr_o <= inst_i[25:21];
		reg2_addr_o <= inst_i[20:16];
		imm <= `ZeroWord;
		link_addr_o <= `ZeroWord;
		branch_target_address_o <= `ZeroWord;
		branch_flag_o <= `NotBranch;
		next_inst_in_delayslot_o <= `NotInDelaySlot;
		case(op)
			`EXE_SPECIAL_INST: begin
				case(op2)
					5'b00000: begin
						case(op3)
						
							`EXE_OR: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_OR_OP;
								alusel_o <= `EXE_RES_LOGIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_AND: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_AND_OP;
								alusel_o <= `EXE_RES_LOGIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_XOR: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_XOR_OP;
								alusel_o <= `EXE_RES_LOGIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_SLT: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_SLT_OP;
								alusel_o <= `EXE_RES_ARITHMETIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_ADD: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_ADD_OP;
								alusel_o <= `EXE_RES_ARITHMETIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_SUB: begin
								wreg_o <= `WriteEnable;
								aluop_o <= `EXE_SUB_OP;
								alusel_o <= `EXE_RES_ARITHMETIC;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b1;
								instvalid <= `InstValid;
							end
							
							`EXE_JR: begin
								wreg_o <= `WriteDisable;
								aluop_o <= `EXE_JR_OP;
								alusel_o <= `EXE_RES_JUMP_BRANCH;
								reg1_read_o <= 1'b1;
								reg2_read_o <= 1'b0;
								link_addr_o <= `ZeroWord;
								
								branch_target_address_o <= reg1_o;
								branch_flag_o <= `Branch;
								
								next_inst_in_delayslot_o <= `InDelaySlot;
								instvalid <= `InstValid;
							end
							default: begin
							end
						endcase
					end
					default: begin
					end
				endcase
			end
			`EXE_ORI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_OR_OP;
				alusel_o <= `EXE_RES_LOGIC;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {16'h0, inst_i[15:0]};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_ANDI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_AND_OP;
				alusel_o <= `EXE_RES_LOGIC;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {16'h0, inst_i[15:0]};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_XORI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_XOR_OP;
				alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {16'h0, inst_i[15:0]};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_LUI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_OR_OP;
				alusel_o <= `EXE_RES_LOGIC; 
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {inst_i[15:0], 16'h0};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_SLTI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_SLT_OP;
				alusel_o <= `EXE_RES_ARITHMETIC;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {{16{inst_i[15]}}, inst_i[15:0]};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_ADDI: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_ADDI_OP;
				alusel_o <= `EXE_RES_ARITHMETIC;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {{16{inst_i[15]}}, inst_i[15:0]};
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_J: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_J_OP;
				alusel_o <= `EXE_RES_JUMP_BRANCH;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				link_addr_o <= `ZeroWord;
				branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
				branch_flag_o <= `Branch;
				next_inst_in_delayslot_o <= `InDelaySlot;
				instvalid <= `InstValid;
			end
			
			`EXE_BEQ: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_BEQ_OP;
				alusel_o <= `EXE_RES_JUMP_BRANCH;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				instvalid <= `InstValid;
				if(reg1_o == reg2_o) begin
					branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
				end
			end
			
			`EXE_BNE: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_BLEZ_OP;
				alusel_o <= `EXE_RES_JUMP_BRANCH;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				instvalid <= `InstValid;
				if(reg1_o != reg2_o) begin
					branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
				end
			end
			
			`EXE_LB: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_LB_OP;
				alusel_o <= `EXE_RES_LOAD_STORE;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_LW: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_LW_OP;
				alusel_o <= `EXE_RES_LOAD_STORE; 
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				wd_o <= inst_i[20:16];
				instvalid <= `InstValid;
			end
			
			`EXE_SB: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_SB_OP;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				instvalid <= `InstValid;
				alusel_o <= `EXE_RES_LOAD_STORE;
			end
			
			`EXE_SW: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_SW_OP;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				instvalid <= `InstValid;
				alusel_o <= `EXE_RES_LOAD_STORE;
			end
		endcase
	end
end
	

always @ (*) begin
	stallreq_for_reg1_loadrelate <= `NoStop;
	if(rst == `RstEnable)
		reg1_o <= `ZeroWord;
	else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1)
	  stallreq_for_reg1_loadrelate <= `Stop;
	else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))
		reg1_o <= ex_wdata_i;
	else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))
		reg1_o <= mem_wdata_i;
	else if(reg1_read_o == 1'b1)
		reg1_o <= reg1_data_i;
	else if(reg1_read_o == 1'b0)
		reg1_o <= imm;
	else
		reg1_o <= `ZeroWord;
end

always @ (*) begin
	stallreq_for_reg2_loadrelate <= `NoStop;
	if(rst == `RstEnable)
		reg2_o <= `ZeroWord;
	else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1)
		stallreq_for_reg2_loadrelate <= `Stop;
	else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))
		reg2_o <= ex_wdata_i;
	else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))
		reg2_o <= mem_wdata_i;
	else if(reg2_read_o == 1'b1)
	  	reg2_o <= reg2_data_i;
	else if(reg2_read_o == 1'b0)
		reg2_o <= imm;
	else
		reg2_o <= `ZeroWord;
end

always @ (*) begin
	if(rst == `RstEnable)
		is_in_delayslot_o <= `NotInDelaySlot;
	else
		is_in_delayslot_o <= is_in_delayslot_i;
end

endmodule