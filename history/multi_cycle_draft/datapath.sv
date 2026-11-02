// ----------------------------------------------------
// Datapath Top
// ----------------------------------------------------
module datapath (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_en,
    input  logic        rf_we,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [31:0] instr_code,
    input  logic		rfsrc_sel,
	input  logic [ 1:0] j_u_sel,
    input  logic [31:0] drdata,
    input  logic        branch,
	input  logic		jal,
	input  logic		jalr,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic [31:0] alu_result, rf_rd1, rf_rd2;
    logic [31:0] imm_extend, alusrc_muxout, mux5x1_out;
    logic b_taken;
	logic [2:0] mux5x1_src_sel;
	logic [31:0] pc_imm, pc4;

	logic [31:0] dec2exe_rs1, dec2exe_rs2, dec2exe_imm;
	logic [31:0] exe2mem_alu, exe2mem_rs2;
	logic [31:0] mem2wb_rdata;

    assign daddr = exe2mem_alu;
    assign dwdata = exe2mem_rs2;
	assign mux5x1_src_sel = {j_u_sel, rfsrc_sel};


    program_counter U_PC (
        .clk(clk),
        .rst_n(rst_n),
		.pc_en(pc_en),
        .branch(branch),
        .b_taken(b_taken),
		.jal(jal),
		.jalr(jalr),
        .ff_imm_ext(dec2exe_imm),
        .rs1(dec2exe_rs1),
		.pc4(pc4),
		.pc_imm(pc_imm),
        .pc(instr_addr)
    );


    reg_file U_REG_FILE (
        .clk(clk),
        .rst_n(rst_n),
        .ra1(instr_code[19:15]),
        .ra2(instr_code[24:20]),
        .wa(instr_code[11:7]),
        .wd(mux5x1_out),
        .we(rf_we),
        .rd1(rf_rd1),
        .rd2(rf_rd2)
    );

	register_file U_DEC_RS1(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(rf_rd1),
		.data_out(dec2exe_rs1)
	);

	register_file U_DEC_RS2(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(rf_rd2),
		.data_out(dec2exe_rs2)
	);

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

	register_file U_DEC_IMM(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(imm_extend),
		.data_out(dec2exe_imm)
	);

    mux_2x1 U_ALUSRC_MUX (
        .sel(alusrc_sel),
        .in0(dec2exe_rs2),
        .in1(dec2exe_imm),
        .mux_out(alusrc_muxout)
    );

    alu U_ALU (
        .rs1(dec2exe_rs1),
        .rs2(alusrc_muxout),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .b_taken(b_taken)
    );

	mux_5x1 U_5x1_MUX(
	    .sel(mux5x1_src_sel),
	    .in0(alu_result),
	    .in1(mem2wb_rdata),
	    .in2(dec2exe_imm),
	    .in3(pc_imm),
	    .in4(pc4),
	    .mux_out(mux5x1_out)
	);

	register_file U_EXE_ALU(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(alu_result),
		.data_out(exe2mem_alu)
	);

	register_file U_EXE_RS2(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(dec2exe_rs2),
		.data_out(exe2mem_rs2)
	);

	register_file U_MEM_RDATA(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(drdata),
		.data_out(mem2wb_rdata)
	);

endmodule

// ----------------------------------------------------
// Register File
// ----------------------------------------------------
module reg_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [ 4:0] ra1,
    input  logic [ 4:0] ra2,
    input  logic [ 4:0] wa,
    input  logic [31:0] wd,
    input  logic        we,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] rf[0:31];

    assign rd1 = (ra1 == 5'd0) ? 32'd0 : rf[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : rf[ra2];

    always_ff @(posedge clk) begin
		if(we) rf[wa] <= wd;
    end
endmodule

// ----------------------------------------------------
// ALU
// ----------------------------------------------------
module alu (
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic [ 3:0] alu_control,
    output logic [31:0] alu_result,
    output logic        b_taken
);
    always_comb begin
        alu_result = 32'h0000_0000;
        case (alu_control)
            4'b0_000: alu_result = rs1 + rs2;
            4'b1_000: alu_result = rs1 - rs2;
            4'b0_100: alu_result = rs1 ^ rs2;
            4'b0_110: alu_result = rs1 | rs2;
            4'b0_111: alu_result = rs1 & rs2;
            4'b0_001: alu_result = rs1 << rs2;
            4'b0_101: alu_result = rs1 >> rs2;
            4'b1_101: alu_result = $signed(rs1) >>> rs2;
            4'b0_010: alu_result = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
            4'b0_011: alu_result = (rs1 < rs2) ? 32'd1 : 32'd0;
        endcase
    end

    always_comb begin
        b_taken = 1'b0;
        case (alu_control)
            4'b0_000:  b_taken = ($signed(rs1) == $signed(rs2));  // BEQ
            4'b0_001:  b_taken = ($signed(rs1) != $signed(rs2));  // BNE
            4'b0_100:  b_taken = ($signed(rs1) < $signed(rs2));  // BLT
            4'b0_101:  b_taken = ($signed(rs1) >= $signed(rs2));  // BGE
            4'b0_110:  b_taken = (rs1 < rs2);  // BLTU
            4'b0_111:  b_taken = (rs1 >= rs2);  // BGEU
            default: b_taken = 1'b0;
        endcase
    end
endmodule

// ----------------------------------------------------
// Immediate Extender
// ----------------------------------------------------
module imm_extend
    import rv32_pkg::*;
(
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);
    opcode_e opcode;
    assign opcode = opcode_e'(instr_code[6:0]);

    always_comb begin
        case (opcode)
            OP_STYPE:imm_extend = {{20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]};
            OP_ITYPE, OP_ILTYPE, OP_JALR:imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            OP_BTYPE:imm_extend = {{20{instr_code[31]}},instr_code[7],instr_code[30:25],instr_code[11:8],1'b0};
			OP_LUI, OP_AUIPC: imm_extend = {instr_code[31:12], 12'b0};
			OP_JAL: imm_extend = { {12{instr_code[31]}}, instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0 };            
//			OP_JALR: imm_extend = { {20{instr_code[31]}}, instr_code[31:20]};
			default: imm_extend = 32'd0;
        endcase
    end
endmodule

// ----------------------------------------------------
// Program Counter
// ----------------------------------------------------
module program_counter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_en,
    input  logic        branch,
    input  logic        b_taken,
	input  logic		jal,
	input  logic		jalr,
    input  logic [31:0] ff_imm_ext,
	input  logic [31:0] rs1,
	output logic [31:0] pc4,
	output logic [31:0] pc_imm, // pc imm or rs1 + imm
    output logic [31:0] pc
);
    logic [31:0] register_pc;
	logic [31:0] pc_next;
	logic [31:0] jalsrc_muxout;
    logic pc_sel;
	logic [31:0] exe2fetch_pc_next;

    assign pc_sel = (branch & b_taken) | jal | jalr;
    assign pc = register_pc;

	assign pc4 = pc + 4;
	assign pc_imm = jalsrc_muxout + ff_imm_ext;

	register_file U_EXE_PCNEXT(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(pc_next),
		.data_out(exe2fetch_pc_next)
	);

    always_ff @(posedge clk) begin
        if (!rst_n) register_pc <= 32'd0;
		else begin
			if(pc_en) register_pc <= exe2fetch_pc_next;
		end
    end

    mux_2x1 U_PC_MUX (
        .sel(pc_sel),
        .in0(pc4),
        .in1(pc_imm),
        .mux_out(pc_next)
    );

    mux_2x1 U_JALRSRC_MUX (
        .sel(jalr),
        .in0(pc),
        .in1(rs1),
        .mux_out(jalsrc_muxout)
    );

endmodule

// ----------------------------------------------------
// Mux 2x1
// ----------------------------------------------------
module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    output logic [31:0] mux_out
);
    assign mux_out = sel ? in1 : in0;
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    output logic [31:0] mux_out
);

	always_comb begin
		case(sel)
			3'b000: mux_out = in0; // ALU result
			3'b001: mux_out = in1; // Load data
			3'b010: mux_out = in2; // imm_extend
			3'b011: mux_out = in3; // pc_imm
			3'b100: mux_out = in4; // pc4
			default: mux_out = in0;
		endcase
	end
endmodule

module register_file(
	input				clk,
	input		  		rst_n,
	input  logic [31:0] data_in,
	output logic [31:0] data_out
);

	always_ff@(posedge clk)begin
		if(!rst_n) data_out <= 32'd0;
		else data_out <= data_in;
	end

endmodule
