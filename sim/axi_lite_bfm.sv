`timescale 1ns/1ps

// AXI4-Lite BFM para acesso de registradores/CSRs do DUT.
// Observação: larguras exatas dos campos devem ser confirmadas na especificação do projeto.
interface axi_lite_bfm #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned CLK_FREQ_MHZ = 100
);
    localparam time CLK_PERIOD = (1_000.0 / CLK_FREQ_MHZ) * 1ns;

    logic ACLK;
    logic ARESETn;

    // Canal de endereço de escrita
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic                  AWVALID;
    logic                  AWREADY;

    // Canal de dados de escrita
    logic [DATA_WIDTH-1:0] WDATA;
    logic                  WVALID;
    logic                  WREADY;

    // Canal de resposta de escrita
    logic [1:0]            BRESP;
    logic                  BVALID;
    logic                  BREADY;

    // Canal de endereço de leitura
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic                  ARVALID;
    logic                  ARREADY;

    // Canal de dados de leitura
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RREADY;

    // Geração do sinal de clock.
    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD / 2) ACLK = ~ACLK;
    end

    // Reset do DUT, tratado de forma síncrona ao clock.
    task automatic reset_assert(int unsigned cycles = 3);
        AWADDR  = '0;
        AWVALID = 1'b0;
        WDATA   = '0;
        WVALID  = 1'b0;
        BREADY  = 1'b0;

        ARADDR  = '0;
        ARVALID = 1'b0;
        RREADY  = 1'b0;

        ARESETn = 1'b0;
        repeat (cycles) @(posedge ACLK);
        @(negedge ACLK);
        ARESETn = 1'b1;
    endtask

    function automatic bit reset_is_asserted();
        return !ARESETn;
    endfunction

    // Escrita em um endereço de CSR/registro.
    task automatic write_reg(input logic [ADDR_WIDTH-1:0] addr,
                             input logic [DATA_WIDTH-1:0] data,
                             output logic [1:0] resp);
        // Endereço da transação
        AWADDR  = addr;
        AWVALID = 1'b1;

        // Dados da transação
        WDATA   = data;
        WVALID  = 1'b1;

        // Espera handshake de endereço
        while (!(AWVALID && AWREADY)) @(posedge ACLK);
        AWVALID = 1'b0;

        // Espera handshake de dados
        while (!(WVALID && WREADY)) @(posedge ACLK);
        WVALID = 1'b0;

        // Espera resposta do DUT
        BREADY = 1'b1;
        while (!(BVALID && BREADY)) @(posedge ACLK);
        resp = BRESP;
        BREADY = 1'b0;
    endtask

    // Leitura de um endereço de CSR/registro.
    task automatic read_reg(input logic [ADDR_WIDTH-1:0] addr,
                            output logic [DATA_WIDTH-1:0] data,
                            output logic [1:0] resp);
        ARADDR  = addr;
        ARVALID = 1'b1;

        while (!(ARVALID && ARREADY)) @(posedge ACLK);
        ARVALID = 1'b0;

        RREADY = 1'b1;
        while (!(RVALID && RREADY)) @(posedge ACLK);
        data = RDATA;
        resp = RRESP;
        RREADY = 1'b0;
    endtask
endinterface
