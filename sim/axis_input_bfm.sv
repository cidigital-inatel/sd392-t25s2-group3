`timescale 1ns/1ps

// BFM para AXI4-Stream de entrada do DUT.
// DUT = Subordinate.
// Este canal transporta seeds, public keys e ciphertexts enviados ao acelerador.
interface axis_input_bfm #(
    parameter int unsigned TDATA_WIDTH = 32,
    parameter int unsigned TUSER_WIDTH = 0,
    parameter int unsigned CLK_FREQ_MHZ = 100
);
    localparam time CLK_PERIOD = (1_000.0 / CLK_FREQ_MHZ) * 1ns;

    logic ACLK;
    logic ARESETn;

    logic [TDATA_WIDTH-1:0] TDATA;
    logic                   TVALID;
    logic                   TREADY;
    logic                   TLAST;
    logic [TUSER_WIDTH-1:0] TUSER;

    // Sinais opcionais, usados somente se a especificação do projeto exigir.
    logic [TDATA_WIDTH/8-1:0] TKEEP;
    logic [TDATA_WIDTH/8-1:0] TSTRB;

    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD / 2) ACLK = ~ACLK;
    end

    task automatic reset_assert(int unsigned cycles = 3);
        TDATA  = '0;
        TVALID = 1'b0;
        TLAST  = 1'b0;
        TUSER  = '0;
        TKEEP  = '0;
        TSTRB  = '0;
        TREADY = 1'b0;
        ARESETn = 1'b0;
        repeat (cycles) @(posedge ACLK);
        @(negedge ACLK);
        ARESETn = 1'b1;
    endtask

    function automatic bit reset_is_asserted();
        return !ARESETn;
    endfunction

    // Envia um beat de dados para o DUT.
    // A tarefa assume que o DUT já está pronto para aceitar dados.
    task automatic send_beat(input logic [TDATA_WIDTH-1:0] value,
                             input logic last = 1'b0,
                             input logic [TUSER_WIDTH-1:0] user = '0);
        TDATA  = value;
        TLAST  = last;
        TUSER  = user;
        TVALID = 1'b1;

        while (!(TVALID && TREADY)) @(posedge ACLK);
        @(negedge ACLK);
        TVALID = 1'b0;
        TLAST  = 1'b0;
        TUSER  = '0;
    endtask

    // Espera o DUT indicar que está pronto para receber o próximo beat.
    task automatic wait_for_ready();
        while (!TREADY) @(posedge ACLK);
    endtask

    // Forma simples de transmitir um pacote em múltiplos beats.
    task automatic send_packet(input logic [TDATA_WIDTH-1:0] data[],
                               input bit last_marker = 1'b1);
        int unsigned i;
        for (i = 0; i < data.size(); i++) begin
            if (i == (data.size() - 1))
                send_beat(data[i], last_marker);
            else
                send_beat(data[i], 1'b0);
        end
    endtask
endinterface
