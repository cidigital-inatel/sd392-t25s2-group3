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
