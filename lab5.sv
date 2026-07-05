//multiply operation
//multiply instantiation temp
// multiply (.A(), .B(), .R(), .Cout(), .OF());
module multiply (input signed [7:0] A, B, 
output logic [7:0] R,
output logic Cout, OF);
logic [7:0] Rtemp;
wire signerror;
assign {Rtemp, R} = A * B;
assign signerror = (A[7] ^ B[7]) ^ R[7];
assign Cout = (Rtemp == 8'd0 | Rtemp == - 8'd1) ? 1'b0 : 1'b1;
assign OF = signerror | Cout;
endmodule

//D register
//DReg instantiation temp 
// DReg #() D# (.clk(), .reset(), .enable(), .D(), .Q());
module DReg #(parameter N = 8)(input clk, reset, enable,
input [(N-1):0] D, 
output logic [(N-1):0] Q);
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        Q <= {N{1'b0}};
    else if (enable) 
        Q <= D;
end
endmodule

//4:1 MUX
//MUX instantiation temp 
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
//ROM instantiation temp 
//ROM ROM#(.PC(), .IR());
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
//IR instantiation temp 
//InstructionReg #(16, 4) IREG1 (.clk(), .reset(), .IR(), .OPCODE(), .RA(), .RB(), .RD());
module InstructionReg #(parameter N = 16, M = 4)(input clk, reset,
input [(N-1):0] IR,
output logic [(M-1):0] OPCODE, RA, RB, RD);
//OPCODE DReg
DReg #(M) D_OPCODE (.clk(clk), .reset(reset), .enable(1'b1), .D(IR[15:12]), 
.Q(OPCODE));
//RA DReg
DReg #(M) D_RA (.clk(clk), .reset(reset), .enable(1'b1), .D(IR[11:8]), 
.Q(RA));
//RB DReg
DReg #(M) D_RB (.clk(clk), .reset(reset), .enable(1'b1), .D(IR[7:4]), 
.Q(RB));
//RD DReg
DReg #(M) D_RD (.clk(clk), .reset(reset), .enable(1'b1), .D(IR[3:0]), 
.Q(RD));
endmodule

//register file
//RegFile instantiation temp 
//RegFile RegF#(.reset(), .clk(), .OPCODE(), .RA(), .RB(), .RD(), .state(), .RF_data_in(), .RF_data_out0(), .RF_data_out1());
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
//ControlUnit instantiation temp 
//ControlUnit CU1 (.clk(), .reset(), .OPCODE(), .RA(), .RB(), .RD(), .A(), .B(), .PC(), .state(), .ALU_control), .MEM_write(), .next_PC());
module ControlUnit (input clk, reset, input [3:0] OPCODE, RA, RB, RD,
input [7:0] A, B, PC,
output logic [1:0] state, 
output logic [3:0] ALU_control,
output logic MEM_write, 
output logic [7:0] next_PC);
//states
localparam IF = 2'b00, FD = 2'b01, EX = 2'b10, RWB = 2'b11;
//OPCODE checks
localparam LDI = 4'b0001, ADD = 4'b0010, SUB = 4'b0011, ADI = 4'b0100,
MUL = 4'b0101, DIV = 4'b0110, DEC = 4'b0111, INC = 4'b1000, 
NOR = 4'b1001, NAND = 4'b1010, XOR = 4'b1011, COMP = 4'b1100,
CMPJ = 4'b1101, JMP = 4'b1110, HALT = 4'b1111;
//local variables
logic [1:0] next_state;
DReg #(2) D1 (.clk(clk), .reset(reset), .enable(1'b1), .D(next_state), 
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
            MEM_write = 1'b1;
        end
        RWB : begin
            //mabye change ALU_control value here
            ALU_control = OPCODE;
            MEM_write = 1'b0;   
            if (OPCODE == CMPJ) begin
                if (A >= B)
                    next_PC = PC + {4'b0000,RD};
                else
                    next_PC = PC + 8'd1;
            end
            else if (OPCODE == JMP) 
                next_PC = {RA,RB};
            else if (OPCODE == HALT)
                next_PC = PC;
            else 
                next_PC = PC + 8'd1; 
        end
        default : begin
            ALU_control = 4'b0000; 
            next_PC = PC; MEM_write = 1'b0;
        end
    endcase
end
endmodule

//ALU
//operates combinatorially
//non-arithmetic operations Cout = 1'b0, OF = 1'b0
//ALU instantiation temp 
//ALU ALU1 (.RA(), .RB(), .A(), .B(), .ALU_control(), .ALU_out(), .Cout(), .OF());
module ALU (input [3:0] RA, RB, input [7:0] A, B,
input [3:0] ALU_control,
output logic [7:0] ALU_out, 
output logic Cout, OF);
//operations
localparam LDI = 4'b0001, ADD = 4'b0010, SUB = 4'b0011, ADI = 4'b0100,
MUL = 4'b0101, DIV = 4'b0110, DEC = 4'b0111, INC = 4'b1000, 
NOR = 4'b1001, NAND = 4'b1010, XOR = 4'b1011, COMP = 4'b1100,
CMPJ = 4'b1101, JMP = 4'b1110, HALT = 4'b1111;
//local variables
logic Cout_multi, OF_multi;
logic [7:0] AB_product;
//multiply module
multiply MULTI1(.A(A), .B(B), 
.R(AB_product), .Cout(Cout_multi), .OF(OF_multi));
always_comb begin
    //init values
    ALU_out = 7'd0; Cout = 1'b0; OF = 1'b0;
    case (ALU_control)
        LDI : begin
            ALU_out = {RA, RB}; Cout = 1'b0; OF = 1'b0;
        end
        ADD : begin
            {Cout,ALU_out} = {A[7], A} + {B[7], B};
            OF = ~(A[7]^B[7]) & (A[7]^ALU_out[7]); 
        end
        SUB : begin
            {Cout,ALU_out} = {A[7], A} - {B[7], B};
            OF = (A[7]^B[7]) & (A[7]^ALU_out[7]); 
        end
        ADI : begin
            ALU_out =  A + {4'b0000, RB}; 
            Cout = 1'b0; OF = 1'b0;
        end
        MUL : begin
            ALU_out = AB_product;
            Cout = Cout_multi; OF = OF_multi;
        end
        DIV : begin
            {Cout, ALU_out} = {A[7], A} / {B[7], B};
            OF = 1'b0;
        end
        DEC : begin
            ALU_out = B - 8'd1;
            OF = (A[7]^B[7]) & (A[7]^ALU_out[7]); 
        end
        INC : begin
            ALU_out = B + 8'd1;
            OF = ~(A[7]^B[7]) & (A[7]^ALU_out[7]); 
        end
        NOR : begin
            ALU_out = ~(A | B);
            Cout = 1'b0; OF = 1'b0;
        end
        NAND : begin
            ALU_out = ~(A && B);
            Cout = 1'b0; OF = 1'b0;
        end
        XOR : begin
            ALU_out = A ^ B;
            Cout = 1'b0; OF = 1'b0;
        end
        COMP : begin
            ALU_out = ~B;
            Cout = 1'b0; OF = 1'b0;
        end
        default : begin 
            ALU_out = 7'd0; Cout = 1'b0; OF = 1'b0;
        end
    endcase
end
endmodule

//W register
//WReg instantiation temp 
//WReg WR1 (.clk(), .reset(), .enable(), .data_in(), .data_out());
module WReg (input clk, reset, enable,
input [7:0] data_in,
output logic [7:0] data_out);
DReg #(8) D1 (.clk(clk), .reset(reset), .enable(enable), .D(data_in), 
.Q(data_out));
endmodule

//program counter
//PC instantiation temp 
//ProgramCounter PC1 (.clk(), .reset(), .enable(), .next_PC(), .count());
module ProgramCounter (input clk, reset, enable,
input [7:0] next_PC,
output logic [7:0] count);
always_ff @(posedge clk or posedge reset) begin 
    if (reset)
        count <= 8'd0;
    else if (enable)
        count <= next_PC;
end
endmodule

//main module for testbench
//lab5 instantiation temp
//lab5 LAB1 (.clk(), .reset(), .OPCODE(), .state(), .PC(), .ALU_out, .W_Reg(), .Cout(), .OF() )
module lab5(input clk, reset, output logic [3:0] OPCODE,
output logic [1:0] state,
output logic [7:0] PC, ALU_out, W_Reg,
output logic Cout, OF);
//local constants
//local variables
logic MEM_write; //write enable for WReg
logic [3:0] ALU_control; //OPCODE = ALU_control passed to ALU
logic [3:0] RA, RB, RD;
logic [7:0] A, B; //contents of RA and RB in RegFile
logic [7:0] next_PC;
logic [7:0] data_out; //value output from WReg
logic [15:0] IR;
//Program Counter
//input next_PC to update the program count PC
ProgramCounter PC1 (.clk(clk), .reset(reset), .enable(1'b1), 
.next_PC(next_PC), 
.count(PC));
//Instruction Memory
//input counter points to instruction address
ROM ROM1 (.PC(PC), 
.IR(IR));
//Instruction Register
//holds the current 16-bit instruction
//decodes IR into OPCODE, RA, RB, and RD
InstructionReg #(16, 4) IREG1 (.clk(clk), .reset(reset), 
.IR(IR), 
.OPCODE(OPCODE), .RA(RA), .RB(RB), .RD(RD));
//Controller
//Determines state
//Passes OPCODE = ALU_control to ALU
//Enables W Reg with MEM_write if in RWB
//Determines next_PC based on state
ControlUnit CU1 (.clk(clk), .reset(reset), .OPCODE(OPCODE), 
.RA(RA), .RB(RB), .RD(RD), .A(A), .B(B), .PC(PC), 
.state(state), .ALU_control(ALU_control), 
.MEM_write(MEM_write), .next_PC(next_PC));
//Register File
//holds data_out value from W Reg in memoryn, stores at RF[RD]
//accesses values at RF[RA] and RF[RB] and passes to ALU
RegFile RegF1 (.reset(reset), .clk(clk), 
.OPCODE(OPCODE), .RA(RA), .RB(RB), .RD(RD), .state(state), 
.RF_data_in(data_out), 
.RF_data_out0(A), .RF_data_out1(B));
//ALU
//operates on RA, RB, A, or B depending on OPCODE = ALU_control
//output results to WReg
ALU ALU1 (.RA(RA), .RB(RB), .A(A), .B(B), .ALU_control(ALU_control), 
.ALU_out(ALU_out), .Cout(Cout), .OF(OF));
//W Register
WReg WR1 (.clk(clk), .reset(reset), .enable(MEM_write), .data_in(ALU_out), 
.data_out(data_out));
assign W_Reg = data_out;
endmodule

//Master clock from 50MHz to 1000Hz
//master clock - sets master clock domain
module master_clock #(parameter frequency = (50000000/(1000*2)), N = 16)
(input clk, reset, enable, 
output logic clk_1000Hz);
//local variables
logic next_clock;
logic [(N-1):0] next_count, count;
//sync counter
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= {N{1'b0}};
        clk_1000Hz <= 1'b0;
    end
    else if (enable) begin
        count <= next_count;
        clk_1000Hz <= next_clock;
    end
end
always_comb begin
    //init values
    next_clock = clk_1000Hz; 
    next_count = count;   
    if (count == (frequency-1)) begin
        next_clock = ~clk_1000Hz;
        next_count = {N{1'b0}};
    end
    else begin
        next_count = count + {{(N-1){1'b0}}, 1'b1};
    end
end
endmodule

//Hex display conversion
module ASCII27Seg(input [7:0] AsciiCode, output logic [6:0] HexSeg);
    always_comb begin 
        HexSeg = 7'd0;  //initialization of variable HexSeg, turn all segments ON
        case(AsciiCode)
            //uppercase and lowercase letters
            //A
            8'h41 : HexSeg[3] = 1'b1;
            //a
            8'h61 : HexSeg[3] = 1'b1;
            //B
            8'h42 : begin 
                HexSeg[0] = 1'b1; HexSeg[1] = 1'b1;
            end
            //b
            8'h62 : begin 
                HexSeg[0] = 1'b1; HexSeg[1] = 1'b1;
            end
            //C
            8'h43 : begin
                HexSeg[1] = 1'b1; HexSeg[2] = 1'b1; HexSeg[6] = 1'b1;
            end
            //c
            8'h63 : begin
                HexSeg[1] = 1'b1; HexSeg[2] = 1'b1; HexSeg[6] = 1'b1;
            end
            //D
            8'h44 : begin
                HexSeg [0] = 1'b1; HexSeg[5] = 1'b1;
            end
            //d
            8'h64 : begin
                HexSeg [0] = 1'b1; HexSeg[5] = 1'b1;
            end
            //E
            8'h45 : begin
                HexSeg [1] = 1'b1; HexSeg[2] = 1'b1;
            end
            //e
            8'h65 : begin
                HexSeg [1] = 1'b1; HexSeg[2] = 1'b1;
            end
            //F
            8'h46 : begin
                HexSeg [1] = 1'b1; HexSeg[2] = 1'b1; HexSeg[3] = 1'b1;
            end
            //f
            8'h66 : begin
                HexSeg [1] = 1'b1; HexSeg[2] = 1'b1; HexSeg[3] = 1'b1;
            end
            //G
            8'h47 : begin
                HexSeg [4] = 1'b1;
            end
            //g
            8'h67 : begin
                HexSeg [4] = 1'b1;
            end
            //H
            8'h48 : begin
                HexSeg [0] = 1'b1; HexSeg [3]= 1'b1;
            end
            //h
            8'h68 : begin
                HexSeg [0] = 1'b1; HexSeg [3]= 1'b1;
            end
            //I
            8'h49 : begin
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [3] = 1'b1; HexSeg [6] = 1'b1;
            end
            //i
            8'h69 : begin
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [3] = 1'b1; HexSeg [6] = 1'b1;
            end
            //J
            8'h4A : begin
                HexSeg [0] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //j
            8'h6A : begin
                HexSeg [0] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //K
            8'h4B : begin
                HexSeg [0] = 1'b1; HexSeg [3]= 1'b1;
            end
            //k
            8'h6B : begin
                HexSeg [0] = 1'b1; HexSeg [3]= 1'b1;
            end
            //L
            8'h4C : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [6] = 1'b1;
            end
            //l
            8'h6C : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [6] = 1'b1;
            end
            //M
            8'h4D: begin 
                HexSeg [1] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //m
            8'h6D: begin 
                HexSeg [1] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //N
            8'h4E: begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1;
            end
            //n
            8'h6E: begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1;
            end
            //O
            8'h4F : begin 
                HexSeg [6] = 1'b1;
            end
            //o
            8'h6F : begin 
                HexSeg [6] = 1'b1;
            end
            //P
            8'h50 : begin 
                HexSeg [2] = 1'b1; HexSeg [3] = 1'b1;
            end
                //p
            8'h70 : begin 
                HexSeg [2] = 1'b1; HexSeg [3] = 1'b1;
            end
            //Q
            8'h51 : begin
                HexSeg [3] = 1'b1; HexSeg [4] = 1'b1;
            end
            //q
            8'h71 : begin
                HexSeg [3] = 1'b1; HexSeg [4] = 1'b1;
            end
            //R
            8'h52 : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1;
            end
            //r
            8'h72 : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1; HexSeg [3] = 1'b1; HexSeg [5] = 1'b1;
            end
            //S
            8'h53 : begin
                HexSeg [1] = 1'b1; HexSeg [4] = 1'b1;
            end
            //s
            8'h73 : begin
                HexSeg [1] = 1'b1; HexSeg [4] = 1'b1;
            end
            //T
            8'h54 : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1;
            end
            //t
            8'h74 : begin 
                HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [2] = 1'b1;
            end
            //U
            8'h55 : begin 
                HexSeg [0] = 1'b1; HexSeg [6] = 1'b1;
            end
            //u
            8'h75 : begin 
                HexSeg [0] = 1'b1; HexSeg [6] = 1'b1;
            end
            //V
            8'h56 : begin 
            HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end 
            //V
            8'h76 : begin 
            HexSeg [0] = 1'b1; HexSeg [1] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end 
            //W
            8'h57 : begin 
                HexSeg [0] = 1'b1; HexSeg [2] = 1'b1; HexSeg [4] = 1'b1; HexSeg [6] = 1'b1;
            end
            //w
            8'h77 : begin 
                HexSeg [0] = 1'b1; HexSeg [2] = 1'b1; HexSeg [4] = 1'b1; HexSeg [6] = 1'b1;
            end
            //X
            8'h58 : begin 
                HexSeg [0] = 1'b1; HexSeg [3]= 1'b1;
            end
            //x
            8'h78 : begin 
                HexSeg [0] = 1'b1; HexSeg [3]= 1;
            end
            //Y
            8'h59 : begin 
                HexSeg [0] = 1'b1; HexSeg [4]= 1'b1;
            end
            //y
            8'h79 : begin 
                HexSeg [0] = 1'b1; HexSeg [4]= 1'b1;
            end
            //Z
            8'h5A : begin 
                HexSeg [2] = 1'b1; HexSeg [5]= 1'b1;
            end
            //z
            8'h7A : begin 
                HexSeg [2] = 1'b1; HexSeg [5]= 1'b1;
            end
            //numbers 0-9
            //0
            8'h30 : begin 
                HexSeg [6] = 1'b1;
            end
            //1
            8'h31 : begin 
                HexSeg [0] = 1'b1; HexSeg [3] = 1'b1; HexSeg [4] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //2
            8'h32 : begin 
                HexSeg [2] = 1'b1; HexSeg [5] = 1'b1;
            end
            //3
            8'h33 : begin 
                HexSeg [4] = 1'b1; HexSeg [5] = 1'b1;
            end
            //4
            8'h34 : begin 
                HexSeg [0] = 1'b1; HexSeg [3] = 1'b1; HexSeg [4] = 1'b1;
            end
            //5
            8'h35 : begin 
                HexSeg [1] = 1'b1; HexSeg [4] = 1'b1;
            end    
            //6
            8'h36 : begin 
                HexSeg [1] = 1'b1;
            end
            //7
            8'h37 : begin 
                HexSeg [3] = 1'b1; HexSeg [4] = 1'b1; HexSeg [5] = 1'b1; HexSeg [6] = 1'b1;
            end
            //8
            8'h38 : begin 
                //all segments ON
            end
            //9
            8'h39 : begin 
                HexSeg [4] = 1'b1;
            end
            default : HexSeg = 8'b11111111;  //defualt of variable HexSeg, all segments OFF
        endcase
    end 
endmodule

//7-seg display module
module HexCodes(input [2:0] display_mode, input [7:0] last_name [5:0], input [7:0] PC, W_Reg, ALU_out, 
input [3:0] OPCODE,
output logic [6:0] HexSeg5 ,HexSeg4, HexSeg3, HexSeg2, HexSeg1, HexSeg0);
//local variables
logic [7:0] hrs_tens, hrs_ones, min_tens, min_ones, sec_tens, sec_ones;
logic [7:0] Time [5:0];
Bi27Seg SevH5(Time[5], HexSeg5);
Bi27Seg SevH4(Time[4], HexSeg4);
Bi27Seg SevH3(Time[3], HexSeg3);
Bi27Seg SevH2(Time[2], HexSeg2);
Bi27Seg SevH1(Time[1], HexSeg1);
Bi27Seg SevH0(Time[0], HexSeg0);
//sets hex display position
always_comb begin   
    Time[5] = hrs_tens;
    Time[4] = hrs_ones;
    Time[3] = min_tens;
    Time[2] = min_ones;
    Time[1] = sec_tens;
    Time[0] = sec_ones;
end 
//gets time digits
always_comb begin
    hrs_tens = hrs / 8'd10;
    hrs_ones = hrs % 8'd10;
    min_tens = min / 8'd10;
    min_ones = min % 8'd10;
    sec_tens = sec / 8'd10;
    sec_ones = sec % 8'd10;
end
endmodule

//main module physical validation
//need HEX display code
//SW1 and KEY0 single-step mode
module lab5_pv(input clk, SW0, SW1, KEY0, SW2, SW3, SW4,
output logic [6:0] SevSeg5, SevSeg4, SevSeg3, SevSeg2, SevSeg1, SevSeg0,
output logic LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7 );
//local variables
logic KEY0_clk;
logic clk_1000Hz;
logic main_clk;
logic [2:0] display_mode;
logic [7:0] PC;
//freq divide 50MHz fpga clock to 1000Hz 
master_clock MC1 (.clk(clk), .reset(SW0), .enable(),
.clk_1000Hz(clk_1000Hz));
//microprocessor module
lab5 LAB1 (.clk(main_clk), .reset(SW0), 
.OPCODE(), .state(), .PC(PC), .ALU_out(), .W_Reg(), .Cout(), .OF() );
//for display mode
always_comb begin
end
assign KEY0_clk = KEY0; //for single-step mode
assign main_clk = (SW1) ? KEY0_clk : clk_1000Hz; //for single-step mode
assign display_mode = {SW4, SW3, SW2}; 
assign {LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0} = PC;  
endmodule