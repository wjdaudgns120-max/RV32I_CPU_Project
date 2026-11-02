module control_unit
	import rv32_pkg::*;
(
	input  logic		clk,
	input  logic		rst_n,
	input  logic [31:0] instr_code,
	output logic		pc_en,
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

	typedef enum logic [3:0] {
		FETCH,
		DECODE,
		EXECUTE,
		MEM,
		WB
	} state_e;

	state_e c_state, n_state;

	always_ff@(posedge clk) begin
		if(!rst_n) begin
			c_state <= FETCH;
		end else begin
			c_state <= n_state;
		end
	end

	always_comb begin
		n_state = c_state;
		case(c_state)
			FETCH:begin
				n_state = DECODE;
			end
			DECODE:begin
				n_state = EXECUTE;
			end
			EXECUTE:begin
				case(opcode)
					OP_RTYPE, OP_BTYPE, OP_ITYPE, OP_LUI, OP_AUIPC, OP_JAL, OP_JALR : 
						n_state = FETCH;
					OP_STYPE, OP_ILTYPE : 
						n_state = MEM;
				endcase
			end
			MEM:begin
				if(opcode == OP_STYPE) n_state = FETCH;
				else n_state = WB;
			end
			WB:begin
				n_state = FETCH;
			end
		endcase
	end

	always_comb begin
		pc_en		= 0;
		rf_we		= 0;
		branch		= 0;
		jal			= 0;
		jalr		= 0;
		alusrc_sel	= 0;
		alu_control = 4'b0_000; // {func7[5], func3}
		rfsrc_sel	= 0; // To control for WB to reg_file
		j_u_sel		= 0;
		dwe			= 0;
		itype		= 3'b111; // SW, LW
		case(c_state)
			FETCH:begin
				pc_en = 1;
			end
			DECODE:begin
			end
			EXECUTE: begin
				case(opcode)
					OP_RTYPE: begin // R-type
						rf_we		= 1;
						alusrc_sel	= 0;
						alu_control = {instr_code[30], func3};
						rfsrc_sel	= 0;
						j_u_sel		= 0;
					end
					OP_BTYPE: begin
						branch		= 1;
						alusrc_sel	= 0;
						alu_control = {1'b0, func3}; // to calculate data mem addr
					end
					OP_STYPE: begin // S-type
						alusrc_sel	= 1;
						alu_control = 0;
					end
					OP_ITYPE: begin
						rf_we		= 1;
						alusrc_sel	= 1;
						if(func3 == 3'b101) alu_control = {instr_code[30], instr_code[14:12]};
						else alu_control = {1'b0, func3};
						rfsrc_sel	= 0;
						j_u_sel		= 0;
					end
					OP_ILTYPE: begin
						alusrc_sel	= 1;
						alu_control = 0; // to calculate data mem addr
					end
					// LUI,AUI type
					OP_LUI: begin
						rf_we		= 1; 
						rfsrc_sel	= 0; // To control for WB to reg_file
						j_u_sel		= 2'b01;
					end
					OP_AUIPC: begin
						rf_we		= 1; 
						rfsrc_sel	= 1; // To control for WB to reg_file
						j_u_sel		= 2'b01;
					end
					OP_JAL: begin
						rf_we		= 1; 
						jal			= 1;
						rfsrc_sel	= 0; // To control for WB to reg_file
						j_u_sel		= 2'b10;
					end
					OP_JALR: begin
						rf_we		= 1; 
						jalr		= 1;
						rfsrc_sel	= 0; // To control for WB to reg_file
						j_u_sel		= 2'b10;
					end
				endcase
			end
			MEM:begin
				itype = func3;
				if(opcode == OP_STYPE) dwe = 1;
			end
			WB:begin
				rf_we = 1;
				rfsrc_sel = 1;
				j_u_sel = 2'b00;
			end
		endcase
	end

endmodule

