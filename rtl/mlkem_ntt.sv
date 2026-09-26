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
