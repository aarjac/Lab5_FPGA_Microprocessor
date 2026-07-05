`timescale 1ns/1ps

//simulation 
//still need to add filelog
module lab5_testbench();
//inputs
logic clk, reset;
//outputs
logic Cout, OF;
logic [1:0] state;
logic [3:0] OPCODE;
logic [7:0] PC, ALU_out, W_Reg;
//for writing to filelog
//how do we get these values from the modules???
/*
logic [3:0] RA, RB, RD;
logic [15:0] IR;
*/
//filelog
integer filelog;
//RegFile writing - delete one finished testing
integer i, RegFilelog;
lab5 L1 (.clk(clk), .reset(reset), 
.OPCODE(OPCODE), .state(state), .PC(PC),
.ALU_out(ALU_out), .W_Reg(W_Reg), .Cout(Cout), .OF(OF));
//init clock
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end
//test
initial begin
    //init file log
    filelog = $fopen("C:/Users/aaron/Documents/FPGA/EEE333LABS/Lab5/lab5_filelogs/lab5_filelog.csv", "w");
    $fwrite(filelog, "PC, IR, OPCODE, RA, RB, RD, W_Reg, Cout, OF \n");
    //init processor
    reset = 1'b1; #10; reset = 1'b0; #10;
    repeat (81) begin
        #40;
    end
    $fclose(filelog);
    //write RegFile to filelog
    //for debugging remove once complete
    RegFilelog = $fopen("C:/Users/aaron/Documents/FPGA/EEE333LABS/Lab5/lab5_filelogs/RegFile_filelog.csv", "w");
    $fwrite(RegFilelog, "#, value \n");
    for (i = 0; i < 16; i++) begin
        $fwrite(RegFilelog, "%d, %b \n", i, L1.RegF1.RF[i]);
    end
    $fclose(RegFilelog);
    $stop;
end
//write results to filelog
always_ff @(posedge clk) begin
    if (reset)
        $fwrite(filelog, "reset \n");
    else if (state == 2'b10) begin
        $fwrite(filelog, "%b, %h, %b, %b, %b, %b, %b, %b, %b \n",
        PC, L1.ROM1.IR, OPCODE, L1.IREG1.RA, 
        L1.IREG1.RB, L1.IREG1.RD, 
        W_Reg, Cout, OF);
    end
end
endmodule
