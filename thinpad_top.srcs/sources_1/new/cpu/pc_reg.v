`include "../defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    output reg[`InstAddrBus] pc,
    output reg ce,

	input wire branch_flag_i,
    input wire[`RegBus] branch_target_address_i,
	input wire virtual_pause_flag,
	input wire flush,
	input wire[`RegBus] new_pc

);

	always @ (posedge clk) begin
		if ( rst == `RstEnable || ce == `ChipDisable) begin
			pc <= `StartPC;
		end else begin
			if(flush == 1'b1) begin //此时表示异常发生
				pc <= new_pc;
			end else if(stall[0] == `NoStop) begin
				pc <= pc + 4'h4;
			end else if(stall == 6'b000011) begin
				if (branch_flag_i == `Branch) begin
					pc <= branch_target_address_i; 
				end else if(virtual_pause_flag) begin
					// 此时不更新PC，即PC值不发生变化
				end else begin
					pc <= pc + 4'h4;
				end
			end
		end
	end
	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule
