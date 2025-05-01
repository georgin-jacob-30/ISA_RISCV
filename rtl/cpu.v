//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire              zero_flag_ex_mem;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      63:0] current_pc_id_ex, branch_pc_ex_mem,jump_pc_ex_mem;
wire [      63:0] branch_pc_id_ex,jump_pc_id_ex;
wire [      63:0] current_pc_if_id;
wire [      31:0] instruction;
wire [      31:0] instruction_if_id;
wire [      31:0] instruction_id_ex;
wire [      31:0] instruction_ex_mem;
wire [      31:0] instruction_mem_wb;
wire [       1:0] alu_op;
wire [       1:0] alu_op_id_ex;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire              reg_dst_id_ex,branch_id_ex,mem_read_id_ex,mem_2_reg_id_ex,
                  mem_write_id_ex,alu_src_id_ex, reg_write_id_ex, jump_id_ex;
wire              mem_write_ex_mem, mem_read_ex_mem, mem_2_reg_ex_mem, reg_write_ex_mem, branch_ex_mem, jump_ex_mem;
wire              reg_write_mem_wb, mem_2_reg_mem_wb;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data_wb,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;
wire [      63:0] mem_data_mem_wb;
wire [      63:0] alu_out_ex_mem;
wire [      63:0] alu_out_mem_wb;
wire [      63:0] regfile_rdata_1_id_ex,regfile_rdata_2_id_ex;
wire [      63:0] regfile_rdata_2_ex_mem;

wire signed [63:0] immediate_extended;
wire signed [63:0] immediate_extended_id_ex;


reg_arstn_en#(
      .DATA_W     (32+64)
   ) reg_if_id(
      .clk(clk),
      .arst_n(arst_n),
      .en(enable),
      .din({instruction, current_pc}),
      .dout({instruction_if_id, current_pc_if_id})
);
reg_arstn_en#(
      .DATA_W     (64+64+64+32+8+2+64)
   ) reg_id_ex(
      .clk(clk),
      .arst_n(arst_n),
      .en(enable),
      .din({instruction_if_id, regfile_rdata_1, regfile_rdata_2, immediate_extended, reg_dst,branch,mem_read,mem_2_reg,mem_write,alu_src, reg_write, jump, alu_op, current_pc_if_id}),
      .dout({instruction_id_ex, regfile_rdata_1_id_ex, regfile_rdata_2_id_ex, immediate_extended_id_ex, reg_dst_id_ex,branch_id_ex,mem_read_id_ex,mem_2_reg_id_ex,mem_write_id_ex,alu_src_id_ex, reg_write_id_ex, jump_id_ex, alu_op_id_ex, current_pc_id_ex})
);
reg_arstn_en#(
      .DATA_W     (1+64+32+64+6+64+64)
   ) reg_ex_mem(
      .clk(clk),
      .arst_n(arst_n),
      .en(enable),
      .din({zero_flag, alu_out, instruction_id_ex, regfile_rdata_2_id_ex, jump_pc, branch_pc, branch_id_ex,mem_read_id_ex,mem_2_reg_id_ex,mem_write_id_ex,reg_write_id_ex, jump_id_ex}),
      .dout({zero_flag_ex_mem, alu_out_ex_mem, instruction_ex_mem, regfile_rdata_2_ex_mem, jump_pc_ex_mem, branch_pc_ex_mem, branch_ex_mem,mem_read_ex_mem,mem_2_reg_ex_mem,mem_write_ex_mem,reg_write_ex_mem, jump_ex_mem})
);
reg_arstn_en#(
      .DATA_W     (64+32+2+64)
   ) reg_mem_wb(
      .clk(clk),
      .arst_n(arst_n),
      .en(enable),
      .din({alu_out_ex_mem, instruction_ex_mem, mem_2_reg_ex_mem,reg_write_ex_mem, mem_data}),
      .dout({alu_out_mem_wb, instruction_mem_wb, mem_2_reg_mem_wb,reg_write_mem_wb, mem_data_mem_wb})
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_if_id),
    .immediate_extended  (immediate_extended)
);

pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_ex_mem ),
   .jump_pc   (jump_pc_ex_mem   ),
   .zero_flag (zero_flag_ex_mem),
   .branch    (branch_ex_mem    ),
   .jump      (jump_ex_mem      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

sram_BW32 #(
   .ADDR_W(9 )
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

sram_BW64 #(
   .ADDR_W(10)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_ex_mem        ),
   .wen      (mem_write_ex_mem      ),
   .ren      (mem_read_ex_mem       ),
   .wdata    (regfile_rdata_2_ex_mem),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

control_unit control_unit(
   .opcode   (instruction_if_id[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_mem_wb         ),
   .raddr_1  (instruction_if_id[19:15]),
   .raddr_2  (instruction_if_id[24:20]),
   .waddr    (instruction_mem_wb[11:7] ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

alu_control alu_ctrl(
   .func7_5       ({instruction_id_ex[30], instruction_id_ex[25]}   ),
   .func3          (instruction_id_ex[14:12]),
   .alu_op         (alu_op_id_ex            ),
   .alu_control    (alu_control       )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_id_ex),
   .input_b (regfile_rdata_2_id_ex    ),
   .select_a(alu_src_id_ex           ),
   .mux_out (alu_operand_2     )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (regfile_rdata_1_id_ex ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_mem_wb     ),
   .input_b  (alu_out_mem_wb      ),
   .select_a (mem_2_reg_mem_wb    ),
   .mux_out  (regfile_wdata)
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .current_pc         (current_pc_id_ex        ),
   .immediate_extended (immediate_extended_id_ex),
   .branch_pc          (branch_pc         ),
   .jump_pc            (jump_pc           )
);


endmodule


