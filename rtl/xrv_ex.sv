`include "glb.svh"
/*******************************************************************************
*  Execuate
* *******************************************************************************/ 
module xrv_ex(
    input                       clk,
    input                       rstb,
    //input                       flush,

    output logic                ex_jmp,
    output logic [31:0]         ex_jmp_addr,
    //output logic                ncycle_alu_wait,
    output                      ls_done,

    input                       ex_valid,
    input        [31:0]         ex_pc,
    input                       op_lui,              
    input                       op_auipc,
    input                       op_jal,  
    input                       op_jalr,
    input                       op_branch,
    input                       op_load,
    input                       op_store,
    input                       op_imm,
    input                       op_reg,
    input                       op_is_compressed,

    input        [31:0]         imm_signed,
    input        [31:0]         imm_unsigned,
    input        [4:0]          src1,
    input        [4:0]          src2,
    input        [4:0]          dest,
    input                       funct3_is_0,
    input                       funct3_is_1,
    input                       funct3_is_2,
    input                       funct3_is_3,
    input                       funct3_is_4,
    input                       funct3_is_5,
    input                       funct3_is_6,
    input                       funct3_is_7,
    input                       funct7_bit5,
    //input        [2:0]          funct3,
    //input        [6:0]          funct7,

    output logic [31:0]         d_addr,
    output logic                d_wr_req,
    output logic [3 :0]         d_be,
    output logic [31:0]         d_wr_data,
    input                       d_wr_ready,
    output logic                d_rd_req,
    input                       d_rd_ready,
    input        [31:0]         d_rd_data
);

    localparam logic [31:0] ALL0 = 32'h0;
    localparam logic [31:0] ALL1 = 32'hFFFF_FFFF; 

    logic ld_done;


    (* ram_style = "distributed" *) logic [31:0] x_reg[0:31];

    `ifdef DBG
        integer fp;
        integer tick;
        initial begin
            tick = 0;
            fp = $fopen("core.log","w");
        end
        wire [31:0][31:0] x;
        genvar i;
        generate 
            for(i=0;i<32;i++) begin
                assign x[i] = x_reg[i];
            end
        endgenerate
    `endif


    initial begin
        int i;
        for(i=0;i<32;i++) begin
            x_reg[i] = 0;
        end
    end

    wire [31:0] reg1 = x_reg[src1];
    wire [31:0] reg2 = x_reg[src2];

    wire signed [31:0] operand1 = reg1;
    wire operand2_is_unsigned = funct3_is_3;
    wire signed [31:0] operand2 = (op_reg|op_branch|op_store) ? reg2 : (operand2_is_unsigned ? imm_unsigned : imm_signed);

    logic [31:0] dest_reg_val;
    logic dest_reg_wr_en;


    logic [31:0] dest_reg_op_imm_or_op_reg;
    logic [31:0] dest_reg_op_load;
    logic [31:0] operand1_minus_operand2;
    logic [31:0] operand1_plus_operand2;
    logic        operand1_lt_operand2;
    logic        operand1_lt_operand2_u;
    logic [31:0] operand_ls;
    logic [31:0] operand_rs;

    //logic ncycle_alu_cmp;
    //logic op_imm_reg;
    //logic op_reg_reg;
    //logic funct3_is_0_reg;
    //logic funct3_is_1_reg;
    //logic funct3_is_2_reg;
    //logic funct3_is_3_reg;
    //logic funct3_is_4_reg;
    //logic funct3_is_5_reg;
    //logic funct3_is_6_reg;
    //logic funct3_is_7_reg;
    //logic funct7_bit5_reg;
    //logic [4:0] dest_reg;
    logic dest_not0;
    logic ex_imm_reg;

    `ifdef OP_IMM_REG_2_STAGE
    wire ex_en;
    //assign ncycle_alu_wait = ex_en & (op_imm|op_reg) & ~ncycle_alu_cmp;
    //logic [1:0] ncycle_alu_wait_dly;
    //assign ex_en = (ex_valid|ncycle_alu_wait_dly[1])&~ex_jmp&~ncycle_alu_wait_dly[0];
    assign ex_en = (ex_valid&~ex_jmp);
    //always @(posedge clk or negedge rstb) begin
    //    if(~rstb) begin
    //        ncycle_alu_wait_dly <= 0;
    //    end else begin
    //        ncycle_alu_wait_dly <= {ncycle_alu_wait_dly[0],ncycle_alu_wait};
    //    end
    //end 

    //always @(posedge clk or negedge rstb) begin
    //    if(~rstb) begin
    //        ncycle_alu_cmp <= 0;
    //    end else begin
    //        if(ex_en & (op_imm | op_reg) ) begin
    //            ncycle_alu_cmp <= 1;
    //        end else begin
    //            ncycle_alu_cmp <= 0;
    //        end
    //    end
    //end 

    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            ex_imm_reg <= 0;
        end else begin
            ex_imm_reg <= ex_en & (op_imm|op_reg);
        end
    end 

    always @(posedge clk) begin
        operand1_minus_operand2 <= operand1 - operand2;
        operand1_plus_operand2  <= operand1 + operand2;
        operand1_lt_operand2_u <= $unsigned(operand1) < $unsigned(operand2);
        operand1_lt_operand2   <= $signed(operand1) < $signed(operand2);
        operand_rs <= (funct7_bit5 ? operand1 >>> operand2[4:0] : operand1 >> operand2[4:0]);
        operand_ls <= operand1 << operand2[4:0];
        dest_reg_op_imm_or_op_reg <= funct3_is_4 ? operand1 ^ operand2 :
                                     funct3_is_6 ? operand1 | operand2 :
                                                        operand1 & operand2;
        //op_imm_reg <= op_imm;
        //op_reg_reg <= op_reg;
        //funct3_is_0_reg <= funct3_is_0;
        //funct3_is_1_reg <= funct3_is_1;
        //funct3_is_2_reg <= funct3_is_2;
        //funct3_is_3_reg <= funct3_is_3;
        //funct3_is_4_reg <= funct3_is_4;
        //funct3_is_5_reg <= funct3_is_5;
        //funct3_is_6_reg <= funct3_is_6;
        //funct3_is_7_reg <= funct3_is_7;
        //funct7_bit5_reg <= funct7_bit5;
        //dest_reg <= dest;
    end
    `else
        wire ex_en = ex_valid&~ex_jmp;
        assign ex_imm_reg = ex_en & (op_imm | op_reg);
        //assign ncycle_alu_wait = 0;
        //assign ncycle_alu_cmp = ex_en & (op_imm|op_reg);
        always @(*) begin
            operand1_minus_operand2 = operand1 - operand2;
            operand1_plus_operand2  = operand1 + operand2;
            operand1_lt_operand2_u = $unsigned(operand1) < $unsigned(operand2);
            operand1_lt_operand2   = $signed(operand1) < $signed(operand2);
            operand_rs = (funct7_bit5 ? operand1 >>> operand2[4:0] : operand1 >> operand2[4:0]);
            operand_ls = operand1 << operand2[4:0];
            dest_reg_op_imm_or_op_reg = funct3_is_4 ? operand1 ^ operand2 :
                                        funct3_is_6 ? operand1 | operand2 :
                                                            operand1 & operand2;
        end
        //assign op_imm_reg = op_imm;
        //assign op_reg_reg = op_reg;
        //assign funct3_is_0_reg = funct3_is_0;
        //assign funct3_is_1_reg = funct3_is_1;
        //assign funct3_is_2_reg = funct3_is_2;
        //assign funct3_is_3_reg = funct3_is_3;
        //assign funct3_is_4_reg = funct3_is_4;
        //assign funct3_is_5_reg = funct3_is_5;
        //assign funct3_is_6_reg = funct3_is_6;
        //assign funct3_is_7_reg = funct3_is_7;
        //assign funct7_bit5_reg = funct7_bit5;
        //assign dest_reg = dest;
    `endif
    assign dest_not0 = |dest;


    always @(*) begin
            dest_reg_wr_en = 0;
            dest_reg_val = 0;
            if(ld_done) begin
                dest_reg_val = dest_reg_op_load;
                dest_reg_wr_en = dest_not0;
                `LOG_CORE($sformatf("PC=%05x OP_LOAD %08x from %08x\n", ex_pc, d_rd_data, d_addr));
            end else if(ex_imm_reg) begin
                if(op_imm|op_reg) begin
                    dest_reg_val = funct3_is_0 ? ( (funct7_bit5&op_reg) ? operand1_minus_operand2 : operand1_plus_operand2) :
                                   funct3_is_1 ? operand_ls :
                                   funct3_is_5 ? operand_rs :
                                   funct3_is_2 ? {31'h0,operand1_lt_operand2} :
                                   funct3_is_3 ? {31'h0,operand1_lt_operand2_u} : dest_reg_op_imm_or_op_reg;
                    dest_reg_wr_en = dest_not0;
                end
            end else if(ex_en) begin
                if(op_lui) begin
                    dest_reg_val = imm_signed;
                    dest_reg_wr_en = dest_not0;
                    `LOG_CORE($sformatf("PC=%05x LUI\n",ex_pc));
                end else if(op_auipc) begin
                    dest_reg_val = ex_pc + $signed(imm_signed&32'hFFFFF000) + 4;
                    dest_reg_wr_en = dest_not0;
                    `LOG_CORE($sformatf("PC=%05x AUIPC \n",ex_pc));
                end else if(op_jal|op_jalr) begin
                    dest_reg_val = ex_pc + (op_is_compressed ? 2 : 4);
                    dest_reg_wr_en = dest_not0;
                    `LOG_CORE($sformatf("PC=%05x OP_JAL|OP_JALR\n",ex_pc));
                end
            end
    end

    always @(posedge clk) begin
        if(dest_reg_wr_en) begin
            x_reg[dest] <= dest_reg_val;
        end
    end
     
/*******************************************************************************
* JMP
********************************************************************************/ 
    logic operand_eq;
    wire operand_lt  = $signed(operand1) < $signed(operand2);
    wire operand_ltu = $unsigned(operand1) < $unsigned(operand2);
    assign operand_eq  = operand1 == operand2;

    wire branch = op_branch & (  (funct3_is_0 & operand_eq) |
                                 (funct3_is_1 & ~operand_eq) |
                                 (funct3_is_4 & operand_lt)  |
                                 (funct3_is_5 & ~operand_lt)  |
                                 (funct3_is_6 & operand_ltu) |
                                 (funct3_is_7 & ~operand_ltu) );
                            
    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            ex_jmp <= 0;
        end else begin
            if(ex_en) begin
                ex_jmp <= branch|op_jalr;
            end else begin
                ex_jmp <= 0;
            end
        end
    end
     
    logic signed [31:0] branch_addr;
    logic signed [31:0] jalr_addr;
    logic        branch_reg;
    always @(posedge clk) begin
        branch_addr <= ex_pc + imm_signed;
        jalr_addr <= operand1 + imm_signed;
        branch_reg <= branch;
    end
    assign ex_jmp_addr = branch_reg ? branch_addr : jalr_addr;

/*******************************************************************************
*  Load/Store 
********************************************************************************/ 
    always @(posedge clk) begin
        dest_reg_op_load <= funct3_is_0 ? (
                            d_addr[1:0] == 0 ? {d_rd_data[7] ? ALL1[31:8] : ALL0[31:8],d_rd_data[7:0]} :
                            d_addr[1:0] == 1 ? {d_rd_data[15] ? ALL1[31:8] : ALL0[31:8], d_rd_data[15:8]} :
                            d_addr[1:0] == 2 ? {d_rd_data[23] ? ALL1[31:8] : ALL0[31:8], d_rd_data[23:16]} :
                                               {d_rd_data[31] ? ALL1[31:8] : ALL0[31:8], d_rd_data[31:24]}
                       ) :
                       funct3_is_1 ? (
                           d_addr[1] == 0 ? {d_rd_data[15] ? ALL1[31:16] : ALL0[31:16], d_rd_data[15:0]} :
                                            {d_rd_data[31] ? ALL1[31:16] : ALL0[31:16], d_rd_data[31:16]}
                       ) :
                       funct3_is_2 ? d_rd_data[31:0] :
                       funct3_is_4 ? (
                            d_addr[1:0] == 0 ? {ALL0[31:8],d_rd_data[7:0]} :
                            d_addr[1:0] == 1 ? {ALL0[31:8],d_rd_data[15:8]} :
                            d_addr[1:0] == 2 ? {ALL0[31:8],d_rd_data[23:16]} :
                                               {ALL0[31:8],d_rd_data[31:24]}
                       ):
                       funct3_is_5 ? (
                           d_addr[1] == 0 ? {ALL0[31:16],d_rd_data[15:0]} : {ALL0[31:16],d_rd_data[31:16]}
                       ) : 32'h0;

    end 

    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            d_wr_req <= 0;
        end else begin
            if(d_wr_ready) begin
                d_wr_req <= 0;
            end else if(ex_en&op_store)begin
                d_wr_req <= 1;
            end
        end
    end

    wire [1:0] laddr = operand1[1:0] + imm_signed[1:0];

    always @(posedge clk) begin
        if(op_store&ex_en) begin
            d_wr_data <= funct3_is_0 ? 
                            (laddr == 0 ? {24'h0,operand2[7:0]} :
                             laddr == 1 ? {16'h0,operand2[7:0],8'h0} :
                             laddr == 2 ? {8'h0, operand2[7:0],16'h0} :
                                          {operand2[7:0],24'h0}) :
                         funct3_is_1 ?
                               (laddr[1] ? {operand2[15:0],16'h0} : {16'h0, operand2[15:0]}) : 
                         operand2;
        end
    end

    always @(posedge clk) begin
        if((op_store|op_load)&ex_en) begin
            d_be <=  (funct3_is_0 | funct3_is_4) ? 
                            (laddr == 0 ? 4'h1 : 
                            laddr == 1 ? 4'h2 :
                            laddr == 2 ? 4'h4 : 4'h8) :
                     (funct3_is_1 | funct3_is_5) ? 
                               (laddr[1] ? 4'hc : 4'h3) :
                     4'hf;
        end
    end

    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            d_rd_req <= 0;
        end else begin
            if(d_rd_ready) begin
                d_rd_req <= 0;
            end else if(ex_en&op_load) begin
                d_rd_req <= 1;
            end
        end
    end

    always @(posedge clk) begin
        if((op_store|op_load)&ex_en) begin
            d_addr <= reg1 + imm_signed;
        end
    end
     
    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            ld_done <= 0;
        end else begin
            ld_done <= d_rd_req&d_rd_ready;
        end
    end 

    assign ls_done = ld_done | (d_wr_req&d_wr_ready);
     
endmodule
