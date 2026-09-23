`timescale 1ns/1ps
// BFM de exemplo - trocar apenas as lógicas de protocolo para novos BFMs
interface bfm #(parameter int DATA_WIDTH = 4, parameter int CLK_FREQ_MHZ = 100);
    localparam time CLK_PERIOD = (1_000.0 / CLK_FREQ_MHZ) * 1ns;
    logic clk;
    logic reset_n;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    // Geração do sinal de clock
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Reset síncrono com asserção (quantidade de ciclos em reset)
    task automatic assert_reset(int unsigned cycles = 3);
        data_in = '0;
        reset_n = 1'b0;
        repeat (cycles) @(posedge clk);
        @(negedge clk);
        reset_n = 1'b1;
    endtask

    // Checagem se o reset está concluído
    function automatic bit reset_is_asserted();
        return !reset_n;
    endfunction

    // LÓGICAS DE PROTOCOLO

    // Enviar um novo estímulo antes do próximo pulso de clock
    task automatic drive_word(logic [DATA_WIDTH-1:0] value);
        @(negedge clk);
        data_in <= value;
    endtask

    // Conversão de binário para código gray (apenas um exemplo de demonstração)
    function automatic logic [DATA_WIDTH-1:0] bin_to_gray(logic [DATA_WIDTH-1:0] value);
        return value ^ (value >> 1);
    endfunction
endinterface
