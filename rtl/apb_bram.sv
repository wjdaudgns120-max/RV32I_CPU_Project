module apb_bram (
    input  logic        clk,
    input  logic [ 2:0] itype,
    input  logic        psel,
    input  logic        penable,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        pwrite,
    output logic [31:0] prdata,
    output logic        pready
);

    logic [31:0] dmem[0:127];

    assign pready = (penable & psel) ? 1'b1 : 1'b0;




    always_ff @(posedge clk) begin
        if (pready) begin
            case (itype)
                // sb
                3'b000: begin
                    case (paddr[1:0])
                        2'b00: dmem[paddr[31:2]][7:0]   <= pwdata[7:0];
                        2'b01: dmem[paddr[31:2]][15:8]  <= pwdata[7:0];
                        2'b10: dmem[paddr[31:2]][23:16] <= pwdata[7:0];
                        2'b11: dmem[paddr[31:2]][31:24] <= pwdata[7:0];
                    endcase
                end

                // sh
                3'b001: begin
                    case (paddr[1:0])
                        2'b00: dmem[paddr[31:2]][15:0]  <= pwdata[15:0];
                        2'b10: dmem[paddr[31:2]][31:16] <= pwdata[15:0];
                    endcase
                end

                // sw
                3'b010: begin
                    dmem[paddr[31:2]] <= pwdata;
                end

            endcase
        end
    end

    always_comb begin
        if(pready) begin
            case (itype)
                // lb 
                3'b000: begin 
                    case(paddr[1:0])
                        2'b00 : prdata = {{24{dmem[paddr[31:2]][ 7]}}, dmem[paddr[31:2]][ 7: 0]};
                        2'b01 : prdata = {{24{dmem[paddr[31:2]][15]}}, dmem[paddr[31:2]][15: 8]};
                        2'b10 : prdata = {{24{dmem[paddr[31:2]][23]}}, dmem[paddr[31:2]][23:16]};
                        2'b11 : prdata = {{24{dmem[paddr[31:2]][31]}}, dmem[paddr[31:2]][31:24]};
                    endcase
                end

                // lh
                3'b001: begin
                    case(paddr[1:0])
                        2'b00 : prdata = {{16{dmem[paddr[31:2]][15]}}, dmem[paddr[31:2]][15: 0]};
                        2'b10 : prdata = {{16{dmem[paddr[31:2]][31]}}, dmem[paddr[31:2]][31:16]};
                        default: prdata = 32'd0;
                    endcase
                end

                //lw
                3'b010: prdata = dmem[paddr[31:2]];

                // lbu
                3'b100: begin
                    case(paddr[1:0])
                        2'b00 : prdata = {24'd0, dmem[paddr[31:2]][ 7: 0]};
                        2'b01 : prdata = {24'd0, dmem[paddr[31:2]][15: 8]};
                        2'b10 : prdata = {24'd0, dmem[paddr[31:2]][23:16]};
                        2'b11 : prdata = {24'd0, dmem[paddr[31:2]][31:24]};
                    endcase
                end

                // lhu
                3'b101: begin
                    case(paddr[1:0])
                        2'b00 : prdata = {16'd0, dmem[paddr[31:2]][15: 0]};
                        2'b10 : prdata = {16'd0, dmem[paddr[31:2]][31:16]};
                        default: prdata = 32'd0;
                    endcase

                end
                default: prdata = 32'd0;
            endcase
        end
        else prdata = 32'dz;
    end
endmodule
