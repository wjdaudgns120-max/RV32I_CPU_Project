
module instruction_rom(
	input  logic [31:0] instr_addr,
	output logic [31:0] instr_code
);

	logic [31:0] instr_rom [0:127];

	`ifdef SIMULATION_TEST
//	initial begin
//		instr_rom[0] = 32'h0032_8513; // addi x10, x5, 3 -> for address
//		instr_rom[1] = 32'h0173_8593; // addi x11, x7, 23 -> for data 30
//		instr_rom[2] = 32'h00b5_2223; // sw x11, 4(x10) -> x11 value(30) store at m12(4 + 8) 
//		instr_rom[3] = 32'h0045_2603; // lw x12, 4(x10) -> m12(4(x10) value(30) load at x12
//		instr_rom[4] = 32'h00a6_0693; // addi x13, x12, 10
//
//	end
	`endif

	`ifdef SIMULATION_TEST1
	initial begin
		instr_rom[0] = 32'h0041_82b3;
		instr_rom[1] = 32'h0053_2323;
		instr_rom[2] = 32'h0023_8413;
		instr_rom[3] = 32'h0063_2503;
//		instr_rom[4] = 32'hfe62_8ce3; // beq x5, x6, -8
//		instr_rom[5] = 32'hfe62_9ce3; // bne x5, x6, -8
		instr_rom[6] = 32'h1234_5537; // lui x10, 0x12345
		instr_rom[7] = 32'h1234_5597; // auipc x11, 0x12345

	end
`endif

	initial
	$readmemh("./rtl/rom_code_ex1.mem", instr_rom, 0, 32);

	assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
