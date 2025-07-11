`define AXI_ADDR_WIDTH        32
`define AXI_DATA_WIDTH        256
`define AXI_ALEN_WIDTH        8
`define AXI_ASIZE_WIDTH       3
`define AXI_MAX_OUTSTD_RD     2
`define AXI_MAX_OUTSTD_WR     2
`define AXI_USER_RESP_WIDTH   1
`define AXI_USER_REQ_WIDTH    1
`define AXI_USER_DATA_WIDTH   1
`define AXI_TXN_ID_WIDTH      4

package amba_axi_pkg;

  //*******************************
  //  AXI - AXIv4
  //*******************************

  typedef logic [`AXI_ADDR_WIDTH-1:0]       axi_addr_t;
  typedef logic [`AXI_DATA_WIDTH-1:0]       axi_data_t;
  typedef logic [`AXI_ALEN_WIDTH-1:0]       axi_alen_t;
  typedef logic [(`AXI_DATA_WIDTH/8)-1:0]   axi_wr_strb_t;
  typedef logic [`AXI_USER_REQ_WIDTH-1:0]   axi_user_req_t;
  typedef logic [`AXI_USER_DATA_WIDTH-1:0]  axi_user_data_t;
  typedef logic [`AXI_USER_RESP_WIDTH-1:0]  axi_user_rsp_t;
  typedef logic [`AXI_TXN_ID_WIDTH-1:0]     axi_tid_t;

  typedef enum logic [`AXI_ASIZE_WIDTH-1:0] {
    AXI_BYTE,
    AXI_HALF_WORD,
    AXI_WORD,
    AXI_DWORD,
    AXI_BYTES_16,
    AXI_BYTES_32,
    AXI_BYTES_64,
    AXI_BYTES_128
  } axi_size_t;

  typedef enum logic [1:0] {
    AXI_FIXED,
    AXI_INCR,
    AXI_WRAP,
    AXI_RESERVED
  } axi_burst_t;

  typedef enum logic [1:0] {
    AXI_OKAY,
    AXI_EXOKAY,
    AXI_SLVERR,
    AXI_DECERR
  } axi_resp_t;

  typedef enum logic [2:0] {
    AXI_INSTRUCTION = 'b100,
    AXI_NONSECURE   = 'b010,
    AXI_SECURE      = 'b001
  } axi_prot_t;

  typedef struct packed {
    // Globals
    logic           aclk;
    logic           arst;
  } s_axi_glb_t;

  typedef struct packed {
    // Write Addr channel
    logic           awready;
    // Write Data channel
    logic           wready;
    // Write Response channel
    axi_tid_t       bid;
    axi_resp_t      bresp;
    axi_user_rsp_t  buser;
    logic           bvalid;
    // Read addr channel
    logic           arready;
    // Read data channel
    axi_tid_t       rid;
    axi_data_t      rdata;
    axi_resp_t      rresp;
    logic           rlast;
    axi_user_req_t  ruser;
    logic           rvalid;
  } s_axi_miso_t;

  typedef struct packed {
    // Write Address channel
    axi_tid_t       awid;
    axi_addr_t      awaddr;
    axi_alen_t      awlen;
    axi_size_t      awsize;
    axi_burst_t     awburst;
    logic           awlock;
    logic [3:0]     awcache;
    axi_prot_t      awprot;
    logic [3:0]     awqos;
    logic [3:0]     awregion;
    axi_user_req_t  awuser;
    logic           awvalid;
    // Write Data channel
    //logic         wid; //Only on AXI3
    axi_data_t      wdata;
    axi_wr_strb_t   wstrb;
    logic           wlast;
    axi_user_data_t wuser;
    logic           wvalid;
    // Write Response channel
    logic           bready;
    // Read Address channel
    axi_tid_t       arid;
    axi_addr_t      araddr;
    axi_alen_t      arlen;
    axi_size_t      arsize;
    axi_burst_t     arburst;
    logic           arlock;
    logic [3:0]     arcache;
    axi_prot_t      arprot;
    logic [3:0]     arqos;
    logic [3:0]     arregion;
    axi_user_req_t  aruser;
    logic           arvalid;
    // Read Data channel
    logic           rready;
  } s_axi_mosi_t;

  //*******************************
  //  AXIL - AXIv4 Lite
  //*******************************

  typedef struct packed {
    // Write Addr channel
    logic           awready;
    // Write Data channel
    logic           wready;
    // Write Response channel
    axi_tid_t       bid;
    axi_resp_t      bresp;
    logic           bvalid;
    // Read addr channel
    logic           arready;
    // Read data channel
    axi_tid_t       rid;
    axi_data_t      rdata;
    axi_resp_t      rresp;
    logic           rvalid;
  } s_axil_miso_t;

  typedef struct packed {
    // Write Address channel
    axi_tid_t       awid;
    axi_addr_t      awaddr;
    axi_prot_t      awprot;
    logic           awvalid;
    // Write Data channel
    axi_data_t      wdata;
    axi_wr_strb_t   wstrb;
    logic           wvalid;
    // Write Response channel
    logic           bready;
    // Read Address channel
    axi_tid_t       arid;
    axi_addr_t      araddr;
    axi_prot_t      arprot;
    logic           arvalid;
    // Read Data channel
    logic           rready;
  } s_axil_mosi_t;

  //*******************************
  //  AXIS - AXIv4 Stream
  //*******************************

  `ifndef AXIS_DATA_WIDTH
    `define AXIS_DATA_WIDTH       8
  `endif

  `ifndef AXIS_TXN_ID_WIDTH
    `define AXIS_TXN_ID_WIDTH     8
  `endif

  `ifndef AXIS_TDST_WIDTH
    `define AXIS_TDST_WIDTH       1
  `endif

  `ifndef AXIS_TUSER_WIDTH
    `define AXIS_TUSER_WIDTH      1
  `endif

  typedef logic [`AXIS_DATA_WIDTH-1:0]      axis_data_t;
  typedef logic [`AXIS_DATA_WIDTH/8-1:0]    axis_strb_t;
  typedef logic [`AXIS_DATA_WIDTH/8-1:0]    axis_tkeep_t;
  typedef logic [`AXIS_TXN_ID_WIDTH-1:0]    axis_tid_t;
  typedef logic [`AXIS_TDST_WIDTH-1:0]      axis_tdest_t;
  typedef logic [`AXIS_TUSER_WIDTH-1:0]     axis_tuser_t;

  typedef struct packed {
    logic           tvalid;
    axis_data_t     tdata;
    axis_strb_t     tstrb;
    axis_tkeep_t    tkeep;
    logic           tlast;
    axis_tid_t      tid;
    axis_tdest_t    tdest;
    axis_tuser_t    tuser;
  } s_axis_mosi_t;

  typedef struct packed {
    logic           tready;
  } s_axis_miso_t;

endpackage
