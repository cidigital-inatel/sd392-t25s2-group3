// =============================================================================
// Projeto: Acelerador Criptográfico ML-KEM com Interface AXI4 (FIPS 203)
// Módulo: Processador NTT / INTT e Multiplicação Polinomial (ENTREGÁVEL M1.1)
// Linguagem: SystemVerilog
//
// Descrição:
//   Processador NTT (Number Theoretic Transform), INTT (Inverse NTT) e multiplicação
//    de polinômios no domínio transformado para o algoritmo ML-KEM, em conformidade
//    com a norma NIST FIPS 203 (§4.3).
//
// Referências FIPS 203:
//   - §4.1: Anel Polinomial R_q = Z_q[X]/(X^256 + 1) com q = 3329 e n = 256.
//   - §4.3: Transformada Teórica de Números (NTT) e sua Inversa (INTT).
//   - Algoritmo 8 (NTT): Converte polinômio f em R_q para f_hat em T_q.
//   - Algoritmo 9 (NTT^-1): Converte f_hat em T_q de volta para f em R_q.
//   - Algoritmo 10 (MultiplyNTT / BaseCaseMultiply): Multiplicação ponto a ponto
//     no domínio transformado NTT.
//
// Autores: Grupo 3 - CI Digital 2025T2 - Inatel
// =============================================================================

// =============================================================================
// Pacote de Definições e Parâmetros da NTT (FIPS 203)
// =============================================================================
package mlkem_ntt_pkg;

  // ---------------------------------------------------------------------------
  // Constantes Matemáticas Fundamentais (FIPS 203, §4.1 & §4.3)
  // ---------------------------------------------------------------------------
  localparam int unsigned MLKEM_Q            = 3329; // Módulo prime q = 3329
  localparam int unsigned MLKEM_N            = 256;  // Grau do polinômio n = 256
  localparam int unsigned MLKEM_LOG2_N       = 8;    // log2(256)
  localparam int unsigned MLKEM_NTT_STAGES   = 7;    // 7 camadas de borboletas (layers 0..6)
  localparam int unsigned MLKEM_COEFF_BITS   = 12;   // Bits para representar mod q (0..3328)
  localparam int unsigned MLKEM_DATA_WIDTH   = 16;   // Largura padrão do barramento de dados
  localparam int unsigned MLKEM_ZETA_COUNT   = 128;  // Número de fatores de torção (zetas)

  // Parâmetros de redução de Montgomery (R = 2^16 mod 3329 = 2285; Q' = -q^-1 mod 2^16 = 62209)
  localparam logic [15:0] MONTGOMERY_R       = 16'd2285;
  localparam logic [15:0] MONTGOMERY_Q_INV   = 16'd62209;

  // ---------------------------------------------------------------------------
  // Codificação dos Comandos (Modos de Operação do Processador NTT)
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    OP_NTT_IDLE       = 3'b000, // Processador em repouso
    OP_NTT_FORWARD    = 3'b001, // NTT Direta (FIPS 203 Algoritmo 8)
    OP_NTT_INVERSE    = 3'b010, // INTT Inversa (FIPS 203 Algoritmo 9)
    OP_NTT_BASEMUL    = 3'b011, // Multiplicação BaseCase (FIPS 203 Algoritmo 10)
    OP_NTT_ACCUMULATE = 3'b100, // Multiplicação e Acumulação Vetorial no domínio NTT
    OP_NTT_ZEROIZE    = 3'b111  // Limpeza de segurança (Zeroização de registradores)
  } ntt_op_cmd_e;

  // ---------------------------------------------------------------------------
  // Estados da FSM de Controle da NTT
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    ST_NTT_RESET      = 4'b0000, // Estado de inicialização / reset
    ST_NTT_IDLE       = 4'b0001, // Aguardando comando de início (start)
    ST_NTT_FETCH      = 4'b0010, // Leitura de coeficientes da memória
    ST_NTT_STAGE_CALC = 4'b0011, // Execução das camadas de borboleta (Stages 0..6)
    ST_NTT_BASEMUL    = 4'b0100, // Processamento de BaseCaseMultiply (Alg 10)
    ST_NTT_ACCUM      = 4'b0101, // Acumulação do resultado da multiplicação
    ST_NTT_STORE      = 4'b0110, // Escrita dos coeficientes processados
    ST_NTT_DONE       = 4'b0111, // Sinalização de conclusão de operação
    ST_NTT_ZEROIZING  = 4'b1000, // Executando rotina de limpeza de chaves/dados
    ST_NTT_ERROR      = 4'b1111  // Condição de erro / estouro de limites
  } ntt_fsm_state_e;

  // Structure para encapsulamento de coeficientes em formato NTT
  typedef struct packed {
    logic [MLKEM_DATA_WIDTH-1:0] coeff0;
    logic [MLKEM_DATA_WIDTH-1:0] coeff1;
  } ntt_coeff_pair_t;

endpackage : mlkem_ntt_pkg


// =============================================================================
// Submódulo 1: Unidade Aritmética Modular (Montgomery e Barrett Reduction)
// Rastreabilidade: FIPS 203 §4.3 & §4.1
// =============================================================================
module mlkem_modular_arith
  import mlkem_ntt_pkg::*;
(
  input  logic [MLKEM_DATA_WIDTH-1:0] operand_a_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] operand_b_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] zeta_i,
  output logic [MLKEM_DATA_WIDTH-1:0] result_add_o,
  output logic [MLKEM_DATA_WIDTH-1:0] result_sub_o,
  output logic [MLKEM_DATA_WIDTH-1:0] result_mont_o
);

  // TODO: Declarar sinais internos para redução de Montgomery / Barrett.

  // TODO: Implementar função de Redução de Montgomery (Montgomery Reduce):
  //       Recebe produto de 32 bits, retorna (a * R^-1 mod q).
  function automatic logic [MLKEM_DATA_WIDTH-1:0] montgomery_reduce(
    input logic [31:0] prod_i
  );
    // TODO: Implementar lógica matemática de redução de Montgomery.
    return '0;
  endfunction

  // TODO: Implementar função de Adição Modular: (a + b) mod q.
  function automatic logic [MLKEM_DATA_WIDTH-1:0] mod_q_add(
    input logic [MLKEM_DATA_WIDTH-1:0] a_i,
    input logic [MLKEM_DATA_WIDTH-1:0] b_i
  );
    // TODO: Implementar soma modular.
    return '0;
  endfunction

  // TODO: Implementar função de Subtração Modular: (a - b + q) mod q.
  function automatic logic [MLKEM_DATA_WIDTH-1:0] mod_q_sub(
    input logic [MLKEM_DATA_WIDTH-1:0] a_i,
    input logic [MLKEM_DATA_WIDTH-1:0] b_i
  );
    // TODO: Implementar subtração modular.
    return '0;
  endfunction

  // TODO: Atribuir saídas funcionais após a implementação das funções acima.
  assign result_add_o  = '0;
  assign result_sub_o  = '0;
  assign result_mont_o = '0;

endmodule : mlkem_modular_arith


// =============================================================================
// Submódulo 2: Tabela de Fatores de Torção (ROM de Zetas)
// Rastreabilidade: FIPS 203 §4.3, Tabela de valores zeta em representação de Montgomery
// =============================================================================
module mlkem_zeta_rom
  import mlkem_ntt_pkg::*;
(
  input  logic [6:0]                  zeta_addr_i,
  output logic [MLKEM_DATA_WIDTH-1:0] zeta_val_o,
  output logic [MLKEM_DATA_WIDTH-1:0] zeta_inv_val_o
);

  // TODO: Declarar arranjo ROM de zetas pré-calculados conforme FIPS 203.
  // logic [MLKEM_DATA_WIDTH-1:0] zeta_table [0:127];
  // logic [MLKEM_DATA_WIDTH-1:0] zeta_inv_table [0:127];

  // TODO: Leitura síncrona/assíncrona dos fatores de torção para NTT e INTT.
  assign zeta_val_o     = '0;
  assign zeta_inv_val_o = '0;

endmodule : mlkem_zeta_rom


// =============================================================================
// Submódulo 3: Unidade Borboleta (Butterfly Unit - Cooley-Tukey / Gentleman-Sande)
// Rastreabilidade: FIPS 203 §4.3 (Algoritmo 8: NTT e Algoritmo 9: INTT)
// =============================================================================
module mlkem_butterfly_unit
  import mlkem_ntt_pkg::*;
(
  input  logic                        clk_i,
  input  logic                        rst_ni,
  input  logic                        is_inverse_i,  // 0: Cooley-Tukey (NTT), 1: Gentleman-Sande (INTT)
  input  logic [MLKEM_DATA_WIDTH-1:0] coeff_a_i,     // Coeficiente superior
  input  logic [MLKEM_DATA_WIDTH-1:0] coeff_b_i,     // Coeficiente inferior
  input  logic [MLKEM_DATA_WIDTH-1:0] zeta_factor_i, // Fator de torção (zeta)
  output logic [MLKEM_DATA_WIDTH-1:0] coeff_a_o,     // Resultado superior
  output logic [MLKEM_DATA_WIDTH-1:0] coeff_b_o      // Resultado inferior
);

  // TODO: Declarar registradores de pipeline para operação borboleta.

  // TODO: Instanciar primitiva mlkem_modular_arith ou lógica customizada de borboleta.

  // TODO: Lógica de seleção do modo de borboleta:
  //   - Cooley-Tukey (NTT Direta):
  //       A' = A + B * zeta (mod q)
  //       B' = A - B * zeta (mod q)
  //   - Gentleman-Sande (INTT Inversa):
  //       A' = A + B (mod q)
  //       B' = (A - B) * zeta (mod q)

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // TODO: Limpeza de registradores de borboleta
    end else begin
      // TODO: Atualização de estados/pipeline da borboleta
    end
  end

  assign coeff_a_o = '0;
  assign coeff_b_o = '0;

endmodule : mlkem_butterfly_unit


// =============================================================================
// Submódulo 4: Unidade de Multiplicação Caso-Base (BaseCase Multiply Unit)
// Rastreabilidade: FIPS 203 Algoritmo 10 (BaseCaseMultiply)
// =============================================================================
module mlkem_basemul_unit
  import mlkem_ntt_pkg::*;
(
  input  logic                        clk_i,
  input  logic                        rst_ni,
  input  logic [MLKEM_DATA_WIDTH-1:0] a0_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] a1_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] b0_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] b1_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] gamma_i, // Fator gamma para o polinômio de grau 1
  output logic [MLKEM_DATA_WIDTH-1:0] c0_o,   // Coeficiente c0 de saída
  output logic [MLKEM_DATA_WIDTH-1:0] c1_o    // Coeficiente c1 de saída
);

  // TODO: Implementar equações do Algoritmo 10 da FIPS 203:
  //   c0 = (a0*b0 + a1*b1*gamma) mod q
  //   c1 = (a0*b1 + a1*b0) mod q

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // TODO: Reseta registradores do basemul
    end else begin
      // TODO: Pipeline de multiplicação basecase
    end
  end

  assign c0_o = '0;
  assign c1_o = '0;

endmodule : mlkem_basemul_unit


// =============================================================================
// Submódulo 5: Memória SRAM Interna para Coeficientes Polinomials
// Rastreabilidade: Armazenamento temporário de R_q e T_q durante NTT/INTT
// =============================================================================
module mlkem_poly_ram_buffer
  import mlkem_ntt_pkg::*;
(
  input  logic                        clk_i,
  input  logic                        we_a_i,
  input  logic [MLKEM_LOG2_N-1:0]     addr_a_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] wdata_a_i,
  output logic [MLKEM_DATA_WIDTH-1:0] rdata_a_o,

  input  logic                        we_b_i,
  input  logic [MLKEM_LOG2_N-1:0]     addr_b_i,
  input  logic [MLKEM_DATA_WIDTH-1:0] wdata_b_i,
  output logic [MLKEM_DATA_WIDTH-1:0] rdata_b_o,

  input  logic                        zeroize_i // Pulso de zeroização para sanitização
);

  // TODO: Array de memória SRAM dual-port de 256 palavras x 16 bits.
  // logic [MLKEM_DATA_WIDTH-1:0] ram_matrix [0:MLKEM_N-1];

  // TODO: Implementar leitura/escrita dual-port e rotina de zeroização (flush).

  assign rdata_a_o = '0;
  assign rdata_b_o = '0;

endmodule : mlkem_poly_ram_buffer


// =============================================================================
// Submódulo 6: FSM de Controle Sequencial da NTT / INTT / BaseMul
// Rastreabilidade: Orquestração de loops do Algoritmo 8, 9 e 10 (FIPS 203)
// =============================================================================
module mlkem_ntt_fsm
  import mlkem_ntt_pkg::*;
(
  input  logic           clk_i,
  input  logic           rst_ni,
  input  ntt_op_cmd_e    cmd_op_i,
  input  logic           start_i,
  output ntt_fsm_state_e state_o,
  output logic [2:0]     stage_counter_o, // Contador de camadas (0 a 6)
  output logic [7:0]     poly_index_o,    // Índice dos coeficientes
  output logic [6:0]     zeta_index_o,    // Índice da tabela de zetas
  output logic           busy_o,
  output logic           done_o,
  output logic           error_o
);

  // TODO: Declarar sinalização interna de controle de estado.
  ntt_fsm_state_e current_state, next_state;

  // TODO: Transições de estado da FSM:
  //       ST_NTT_IDLE -> ST_NTT_FETCH -> ST_NTT_STAGE_CALC -> ST_NTT_STORE -> ST_NTT_DONE

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      current_state <= ST_NTT_RESET;
    end else begin
      current_state <= next_state;
    end
  end

  always_comb begin
    // TODO: Lógica de próximo estado (next_state) e atribuição dos contadores de loop.
    next_state = current_state;
  end

  assign state_o         = current_state;
  assign stage_counter_o = '0;
  assign poly_index_o    = '0;
  assign zeta_index_o    = '0;
  assign busy_o          = '0;
  assign done_o          = '0;
  assign error_o         = '0;

endmodule : mlkem_ntt_fsm


// =============================================================================
// MÓDULO PRINCIPAL: mlkem_ntt (Top-Level do Subsistema NTT - Entregável M1.1)
// Rastreabilidade: FIPS 203 §4.3 (Algoritmos 8, 9 e 10)
// =============================================================================
module mlkem_ntt
  import mlkem_ntt_pkg::*;
(
  // ---------------------------------------------------------------------------
  // Clocks e Resets
  // ---------------------------------------------------------------------------
  input  logic                        clk_i,        // Clock principal do sistema
  input  logic                        rst_ni,       // Reset assíncrono (ativo em nível baixo)

  // ---------------------------------------------------------------------------
  // Interface de Comando e Controle
  // ---------------------------------------------------------------------------
  input  logic                        start_i,      // Sinal de início de operação (pulsado)
  input  ntt_op_cmd_e                 cmd_op_i,     // Seleção da operação (NTT, INTT, BASEMUL, ACCUM)
  output logic                        ready_o,      // Pronto para receber novo comando
  output logic                        busy_o,       // Operação em andamento
  output logic                        done_o,       // Operação concluída com sucesso
  output logic                        error_o,      // Indicador de erro de execução/parâmetro

  // ---------------------------------------------------------------------------
  // Interface de Leitura de Entrada (Polinômio A e Polinômio B)
  // ---------------------------------------------------------------------------
  output logic [MLKEM_LOG2_N-1:0]     rd_addr_a_o,  // Endereço de leitura do Polinômio A
  input  logic [MLKEM_DATA_WIDTH-1:0] rd_data_a_i,  // Dado de entrada do Polinômio A
  output logic [MLKEM_LOG2_N-1:0]     rd_addr_b_o,  // Endereço de leitura do Polinômio B (usado em BaseMul)
  input  logic [MLKEM_DATA_WIDTH-1:0] rd_data_b_i,  // Dado de entrada do Polinômio B

  // ---------------------------------------------------------------------------
  // Interface de Escrita de Saída (Polinômio Resultante)
  // ---------------------------------------------------------------------------
  output logic                        wr_en_o,      // Habilita escrita do resultado
  output logic [MLKEM_LOG2_N-1:0]     wr_addr_o,    // Endereço de escrita no buffer de saída
  output logic [MLKEM_DATA_WIDTH-1:0] wr_data_o,    // Dado do coeficiente calculado

  // ---------------------------------------------------------------------------
  // Interface de Sanitização de Segurança
  // ---------------------------------------------------------------------------
  input  logic                        zeroize_i     // Comando de zeramento forçado do estado interno
);

  // ===========================================================================
  // Declaração de Sinais Internos e Interconexões
  // ===========================================================================
  ntt_fsm_state_e fsm_state;
  logic [2:0]     current_stage;
  logic [7:0]     coeff_idx;
  logic [6:0]     zeta_idx;

  logic [MLKEM_DATA_WIDTH-1:0] zeta_val;
  logic [MLKEM_DATA_WIDTH-1:0] zeta_inv_val;

  logic [MLKEM_DATA_WIDTH-1:0] bfly_a_in, bfly_b_in;
  logic [MLKEM_DATA_WIDTH-1:0] bfly_a_out, bfly_b_out;

  logic [MLKEM_DATA_WIDTH-1:0] basemul_c0, basemul_c1;

  // ===========================================================================
  // Instanciação dos Submódulos
  // ===========================================================================

  // 1. Instância da FSM de Controle
  mlkem_ntt_fsm u_ntt_fsm (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .cmd_op_i        (cmd_op_i),
    .start_i         (start_i),
    .state_o         (fsm_state),
    .stage_counter_o (current_stage),
    .poly_index_o    (coeff_idx),
    .zeta_index_o    (zeta_idx),
    .busy_o          (busy_o),
    .done_o          (done_o),
    .error_o         (error_o)
  );

  // 2. Instância da ROM de Zetas
  mlkem_zeta_rom u_zeta_rom (
    .zeta_addr_i     (zeta_idx),
    .zeta_val_o      (zeta_val),
    .zeta_inv_val_o  (zeta_inv_val)
  );

  // 3. Instância da Unidade Borboleta (NTT/INTT)
  mlkem_butterfly_unit u_butterfly (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .is_inverse_i    (cmd_op_i == OP_NTT_INVERSE),
    .coeff_a_i       (bfly_a_in),
    .coeff_b_i       (bfly_b_in),
    .zeta_factor_i   ((cmd_op_i == OP_NTT_INVERSE) ? zeta_inv_val : zeta_val),
    .coeff_a_o       (bfly_a_out),
    .coeff_b_o       (bfly_b_out)
  );

  // 4. Instância da Unidade BaseCaseMultiply (Algoritmo 10)
  mlkem_basemul_unit u_basemul (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .a0_i            (rd_data_a_i),
    .a1_i            (rd_data_a_i), // TODO: Ajustar para o par de coeficientes
    .b0_i            (rd_data_b_i),
    .b1_i            (rd_data_b_i), // TODO: Ajustar para o par de coeficientes
    .gamma_i         (zeta_val),
    .c0_o            (basemul_c0),
    .c1_o            (basemul_c1)
  );

  // 5. Instância do Buffer RAM Interno
  mlkem_poly_ram_buffer u_poly_buffer (
    .clk_i           (clk_i),
    .we_a_i          (1'b0),
    .addr_a_i        ('0),
    .wdata_a_i       ('0),
    .rdata_a_o       (),
    .we_b_i          (1'b0),
    .addr_b_i        ('0),
    .wdata_b_i       ('0),
    .rdata_b_o       (),
    .zeroize_i       (zeroize_i)
  );

  // ===========================================================================
  // Funções Internas do Módulo Top
  // ===========================================================================

  // TODO: Função para validação de limites de coeficientes (deve ser < 3329)
  function automatic logic check_coeff_validity(
    input logic [MLKEM_DATA_WIDTH-1:0] coeff_val_i
  );
    // TODO: Implementar verificação se coeff_val_i < MLKEM_Q
    return (coeff_val_i < MLKEM_Q);
  endfunction

  // TODO: Função para calcular os endereços dos pares borboleta com base na camada (stage)
  function automatic logic [7:0] get_butterfly_pair_index(
    input logic [2:0] stage_i,
    input logic [7:0] elem_idx_i
  );
    // TODO: Implementar cálculo de índice de par de borboleta de acordo com o passo da etapa
    return '0;
  endfunction

  // ===========================================================================
  // Tasks de Processamento e Controle Interno
  // ===========================================================================

  // TODO: Task para reset e sanitização de registradores internos de estado
  task automatic reset_internal_registers();
    begin
      // TODO: Limpar registradores sensíveis e acumuladores internos
    end
  endtask

  // TODO: Task para execução de rotina de zeroização de emergência
  task automatic perform_zeroization();
    begin
      // TODO: Sobrescrever todos os registradores temporários com zeros
    end
  endtask

  // ===========================================================================
  // Lógica de Atribuição de Saídas
  // ===========================================================================
  assign ready_o     = (fsm_state == ST_NTT_IDLE);
  assign rd_addr_a_o = '0;
  assign rd_addr_b_o = '0;
  assign wr_en_o     = 1'b0;
  assign wr_addr_o   = '0;
  assign wr_data_o   = '0;

endmodule : mlkem_ntt