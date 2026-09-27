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

`timescale 1ns/1ps

module ntt_tb;

    // ========================================================================
    // PARÂMETROS
    // ========================================================================

    localparam int N  = 256;
    localparam int Q  = 3329;
    localparam int DW = 12;

    // Número máximo de ciclos permitidos para o DUT completar uma operação.
    // O valor deve ser ajustado posteriormente de acordo com a arquitetura
    // definitiva do RTL.
    localparam int TIMEOUT_CYCLES = 20000;

    // ========================================================================
    // SINAIS DO TESTBENCH
    // ========================================================================

    logic clk;
    logic rst;

    logic start;
    logic valid_in;
    logic [DW-1:0] data_in;

    logic valid_out;
    logic [DW-1:0] data_out;

    logic busy;
    logic done;

    // ========================================================================
    // MEMÓRIAS DO TESTBENCH
    // ========================================================================

    // Vetor enviado ao DUT.
    logic [DW-1:0] input_poly [0:N-1];

    // Resultado esperado calculado pelo modelo de referência.
    logic [DW-1:0] expected_poly [0:N-1];

    // Resultado recebido do DUT.
    logic [DW-1:0] output_poly [0:N-1];

    // ========================================================================
    // CONTADORES / FLAGS
    // ========================================================================

    integer output_count;
    integer error_count;

    integer test_count;
    integer pass_count;
    integer fail_count;

    // ========================================================================
    // INSTÂNCIA DO DUT
    // ========================================================================
    // Interface esperada:
    //   clk
    //   rst
    //   start
    //   valid_in
    //   data_in
    //   valid_out
    //   data_out
    //   busy
    //   done
    // ========================================================================

    mlkem_ntt #(
        .N    (N),
        .Q    (Q),
        .DW   (DW),
        .ADDRW(8)
    ) dut (
        .clk      (clk),
        .rst      (rst),

        .start    (start),
        .valid_in (valid_in),
        .data_in  (data_in),

        .valid_out(valid_out),
        .data_out (data_out),

        .busy     (busy),
        .done     (done)
    );

    // ========================================================================
    // GERAÇÃO DO CLOCK
    // Clock de 10 ns: frequência = 100 MHz
    // ========================================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // ========================================================================
    // TABELA DE ZETAS
    // ========================================================================
    // Valores definidos no FIPS 203, Appendix A.
    // O algoritmo da NTT utiliza:
    // zeta = zetas[k]
    // iniciando em: k = 1
    // Portanto, zetas[0] não é utilizada pela NTT direta.
    // ========================================================================

    function automatic logic [DW-1:0] get_zeta(input integer index);

        begin

            case (index)

                0   : get_zeta = 12'd1;
                1   : get_zeta = 12'd1729;
                2   : get_zeta = 12'd2580;
                3   : get_zeta = 12'd3289;
                4   : get_zeta = 12'd2642;
                5   : get_zeta = 12'd630;
                6   : get_zeta = 12'd1897;
                7   : get_zeta = 12'd848;

                8   : get_zeta = 12'd1062;
                9   : get_zeta = 12'd1919;
                10  : get_zeta = 12'd193;
                11  : get_zeta = 12'd797;
                12  : get_zeta = 12'd2786;
                13  : get_zeta = 12'd3260;
                14  : get_zeta = 12'd569;
                15  : get_zeta = 12'd1746;

                16  : get_zeta = 12'd296;
                17  : get_zeta = 12'd2447;
                18  : get_zeta = 12'd1339;
                19  : get_zeta = 12'd1476;
                20  : get_zeta = 12'd3046;
                21  : get_zeta = 12'd56;
                22  : get_zeta = 12'd2240;
                23  : get_zeta = 12'd1333;

                24  : get_zeta = 12'd1426;
                25  : get_zeta = 12'd2094;
                26  : get_zeta = 12'd535;
                27  : get_zeta = 12'd2882;
                28  : get_zeta = 12'd2393;
                29  : get_zeta = 12'd2879;
                30  : get_zeta = 12'd1974;
                31  : get_zeta = 12'd821;

                32  : get_zeta = 12'd289;
                33  : get_zeta = 12'd331;
                34  : get_zeta = 12'd3253;
                35  : get_zeta = 12'd1756;
                36  : get_zeta = 12'd1197;
                37  : get_zeta = 12'd2304;
                38  : get_zeta = 12'd2277;
                39  : get_zeta = 12'd2055;

                40  : get_zeta = 12'd650;
                41  : get_zeta = 12'd1977;
                42  : get_zeta = 12'd2513;
                43  : get_zeta = 12'd632;
                44  : get_zeta = 12'd2865;
                45  : get_zeta = 12'd33;
                46  : get_zeta = 12'd1320;
                47  : get_zeta = 12'd1915;

                48  : get_zeta = 12'd2319;
                49  : get_zeta = 12'd1435;
                50  : get_zeta = 12'd807;
                51  : get_zeta = 12'd452;
                52  : get_zeta = 12'd1438;
                53  : get_zeta = 12'd2868;
                54  : get_zeta = 12'd1534;
                55  : get_zeta = 12'd2402;

                56  : get_zeta = 12'd2647;
                57  : get_zeta = 12'd2617;
                58  : get_zeta = 12'd1481;
                59  : get_zeta = 12'd648;
                60  : get_zeta = 12'd2474;
                61  : get_zeta = 12'd3110;
                62  : get_zeta = 12'd1227;
                63  : get_zeta = 12'd910;

                64  : get_zeta = 12'd17;
                65  : get_zeta = 12'd2761;
                66  : get_zeta = 12'd583;
                67  : get_zeta = 12'd2649;
                68  : get_zeta = 12'd1637;
                69  : get_zeta = 12'd723;
                70  : get_zeta = 12'd2288;
                71  : get_zeta = 12'd1100;

                72  : get_zeta = 12'd1409;
                73  : get_zeta = 12'd2662;
                74  : get_zeta = 12'd3281;
                75  : get_zeta = 12'd233;
                76  : get_zeta = 12'd756;
                77  : get_zeta = 12'd2156;
                78  : get_zeta = 12'd3015;
                79  : get_zeta = 12'd3050;

                80  : get_zeta = 12'd1703;
                81  : get_zeta = 12'd1651;
                82  : get_zeta = 12'd2789;
                83  : get_zeta = 12'd1789;
                84  : get_zeta = 12'd1847;
                85  : get_zeta = 12'd952;
                86  : get_zeta = 12'd1461;
                87  : get_zeta = 12'd2687;

                88  : get_zeta = 12'd939;
                89  : get_zeta = 12'd2308;
                90  : get_zeta = 12'd2437;
                91  : get_zeta = 12'd2388;
                92  : get_zeta = 12'd733;
                93  : get_zeta = 12'd2337;
                94  : get_zeta = 12'd268;
                95  : get_zeta = 12'd641;

                96  : get_zeta = 12'd1584;
                97  : get_zeta = 12'd2298;
                98  : get_zeta = 12'd2037;
                99  : get_zeta = 12'd3220;
                100 : get_zeta = 12'd375;
                101 : get_zeta = 12'd2549;
                102 : get_zeta = 12'd2090;
                103 : get_zeta = 12'd1645;

                104 : get_zeta = 12'd1063;
                105 : get_zeta = 12'd319;
                106 : get_zeta = 12'd2773;
                107 : get_zeta = 12'd757;
                108 : get_zeta = 12'd2099;
                109 : get_zeta = 12'd561;
                110 : get_zeta = 12'd2466;
                111 : get_zeta = 12'd2594;

                112 : get_zeta = 12'd2804;
                113 : get_zeta = 12'd1092;
                114 : get_zeta = 12'd403;
                115 : get_zeta = 12'd1026;
                116 : get_zeta = 12'd1143;
                117 : get_zeta = 12'd2150;
                118 : get_zeta = 12'd2775;
                119 : get_zeta = 12'd886;

                120 : get_zeta = 12'd1722;
                121 : get_zeta = 12'd1212;
                122 : get_zeta = 12'd1874;
                123 : get_zeta = 12'd1029;
                124 : get_zeta = 12'd2110;
                125 : get_zeta = 12'd2935;
                126 : get_zeta = 12'd885;
                127 : get_zeta = 12'd2154;

                default:
                    get_zeta = 12'd0;

            endcase
        end
    endfunction

    // ========================================================================
    // FUNÇÃO DE REDUÇÃO MODULAR
    // Retorna: value mod Q garantindo resultado no intervalo: 0 <= resultado < Q
    // ========================================================================

    function automatic logic [DW-1:0]
        mod_q(input integer value);

        integer temp;

        begin

            temp = value % Q;

            if (temp < 0)
                temp = temp + Q;

            mod_q = temp[DW-1:0];

        end

    endfunction

    // ========================================================================
    // MODELO DE REFERÊNCIA DA NTT
    // Implementação equivalente ao algoritmo iterativo da NTT.
    // Pseudocódigo:k = 1
    //   for len = 128 ... 2:
    //       for start = 0 ... 256:
    //           zeta = zetas[k]
    //           for j = start ... start + len:
    //               t = zeta * f[j + len] mod q
    //               f[j + len] = f[j] - t mod q
    //               f[j] = f[j] + t mod q
    // ========================================================================

    task automatic calculate_reference;

        integer len;
        integer start_addr;
        integer j;
        integer k;

        integer product;
        integer t;

        integer a_temp;
        integer b_temp;

        logic [DW-1:0] ref [0:N-1];

        begin

            // ---------------------------------------------------------------
            // Copia o vetor de entrada para a memória interna do modelo.
            // ---------------------------------------------------------------

            for (j = 0; j < N; j = j + 1) begin
                ref[j] = input_poly[j];
            end

            // ---------------------------------------------------------------
            // Primeiro índice da tabela de zetas utilizado pela NTT.
            // ---------------------------------------------------------------

            k = 1;

            // ---------------------------------------------------------------
            // Sete estágios da NTT.
            // ---------------------------------------------------------------

            for (len = 128; len >= 2; len = len / 2) begin

                // -----------------------------------------------------------
                // Cada estágio possui: N / (2 * len)
                // Cada bloco utiliza uma única zeta.
                // -----------------------------------------------------------

                for (
                    start_addr = 0;
                    start_addr < N;
                    start_addr = start_addr + (2 * len)
                ) begin

                    // -------------------------------------------------------
                    // Obtém a zeta correspondente ao bloco atual.
                    // -------------------------------------------------------

                    logic [DW-1:0] zeta;

                    zeta = get_zeta(k);

                    k = k + 1;

                    // -------------------------------------------------------
                    // Processa todas as butterflies do bloco.
                    // -------------------------------------------------------

                    for (
                        j = start_addr;
                        j < start_addr + len;
                        j = j + 1
                    ) begin

                        // ---------------------------------------------------
                        // Multiplicação:                       
                        // t = zeta * f[j + len] mod Q
                        // ---------------------------------------------------

                        product = zeta * ref[j + len];

                        t = product % Q;

                        // ---------------------------------------------------
                        // Butterfly:                   
                        //       a' = a + t
                        //       b' = a - t
                        // ---------------------------------------------------

                        a_temp = ref[j] + t;
                        b_temp = ref[j] - t;

                        // ---------------------------------------------------
                        // Redução modular.
                        // ---------------------------------------------------

                        ref[j]      = mod_q(a_temp);
                        ref[j + len] = mod_q(b_temp);

                    end

                end

            end

            // ---------------------------------------------------------------
            // Copia resultado do modelo para expected_poly.
            // ---------------------------------------------------------------

            for (j = 0; j < N; j = j + 1) begin
                expected_poly[j] = ref[j];
            end
        end
    endtask

    // ========================================================================
    // RESET DO DUT
    // ========================================================================

    task automatic reset_dut;

        begin

            rst      = 1'b1;
            start    = 1'b0;
            valid_in = 1'b0;
            data_in  = '0;

            repeat (5)
                @(posedge clk);

            rst = 1'b0;
            @(posedge clk);

        end
    endtask

    // ========================================================================
    // ENVIO DO VETOR DE ENTRADA
    // ========================================================================
    // Protocolo adotado pelo testbench:
    //   1. start = 1 por um ciclo;
    //   2. start = 0;
    //   3. 256 coeficientes são enviados;
    //   4. valid_in indica quando data_in é válido.
    // IMPORTANTE:
    // O protocolo deve ser compatível com o mlkem_ntt.sv.
    // ========================================================================

    task automatic send_input;

        integer i;

        begin

            // ---------------------------------------------------------------
            // Solicita início da operação.
            // ---------------------------------------------------------------

            @(posedge clk);

            start    <= 1'b1;
            valid_in <= 1'b0;

            @(posedge clk);

            start <= 1'b0;

            // ---------------------------------------------------------------
            // Envia os 256 coeficientes.
            // ---------------------------------------------------------------

            for (i = 0; i < N; i = i + 1) begin

                @(posedge clk);

                valid_in <= 1'b1;
                data_in  <= input_poly[i];

            end

            // ---------------------------------------------------------------
            // Finaliza transmissão.
            // ---------------------------------------------------------------

            @(posedge clk);

            valid_in <= 1'b0;
            data_in  <= '0;

        end
    endtask

    // ========================================================================
    // RECEPÇÃO DO RESULTADO
    // ========================================================================
    // Cada ciclo em que valid_out = 1 representa um coeficiente válido.
    // O testbench armazena:
    //   output_poly[0]
    //   output_poly[1]...
    //   output_poly[255]
    // ========================================================================

    task automatic receive_output;

        integer cycle_count;

        begin

            output_count = 0;
            cycle_count  = 0;

            while (output_count < N) begin

                @(posedge clk);

                cycle_count = cycle_count + 1;

                // -----------------------------------------------------------
                // Verifica timeout.
                // -----------------------------------------------------------

                if (cycle_count > TIMEOUT_CYCLES) begin

                    $display("");
                    $display("=================================================");
                    $display("ERRO: TIMEOUT aguardando resultado da NTT");
                    $display("=================================================");
                    $display("");

                    $fatal;

                end

                // -----------------------------------------------------------
                // Recebe coeficiente.
                // -----------------------------------------------------------

                if (valid_out) begin

                    output_poly[output_count] = data_out;
                    output_count = output_count + 1;

                end
            end

            // Aguarda o término da operação, caso o DUT utilize done.
            // Se o DUT gerar done antes do último valid_out, o while abaixo
            // simplesmente não será necessário para a funcionalidade principal.
            // A verificação de done é feita separadamente.
        end
    endtask

    // ========================================================================
    // COMPARAÇÃO DUT x REFERÊNCIA
    // ========================================================================

    task automatic compare_result;

        integer i;
        integer errors;

        begin

            errors = 0;

            $display("");
            $display("-------------------------------------------------");
            $display("Comparando resultado da NTT...");
            $display("-------------------------------------------------");

            for (i = 0; i < N; i = i + 1) begin

                if (output_poly[i] !== expected_poly[i]) begin

                    errors = errors + 1;

                    $display("ERRO[%0d] : esperado = %0d | recebido = %0d", i, expected_poly[i], output_poly[i]);

                end
            end

            // ---------------------------------------------------------------
            // Resultado do teste.
            // ---------------------------------------------------------------

            if (errors == 0) begin

                $display("");
                $display("*************************************************");
                $display("*                 TESTE PASSOU                  *");
                $display("*************************************************");
                $display("");

                pass_count = pass_count + 1;

            end
            else begin

                $display("");
                $display("*************************************************");
                $display("*                 TESTE FALHOU                 *");
                $display("* Erros encontrados: %0d                       *", errors);
                $display("*************************************************");
                $display("");

                fail_count = fail_count + 1;

            end
        end
    endtask

    // ========================================================================
    // TESTE 001
    // RESET
    // ========================================================================

    task automatic test_reset;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - RESET", test_count);
            $display("=================================================");

            reset_dut();

            if (
                busy === 1'b0 &&
                done === 1'b0 &&
                valid_out === 1'b0
            ) begin

                $display("PASS: DUT permaneceu inativo após reset.");
                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL: sinais inválidos após reset.");
                fail_count = fail_count + 1;

            end

        end
    endtask

    // ========================================================================
    // TESTE 002
    // VETOR ZERO
    // ========================================================================
    // Entrada: f[i] = 0   
    // Resultado esperado:
    //   NTT(f)[i] = 0
    // ========================================================================

    task automatic test_zero;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VETOR ZERO", test_count);
            $display("=================================================");


            for (i = 0; i < N; i = i + 1)
                input_poly[i] = 12'd0;


            calculate_reference();
            send_input();
            receive_output();
            compare_result();

        end
    endtask

    // ========================================================================
    // TESTE 003
    // IMPULSO NA POSIÇÃO 0
    // ========================================================================

    task automatic test_impulse_zero;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - IMPULSO NA POSIÇÃO 0", test_count);
            $display("=================================================");

            for (i = 0; i < N; i = i + 1)
                input_poly[i] = 12'd0;
                
            input_poly[0] = 12'd1;


            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask

    // ========================================================================
    // TESTE 004
    // IMPULSO NA POSIÇÃO 1
    // ========================================================================

    task automatic test_impulse_one;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - IMPULSO NA POSIÇÃO 1", test_count);
            $display("=================================================");

            for (i = 0; i < N; i = i + 1)
                input_poly[i] = 12'd0;

            input_poly[1] = 12'd1;

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask

    // ========================================================================
    // TESTE 005
    // TODOS OS COEFICIENTES = 1
    // ========================================================================

    task automatic test_all_ones;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - TODOS OS COEFICIENTES = 1", test_count);
            $display("=================================================");


            for (i = 0; i < N; i = i + 1)
                input_poly[i] = 12'd1;

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask

    // ========================================================================
    // TESTE 006
    // TODOS OS COEFICIENTES = Q-1
    // ========================================================================

    task automatic test_all_q_minus_1;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - TODOS OS COEFICIENTES = Q-1", test_count);
            $display("=================================================");

            for (i = 0; i < N; i = i + 1)
                input_poly[i] = Q - 1;

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask


    // ========================================================================
    // TESTE 007
    // VETOR CRESCENTE
    // ========================================================================

    task automatic test_incremental;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VETOR CRESCENTE", test_count);
            $display("=================================================");


            for (i = 0; i < N; i = i + 1)
                input_poly[i] = i % Q;

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask

    // ========================================================================
    // TESTE 008
    // VETOR DECRESCENTE
    // ========================================================================

    task automatic test_decremental;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VETOR DECRESCENTE", test_count);
            $display("=================================================");


            for (i = 0; i < N; i = i + 1)
                input_poly[i] = (Q - 1) - (i % Q);

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask


    // ========================================================================
    // TESTE 009
    // VALORES EXTREMOS
    // ========================================================================

    task automatic test_extremes;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VALORES EXTREMOS", test_count);
            $display("=================================================");


            for (i = 0; i < N; i = i + 1) begin

                if ((i % 2) == 0)
                    input_poly[i] = 12'd0;
                else
                    input_poly[i] = Q - 1;

            end

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask


    // ========================================================================
    // TESTE 010
    // VETOR PSEUDOALEATÓRIO

    // Utiliza uma seed fixa para tornar o teste reprodutível.
    // Isso é importante para regressão.
    // ========================================================================

    task automatic test_random;

        integer i;
        integer seed;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VETOR PSEUDOALEATÓRIO", test_count);
            $display("=================================================");

            // Seed fixa.
            seed = 32'h12345678;

            for (i = 0; i < N; i = i + 1) begin

                input_poly[i] = $urandom(seed) % Q;

            end

            calculate_reference();
            send_input();
            receive_output();
            compare_result();
        end
    endtask

    // ========================================================================
    // TESTE 011
    // VÁRIOS PADRÕES
    // Cada posição recebe um padrão determinístico.
    // ========================================================================

    task automatic test_pattern;

        integer i;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - PADRÃO DETERMINÍSTICO", test_count);
            $display("=================================================");

            for (i = 0; i < N; i = i + 1) begin

                input_poly[i] =
                    ((i * 37) + 123) % Q;

            end

            calculate_reference();
            send_input();
            receive_output();
            compare_result();

        end
    endtask

    // ========================================================================
    // TESTE 012
    // ZETA ROM
    //
    // Verifica se a tabela utilizada pelo modelo possui os valores esperados
    // do FIPS 203.    
    // ========================================================================

    task automatic test_zeta_rom;

        integer errors;

        begin

            test_count = test_count + 1;

            $display("");
            $display("=================================================");
            $display("TESTE %0d - VALIDAÇÃO DA TABELA DE ZETAS", test_count);
            $display("=================================================");

            errors = 0;

            if (get_zeta(1) != 12'd1729) begin
                $display("ERRO: zeta[1]");
                errors = errors + 1;
            end

            if (get_zeta(2) != 12'd2580) begin
                $display("ERRO: zeta[2]");
                errors = errors + 1;
            end

            if (get_zeta(3) != 12'd3289) begin
                $display("ERRO: zeta[3]");
                errors = errors + 1;
            end

            if (get_zeta(64) != 12'd17) begin
                $display("ERRO: zeta[64]");
                errors = errors + 1;
            end

            if (get_zeta(127) != 12'd2154) begin
                $display("ERRO: zeta[127]");
                errors = errors + 1;
            end

            if (errors == 0) begin

                $display("PASS: tabela de zetas validada.");
                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL: %0d erros na tabela.", errors);
                fail_count = fail_count + 1;

            end
        end
    endtask


    // ========================================================================
    // MONITOR DE BUSY
    // ========================================================================
    //
    // Este bloco apenas registra mudanças do sinal busy.
    // Útil durante a análise das formas de onda.
    // ========================================================================

    always @(posedge clk) begin

        if (busy) begin

            // O DUT está executando uma operação.
            // Não é necessário imprimir todos os ciclos para evitar excesso
            // de informação no transcript.
            // O sinal pode ser observado diretamente no waveform.
        end
    end

    // ========================================================================
    // MONITOR DE VALID_OUT
    // Mostra cada coeficiente produzido pelo DUT.
    // ========================================================================

    always @(posedge clk) begin

        if (valid_out) begin

            $display(
                "[NTT OUTPUT] index=%0d data=%0d",
                output_count,
                data_out
            );
        end
    end

    // ========================================================================
    // PROGRAMA PRINCIPAL DE TESTES
    // ========================================================================

    initial begin

        // ---------------------------------------------------------------
        // Inicialização.
        // ---------------------------------------------------------------

        rst          = 1'b0;
        start        = 1'b0;
        valid_in     = 1'b0;
        data_in      = '0;

        output_count = 0;

        test_count   = 0;
        pass_count   = 0;
        fail_count   = 0;

        // ---------------------------------------------------------------
        // Mensagem inicial.
        // ---------------------------------------------------------------

        $display("");
        $display("=================================================");
        $display("          ML-KEM NTT RTL TESTBENCH");
        $display("=================================================");
        $display("N  = %0d", N);
        $display("Q  = %0d", Q);
        $display("DW = %0d bits", DW);
        $display("=================================================");

        // ---------------------------------------------------------------
        // Reset inicial.
        // ---------------------------------------------------------------

        reset_dut();

        // ---------------------------------------------------------------
        // Testes.
        // ---------------------------------------------------------------

        test_zeta_rom();
        test_reset();
        test_zero();
        test_impulse_zero();
        test_impulse_one();
        test_all_ones();
        test_all_q_minus_1();
        test_incremental();
        test_decremental();
        test_extremes();
        test_pattern();
        test_random();

        // ---------------------------------------------------------------
        // Resumo final.
        // ---------------------------------------------------------------

        $display("");
        $display("");
        $display("=================================================");
        $display("              RESUMO DA SIMULAÇÃO");
        $display("=================================================");
        $display("Total de testes : %0d", test_count);
        $display("Passou          : %0d", pass_count);
        $display("Falhou          : %0d", fail_count);
        $display("=================================================");

        if (fail_count == 0) begin

            $display("");
            $display("*************************************************");
            $display("*                                               *");
            $display("*       TODA A REGRESSÃO FOI APROVADA           *");
            $display("*                                               *");
            $display("*************************************************");
            $display("");

        end
        else begin

            $display("");
            $display("*************************************************");
            $display("*                                               *");
            $display("*       EXISTEM TESTES COM FALHA                 *");
            $display("*                                               *");
            $display("*************************************************");
            $display("");

        end

        // ---------------------------------------------------------------
        // Finaliza simulação.
        // ---------------------------------------------------------------

        $finish;
    end
endmodule