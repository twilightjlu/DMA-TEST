module dma_fsm
  import amba_axi_pkg::*;
  import dma_pkg::*;
(
  input                                     clk,
  input                                     rst,
  // From/To CSRs
  input   s_dma_control_t                   dma_ctrl_i,
  input   s_dma_desc_t [`DMA_NUM_DESC-1:0]  dma_desc_i,
  output  s_dma_status_t                    dma_stats_o,
  output  s_dma_error_t                     dma_error_o,
  // To/From streamers
  output  s_dma_str_in_t                    dma_stream_rd_o,
  input   s_dma_str_out_t                   dma_stream_rd_i,
  output  s_dma_str_in_t                    dma_stream_wr_o,
  input   s_dma_str_out_t                   dma_stream_wr_i,
  // From/To AXI I/F
  output  logic                             dma_fsm_clear_o,
  output  logic                             dma_fsm_active_o,
  input   s_dma_error_t                     axi_txn_err_i,
  input                                     dma_axi_outsding_pend_i
);
  dma_st_t cur_st_ff, next_st;
  logic [`DMA_NUM_DESC-1:0] rd_desc_done_ff, next_rd_desc_done;
  logic [`DMA_NUM_DESC-1:0] wr_desc_done_ff, next_wr_desc_done;

  logic desc_is_running; // Gets set when there are pending descriptors to process
  logic desc_rd_is_running, desc_wr_is_running;
  logic abort_ff;

  // check if csr descriptors are valid
  function automatic logic check_cfg();
    logic [`DMA_NUM_DESC-1:0] valid_desc;

    valid_desc = '0;

    for (int i=0; i<`DMA_NUM_DESC; i++) begin
      if (dma_desc_i[i].enable) begin
        valid_desc[i] = (|dma_desc_i[i].num_bytes);
      end
    end
    return |valid_desc;
  endfunction

  // ------------------------------------------------------------------------------
  // FSM
  // ------------------------------------------------------------------------------
  always_comb begin : fsm_dma_ctrl
    next_st = DMA_ST_IDLE;

    case (cur_st_ff)
      DMA_ST_IDLE: begin
        if (dma_ctrl_i.go) begin
          next_st = DMA_ST_CFG;
        end
      end
      DMA_ST_CFG: begin
        // if any csr descriptor is valid, start running
        if (~dma_ctrl_i.abort_req && check_cfg()) begin
          next_st = DMA_ST_RUN;
        end
        else begin
          next_st = DMA_ST_DONE;
        end
      end
      DMA_ST_RUN: begin
        // dma is still running
        if (desc_is_running || dma_axi_outsding_pend_i) begin
          next_st = DMA_ST_RUN;
        end
        else begin
          next_st = DMA_ST_DONE;
        end
      end
      DMA_ST_DONE: begin
        if (dma_ctrl_i.go) begin
          next_st = DMA_ST_DONE;
        end
        else begin
          next_st = DMA_ST_IDLE;
        end
      end
    endcase
  end : fsm_dma_ctrl

  // dma status
  always_comb begin : dma_status
    dma_error_o = s_dma_error_t'('0);

    if (axi_txn_err_i.valid) begin
      dma_error_o.addr     = axi_txn_err_i.addr;
      dma_error_o.type_err = DMA_ERR_OPE;
      dma_error_o.src      = axi_txn_err_i.src;
      dma_error_o.valid    = 1'b1;
    end
    dma_stats_o.error = axi_txn_err_i.valid;
    dma_stats_o.done  = (cur_st_ff == DMA_ST_DONE);
    dma_fsm_clear_o       = (cur_st_ff == DMA_ST_DONE) && (next_st == DMA_ST_IDLE);
  end : dma_status

  assign dma_fsm_active_o = (cur_st_ff == DMA_ST_RUN);

  // streamer status
  assign desc_is_running = desc_rd_is_running || desc_wr_is_running;
  assign desc_rd_is_running = (cur_st_ff == DMA_ST_RUN) & dma_stream_rd_o.valid;
  assign desc_wr_is_running = (cur_st_ff == DMA_ST_RUN) & dma_stream_wr_o.valid;

  // ------------------------------------------------------------------------------
  // FSM to Streamer Control
  // ------------------------------------------------------------------------------
  always_comb begin : rd_streamer
    dma_stream_rd_o   = s_dma_str_in_t'('0);
    next_rd_desc_done = rd_desc_done_ff;

    // any csr descriptor is valid
    if (cur_st_ff == DMA_ST_RUN) begin
      for (int i=0; i<`DMA_NUM_DESC; i++) begin
        if (dma_desc_i[i].enable && (|dma_desc_i[i].num_bytes) && (~rd_desc_done_ff[i])) begin
          dma_stream_rd_o.valid = ~abort_ff;
          dma_stream_rd_o.idx   = i;
          break;
        end
      end

      if (dma_stream_rd_i.done) begin
        next_rd_desc_done[dma_stream_rd_o.idx] = 1'b1;
      end
    end

    if (cur_st_ff == DMA_ST_DONE) begin
      next_rd_desc_done = '0;
    end
  end : rd_streamer

  always_comb begin : wr_streamer
    dma_stream_wr_o   = s_dma_str_in_t'('0);
    next_wr_desc_done = wr_desc_done_ff;

    if (cur_st_ff == DMA_ST_RUN) begin
      for (int i=0; i<`DMA_NUM_DESC; i++) begin
        if (dma_desc_i[i].enable && (|dma_desc_i[i].num_bytes) && (~wr_desc_done_ff[i])) begin
          dma_stream_wr_o.idx   = i;
          dma_stream_wr_o.valid = ~abort_ff;
          break;
        end
      end

      if (dma_stream_wr_i.done) begin
        next_wr_desc_done[dma_stream_wr_o.idx] = 1'b1;
      end
    end

    if (cur_st_ff == DMA_ST_DONE) begin
      next_wr_desc_done = '0;
    end
  end : wr_streamer

  always_ff @ (posedge clk) begin
    if (rst) begin
      cur_st_ff       <= dma_st_t'('0);
      rd_desc_done_ff <= '0;
      wr_desc_done_ff <= '0;
      abort_ff        <= '0;
    end
    else begin
      cur_st_ff       <= next_st;
      rd_desc_done_ff <= next_rd_desc_done;
      wr_desc_done_ff <= next_wr_desc_done;
      abort_ff        <= dma_ctrl_i.abort_req;
    end
  end
endmodule
