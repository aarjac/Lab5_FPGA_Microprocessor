//D register
//instantiation temp of DReg 
// Dreg #() D# (.clk(), .reset(), .D(), .Q());
module DReg #(parameter N = 8)(input clk, reset,
input [(N-1):0] D, 
output logic [(N-1):0] Q);
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        Q <= {N{1'b0}};
    else 
        Q <= D;
end
endmodule

//4:1 MUX
//instatiation temp of MUX 
// MUX4to1 #(#) MUX# (.A(), .B(), .C(), .D(), .select(), .Y());
module MUX4to1 #(parameter N = 8)(input [(N-1):0] A, B, C, D,
input [1:0] select,
output logic [(N-1):0] Y);
always_comb begin
    //init
    Y = {N{1'b0}};
    case(select)
    2'b00 : Y = A;
    2'b01 : Y = B;
    2'b10 : Y = C;
    2'b11 : Y = D;
    default : Y = {N{1'bx}};
    endcase
end
endmodule

//instruction memory (ROM)
module ROM (input [7:0] PC, output logic [15:0] IR);
//mem variables
logic [15:0] mem [20:0];
//program
assign mem[0] = 16'h1000; assign mem[1] = 16'h1011; assign mem[2] = 16'h1002; assign mem[3] = 16'h10A3; assign mem[4] = 16'hD236;
assign mem[5] = 16'h2014; assign mem[6] = 16'h4100; assign mem[7] = 16'h4401; assign mem[8] = 16'h8022; assign mem[9] = 16'hE040;
assign mem[10] = 16'h4405; assign mem[11] = 16'h6536; assign mem[12] = 16'h5637; assign mem[13] = 16'h3538; assign mem[14] = 16'h4329;
assign mem[15] = 16'h709A; assign mem[16] = 16'h70AB; assign mem[17] = 16'hBB8C; assign mem[18] = 16'h9C1D; assign mem[19] = 16'hC0DF;
assign mem[20] = 16'hF000;
//assign instruction
assign IR = mem[PC];
endmodule

//instruction register
//instantiate D register
module InstructionReg #(parameter N = 16, M = 4)(input clk, reset,
input [(N-1):0] IR,
output logic [(M-1):0] OPCODE, RA, RB, RD);
//OPCODE DReg
Dreg #(M) D_OPCODE (.clk(clk), .reset(reset), .D(IR[15:12]), .Q(OPCODE));
//RA DReg
Dreg #(M) D_RA (.clk(clk), .reset(reset), .D(IR[11:8]), .Q(RA));
//RB DReg
Dreg #(M) D_RB (.clk(clk), .reset(reset), .D(IR[7:4]), .Q(RB));
//RD DReg
Dreg #(M) D_RD (.clk(clk), .reset(reset), .D(IR[3:0]), .Q(RD));
endmodule

//register file
//needs editing
//16 8-bit DReg
module RegFile(input reset, clk, input [3:0] OPCODE, RA, RB, RD, 
input [1:0] state, input [7:0] RF_data_in,
output logic [7:0] RF_data_out0, RF_data_out1);
//16 registers, 8 bits each
logic [7:0] RF [15:0];
//states
localparam IF = 2'b00, FD = 2'b01, EX = 2'b10, RWB = 2'b11;
//OPCODE checks
localparam CMPJ = 4'b1101, JMP = 4'b1110, HALT = 4'b1111;
integer i;
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin 
        RF_data_out0 <= 8'd0;
        RF_data_out1 <= 8'd0;
        for(i = 0; i < 16; i++)
            RF[i] <= 8'd0;
    end
    else begin
        RF_data_out0 <= RF[RA];
        RF_data_out1 <= RF[RB];
        if ((state == RWB) && 
        ((OPCODE != CMPJ) || (OPCODE != JMP) || (OPCODE != HALT))) 
            RF[RD] <= RF_data_in;
    end
end
endmodule

//controller
//implemented via FSM using DReg and MUX4to1
//might have to fix some things here
module ControlUnit (input clk, reset, input [3:0] OPCODE, RA, RB, RD,
input [7:0] PC,
output logic [1:0] state, 
output logic [3:0] ALU_control,
output logic MEM_write);
//states
localparam IF = 2'b00, FD = 2'b01, EX = 2'b10, RWB = 2'b11;
//OPCODE checks
localparam CMPJ = 4'b1101, JMP = 4'b1110, HALT = 4'b1111;
//local variables
logic [1:0] next_state;
logic [7:0] next_PC;
Dreg #(2) D1 (.clk(clk), .reset(reset), .D(next_state), 
.Q(state));
MUX4to1 #(2) MUX1 (.A(FD), .B(EX), .C(RWB), .D(IF), .select(state), 
.Y(next_state));
//determine next_state
always_comb begin
    //init values
    ALU_control = 4'b0000; next_PC = PC; MEM_write = 1'b0;
    case (state)
        EX : begin
            ALU_control = OPCODE;
            next_PC = PC;
        end
        RWB : begin
            //mabye change ALU_control value here
            ALU_control = OPCODE;
            MEM_write = 1'b1;
            case (OPCODE)
                CMPJ : begin
                    if (RA >= RB)
                        next_PC = PC + RD;
                    else
                        next_PC = PC;
                end
                JMP : next_PC = {RA,RB};
                HALT : next_PC = PC;
                default : next_PC = PC;
            endcase
        end
    endcase
end
endmodule

//ALU

//W register

//program counter

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