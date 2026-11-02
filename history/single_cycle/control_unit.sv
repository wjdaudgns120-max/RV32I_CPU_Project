module control_unit
	import rv32_pkg::*;
(
	input  logic [31:0] instr_code,
	output logic		rf_we,
	output logic		branch,
	output logic		jal,
	output logic		jalr,
    output logic		alusrc_sel,
	output logic [ 3:0]	alu_control,
	output logic		rfsrc_sel,
	output logic [ 1:0] j_u_sel,
	output logic		dwe,
	output logic [ 2:0] itype // instruction type : func3
);

	logic [2:0] func3;

	opcode_e opcode;
	instr_rtype_e instr_rtype;
	instr_btype_e instr_btype;
	instr_stype_e instr_stype;
	instr_itype_e instr_itype;
	instr_iltype_e instr_iltype;
	instr_utype_e instr_utype;
	instr_jtype_e instr_jtype;

	assign opcode = opcode_e'(instr_code[6:0]);
	assign func3 = instr_code[14:12];
	assign instr_rtype = instr_rtype_e'(alu_control);
	assign instr_btype = instr_btype_e'(func3);
	assign instr_stype = instr_stype_e'(func3);
	assign instr_itype = instr_itype_e'(func3);
	assign instr_iltype = instr_iltype_e'(func3);
	assign instr_utype = instr_utype_e'(opcode);
	assign instr_jtype = instr_jtype_e'(opcode);

	always_comb begin
		rf_we		= 0;
		branch		= 0;
		jal			= 0;
		jalr		= 0;
		alusrc_sel	= 0;
		alu_control = 4'b0_000; // {func7[5], func3}
		rfsrc_sel	= 0; // To control for WB to reg_file
		j_u_sel		= 0;
		dwe			= 0;
		itype		= 3'b010; // SW, LW
		case(opcode)
			OP_RTYPE: begin // R-type
				rf_we		= 1;
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 0;
				alu_control = {instr_code[30], func3};
				rfsrc_sel	= 0;
				j_u_sel		= 0;
				dwe			= 0;
				itype		= 3'b000;
			end
			OP_BTYPE: begin
				rf_we		= 0; 
				branch		= 1;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 0;
				alu_control = {1'b0, func3}; // to calculate data mem addr
				rfsrc_sel	= 0; // To control for WB to reg_file
				j_u_sel		= 0;
				dwe			= 0; // To load from data mem
				itype		= 3'b111; // SW, LW
			end
			OP_STYPE: begin // S-type
				rf_we		= 0;
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 1;
				alu_control = 0;
				rfsrc_sel	= 0;
				j_u_sel		= 0;
				dwe			= 1;
				itype		= func3; // SW, LW
			end
			OP_ITYPE: begin
				rf_we		= 1;
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 1;
				if(func3 == 3'b101) alu_control = {instr_code[30], instr_code[14:12]};
				else alu_control = {1'b0, func3};
				rfsrc_sel	= 0;
				j_u_sel		= 0;
				dwe			= 0;
				itype		= 3'b111; // or: data mem default mode
			end
			OP_ILTYPE: begin
				rf_we		= 1; 
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 1;
				alu_control = 0; // to calculate data mem addr
				rfsrc_sel	= 1; // To control for WB to reg_file
				j_u_sel		= 0;
				dwe			= 0; // To load from data mem
				itype		= func3; // SW, LW
			end
			// LUI,AUI type
			OP_LUI: begin
				rf_we		= 1; 
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 0;
				alu_control = 0; // to calculate data mem addr
				rfsrc_sel	= 0; // To control for WB to reg_file
				j_u_sel		= 2'b01;
				dwe			= 0; // To load from data mem
				itype		= 3'b000; // SW, LW
			end
			OP_AUIPC: begin
				rf_we		= 1; 
				branch		= 0;
				jal			= 0;
				jalr		= 0;
				alusrc_sel	= 0;
				alu_control = 0; // to calculate data mem addr
				rfsrc_sel	= 1; // To control for WB to reg_file
				j_u_sel		= 2'b01;
				dwe			= 0; // To load from data mem
				itype		= 3'b000; // SW, LW
			end
			OP_JAL: begin
				rf_we		= 1; 
				branch		= 0;
				jal			= 1;
				jalr		= 0;
				alusrc_sel	= 0;
				alu_control = 0; // to calculate data mem addr
				rfsrc_sel	= 0; // To control for WB to reg_file
				j_u_sel		= 2'b10;
				dwe			= 0; // To load from data mem
				itype		= 3'b000; // SW, LW
			end
			OP_JALR: begin
				rf_we		= 1; 
				branch		= 0;
				jal			= 0;
				jalr		= 1;
				alusrc_sel	= 0;
				alu_control = 0; // to calculate data mem addr
				rfsrc_sel	= 0; // To control for WB to reg_file
				j_u_sel		= 2'b10;
				dwe			= 0; // To load from data mem
				itype		= 3'b000; // SW, LW
			end
		endcase
	end

endmodule

