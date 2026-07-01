//main module for testbench
module lab5(input clk, reset, output logic [3:0] OPCODE,
output logic [1:0] State,
output logic [7:0] PC, Alu_out, W_Reg,
output logic Cout, OF);
endmodule

//main module physical validation
module lab5_pv(input clk, SW0, SW1, KEY0, SW2, SW3, SW4,
output logic [6:0] SevSeg5, SevSeg4, SevSeg3, SevSeg2, SevSeg1, SevSeg0,
output logic LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7 );
endmodule