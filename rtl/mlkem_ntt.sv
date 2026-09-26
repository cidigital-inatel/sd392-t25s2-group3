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

endpackage : mlkem_ntt_pkg
