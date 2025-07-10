module dma_fifo
  import amba_axi_pkg::*;
  import dma_pkg::*;
#(
  parameter int DEPTH = `DMA_FIFO_DEPTH,
  parameter int WIDTH = `DMA_DATA_WIDTH
)(
  input                                       clk,
  input                                       rst,

  input                                       write_i,
  input         [WIDTH-1:0]                   data_i,

  input                                       read_i,
  output  logic [WIDTH-1:0]                   data_o,

  output  logic                               full_o,
  output  logic                               empty_o,
  output  logic                               error_o,
  output  logic [$clog2(DEPTH>1?DEPTH:2):0]   ocup_o,
  input                                       clear_i,
  output  logic [$clog2(DEPTH>1?DEPTH:2):0]   free_o
);
  `define MSB_SLOT  $clog2(DEPTH>1?DEPTH:2)
  typedef logic [$clog2(DEPTH>1?DEPTH:2):0] msb_t;

  logic [DEPTH-1:0] [WIDTH-1:0] fifo_ff;
  msb_t                         write_ptr_ff;
  msb_t                         read_ptr_ff;
  msb_t                         next_write_ptr;
  msb_t                         next_read_ptr;
  msb_t                         fifo_ocup;

  always_comb begin
    next_read_ptr = read_ptr_ff;
    next_write_ptr = write_ptr_ff;
    if (DEPTH == 1) begin
      empty_o = (write_ptr_ff == read_ptr_ff);
      full_o  = (write_ptr_ff[0] != read_ptr_ff[0]);
      data_o  = empty_o ? '0 : fifo_ff[0];
    end
    else begin
      empty_o = (write_ptr_ff == read_ptr_ff);
      full_o  = (write_ptr_ff[`MSB_SLOT-1:0] == read_ptr_ff[`MSB_SLOT-1:0]) &&
                (write_ptr_ff[`MSB_SLOT] != read_ptr_ff[`MSB_SLOT]);
      data_o  = empty_o ? '0 : fifo_ff[read_ptr_ff[`MSB_SLOT-1:0]];
    end

    if (write_i && ~full_o)
      next_write_ptr = write_ptr_ff + 'd1;

    if (read_i && ~empty_o)
      next_read_ptr = read_ptr_ff + 'd1;

    error_o = (write_i && full_o) || (read_i && empty_o);
    fifo_ocup = write_ptr_ff - read_ptr_ff;
    free_o = msb_t'(DEPTH) - fifo_ocup;
    ocup_o = fifo_ocup;
  end

  always_ff @ (posedge clk) begin
    if (rst) begin
      write_ptr_ff <= '0;
      read_ptr_ff  <= '0;
    end
    else begin
      if (clear_i) begin
        write_ptr_ff <= '0;
        read_ptr_ff  <= '0;
      end
      else begin
        write_ptr_ff <= next_write_ptr;
        read_ptr_ff <= next_read_ptr;
        if (write_i && ~full_o) begin
          if (DEPTH == 1) begin
            fifo_ff[0] <= data_i;
          end
          else begin
            fifo_ff[write_ptr_ff[`MSB_SLOT-1:0]] <= data_i;
          end
        end
      end
    end
  end

// `ifndef NO_ASSERTIONS
//   initial begin
//     illegal_fifo_slot : assert (2**$clog2(DEPTH) == DEPTH)
//     else $error("FIFO Slots must be power of 2");

//     min_fifo_size : assert (DEPTH >= 1)
//     else $error("FIFO size of DEPTH defined is illegal!");
//   end
// `endif

endmodule
