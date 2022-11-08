`include "../defines.v"

module mmu_tlb(
    input wire clk,
    input wire rst,
    input wire[`RegBus] addr_i,// virtual addr
    output reg[`RegBus] addr_o,// physical addr

    output reg sram_ce,
    output reg flash_ce,
    output reg rom_ce,
    output reg serial_ce,
    output reg vga_ce,

    // tlb
    input wire[`RegBus] satp_i,
    input wire[`RegBus] inst_data_i, // thinpad_top取指之后的写回
    input wire[1:0] current_mode_i,

    // output reg tlb_hit,
    output reg stall_for_virtual,
    output reg stall_for_virtual_mem,
    output reg virtual_pause_flag, // 接回pc_reg模块判断PC值应该发生什么变化
    output wire addr_ready,
    output reg addr_error,

    input wire sfence_vma_i
);

    // tlb 2^6
    reg[34:0] tlbs[63:0];
    reg tlb_hit;
    reg[1:0] mode; // mmu控制内存的状态
    integer i;

    reg[`RegBus] addr_hit;
    reg[`RegBus] addr_buffer;

    assign addr_ready = tlb_hit | (mode == `PHYSICAL_MODE);

    always @ (posedge clk) begin
        if (rst == `RstEnable ) begin
            mode <= `VIRTUAL_MODE_F;
            addr_buffer <= 32'h00000000;
            for(i=0; i<64; i = i+1)begin
                tlbs[i] <= `ZeroWord;
            end
        end
        else if(sfence_vma_i) begin
            for(i=0; i<64; i = i+1)begin
                tlbs[i] <= `ZeroWord;
            end
        end
        else begin
            addr_buffer <= 32'h00000000;
            case (mode)
                `VIRTUAL_MODE_F: begin
                    if(tlb_hit == 1'b0)begin
                        mode <= `VIRTUAL_MODE_S;
                        addr_buffer <= inst_data_i;
                    end
                end 
                `VIRTUAL_MODE_S: begin
                    mode <= `PHYSICAL_MODE;
                    addr_buffer <= inst_data_i;
                end
                `PHYSICAL_MODE: begin
                    mode <= `VIRTUAL_MODE_F;
                    addr_buffer <= 32'h00000000;
                    tlbs[addr_i[17:12]] <= { addr_i[31:18], addr_o[31:12], 1'b1 };
                end
            endcase
        end
    end

    always @ (*) begin
        if (rst == `RstEnable ) begin
            stall_for_virtual <= `NoStop;
            stall_for_virtual_mem <= `NoStop;
            virtual_pause_flag <= 1'b0;
        end
        else begin
            stall_for_virtual <= `NoStop;
            stall_for_virtual_mem <= `NoStop;
            virtual_pause_flag <= 1'b0;
            case (tlb_hit)
                1'b0: begin // hit不到
                    case (mode)
                        `VIRTUAL_MODE_F: begin
                            //　第一次映射   
                            stall_for_virtual <= `Stop;
                            stall_for_virtual_mem <= `Stop;
                            virtual_pause_flag <= 1'b1;
                            addr_o <= {satp_i[19:0], addr_i[31:22],2'b00};
                        end
                        `VIRTUAL_MODE_S: begin
                            // 第二次映射
                            stall_for_virtual <= `Stop;
                            stall_for_virtual_mem <= `Stop;
                            virtual_pause_flag <= 1'b1;
                            addr_o <= {addr_buffer[29:10], addr_i[21:12],2'b00};
                        end
                        `PHYSICAL_MODE: begin
                            addr_o <= {addr_buffer[29:10], addr_i[11:0]};
                            stall_for_virtual <= `NoStop;
                            stall_for_virtual_mem <= `NoStop;
                            virtual_pause_flag <= 1'b0;
                        end 
                    endcase
                end
                1'b1: begin
                    addr_o <= addr_hit;
                end
            endcase
            
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            sram_ce <= 1'b0;
            flash_ce <= 1'b0;
            rom_ce <= 1'b0;
            serial_ce <= 1'b0;
            vga_ce <= 1'b0;
        end
        else begin
            sram_ce <= 1'b0;
            flash_ce <= 1'b0;
            rom_ce <= 1'b0;
            serial_ce <= 1'b0;
            vga_ce <= 1'b0;
            if (tlb_hit == 1'b0) begin
                sram_ce <= 1'b1;
            end
            else if (addr_o >= 32'h10000000 && addr_o <= 32'h10000008) begin
                serial_ce <= 1'b1;
            end
            else if (addr_o >= 32'h80000000 && addr_o <= 32'h807fffff) begin
                sram_ce <= 1'b1;
            end
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            tlb_hit <= 1'b1;
            addr_hit <= 32'h00000000;
            addr_error <= 1'b0;
        end
        else begin
            tlb_hit <= 1'b1;
            addr_hit <= 32'h00000000;
            addr_error <= 1'b0;
            // uart串口
            if(current_mode_i == `USER_MODE) begin
                // 映射到异常地址
                if((addr_i >= 32'h00300000 && addr_i < 32'h7FC0FFFF) || (addr_i >= 32'h80001000 && addr_i < 32'h80100000) || (addr_i > 32'h80101000)) begin
                    addr_error <= 1'b1;
                end else begin
                    if( sfence_vma_i == 1'b0 && tlbs[addr_i[17:12]][0] == 1'b1 && tlbs[addr_i[17:12]][34:21] == addr_i[31:18]) begin
                        tlb_hit <= 1'b1;
                        addr_hit <= { tlbs[addr_i[17:12]][20:1], addr_i[11:0] };
                    end
                    else begin
                        tlb_hit <= 1'b0;
                    end
                end
            end
            else begin
                addr_hit <= addr_i;
            end
        end
    end

endmodule
