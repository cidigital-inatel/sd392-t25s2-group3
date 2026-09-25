// ============================================================================
// Projeto: Acelerador ML-KEM com Interface AXI4 (Entregável M1.2)
// Módulo: Motor Keccak (Keccak-f[1600] / SHA-3 / SHAKE Engine)
// Padrões de Referência: NIST FIPS 202 (SHA-3/Keccak) e NIST FIPS 203 (ML-KEM)
// Linguagem: SystemVerilog
// ============================================================================
// Descrição:
//   Stub estrutural do Motor Keccak para o acelerador ML-KEM. Este módulo é
//   responsável por executar as primitivas criptográficas SHA3-256, SHA3-512,
//   SHAKE128 e SHAKE256, que alimentam as funções de expansão de matriz (SampleNTT),
//   amostragem de ruído (SamplePolyCBD via PRF), derivação de chaves (H, G, J)
//   e rejeição implícita conforme especificado no NIST FIPS 203 (4.1).
// ============================================================================

package mlkem_keccak_pkg;

  // --------------------------------------------------------------------------
  // Enumeração dos Modos de Operação do Motor Keccak (FIPS 202 / FIPS 203 4.1)
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

  // Constantes de estrutura da permutação Keccak-f[1600] (FIPS 202 3.2)
  localparam int KECCAK_STATE_BITS = 1600;
  localparam int KECCAK_LANES      = 25;    // Estado organizado em matriz 5x5 de lanes de 64 bits
  localparam int KECCAK_LANE_BITS  = 64;
  localparam int KECCAK_ROUNDS     = 24;    // 24 rodadas por permutação f[1600]

endpackage : mlkem_keccak_pkg


// ============================================================================
// Submódulo Stub 1: Etapa Theta (FIPS 202 3.2.1)
// ============================================================================
module keccak_step_theta (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada (1600 bits)
  output logic [1599:0] state_out_o   // Estado transformado após difusão Theta
);
  // TODO: Implementar cálculo das paridades das colunas C[x] e D[x]
  // TODO: XOR das paridades vizinhas em cada lane do estado A[x,y,z]
  assign state_out_o = '0; // TODO: Substituir por lógica combinacional
endmodule : keccak_step_theta


// ============================================================================
// Submódulo Stub 2: Etapa Rho (FIPS 202 3.2.2)
// ============================================================================
module keccak_step_rho (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após rotações de bits
);
  // TODO: Implementar rotação de bits por lane conforme Tabela 2 do FIPS 202
  assign state_out_o = '0; // TODO: Substituir por mapa de rotações
endmodule : keccak_step_rho


// ============================================================================
// Submódulo Stub 3: Etapa Pi (FIPS 202 3.2.3)
// ============================================================================
module keccak_step_pi (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após permutação de posições
);
  // TODO: Reorganizar posições das lanes A[x,y] -> A[y, 2x+3y mod 5]
  assign state_out_o = '0; // TODO: Substituir por permutação de fiação
endmodule : keccak_step_pi


// ============================================================================
// Submódulo Stub 4: Etapa Chi (FIPS 202 3.2.4)
// ============================================================================
module keccak_step_chi (
  input  logic [1599:0] state_in_i,   // Estado interno de entrada
  output logic [1599:0] state_out_o   // Estado transformado após não-linearidade NOT/AND/XOR
);
  // TODO: Aplicar transformação não-linear A[x] ^ ((~A[x+1]) & A[x+2]) por linha
  assign state_out_o = '0; // TODO: Substituir por portas não-lineares
endmodule : keccak_step_chi


// ============================================================================
// Submódulo Stub 5: Etapa Iota (FIPS 202 3.2.5)
// ============================================================================
module keccak_step_iota (
  input  logic [1599:0] state_in_i,    // Estado interno de entrada
  input  logic [4:0]    round_idx_i,   // Índice da rodada atual (0 a 23)
  output logic [1599:0] state_out_o    // Estado transformado após injeção da constante RC
);
  // TODO: Adicionar constante de rodada RC[i_r] ao lane (0,0) do estado
  assign state_out_o = '0; // TODO: Substituir por injeção de constante
endmodule : keccak_step_iota


// ============================================================================
// Submódulo Stub 6: Núcleo de Rodada da Permutação Keccak-f[1600]
// ============================================================================
module keccak_f1600_round_core (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic [1599:0] state_i,       // Estado atual
  input  logic [4:0]    round_number_i,// Número da rodada
  output logic [1599:0] state_o        // Estado após 1 rodada R = iota o chi o pi o rho o theta
);

  // Instanciações encadeadas das 5 etapas da rodada Keccak
  logic [1599:0] state_theta;
  logic [1599:0] state_rho;
  logic [1599:0] state_pi;
  logic [1599:0] state_chi;
  logic [1599:0] state_iota;

  // Declaração e Conexão dos Submódulos das Etapas (FIPS 202)
  keccak_step_theta u_theta (.state_in_i(state_i),     .state_out_o(state_theta)); // TODO: Validar conexão
  keccak_step_rho   u_rho   (.state_in_i(state_theta), .state_out_o(state_rho));   // TODO: Validar conexão
  keccak_step_pi    u_pi    (.state_in_i(state_rho),   .state_out_o(state_pi));    // TODO: Validar conexão
  keccak_step_chi   u_chi   (.state_in_i(state_pi),    .state_out_o(state_chi));   // TODO: Validar conexão
  keccak_step_iota  u_iota  (.state_in_i(state_chi),   .round_idx_i(round_number_i), .state_out_o(state_iota)); // TODO: Validar conexão

  assign state_o = state_iota;

endmodule : keccak_f1600_round_core


// ============================================================================
// Módulo Top-Level Stub: Motor Keccak Completo (Deliverable M1.2)
// ============================================================================
module mlkem_keccak_engine
  import mlkem_keccak_pkg::*;
#(
  parameter int DATA_WIDTH = 64  // Largura do barramento de dados de E/S (64 bits)
)(
  // --------------------------------------------------------------------------
  // Sinais Globais de Clock e Reset (Ativo em Nível Baixo)
  // --------------------------------------------------------------------------
  input  logic                  clk_i,          // Clock principal do acelerador
  input  logic                  rst_ni,         // Reset assíncrono ativo baixo

  // --------------------------------------------------------------------------
  // Interface de Controle Criptográfico e Configuração de Modo
  // --------------------------------------------------------------------------
  input  logic                  start_i,        // Pulso para iniciar nova operação
  input  keccak_mode_e          mode_i,         // Seleção do algoritmo: SHA3_256, SHA3_512, SHAKE128, SHAKE256
  input  keccak_cmd_e           cmd_i,          // Comando: INIT, ABSORB, FINISH, SQUEEZE
  input  logic                  zeroize_i,      // Sinal de força maior para limpeza de chaves/estado

  // --------------------------------------------------------------------------
  // Stream de Entrada de Dados (Sponge Absorb Interface)
  // --------------------------------------------------------------------------
  input  logic [DATA_WIDTH-1:0] data_in_i,      // Palavra de dados de entrada
  input  logic                  data_in_valid_i,// Handshake: Dados de entrada válidos
  output logic                  data_in_ready_o,// Handshake: Motor pronto para receber dados
  input  logic                  data_in_last_i, // Indicador de último bloco/palavra da mensagem
  input  logic [2:0]            data_in_bytes_i,// Quantidade de bytes válidos na última palavra (1 a 8 bytes)

  // --------------------------------------------------------------------------
  // Stream de Saída de Dados (Sponge Squeeze / Digest Interface)
  // --------------------------------------------------------------------------
  output logic [DATA_WIDTH-1:0] data_out_o,     // Palavra de dados extraída (Hash / XOF Output)
  output logic                  data_out_valid_o,// Handshake: Dados de saída válidos
  input  logic                  data_out_ready_i,// Handshake: Consumidor pronto para receber dados
  output logic                  data_out_last_o,// Indicador de última palavra do bloco/squeeze

  // --------------------------------------------------------------------------
  // Sinais de Status e Telemetria para o Sistema / CSRs
  // --------------------------------------------------------------------------
  output logic                  ready_o,        // Motor Keccak pronto para novo comando
  output logic                  busy_o,         // Motor Keccak processando permutação
  output logic                  done_o,         // Pulso de operação/squeeze concluído
  output logic                  error_o         // Indicador de erro de protocolo/fronteira
);

  // --------------------------------------------------------------------------
  // Registradores de Estado Interno e Controle de Rodadas
  // --------------------------------------------------------------------------
  logic [1599:0] keccak_state_q, keccak_state_d; // Matriz 5x5 de 64-bit lanes (1600 bits)
  logic [4:0]    round_cnt_q, round_cnt_d;       // Contador de rodadas (0 a 23)
  keccak_fsm_e   state_q, state_d;               // Estado da FSM principal
  logic [1087:0] rate_mask_s;                    // Máscara correspondente à Taxa (Rate r)
  logic [7:0]    pad_byte_s;                     // Sufixo de domínio/padding conforme modo

  // --------------------------------------------------------------------------
  // Declaração de Funções Auxiliares Internas (Stubs - TODO)
  // --------------------------------------------------------------------------

  // Função 1: Rotação circular de bits à esquerda para palavras de 64 bits (FIPS 202 3.2.2)
  function automatic logic [63:0] rotl64(
    input logic [63:0] val_i,
    input logic [5:0]  shift_i
  );
    // TODO: Implementar rotação de bits ((val_i << shift_i) | (val_i >> (64 - shift_i)))
    return 64'h0;
  endfunction : rotl64

  // Função 2: Retorna a constante de rodada RC[i_r] conforme FIPS 202 3.2.5 Tabela 5
  function automatic logic [63:0] get_round_constant(
    input logic [4:0] round_idx_i
  );
    // TODO: Implementar tabela de constantes RC para as 24 rodadas
    return 64'h0;
  endfunction : get_round_constant

  // Função 3: Retorna o byte do sufixo de padding de domínio (FIPS 202 6.1, 6.2 e FIPS 203 4.1)
  function automatic logic [7:0] get_domain_pad_byte(
    input keccak_mode_e mode_i
  );
    // SHA3-256 / SHA3-512 -> Sufixo 0x06 (00000110b)
    // SHAKE128 / SHAKE256 -> Sufixo 0x1F (00011111b)
    // TODO: Retornar o sufixo correto com base no modo selecionado
    return 8'h00;
  endfunction : get_domain_pad_byte

  // Função 4: Retorna a largura do Rate (r em bits) baseado no modo selecionado
  function automatic logic [11:0] get_rate_width(
    input keccak_mode_e mode_i
  );
    // SHAKE128: r = 1344 bits (c = 256)
    // SHAKE256: r = 1088 bits (c = 512)
    // SHA3-256: r = 1088 bits (c = 512)
    // SHA3-512: r = 576 bits  (c = 1024)
    // TODO: Implementar mapeamento de taxa r
    return 12'd0;
  endfunction : get_rate_width

  // Função 5: Zeroização segura do estado interno (Requisito FIPS 203 3.3)
  function automatic logic [1599:0] keccak_state_zeroize();
    // TODO: Forçar limpezas síncronas para apagar resíduos de sementes e chaves
    return 1600'h0;
  endfunction : keccak_state_zeroize


  // --------------------------------------------------------------------------
  // Instanciação do Núcleo da Permutação Keccak-f[1600] (Submódulo)
  // --------------------------------------------------------------------------
  logic [1599:0] perm_state_out_s;

  keccak_f1600_round_core u_keccak_round (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .state_i        (keccak_state_q),
    .round_number_i (round_cnt_q),
    .state_o        (perm_state_out_s)
  ); // TODO: Verificar temporização e pipeline da permutação


  // --------------------------------------------------------------------------
  // Lógica de Máquina de Estados Finos (FSM) do Motor Keccak (Stub)
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

  // Lógica Combinacional de Transição de Estados e Controle da Esponja (Stub)
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
        // Sinaliza que o motor está pronto para receber palavras de dados (Handshake)
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
