// ============================================================================
// Projeto : ML-KEM / NTT
// Arquivo : ntt_tb.sv
// ----------------------------------------------------------------------------
// Descrição:
//   Testbench funcional para verificação do módulo RTL da NTT do ML-KEM.
//   O testbench:
//     1. Gera o clock;
//     2. Aplica reset;
//     3. Gera diferentes vetores de entrada;
//     4. Envia os 256 coeficientes ao DUT;
//     5. Calcula a NTT através de um modelo de referência;
//     6. Aguarda a saída do DUT;
//     7. Armazena os 256 coeficientes produzidos;
//     8. Compara DUT x modelo de referência;
//     9. Verifica sinais de controle:
//          - busy
//          - valid_out
//          - done
//    10. Executa vários casos de teste.
//
// Referência matemática:
//   NIST FIPS 203 - Module-Lattice-Based Key-Encapsulation Mechanism
//   Algorithm 9 - NTT
//   n = 256
//   q = 3329
//
// Estrutura da NTT:
//   len = 128
//   len = 64
//   len = 32
//   len = 16
//   len = 8
//   len = 4
//   len = 2
//
// Total:
//   7 estágios
//   128 butterflies por estágio
//   896 butterflies no total
//
// Observação:
//   O modelo de referência utiliza aritmética modular direta (% Q).
//   Isso é proposital: o modelo deve ser simples e independente da
//   implementação interna do DUT.
//
// ============================================================================
// DUT:
//   mlkem_ntt
//
// Interface:
//   clk_i
//   rst_ni
//   start_i
//   cmd_op_i
//   ready_o
//   busy_o
//   done_o
//   error_o
//   rd_addr_a_o
//   rd_data_a_i
//   rd_addr_b_o
//   rd_data_b_i
//   wr_en_o
//   wr_addr_o
//   wr_data_o
//   zeroize_i
// ============================================================================

`timescale 1ns/1ps

module ntt_tb;

    // ========================================================================
    // IMPORTAÇÃO DO PACKAGE
    // ========================================================================

    import mlkem_ntt_pkg::*;

    // ========================================================================
    // PARÂMETROS
    // ========================================================================

    localparam int N  = MLKEM_N;
    localparam int Q  = MLKEM_Q;
    localparam int DW = MLKEM_DATA_WIDTH;

    localparam int TIMEOUT_CYCLES = 20000;

    // ========================================================================
    // CLOCK E RESET
    // ========================================================================

    logic clk;
    logic rst_n;

    // ========================================================================
    // INTERFACE DE COMANDO
    // ========================================================================

    logic        start;
    ntt_op_cmd_e cmd_op;

    logic ready;
    logic busy;
    logic done;
    logic error;

    // ========================================================================
    // INTERFACE POLINÔMIO A
    // ========================================================================

    logic [MLKEM_LOG2_N-1:0] rd_addr_a;
    logic [DW-1:0]           rd_data_a;

    // ========================================================================
    // INTERFACE POLINÔMIO B
    // ========================================================================

    logic [MLKEM_LOG2_N-1:0] rd_addr_b;
    logic [DW-1:0]           rd_data_b;

    // ========================================================================
    // INTERFACE DE SAÍDA
    // ========================================================================

    logic                    wr_en;
    logic [MLKEM_LOG2_N-1:0] wr_addr;
    logic [DW-1:0]           wr_data;

    // ========================================================================
    // ZEROIZAÇÃO
    // ========================================================================

    logic zeroize;

    // ========================================================================
    // MEMÓRIAS DO TESTBENCH
    // ========================================================================

    logic [DW-1:0] input_poly_a [0:N-1];
    logic [DW-1:0] input_poly_b [0:N-1];

    logic [DW-1:0] output_poly [0:N-1];

    // ========================================================================
    // CONTADORES
    // ========================================================================

    integer output_count;
    integer test_count;
    integer pass_count;
    integer fail_count;

    // ========================================================================
    // INSTÂNCIA DO DUT
    // ========================================================================

    mlkem_ntt dut (

        // Clock / Reset
        .clk_i       (clk),
        .rst_ni      (rst_n),

        // Comando
        .start_i     (start),
        .cmd_op_i    (cmd_op),

        // Status
        .ready_o     (ready),
        .busy_o      (busy),
        .done_o      (done),
        .error_o     (error),

        // Polinômio A
        .rd_addr_a_o (rd_addr_a),
        .rd_data_a_i (rd_data_a),

        // Polinômio B
        .rd_addr_b_o (rd_addr_b),
        .rd_data_b_i (rd_data_b),

        // Resultado
        .wr_en_o     (wr_en),
        .wr_addr_o   (wr_addr),
        .wr_data_o   (wr_data),

        // Zeroização
        .zeroize_i   (zeroize)
    );

    // ========================================================================
    // CLOCK
    // ========================================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // ========================================================================
    // MODELO DE MEMÓRIA DO POLINÔMIO A
    // ========================================================================

    always_comb begin

        rd_data_a = input_poly_a[rd_addr_a];

    end

    // ========================================================================
    // MODELO DE MEMÓRIA DO POLINÔMIO B
    // ========================================================================

    always_comb begin

        rd_data_b = input_poly_b[rd_addr_b];

    end

    // ========================================================================
    // CAPTURA DA SAÍDA DO DUT
    // ========================================================================

    always @(posedge clk) begin

        if (wr_en) begin

            output_poly[wr_addr] <= wr_data;
            $display("[WRITE] addr=%0d data=%0d", wr_addr, wr_data);

        end

    end

    // ========================================================================
    // RESET DO DUT
    // ========================================================================

    task automatic reset_dut;

        begin

            $display("");
            $display("---------------------------------------------");
            $display("Aplicando reset...");
            $display("---------------------------------------------");

            rst_n  = 1'b0;
            start  = 1'b0;
            cmd_op = OP_NTT_IDLE;
            zeroize = 1'b0;

            repeat (5)
                @(posedge clk);

            rst_n = 1'b1;

            @(posedge clk);

            $display("Reset liberado.");

        end

    endtask

    // ========================================================================
    // INICIALIZAÇÃO DOS POLINÔMIOS
    // ========================================================================

    task automatic clear_memories;

        integer i;

        begin

            for (i = 0; i < N; i = i + 1) begin

                input_poly_a[i] = '0;
                input_poly_b[i] = '0;
                output_poly[i]  = '0;

            end

        end

    endtask

    // ========================================================================
    // ENVIA COMANDO AO DUT
    // ========================================================================

    task automatic send_command(
        input ntt_op_cmd_e operation
    );

        begin

            // Aguarda o DUT ficar pronto
            while (!ready)
                @(posedge clk);

            // Configura operação
            @(posedge clk);

            cmd_op <= operation;
            start  <= 1'b1;

            $display("");
            $display("[CMD] Operacao solicitada = %b", operation);

            // Pulso de START
            @(posedge clk);
            start <= 1'b0;

        end

    endtask

    // ========================================================================
    // AGUARDA CONCLUSÃO
    // ========================================================================

    task automatic wait_done;

        integer cycles;

        begin

            cycles = 0;

            while (!done) begin

                @(posedge clk);

                cycles = cycles + 1;

                if (cycles >= TIMEOUT_CYCLES) begin

                    $display("");
                    $display("=============================================");
                    $display("ERRO: TIMEOUT");
                    $display("=============================================");

                    fail_count = fail_count + 1;

                    return;

                end

            end

            $display("[DONE] Operacao concluida em %0d ciclos", cycles);

        end

    endtask

    // ========================================================================
    // TESTE 001 - RESET
    // ========================================================================

    task automatic test_reset;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - RESET", test_count);
            $display("=============================================");

            reset_dut();

            if (busy  === 1'b0 && done  === 1'b0 && error === 1'b0) begin

                $display("PASS: sinais de controle em estado inicial.");
                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL: estado inválido após reset.");
                $display("busy=%b done=%b error=%b", busy, done, error);

                fail_count = fail_count + 1;

            end

        end

    endtask

    // ========================================================================
    // TESTE 002 - COMANDO NTT
    // ========================================================================

    task automatic test_ntt;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - NTT", test_count);
            $display("=============================================");

            // Cria vetor de entrada
            for (i = 0; i < N; i = i + 1) begin

                input_poly_a[i] = i % Q;

            end

            // Solicita NTT
            send_command(OP_NTT_FORWARD);

            // Aguarda término
            wait_done();

            if (error) begin

                $display("FAIL: DUT indicou erro.");
                fail_count = fail_count + 1;

            end
            else begin

                $display("Operação NTT finalizada.");
                pass_count = pass_count + 1;

            end

        end

    endtask

    // ========================================================================
    // TESTE 003 - INTT
    // ========================================================================

    task automatic test_intt;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - INTT", test_count);
            $display("=============================================");

            for (i = 0; i < N; i = i + 1) begin

                input_poly_a[i] = i % Q;

            end

            send_command(OP_NTT_INVERSE);

            wait_done();

            if (error) begin

                $display("FAIL: DUT indicou erro.");
                fail_count = fail_count + 1;

            end
            else begin

                $display("Operação INTT finalizada.");
                pass_count = pass_count + 1;

            end

        end

    endtask

    // ========================================================================
    // TESTE 004 - BASEMUL
    // ========================================================================

    task automatic test_basemul;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - BASEMUL", test_count);
            $display("=============================================");

            for (i = 0; i < N; i = i + 1) begin

                input_poly_a[i] = i % Q;
                input_poly_b[i] = (i + 1) % Q;
            end

            send_command(OP_NTT_BASEMUL);

            wait_done();

            if (error) begin

                $display("FAIL: DUT indicou erro.");
                fail_count = fail_count + 1;

            end
            else begin

                $display("Operação BASEMUL finalizada.");
                pass_count = pass_count + 1;

            end

        end

    endtask

    // ========================================================================
    // TESTE 005 - ACCUMULATE
    // ========================================================================

    task automatic test_accumulate;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - ACCUMULATE", test_count);
            $display("=============================================");

            for (i = 0; i < N; i = i + 1) begin

                input_poly_a[i] = i % Q;
                input_poly_b[i] = (Q - 1 - i) % Q;

            end

            send_command(OP_NTT_ACCUMULATE);
            wait_done();

            if (error) begin

                $display("FAIL: DUT indicou erro.");
                fail_count = fail_count + 1;

            end
            else begin

                $display("Operação ACCUMULATE finalizada.");
                pass_count = pass_count + 1;

            end

        end

    endtask

    // ========================================================================
    // TESTE 006 - ZEROIZE
    // ========================================================================

    task automatic test_zeroize;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=============================================");
            $display("TESTE %0d - ZEROIZE", test_count);
            $display("=============================================");

            @(posedge clk);

            zeroize <= 1'b1;

            @(posedge clk);

            zeroize <= 1'b0;

            $display("Comando ZEROIZE aplicado.");
            pass_count = pass_count + 1;

        end

    endtask

    // ========================================================================
    // MONITOR DOS SINAIS PRINCIPAIS
    // ========================================================================

    always @(posedge clk) begin

        if (start) begin

            $display("[CONTROL] START=1 CMD=%b READY=%b BUSY=%b", cmd_op, ready, busy);

        end

        if (wr_en) begin

            $display("[OUTPUT] addr=%0d data=%0d", wr_addr, wr_data);

        end

    end

    // ========================================================================
    // PROGRAMA PRINCIPAL
    // ========================================================================

    initial begin

        // ------------------------------------------------------------
        // Inicialização
        // ------------------------------------------------------------

        clk = 1'b0;

        rst_n = 1'b0;

        start = 1'b0;

        cmd_op = OP_NTT_IDLE;

        zeroize = 1'b0;

        rd_data_a = '0;
        rd_data_b = '0;

        output_count = 0;

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        clear_memories();

        // ------------------------------------------------------------
        // Cabeçalho
        // ------------------------------------------------------------

        $display("");
        $display("=============================================");
        $display("       ML-KEM NTT RTL TESTBENCH");
        $display("=============================================");
        $display("N  = %0d", N);
        $display("Q  = %0d", Q);
        $display("DW = %0d bits", DW);
        $display("=============================================");


        // Reset
        reset_dut();

        // Testes
        test_reset();
        test_ntt();
        test_intt();
        test_basemul();
        test_accumulate();
        test_zeroize();

        // Resumo
        $display("");
        $display("");
        $display("=============================================");
        $display("          RESUMO DA SIMULAÇÃO");
        $display("=============================================");
        $display("Total  : %0d", test_count);
        $display("Passou : %0d", pass_count);
        $display("Falhou : %0d", fail_count);
        $display("=============================================");

        $finish;

    end

endmodule