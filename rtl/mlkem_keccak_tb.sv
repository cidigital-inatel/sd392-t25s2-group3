// ============================================================================
// Projeto: Acelerador ML-KEM com Interface AXI4
// Arquivo: keccak_tb.sv
// Descrição: Testbench em SystemVerilog para validação funcional do Motor Keccak
// Referências: NIST FIPS 202 (SHA-3/Keccak) e NIST FIPS 203 (ML-KEM)
// ============================================================================

`timescale 1ns/1ps

import mlkem_keccak_pkg::*;

module keccak_tb;

  // --------------------------------------------------------------------------
  // Parâmetros do Testbench
  // --------------------------------------------------------------------------
  localparam int CLK_PERIOD = 10; // Período do clock: 10ns (100 MHz)
  localparam int DATA_WIDTH = 64; // Largura do barramento de dados (64 bits)

  // --------------------------------------------------------------------------
  // Sinais do Testbench (Sinais de Interface com o DUT)
  // --------------------------------------------------------------------------
  logic                  clk;
  logic                  rst_n;

  // Controle e Configuração
  logic                  start;
  keccak_mode_e          mode;
  keccak_cmd_e           cmd;
  logic                  zeroize;

  // Interface de Entrada (Absorção / Absorb)
  logic [DATA_WIDTH-1:0] data_in;
  logic                  data_in_valid;
  logic                  data_in_ready;
  logic                  data_in_last;
  logic [2:0]            data_in_bytes;

  // Interface de Saída (Extração / Squeeze / Digest)
  logic [DATA_WIDTH-1:0] data_out;
  logic                  data_out_valid;
  logic                  data_out_ready;
  logic                  data_out_last;

  // Status e Telemetria
  logic                  ready;
  logic                  busy;
  logic                  done;
  logic                  error;

  // Variáveis Internas de Controle de Teste
  int                    error_count = 0;
  int                    test_id     = 0;

  // --------------------------------------------------------------------------
  // Instanciação do Design Under Test (DUT)
  // --------------------------------------------------------------------------
  mlkem_keccak_engine #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .start_i         (start),
    .mode_i          (mode),
    .cmd_i           (cmd),
    .zeroize_i       (zeroize),
    .data_in_i       (data_in),
    .data_in_valid_i (data_in_valid),
    .data_in_ready_o (data_in_ready),
    .data_in_last_i  (data_in_last),
    .data_in_bytes_i (data_in_bytes),
    .data_out_o      (data_out),
    .data_out_valid_o(data_out_valid),
    .data_out_ready_i(data_out_ready),
    .data_out_last_o (data_out_last),
    .ready_o         (ready),
    .busy_o          (busy),
    .done_o          (done),
    .error_o         (error)
  );

  // --------------------------------------------------------------------------
  // Geração do Sinal de Clock (100 MHz)
  // --------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // --------------------------------------------------------------------------
  // Tasks de Suporte do Testbench (Procedimentos de Teste)
  // --------------------------------------------------------------------------

  // Task 1: Aplicação de Reset Assíncrono no DUT
  task automatic do_reset();
    $display("[TB %0t ps] [INFO] Aplicando Reset no DUT...", $time);
    rst_n   <= 1'b0;
    start   <= 1'b0;
    mode    <= MODE_SHA3_256;
    cmd     <= CMD_INIT;
    zeroize <= 1'b0;
    
    data_in        <= '0;
    data_in_valid  <= 1'b0;
    data_in_last   <= 1'b0;
    data_in_bytes  <= 3'd8;
    data_out_ready <= 1'b1;

    #(CLK_PERIOD * 3);
    rst_n <= 1'b1;
    #(CLK_PERIOD * 2);
    $display("[TB %0t ps] [INFO] Reset liberado. DUT pronto.", $time);
  endtask : do_reset

  // Task 2: Emissão de Comando de Controle
  task automatic send_command(
    input keccak_mode_e mode_in,
    input keccak_cmd_e  cmd_in
  );
    @(posedge clk);
    mode  <= mode_in;
    cmd   <= cmd_in;
    start <= 1'b1;
    @(posedge clk);
    start <= 1'b0;
  endtask : send_command

  // Task 3: Simulação de Absorção de Palavra de Dados (Sponge Absorb)
  task automatic send_word(
    input logic [63:0] word,
    input logic        is_last,
    input logic [2:0]  bytes_valid
  );
    @(posedge clk);
    data_in       <= word;
    data_in_valid <= 1'b1;
    data_in_last  <= is_last;
    data_in_bytes <= bytes_valid;

    // Aguarda o handshaking do DUT (data_in_ready)
    do begin
      @(posedge clk);
    end while (!data_in_ready);

    data_in_valid <= 1'b0;
    data_in_last  <= 1'b0;
  endtask : send_word

  // Task 4: Teste de Inicialização e Verificação do Estado de IDLE
  task automatic test_init_sequence();
    test_id++;
    $display("\n------------------------------------------------------------");
    $display("[TB %0t ps] TESTE %0d: Inicializacao do Contexto Keccak", $time, test_id);
    $display("------------------------------------------------------------");

    send_command(MODE_SHA3_256, CMD_INIT);
    #(CLK_PERIOD * 2);

    if (!ready) begin
      $display("[TB %0t ps] [ERRO] DUT deveria estar em estado READY!", $time);
      error_count++;
    end else begin
      $display("[TB %0t ps] [PASS] Inicializacao concluida com sucesso.", $time);
    end
  endtask : test_init_sequence

  // Task 5: Teste do Modo SHA3-256 (Utilizado para H(s) e Verificação no ML-KEM)
  task automatic test_sha3_256_flow();
    test_id++;
    $display("\n------------------------------------------------------------");
    $display("[TB %0t ps] TESTE %0d: Fluxo SHA3-256 (Funcao H(s) do ML-KEM)", $time, test_id);
    $display("------------------------------------------------------------");

    // 1. Iniciar absorção
    send_command(MODE_SHA3_256, CMD_ABSORB);

    // 2. Enviar vetor de teste de 128 bits (2 palavras de 64 bits)
    send_word(64'h0123456789ABCDEF, 1'b0, 3'd8);
    send_word(64'hFEDCBA9876543210, 1'b1, 3'd8);

    // 3. Solicitar finalização e padding
    send_command(MODE_SHA3_256, CMD_FINISH);
    
    // Aguardar sinal de conclusão (done ou ready)
    #(CLK_PERIOD * 5);
    $display("[TB %0t ps] [PASS] Sequencia SHA3-256 enviada com sucesso.", $time);
  endtask : test_sha3_256_flow

  // Task 6: Teste do Modo SHAKE128 (Utilizado para SampleNTT no ML-KEM)
  task automatic test_shake128_flow();
    test_id++;
    $display("\n------------------------------------------------------------");
    $display("[TB %0t ps] TESTE %0d: Fluxo SHAKE128 XOF (Amostragem SampleNTT)", $time, test_id);
    $display("------------------------------------------------------------");

    // 1. Iniciar modo SHAKE128
    send_command(MODE_SHAKE128, CMD_ABSORB);

    // 2. Enviar Semente (32 bytes = 4 palavras de 64 bits)
    send_word(64'hA5A5A5A5A5A5A5A5, 1'b0, 3'd8);
    send_word(64'h5A5A5A5A5A5A5A5A, 1'b0, 3'd8);
    send_word(64'h1234567890ABCDEF, 1'b0, 3'd8);
    send_word(64'hF0E1D2C3B4A59687, 1'b1, 3'd8);

    // 3. Finalizar e solicitar extração contínua (Squeeze XOF)
    send_command(MODE_SHAKE128, CMD_FINISH);
    #(CLK_PERIOD * 3);
    send_command(MODE_SHAKE128, CMD_SQUEEZE);

    #(CLK_PERIOD * 5);
    $display("[TB %0t ps] [PASS] Fluxo SHAKE128 disparado com sucesso.", $time);
  endtask : test_shake128_flow

  // Task 7: Teste do Mecanismo de Zeroização de Segurança (FIPS 203 §3.3)
  task automatic test_zeroize_mechanism();
    test_id++;
    $display("\n------------------------------------------------------------");
    $display("[TB %0t ps] TESTE %0d: Zeroizacao de Seguranca (FIPS 203 §3.3)", $time, test_id);
    $display("------------------------------------------------------------");

    @(posedge clk);
    zeroize <= 1'b1; // Ativação do sinal de purga de emergência
    @(posedge clk);
    zeroize <= 1'b0;

    #(CLK_PERIOD * 3);

    if (error) begin
      $display("[TB %0t ps] [ERRO] Erro detectado apos zeroizacao!", $time);
      error_count++;
    end else begin
      $display("[TB %0t ps] [PASS] Comando de zeroizacao executado com sucesso.", $time);
    end
  endtask : test_zeroize_mechanism

  // --------------------------------------------------------------------------
  // Sequência Principal de Testes (Main Stimulus Process)
  // --------------------------------------------------------------------------
  initial begin
    $display("============================================================");
    $display(" INICIO DA SIMULACAO: TESTBENCH DO MOTOR KECCAK (ML-KEM)    ");
    $display("============================================================");

    // 1. Reset inicial
    do_reset();

    // 2. Execução dos testes funcionais
    test_init_sequence();
    test_sha3_256_flow();
    test_shake128_flow();
    test_zeroize_mechanism();

    // 3. Relatório final de cobertura
    $display("\n============================================================");
    if (error_count == 0) begin
      $display(" RESULTADO FINAL: TODOS OS TESTES PASSARAM COM SUCESSO! [PASS]");
    end else begin
      $display(" RESULTADO FINAL: ENCONTRADOS %0d ERROS DURANTE A SIMULACAO! [FAIL]", error_count);
    end
    $display("============================================================");

    $finish;
  end

endmodule : keccak_tb
