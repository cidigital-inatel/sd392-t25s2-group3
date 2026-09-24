// Código de exemplo para o UVM: Codificador binário para Gray (síncrono)
module gray_encoder_sync #(
  parameter int DATA_WIDTH = 4
) (
  input  logic                  clk,
  input  logic                  reset_n,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
);
  always_ff @(posedge clk) begin
    if (!reset_n)
      data_out <= '0;
    else
      data_out <= data_in ^ (data_in >> 1);
  end
endmodule
