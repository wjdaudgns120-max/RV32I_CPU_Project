module datamem(
	input  logic		clk,
	input  logic [31:0]	daddr,
	input  logic [31:0]	dwdata,
	input  logic		dwe,
	input  logic [ 2:0]	itype,
	output logic [31:0] drdata
);

	logic [31:0] data_mem [0:127];

	// store
	always_ff @ (posedge clk) begin
		if(dwe) begin
			case(itype) 
				// SB(Store Byte)
				3'b000: begin
					case (daddr[1:0])
						2'b00: data_mem[daddr[31:2]][ 7: 0] <= dwdata[7:0];
						2'b01: data_mem[daddr[31:2]][15: 8] <= dwdata[7:0];
						2'b10: data_mem[daddr[31:2]][23:16] <= dwdata[7:0];
						2'b11: data_mem[daddr[31:2]][31:24] <= dwdata[7:0];
					endcase
				end
				// SH(Store Half)
				3'b001: begin
					case (daddr[1])
						1'b0: data_mem[daddr[31:2]][15: 0] <= dwdata[15:0];
						1'b1: data_mem[daddr[31:2]][31:16] <= dwdata[15:0];
					endcase
				end
				// SW(Store Word)
				3'b010: data_mem[daddr[31:2]]  <= dwdata;
				// default
				default: data_mem[daddr[31:2]] <= data_mem[daddr[31:2]];
			endcase
		end
	end

	// load
	always_comb begin
		drdata = 32'd0;
		case(itype)
			3'b000: begin
				case (daddr[1:0])
						2'b00: drdata = { { 24{data_mem[daddr[31:2]][ 7]}}, data_mem[daddr[31:2]][ 7: 0]};
						2'b01: drdata = { { 24{data_mem[daddr[31:2]][15]}}, data_mem[daddr[31:2]][15: 8]};
						2'b10: drdata = { { 24{data_mem[daddr[31:2]][23]}}, data_mem[daddr[31:2]][23:16]};
						2'b11: drdata = { { 24{data_mem[daddr[31:2]][31]}}, data_mem[daddr[31:2]][31:24]};
				endcase
			end
			3'b001: begin
				case (daddr[1])
						1'b0: drdata = { { 16{data_mem[daddr[31:2]][15]}}, data_mem[daddr[31:2]][15: 0] };
						1'b1: drdata = { { 16{data_mem[daddr[31:2]][31]}}, data_mem[daddr[31:2]][31:16] };
				endcase
			end
			3'b010: drdata = data_mem[daddr[31:2]];
			3'b100: begin
				case (daddr[1:0])
					2'b00: drdata = {24'b0, data_mem[daddr[31:2]][7:0]};
					2'b01: drdata = {24'b0, data_mem[daddr[31:2]][15:8]};
					2'b10: drdata = {24'b0, data_mem[daddr[31:2]][23:16]};
					2'b11: drdata = {24'b0, data_mem[daddr[31:2]][31:24]};
				endcase
			end
			3'b101: begin
				case (daddr[1])
					1'b0: drdata = {16'b0, data_mem[daddr[31:2]][15: 0]};
					1'b1: drdata = {16'b0, data_mem[daddr[31:2]][31:16]};
				endcase
			end
		endcase
	end
endmodule
