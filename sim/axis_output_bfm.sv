`timescale 1ns/1ps

// BFM para AXI4-Stream de saída do DUT.
// DUT = Manager.
// Este canal envia ciphertexts e shared secret K para o ambiente de teste.

interface axis_output_bfm #(
    parameter int unsigned TDATA_WIDTH = 32,
    parameter int unsigned CLK_FREQ_MHZ = 100
);
    localparam time CLK_PERIOD = (1_000.0 / CLK_FREQ_MHZ) * 1ns;

    logic ACLK;
    logic ARESETn;

    // Sinais produzidos pelo DUT (Manager).
    logic [TDATA_WIDTH-1:0] TDATA;
    logic                   TVALID;
    logic                   TLAST;

    // Sinal consumido pelo DUT.
    logic TREADY;

    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD / 2) ACLK = ~ACLK;
    end

    task automatic reset_assert(int unsigned cycles = 3);
        TREADY = 1'b0;
        ARESETn = 1'b0;
        repeat (cycles) @(posedge ACLK);
        @(negedge ACLK);
        ARESETn = 1'b1;
    endtask

    function automatic bit reset_is_asserted();
        return !ARESETn;
    endfunction

    // O ambiente controla TREADY; TDATA, TVALID e TLAST sao produzidos pelo DUT.
    task automatic set_ready(input logic ready);
        @(negedge ACLK);
        TREADY = ready;
    endtask
endinterface
