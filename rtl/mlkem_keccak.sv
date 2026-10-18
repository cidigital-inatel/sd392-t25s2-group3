// ============================================================================
// Projeto: Acelerador ML-KEM com Interface AXI4 (Entregável M1.2)
// Módulo: Motor Keccak (Keccak-f[1600] / SHA-3 / SHAKE Engine)
// Padrões de Referência: NIST FIPS 202 (SHA-3/Keccak) e NIST FIPS 203 (ML-KEM)
// Linguagem: SystemVerilog
// ============================================================================
// Descrição:
//   Implementação RTL do Motor Keccak para o acelerador ML-KEM. Este módulo é
//   responsável por executar as primitivas criptográficas SHA3-256, SHA3-512,
//   SHAKE128 e SHAKE256, que alimentam as funções de expansão de matriz
//   (SampleNTT), amostragem de ruído (SamplePolyCBD via PRF), derivação de
//   chaves (H, G, J) e rejeição implícita conforme especificado no NIST
//   FIPS 203 (§4.1).
//
//   A permutação Keccak-f[1600] segue a FIPS 202 (§3.2), aplicando as etapas
//   Theta, Rho, Pi, Chi e Iota. A construção sponge usa as taxas e os sufixos
//   de domínio de SHA3/SHAKE definidos na FIPS 202.
// ============================================================================

package mlkem_keccak_pkg;

  // --------------------------------------------------------------------------
  // Enumeração dos Modos de Operação do Motor Keccak (FIPS 202 / FIPS 203 §4.1)
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {
    MODE_SHA3_256 = 2'b00,  // Função H(s) e verificação de chave (Rate r = 1088, c = 512)
    MODE_SHA3_512 = 2'b01,  // Função G(c) para expansão de sementes (Rate r = 576, c = 1024)
    MODE_SHAKE128 = 2'b10,  // XOF para amostragem da matriz A (SampleNTT) (Rate r = 1344, c = 256)
    MODE_SHAKE256 = 2'b11   // PRF(s,b) e Função J(s) para CBD/Decaps (Rate r = 1088, c = 512)
  } keccak_mode_e;

  // --------------------------------------------------------------------------
  // Enumeração dos Tipos de Comandos/Operações da FSM Criptográfica
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {
    CMD_INIT    = 2'b00,    // Limpeza de estado e inicialização do contexto Keccak
    CMD_ABSORB  = 2'b01,    // Absorção de blocos de dados na esponja (Sponge Absorb)
    CMD_FINISH  = 2'b10,    // Aplicação do padding específico do modo e execução final
    CMD_SQUEEZE = 2'b11     // Extração contínua de bytes (Sponge Squeeze / XOF)
  } keccak_cmd_e;

  // --------------------------------------------------------------------------
  // Enumeração dos Estados do Controlador Principal do Keccak
  // --------------------------------------------------------------------------
  typedef enum logic [2:0] {
    ST_IDLE     = 3'b000,   // Estado de repouso, aguardando início de comando
    ST_ABSORB   = 3'b001,   // Absorção de palavras de entrada no estado interno
    ST_PADDING  = 3'b010,   // Inserção do sufixo de domínio e bits de padding pad10*1
    ST_PERMUTE  = 3'b011,   // Execução das 24 rodadas da permutação Keccak-f[1600]
    ST_SQUEEZE  = 3'b100,   // Extração de dados da taxa (Rate) para saída
    ST_ZEROIZE  = 3'b101,   // Limpeza de segurança dos registradores sensíveis
    ST_DONE     = 3'b110    // Sinalização de conclusão de operação
  } keccak_fsm_e;

  // Constantes de estrutura da permutação Keccak-f[1600] (FIPS 202 §3.2)
  localparam int KECCAK_STATE_BITS = 1600;
  localparam int KECCAK_LANES      = 25;    // Estado organizado em matriz 5x5 de lanes de 64 bits
  localparam int KECCAK_LANE_BITS  = 64;
  localparam int KECCAK_ROUNDS     = 24;    // 24 rodadas por permutação f[1600]

  // --------------------------------------------------------------------------
  // Função auxiliar: Rotação circular de bits à esquerda para palavras de
  // 64 bits. Usada pela etapa Rho e pela etapa Theta da FIPS 202 §3.2.
  // --------------------------------------------------------------------------
  function automatic logic [63:0] keccak_rotl64(
    input logic [63:0] val_i,
    input int unsigned shift_i
  );
    int unsigned sh;
    begin
      sh = shift_i % 64;
      if (sh == 0) begin
        keccak_rotl64 = val_i;
      end else begin
        keccak_rotl64 = (val_i << sh) | (val_i >> (64 - sh));
      end
    end
  endfunction : keccak_rotl64

  // --------------------------------------------------------------------------
  // Função auxiliar: Constante de rodada RC[i_r], conforme FIPS 202 §3.2.5.
  // A constante é injetada no lane A[0,0] durante a etapa Iota.
  // --------------------------------------------------------------------------
  function automatic logic [63:0] keccak_round_constant(
    input logic [4:0] round_idx_i
  );
    begin
      unique case (round_idx_i)
        5'd0:  keccak_round_constant = 64'h0000_0000_0000_0001;
        5'd1:  keccak_round_constant = 64'h0000_0000_0000_8082;
        5'd2:  keccak_round_constant = 64'h8000_0000_0000_808A;
        5'd3:  keccak_round_constant = 64'h8000_0000_8000_8000;
        5'd4:  keccak_round_constant = 64'h0000_0000_0000_808B;
        5'd5:  keccak_round_constant = 64'h0000_0000_8000_0001;
        5'd6:  keccak_round_constant = 64'h8000_0000_8000_8081;
        5'd7:  keccak_round_constant = 64'h8000_0000_0000_8009;
        5'd8:  keccak_round_constant = 64'h0000_0000_0000_008A;
        5'd9:  keccak_round_constant = 64'h0000_0000_0000_0088;
        5'd10: keccak_round_constant = 64'h0000_0000_8000_8009;
        5'd11: keccak_round_constant = 64'h0000_0000_8000_000A;
        5'd12: keccak_round_constant = 64'h0000_0000_8000_808B;
        5'd13: keccak_round_constant = 64'h8000_0000_0000_008B;
        5'd14: keccak_round_constant = 64'h8000_0000_0000_8089;
        5'd15: keccak_round_constant = 64'h8000_0000_0000_8003;
        5'd16: keccak_round_constant = 64'h8000_0000_0000_8002;
        5'd17: keccak_round_constant = 64'h8000_0000_0000_0080;
        5'd18: keccak_round_constant = 64'h0000_0000_0000_800A;
        5'd19: keccak_round_constant = 64'h8000_0000_8000_000A;
        5'd20: keccak_round_constant = 64'h8000_0000_8000_8081;
        5'd21: keccak_round_constant = 64'h8000_0000_0000_8080;
        5'd22: keccak_round_constant = 64'h0000_0000_8000_0001;
        5'd23: keccak_round_constant = 64'h8000_0000_8000_8008;
        default: keccak_round_constant = 64'h0;
      endcase
    end
  endfunction : keccak_round_constant

  // --------------------------------------------------------------------------
  // Função auxiliar: Deslocamentos da etapa Rho, conforme FIPS 202,
  // Tabela 2. Cada lane A[x,y] possui rotação fixa própria.
  // --------------------------------------------------------------------------
  function automatic int unsigned keccak_rho_offset(
    input int unsigned x_i,
    input int unsigned y_i
  );
    begin
      unique case ((5 * y_i) + x_i)
        0:  keccak_rho_offset = 0;
        1:  keccak_rho_offset = 1;
        2:  keccak_rho_offset = 62;
        3:  keccak_rho_offset = 28;
        4:  keccak_rho_offset = 27;
        5:  keccak_rho_offset = 36;
        6:  keccak_rho_offset = 44;
        7:  keccak_rho_offset = 6;
        8:  keccak_rho_offset = 55;
        9:  keccak_rho_offset = 20;
        10: keccak_rho_offset = 3;
        11: keccak_rho_offset = 10;
        12: keccak_rho_offset = 43;
        13: keccak_rho_offset = 25;
        14: keccak_rho_offset = 39;
        15: keccak_rho_offset = 41;
        16: keccak_rho_offset = 45;
        17: keccak_rho_offset = 15;
        18: keccak_rho_offset = 21;
        19: keccak_rho_offset = 8;
        20: keccak_rho_offset = 18;
        21: keccak_rho_offset = 2;
        22: keccak_rho_offset = 61;
        23: keccak_rho_offset = 56;
        24: keccak_rho_offset = 14;
        default: keccak_rho_offset = 0;
      endcase
    end
  endfunction : keccak_rho_offset

endpackage : mlkem_keccak_pkg


// ============================================================================
// Submódulo 1: Etapa Theta (FIPS 202 §3.2.1)
// ============================================================================
module keccak_step_theta
  import mlkem_keccak_pkg::*;
(
  input  logic [1599:0] state_in_i,   // Estado interno de entrada (1600 bits)
  output logic [1599:0] state_out_o   // Estado transformado após difusão Theta
);
  logic [63:0] a [0:4][0:4];
  logic [63:0] c [0:4];
  logic [63:0] d [0:4];

  always_comb begin
    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        a[x][y] = state_in_i[64 * (x + (5 * y)) +: 64];
      end
    end

    // A[x,y] é interpretado como uma matriz 5x5 de lanes de 64 bits.
    // Theta calcula as paridades C[x] de cada coluna e gera D[x] a partir
    // das colunas vizinhas. Cada lane da coluna x recebe XOR com D[x],
    // espalhando informação por todo o estado antes das rotações.
    for (int x = 0; x < 5; x++) begin
      c[x] = a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4];
    end
    for (int x = 0; x < 5; x++) begin
      d[x] = c[(x + 4) % 5] ^ keccak_rotl64(c[(x + 1) % 5], 1);
    end

    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        state_out_o[64 * (x + (5 * y)) +: 64] = a[x][y] ^ d[x];
      end
    end
  end
endmodule : keccak_step_theta


// ============================================================================
// Submódulo 2: Etapa Rho (FIPS 202 §3.2.2)
// ============================================================================
module keccak_step_rho
  import mlkem_keccak_pkg::*;
(
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após rotações de bits
);
  always_comb begin
    // Rho preserva a posição das lanes e rotaciona os bits internos de cada
    // lane. Os deslocamentos são fixos e vêm diretamente da Tabela 2 da FIPS 202.
    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        state_out_o[64 * (x + (5 * y)) +: 64] =
          keccak_rotl64(state_in_i[64 * (x + (5 * y)) +: 64],
                        keccak_rho_offset(x, y));
      end
    end
  end
endmodule : keccak_step_rho


// ============================================================================
// Submódulo 3: Etapa Pi (FIPS 202 §3.2.3)
// ============================================================================
module keccak_step_pi (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após permutação de posições
);
  always_comb begin
    state_out_o = '0;
    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        // Pi reorganiza as posições das lanes sem alterar seus bits internos:
        // A[x,y] -> B[y, (2*x + 3*y) mod 5].
        state_out_o[64 * (y + (5 * ((2 * x + 3 * y) % 5))) +: 64] =
          state_in_i[64 * (x + (5 * y)) +: 64];
      end
    end
  end
endmodule : keccak_step_pi


// ============================================================================
// Submódulo 4: Etapa Chi (FIPS 202 §3.2.4)
// ============================================================================
module keccak_step_chi (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após não-linearidade NOT/AND/XOR
);
  logic [63:0] a [0:4][0:4];

  always_comb begin
    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        a[x][y] = state_in_i[64 * (x + (5 * y)) +: 64];
      end
    end

    // Chi é a única etapa não linear da rodada Keccak. A transformação é
    // aplicada linha a linha: A[x,y] ^ ((~A[x+1,y]) & A[x+2,y]).
    for (int x = 0; x < 5; x++) begin
      for (int y = 0; y < 5; y++) begin
        state_out_o[64 * (x + (5 * y)) +: 64] =
          a[x][y] ^ ((~a[(x + 1) % 5][y]) & a[(x + 2) % 5][y]);
      end
    end
  end
endmodule : keccak_step_chi


// ============================================================================
// Submódulo 5: Etapa Iota (FIPS 202 §3.2.5)
// ============================================================================
module keccak_step_iota
  import mlkem_keccak_pkg::*;
(
  input  logic [1599:0] state_in_i,    // Estado interno de entrada
  input  logic [4:0]    round_idx_i,   // Índice da rodada atual (0 a 23)
  output logic [1599:0] state_out_o    // Estado transformado após injeção da constante RC
);
  always_comb begin
    // Iota quebra simetrias entre rodadas injetando RC[i_r] somente em A[0,0].
    state_out_o = state_in_i;
    state_out_o[63:0] = state_in_i[63:0] ^ keccak_round_constant(round_idx_i);
  end
endmodule : keccak_step_iota


// ============================================================================
// Submódulo 6: Núcleo de Rodada da Permutação Keccak-f[1600]
// ============================================================================
module keccak_f1600_round_core (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic [1599:0] state_i,       // Estado atual
  input  logic [4:0]    round_number_i,// Número da rodada
  output logic [1599:0] state_o        // Estado após 1 rodada R = ι o χ o π o ρ o θ
);
  logic [1599:0] state_theta;
  logic [1599:0] state_rho;
  logic [1599:0] state_pi;
  logic [1599:0] state_chi;
  logic [1599:0] state_iota;

  // Interface pronta para futura pipeline; a rodada atual é combinacional.
  logic unused_seq_inputs;
  assign unused_seq_inputs = clk_i ^ rst_ni;

  // Encadeamento exato das cinco etapas de rodada da FIPS 202.
  keccak_step_theta u_theta (.state_in_i(state_i),     .state_out_o(state_theta));
  keccak_step_rho   u_rho   (.state_in_i(state_theta), .state_out_o(state_rho));
  keccak_step_pi    u_pi    (.state_in_i(state_rho),   .state_out_o(state_pi));
  keccak_step_chi   u_chi   (.state_in_i(state_pi),    .state_out_o(state_chi));
  keccak_step_iota  u_iota  (.state_in_i(state_chi),   .round_idx_i(round_number_i), .state_out_o(state_iota));

  assign state_o = state_iota;
endmodule : keccak_f1600_round_core


// ============================================================================
// Módulo Top-Level: Motor Keccak Completo (Deliverable M1.2)
// ============================================================================
module mlkem_keccak_engine
  import mlkem_keccak_pkg::*;
#(
  parameter int DATA_WIDTH = 64  // Largura do barramento de dados de E/S (64 bits)
)(
  // --------------------------------------------------------------------------
  // Sinais Globais de Clock e Reset (Ativo em Nível Baixo)
  // --------------------------------------------------------------------------
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // --------------------------------------------------------------------------
  // Interface de Controle Criptográfico e Configuração de Modo
  // --------------------------------------------------------------------------
  input  logic                  start_i,
  input  keccak_mode_e          mode_i,
  input  keccak_cmd_e           cmd_i,
  input  logic                  zeroize_i,

  // --------------------------------------------------------------------------
  // Stream de Entrada de Dados (Sponge Absorb Interface)
  // --------------------------------------------------------------------------
  input  logic [DATA_WIDTH-1:0] data_in_i,
  input  logic                  data_in_valid_i,
  output logic                  data_in_ready_o,
  input  logic                  data_in_last_i,
  input  logic [2:0]            data_in_bytes_i,

  // --------------------------------------------------------------------------
  // Stream de Saída de Dados (Sponge Squeeze / Digest Interface)
  // --------------------------------------------------------------------------
  output logic [DATA_WIDTH-1:0] data_out_o,
  output logic                  data_out_valid_o,
  input  logic                  data_out_ready_i,
  output logic                  data_out_last_o,

  // --------------------------------------------------------------------------
  // Sinais de Status e Telemetria para o Sistema / CSRs
  // --------------------------------------------------------------------------
  output logic                  ready_o,
  output logic                  busy_o,
  output logic                  done_o,
  output logic                  error_o
);

  // --------------------------------------------------------------------------
  // Constantes internas do barramento e limites de saída
  // --------------------------------------------------------------------------
  localparam int DATA_BYTES      = DATA_WIDTH / 8;
  localparam int MAX_RATE_BYTES  = 168; // SHAKE128: rate máximo de 1344 bits
  localparam int SHA3_256_BYTES  = 32;  // Digest fixo de SHA3-256
  localparam int SHA3_512_BYTES  = 64;  // Digest fixo de SHA3-512
  localparam int SHAKE_BLOCK_OUT = MAX_RATE_BYTES; // Bloco liberado por comando SQUEEZE

  // --------------------------------------------------------------------------
  // Retorno após a permutação: permite reutilizar ST_PERMUTE para absorção,
  // padding final e geração de blocos adicionais em SHAKE.
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {
    RET_DONE    = 2'b00,
    RET_ABSORB  = 2'b01,
    RET_SQUEEZE = 2'b10
  } perm_return_e;

  // --------------------------------------------------------------------------
  // Registradores de Estado Interno e Controle de Rodadas
  // --------------------------------------------------------------------------
  logic [1599:0] keccak_state_q, keccak_state_d;
  logic [4:0]    round_cnt_q, round_cnt_d;
  keccak_fsm_e   state_q, state_d;
  logic [7:0]    absorb_pos_q, absorb_pos_d;       // Offset em bytes dentro da taxa (rate)
  logic [7:0]    squeeze_pos_q, squeeze_pos_d;     // Próximo byte a extrair da taxa
  logic [7:0]    squeeze_limit_q, squeeze_limit_d; // Limite de saída do comando corrente
  keccak_mode_e  mode_q, mode_d;                   // Modo travado para manter contexto
  perm_return_e  perm_return_q, perm_return_d;     // Próximo estado após 24 rodadas
  logic          pending_valid_q, pending_valid_d; // Fila simples para comando recebido durante permutação
  keccak_mode_e  pending_mode_q, pending_mode_d;
  keccak_cmd_e   pending_cmd_q, pending_cmd_d;

  logic [1599:0] perm_state_out_s;

  // --------------------------------------------------------------------------
  // Declaração de Funções Auxiliares Internas
  // --------------------------------------------------------------------------

  // Função 1: Rotação circular de bits à esquerda para palavras de 64 bits
  // (FIPS 202 §3.2.2). Mantida no top-level para rastreabilidade das
  // pendências originais, delegando para a função comum do pacote.
  function automatic logic [63:0] rotl64(
    input logic [63:0] val_i,
    input logic [5:0]  shift_i
  );
    begin
      rotl64 = keccak_rotl64(val_i, shift_i);
    end
  endfunction : rotl64

  // Função 2: Retorna a constante de rodada RC[i_r] conforme FIPS 202 §3.2.5.
  function automatic logic [63:0] get_round_constant(
    input logic [4:0] round_idx_i
  );
    begin
      get_round_constant = keccak_round_constant(round_idx_i);
    end
  endfunction : get_round_constant

  // Função 3: Retorna o byte do sufixo de padding de domínio
  // (FIPS 202 §6.1/§6.2 e FIPS 203 §4.1).
  // SHA3-256 / SHA3-512 -> Sufixo 0x06 (00000110b)
  // SHAKE128 / SHAKE256 -> Sufixo 0x1F (00011111b)
  function automatic logic [7:0] get_domain_pad_byte(
    input keccak_mode_e mode_i
  );
    begin
      unique case (mode_i)
        MODE_SHA3_256,
        MODE_SHA3_512: get_domain_pad_byte = 8'h06;
        MODE_SHAKE128,
        MODE_SHAKE256: get_domain_pad_byte = 8'h1F;
        default:       get_domain_pad_byte = 8'h00;
      endcase
    end
  endfunction : get_domain_pad_byte

  // Função 4: Retorna a largura do Rate (r em bits) baseado no modo selecionado.
  // Valores rastreáveis à FIPS 202 e às primitivas chamadas pela FIPS 203 §4.1:
  // SHAKE128: r = 1344 bits (c = 256)
  // SHAKE256: r = 1088 bits (c = 512)
  // SHA3-256: r = 1088 bits (c = 512)
  // SHA3-512: r = 576 bits  (c = 1024)
  function automatic logic [11:0] get_rate_width(
    input keccak_mode_e mode_i
  );
    begin
      unique case (mode_i)
        MODE_SHA3_512: get_rate_width = 12'd576;
        MODE_SHAKE128: get_rate_width = 12'd1344;
        MODE_SHA3_256,
        MODE_SHAKE256: get_rate_width = 12'd1088;
        default:       get_rate_width = 12'd1088;
      endcase
    end
  endfunction : get_rate_width

  // Converte a taxa de bits para bytes; todos os modos suportados possuem
  // taxa múltipla de 8 bits.
  function automatic logic [7:0] get_rate_bytes(
    input keccak_mode_e mode_i
  );
    begin
      get_rate_bytes = get_rate_width(mode_i) >> 3;
    end
  endfunction : get_rate_bytes

  // Define quantos bytes o comando SQUEEZE atual deve entregar. SHA3 possui
  // digest fixo; SHAKE é XOF e libera um bloco de rate por comando.
  function automatic logic [7:0] get_squeeze_limit(
    input keccak_mode_e mode_i
  );
    begin
      unique case (mode_i)
        MODE_SHA3_256: get_squeeze_limit = SHA3_256_BYTES[7:0];
        MODE_SHA3_512: get_squeeze_limit = SHA3_512_BYTES[7:0];
        default:       get_squeeze_limit = SHAKE_BLOCK_OUT[7:0];
      endcase
    end
  endfunction : get_squeeze_limit

  // Normaliza data_in_bytes_i. Como o campo possui 3 bits, o valor 0 é usado
  // para representar 8 bytes válidos em uma palavra cheia.
  function automatic logic [3:0] valid_input_bytes(
    input logic [2:0] encoded_bytes_i
  );
    begin
      // A interface histórica usa 3 bits; valor 0 codifica palavra cheia (8 B).
      valid_input_bytes = (encoded_bytes_i == 3'd0) ? 4'd8 : {1'b0, encoded_bytes_i};
    end
  endfunction : valid_input_bytes

  // Função 5: Zeroização segura do estado interno (Requisito FIPS 203 §3.3).
  // Apaga resíduos de sementes, chaves derivadas e material pseudoaleatório.
  function automatic logic [1599:0] keccak_state_zeroize();
    begin
      keccak_state_zeroize = 1600'h0;
    end
  endfunction : keccak_state_zeroize

  // --------------------------------------------------------------------------
  // Instanciação do Núcleo da Permutação Keccak-f[1600] (Submódulo)
  // --------------------------------------------------------------------------
  keccak_f1600_round_core u_keccak_round (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .state_i        (keccak_state_q),
    .round_number_i (round_cnt_q),
    .state_o        (perm_state_out_s)
  );

  // --------------------------------------------------------------------------
  // Registradores sequenciais da FSM e do estado criptográfico
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q        <= ST_IDLE;
      keccak_state_q <= '0;
      round_cnt_q    <= '0;
    end else if (zeroize_i) begin
      state_q        <= ST_ZEROIZE;
      keccak_state_q <= keccak_state_zeroize(); // TODO: Aplicar zeroização completa
      round_cnt_q    <= '0;
    end else begin
      state_q        <= state_d;
      keccak_state_q <= keccak_state_d;
      round_cnt_q    <= round_cnt_d;
    end
  end

  // --------------------------------------------------------------------------
  // Lógica Combinacional de Transição de Estados e Controle da Esponja
  // --------------------------------------------------------------------------
  always_comb begin
    // Valores padrão para evitar latches
    state_d         = state_q;
    keccak_state_d  = keccak_state_q;
    round_cnt_d     = round_cnt_q;
    
    data_in_ready_o  = 1'b0;
    data_out_o       = '0;
    data_out_valid_o = 1'b0;
    data_out_last_o  = 1'b0;
    ready_o          = 1'b0;
    busy_o           = 1'b1;
    done_o           = 1'b0;
    error_o          = 1'b0;

    case (state_q)
      ST_IDLE: begin
        ready_o = 1'b1;
        busy_o  = 1'b0;
        if (start_i) begin
          case (cmd_i)
            CMD_INIT:    state_d = ST_IDLE;    // TODO: Resetar apenas o estado Keccak
            CMD_ABSORB:  state_d = ST_ABSORB;  // TODO: Iniciar absorção de bloco
            CMD_FINISH:  state_d = ST_PADDING; // TODO: Ir para padding pad10*1
            CMD_SQUEEZE: state_d = ST_SQUEEZE; // TODO: Iniciar extração de palavras
            default:     state_d = ST_IDLE;
          endcase
        end
      end

      ST_ABSORB: begin
        // Sinaliza que o motor está pronto para receber palavras de dados
        // enquanto houver espaço na porção rate do estado.
        data_in_ready_o = 1'b1;
        
        // TODO: Executar XOR do data_in_i no segmento de Rate r do keccak_state_q
        // TODO: Avançar para ST_PERMUTE quando um bloco completo de tamanho r for absorvido
        if (data_in_valid_i && data_in_ready_o) begin
          if (data_in_last_i) begin
            state_d = ST_IDLE; // Retorna para IDLE aguardando o próximo comando
          end
        end
      end

      ST_PADDING: begin
        // TODO: Aplicar o sufixo de domínio (get_domain_pad_byte) e o bit final de pad10*1 no limite da taxa r
        // TODO: Transicionar para ST_PERMUTE para rodar as 24 rodadas finais da absorção
        state_d = ST_DONE; // Simula conclusão do bloco de padding no stub
      end

      ST_PERMUTE: begin
        // TODO: Iterar round_cnt_q de 0 a 23 usando perm_state_out_s
        // TODO: Após 24 rodadas, transicionar para ST_IDLE, ST_SQUEEZE ou ST_DONE
        state_d = ST_DONE;
      end

      ST_SQUEEZE: begin
        // TODO: Fornecer palavras de DATA_WIDTH a partir da parte r do estado keccak_state_q
        // TODO: Se mais bytes forem requisitados além da taxa r, disparar nova permutação ST_PERMUTE (XOF/Squeeze)
        data_out_valid_o = 1'b1;
        data_out_o       = 64'hA5A5A5A5A5A5A5A5; // Valor fictício para teste de extração no stub
        
        if (data_out_ready_i) begin
          data_out_last_o = 1'b1;
          state_d         = ST_DONE;
        end
      end

      ST_ZEROIZE: begin
        // TODO: Limpar buffers e retornar para ST_IDLE
        state_d = ST_IDLE;
      end

      ST_DONE: begin
        done_o  = 1'b1;
        busy_o  = 1'b0;
        state_d = ST_IDLE;
      end

      default: state_d = ST_IDLE;
    endcase
  end

endmodule : mlkem_keccak_engine
