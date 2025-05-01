
module forward_unit#(
   )(
      input wire signed [5-1:0]  next_rs1,
      input wire signed [5-1:0]  next_rs2,
      input wire signed [5-1:0]  prev_rd_mem,
      input wire signed [5-1:0]  prev_rd_wb,
      input wire signed          reg_write_mem, 
      input wire signed          reg_write_wb, 
      output reg signed [1:0]    rs1_mux,
      output reg signed [1:0]    rs2_mux
   );

    always @(*) begin
        if (reg_write_mem & (next_rs1 == prev_rd_mem)) rs1_mux = 2'b01;
        else if (reg_write_wb & (next_rs1 == prev_rd_wb)) rs1_mux = 2'b10;
        else rs1_mux = 2'b10;
    end
    always @(*) begin
        if (reg_write_mem & (next_rs2 == prev_rd_mem)) rs2_mux = 2'b01;
        else if (reg_write_wb & (next_rs2 == prev_rd_wb)) rs2_mux = 2'b10;
        else rs2_mux = 2'b10;
    end
        
endmodule
