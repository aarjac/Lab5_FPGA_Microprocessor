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
lab5 L1 (.clk(clk), .reset(reset), 
.OPCODE(OPCODE), .state(state), .PC(PC),
.ALU_out(ALU_out), .W_Reg(W_Reg), .Cout(Cout), .OF(OF));
//init clock
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end
initial begin
    //init processor
    reset = 1'b1; #10; reset = 1'b0; #10;
    repeat (12) begin
        #5;
    end
    $stop;
end
endmodule
