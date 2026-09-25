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
        TDATA  = '0;
        TVALID = 1'b0;
        TLAST  = 1'b0;
        TREADY = 1'b0;
        ARESETn = 1'b0;
        repeat (cycles) @(posedge ACLK);
        @(negedge ACLK);
        ARESETn = 1'b1;
    endtask

    function automatic bit reset_is_asserted();
        return !ARESETn;
    endfunction

    // Espera o ambiente aceitar o próximo beat.
    task automatic wait_for_accept();
        while (!TREADY) @(posedge ACLK);
    endtask

    // Emite um beat gerado pelo DUT.
    task automatic drive_beat(input logic [TDATA_WIDTH-1:0] value,
                              input logic last = 1'b0);
        TDATA  = value;
        TLAST  = last;
        TVALID = 1'b1;

        while (!(TVALID && TREADY)) @(posedge ACLK);
        @(negedge ACLK);
        TVALID = 1'b0;
        TLAST  = 1'b0;
    endtask

    // Emissão de um pacote em múltiplos beats.
    task automatic drive_packet(input logic [TDATA_WIDTH-1:0] data[],
                                input bit last_marker = 1'b1);
        int unsigned i;
        for (i = 0; i < data.size(); i++) begin
            if (i == (data.size() - 1))
                drive_beat(data[i], last_marker);
            else
                drive_beat(data[i], 1'b0);
        end
    endtask
endinterface
