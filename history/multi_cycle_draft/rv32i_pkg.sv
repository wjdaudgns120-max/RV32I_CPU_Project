package rv32_pkg;

	typedef enum logic [6:0] {
		OP_RTYPE	= 7'b011_0011,
		OP_STYPE  	= 7'b010_0011,
		OP_ITYPE  	= 7'b001_0011,
		OP_ILTYPE 	= 7'b000_0011,
		OP_BTYPE  	= 7'b110_0011,
		OP_LUI    	= 7'b011_0111,
		OP_AUIPC  	= 7'b001_0111,
		OP_JAL    	= 7'b110_1111,
		OP_JALR		= 7'b110_0111
	} opcode_e;

// rv32i instruction enum type
	typedef enum logic [3:0] {
		ADD  = 4'b0000,
		SUB  = 4'b1000,
		SLL  = 4'b0001,
		SLT  = 4'b0010,
		SLTU = 4'b0011,
		XOR  = 4'b0100,
		SRL  = 4'b0101,
		SRA  = 4'b1101,
		OR	 = 4'b0110,
		AND  = 4'b0111
	} instr_rtype_e;

	typedef enum logic [2:0] {
		BEQ  = 3'b000,
		BNE  = 3'b001,
		BLT  = 3'b100,
		BGE  = 3'b101,
		BLTU = 3'b110,
		BGEU = 3'b111
	} instr_btype_e;

	typedef enum logic [2:0] {
		SB  = 3'b000,
		SH  = 3'b001,
		SW  = 3'b010
	} instr_stype_e;

	typedef enum logic [2:0] {
		LB  = 3'b000,
		LH  = 3'b001,
		LW  = 3'b010,
		LBU  = 3'b100,
		LHU  = 3'b101
	} instr_itype_e;

	typedef enum logic [2:0] {
		 ADDI	= 3'b000,
		 SLTI	= 3'b010,
		 SLTIU 	= 3'b011,
         XORI	= 3'b100,
         ORI	= 3'b110,
         ANDI	= 3'b111
	} instr_iltype_e;

	typedef enum logic [6:0] {
		LUI  = 7'b011_0111,
		AUIPC  = 7'b001_0111
	} instr_utype_e;

	typedef enum logic [6:0] {
		JAL  = 7'b110_1111,
		JALR = 7'b110_0111
	} instr_jtype_e;

endpackage
