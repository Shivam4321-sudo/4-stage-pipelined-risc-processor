// ============================================================
//  Testbench — EX Stage (ALU) Unit Test
//  Author : Shivam Sharma | Dec 2025
// ============================================================
`timescale 1ns / 1ps

module tb_ex_stage;

    reg  [3:0]  alu_op;
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    wire [31:0] result;
    wire        zero;

    integer pass_count = 0;
    integer fail_count = 0;

    ex_stage dut (
        .alu_op    (alu_op),
        .operand_a (operand_a),
        .operand_b (operand_b),
        .result    (result),
        .zero      (zero)
    );

    task check;
        input [31:0] expected;
        input [63:0] test_name; // just a label
        begin
            #2;
            if (result === expected) begin
                $display("PASS [%s]: result=%0d", test_name, result);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [%s]: got=%0d expected=%0d", test_name, result, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== ALU Unit Tests ===");

        // ADD
        alu_op=4'b0000; operand_a=32'd10; operand_b=32'd20; check(32'd30, "ADD");

        // SUB
        alu_op=4'b0001; operand_a=32'd50; operand_b=32'd20; check(32'd30, "SUB");

        // AND
        alu_op=4'b0010; operand_a=32'hFF; operand_b=32'h0F; check(32'h0F, "AND");

        // OR
        alu_op=4'b0011; operand_a=32'hF0; operand_b=32'h0F; check(32'hFF, "OR");

        // SLT — true
        alu_op=4'b0100; operand_a=32'd3;  operand_b=32'd5;  check(32'd1,  "SLT_T");

        // SLT — false
        alu_op=4'b0100; operand_a=32'd7;  operand_b=32'd5;  check(32'd0,  "SLT_F");

        // XOR
        alu_op=4'b0101; operand_a=32'hAA; operand_b=32'h55; check(32'hFF, "XOR");

        // SLL
        alu_op=4'b0110; operand_a=32'd1;  operand_b=32'd4;  check(32'd16, "SLL");

        // SRL
        alu_op=4'b0111; operand_a=32'd32; operand_b=32'd2;  check(32'd8,  "SRL");

        // NOR
        alu_op=4'b1000; operand_a=32'h0;  operand_b=32'h0;  check(32'hFFFF_FFFF, "NOR");

        // Zero flag test
        alu_op=4'b0001; operand_a=32'd5; operand_b=32'd5;
        #2;
        if (zero === 1'b1)
            $display("PASS [ZERO_FLAG]: zero=1 when result=0");
        else
            $display("FAIL [ZERO_FLAG]: zero=%b", zero);

        $display("=== Results: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        $finish;
    end

endmodule
