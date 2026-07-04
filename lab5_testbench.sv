`timescale 1ns/1ps

//simulation 
module lab5_testbench();
//inputs
logic clk, reset;
//outputs
logic Cout, OF;
logic [1:0] state;
logic [3:0] OPCODE;
logic [7:0] PC, ALU_out, W_Reg;
lab5 L1 (.clk(), .reset(), 
.OPCODE(), .state(), .PC(),
.ALU_out(), .W_Reg(), .Cout(), .OF());
initial begin
end
endmodule
