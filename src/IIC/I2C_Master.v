
module I2C_Master 
#(
    parameter p_ACLK_kHZ        = 25000,
    parameter p_MAX_DATA_BYTE   = 255
) 
(
    inout  tri1 SCK,
    inout  tri1 SDA,
    
    // slave interface
    output wire         s_axis_tready,
    input  wire [07:00] s_axis_tdata,
    input  wire         s_axis_tvalid,
    input  wire         s_axis_tlast,
    // master interface
    input  wire         m_axis_tready,
    output wire [07:00] m_axis_tdata,
    output wire         m_axis_tvalid,
    output wire         m_axis_tlast,
    // 
    input  wire reset,
    input  wire aresetn,
    input  wire aclk
);
//-----------------------------------------------------------------
localparam pl_I2C_STANDART_baudrate_100kHZ     = 100;
localparam pl_I2C_STANDART_baudrate_400kHZ     = 400;
localparam pl_I2C_STANDART_baudrate_1000kHZ    = 1000;

localparam pl_I2C_100kHz_TICKS  = (p_ACLK_kHZ / pl_I2C_STANDART_baudrate_100kHZ);
localparam pl_I2C_400kHz_TICKS  = (p_ACLK_kHZ / pl_I2C_STANDART_baudrate_400kHZ);
localparam pl_I2C_1000kHz_TICKS = (p_ACLK_kHZ / pl_I2C_STANDART_baudrate_1000kHZ);

localparam pl_I2C_100kHz_HALF_TICKS  = ((p_ACLK_kHZ / pl_I2C_STANDART_baudrate_100kHZ)   /2);
localparam pl_I2C_400kHz_HALF_TICKS  = ((p_ACLK_kHZ / pl_I2C_STANDART_baudrate_400kHZ)   /2);
localparam pl_I2C_1000kHz_HALF_TICKS = ((p_ACLK_kHZ / pl_I2C_STANDART_baudrate_1000kHZ)  /2);

localparam pl_COMMAND_MASK      = 7'b1111111;
localparam pl_COM_SET_baudrate = 7'b1111101;
localparam pl_COM_SET_LENGTH_RX = 7'b1111100;
//-----------------------------------------------------------------
localparam pl_STATE_I2C_LENGTH  = 4;
localparam pl_STATE_MAIN_LENGTH = 4;

localparam [(pl_STATE_I2C_LENGTH -1):00]
                    STATE_I2C_START = 'd0,
                    STATE_I2C_ADDR  = STATE_I2C_START   + 'd1,
                    STATE_I2C_DATA  = STATE_I2C_ADDR    + 'd1,
                    STATE_I2C_ACK   = STATE_I2C_DATA    + 'd1,
                    STATE_I2C_STOP  = STATE_I2C_ACK     + 'd1,
                    STATE_I2C_WAIT  = STATE_I2C_STOP    + 'd1,
                    STATE_I2C_BUSY  = STATE_I2C_WAIT    + 'd1,
                    STATE_I2C_ERR   = STATE_I2C_BUSY    + 'd1
                    ;

localparam [(pl_STATE_MAIN_LENGTH -1):00]
                    STATE_MAIN_LISTEN   = 'd0,
                    STATE_MAIN_SETUP    = STATE_MAIN_LISTEN + 'd1,
                    STATE_MAIN_TX       = STATE_MAIN_SETUP  + 'd1,
                    STATE_MAIN_RX       = STATE_MAIN_TX     + 'd1,
                    STATE_MAIN_RESET    = STATE_MAIN_RX     + 'd1
                    ;

//----------------------------------------------------------------
reg [02:00] r_SCK_filter;
reg [02:00] r_SDA_filter;
initial begin
    r_SCK_filter = 3'b111;
    r_SDA_filter = 3'b111;
end

reg r_i2c_busy;
initial begin
    r_i2c_busy = 1'b0;
end

reg [(pl_STATE_MAIN_LENGTH -1):00]  FSM_MAIN;
reg [(pl_STATE_I2C_LENGTH -1):00]   FSM_I2C ;

initial begin
    FSM_MAIN    = STATE_MAIN_RESET;
    FSM_I2C     = STATE_I2C_BUSY;
end

reg [(pl_STATE_MAIN_LENGTH -1):00]  r_fsm_main;
reg [(pl_STATE_I2C_LENGTH -1):00]   r_fsm_i2c ;
initial begin
    r_fsm_main    = STATE_MAIN_RESET;
    r_fsm_i2c     = STATE_I2C_BUSY;
end

reg [07:00] r_buf_byte;
reg         r_buf_valid;
reg         r_buf_last;
initial begin
    r_buf_byte  = 'd0;
    r_buf_valid = 1'b0;
    r_buf_last  = 1'b0;
end

reg [07:00] r_m_axis_tdata  ;
reg         r_m_axis_tvalid ;
reg         r_m_axis_tlast  ;
reg         r_s_axis_tready ;
initial begin
    r_m_axis_tdata  = 'd0;
    r_m_axis_tvalid = 1'b0;
    r_m_axis_tlast  = 1'b0;
    r_s_axis_tready = 1'b0;
end

reg [07:00] r_setup_baudrate;
reg [07:00] r_setup_length_rx;
reg [07:00] r_setup_length_tx;

initial begin
    r_setup_baudrate    = ('d100 / 'd4);
    r_setup_length_rx   = 'd1;
    r_setup_length_tx   = 'd1;
end
reg [15:00] r_cnt_WD;
initial begin
    r_cnt_WD = pl_I2C_100kHz_TICKS;
end

reg [07:00] r_cnt_byte;
initial begin
    r_cnt_byte          = 'd0;
end

reg r_SDA; 
reg r_SCK;
initial begin
    r_SDA = 'd1;
    r_SCK = 'd1;
end

reg [15:00] r_cnt_sck;
initial begin
    r_cnt_sck = 'd0;
end

reg [07:00] r_cnt_sda;
initial begin
    r_cnt_sda = 'd0;
end

//----------------------------------------------------------------
wire w_SCK_sync;
assign w_SCK_sync = r_SCK_filter[1];

wire w_SDA_sync;
assign w_SDA_sync = r_SDA_filter[1];

wire w_SCK_sync_last;
assign w_SCK_sync_last = r_SCK_filter[2];

wire w_SDA_sync_last;
assign w_SDA_sync_last = r_SDA_filter[2];

wire w_SCK_posedge;
assign w_SCK_posedge = w_SCK_sync & (!w_SCK_sync_last);

wire w_SDA_posedge;
assign w_SDA_posedge = w_SDA_sync & (!w_SDA_sync_last);

wire w_SCK_negedge;
assign w_SCK_negedge = (!w_SCK_sync) & w_SCK_sync_last;

wire w_SDA_negedge;
assign w_SDA_negedge = (!w_SDA_sync) & w_SDA_sync_last;

wire w_SCK_high;
assign w_SCK_high = w_SCK_sync & w_SCK_sync_last;

wire w_SDA_high;
assign w_SDA_high = w_SDA_sync & w_SDA_sync_last;

wire w_SCK_low;
assign w_SCK_low = (!w_SCK_sync) & (!w_SCK_sync_last);

wire w_SDA_low;
assign w_SDA_low = (!w_SDA_sync) & (!w_SDA_sync_last);

wire f_i2c_S;
assign f_i2c_S = (w_SCK_high & w_SDA_negedge);

wire f_i2c_P;
assign f_i2c_P = (w_SCK_high & w_SDA_posedge);

wire f_s_axis_handshake;
assign f_s_axis_handshake = (r_s_axis_tready & s_axis_tvalid)   ?
                                                                (1'b1)
                                                                :
                                                                (1'b0)
                                                                ;

wire f_i2c_fsm_next ;
assign f_i2c_fsm_next = (r_cnt_sda >= 'd8)  ?
                                            (w_SCK_negedge)  
                                            :
                                            (1'b0)
                                            ;

wire f_i2c_to_start ;
assign f_i2c_to_start = (FSM_I2C == STATE_I2C_WAIT)   ?
                                                                                    (r_buf_valid)
                                                                                    :
                                                                                    (((FSM_I2C == STATE_I2C_STOP) & (w_SCK_high))   ?
                                                                                                                                    (r_buf_valid)
                                                                                                                                    :
                                                                                                                                    (1'b0)
                                                                                    )
                                                                                    ;

wire f_i2c_addr_ok  ;
assign f_i2c_addr_ok = 1'b0;

wire f_state_changed;
assign f_state_changed = ((r_fsm_main != FSM_MAIN) | (r_fsm_i2c != FSM_I2C))    ?
                                                                                (1'b1)
                                                                                :
                                                                                (1'b0)
                                                                                ;

wire f_i2c_WD       ;
assign f_i2c_WD = (r_cnt_WD == 'd0) ?
                                    (!f_state_changed)
                                    :
                                    (1'b0)
                                    ;
                                    
wire f_i2c_end      ;
assign f_i2c_end = (FSM_MAIN == STATE_MAIN_TX)  ?
                                                (r_buf_last)
                                                :
                                                (FSM_MAIN == STATE_MAIN_RX) ?
                                                                            (r_cnt_byte >= r_setup_length_rx)
                                                                            :
                                                                            (1'b0)
                                                ;

wire f_fsm_main_listen;
assign f_fsm_main_listen = (FSM_MAIN == STATE_MAIN_LISTEN)  ?
                                                            (1'b1)
                                                            :
                                                            (1'b0)
                                                            ;
wire f_fsm_main_setup;
assign f_fsm_main_setup = (FSM_MAIN == STATE_MAIN_SETUP)    ?
                                                            (1'b1)
                                                            :
                                                            (1'b0)
                                                            ;
wire [06:00] w_com_mask_filtered_data;
assign w_com_mask_filtered_data = (f_fsm_main_listen)   ?
                                                        (s_axis_tdata[07:01] & pl_COMMAND_MASK)
                                                        :
                                                        (f_fsm_main_setup)  ?
                                                                            (r_buf_byte[07:01] & pl_COMMAND_MASK)
                                                                            :
                                                                            ('d0)
                                                                            
                                                        ;

wire f_axis_set_baudrate;
assign f_axis_set_baudrate = (w_com_mask_filtered_data == pl_COM_SET_baudrate)    ? 
                                                                                    (1'b1)
                                                                                    :
                                                                                    (1'b0)
                                                                                    ;
                                                                                    
wire f_axis_set_length_rx;
assign f_axis_set_length_rx = (w_com_mask_filtered_data == pl_COM_SET_LENGTH_RX)    ? 
                                                                                    (1'b1)
                                                                                    :
                                                                                    (1'b0)
                                                                                    ;
                                                                                    /*
wire f_axis_set_length_tx;
assign f_axis_set_baudrate = (w_com_mask_filtered_data == pl_COM_SET_baudrate)    ? 
                                                                                    (1'b1)
                                                                                    :
                                                                                    (1'b0)
                                                                                    ;*/
wire f_main_to_set;
assign f_main_to_set = (f_s_axis_handshake) ?
                                            (f_axis_set_baudrate | f_axis_set_length_rx) /* | f_axis_set_length_tx*/ 
                                            :
                                            (1'b0)
                                            ;
wire f_main_next_state;
assign f_main_next_state = (FSM_I2C == STATE_I2C_ACK)   ?
                                                        (f_i2c_addr_ok ?
                                                                        1'b1
                                                                        :
                                                                        1'b0
                                                        )
                                                        :
                                                        (1'b0)
                                                        ;
wire f_main_end_message;
assign f_main_end_message = (FSM_I2C == STATE_I2C_ACK)   ? 
                                                    (r_buf_last & w_SCK_negedge)
                                                    :
                                                    (1'b0)
                                                    ;

wire [15:00] w_baudrate_half_tick;
assign w_baudrate_half_tick = (r_setup_baudrate >= (1000 / 4)) ? 
                                                                (pl_I2C_1000kHz_TICKS / 2):
                                                                ((r_setup_baudrate >= (400 / 4)) ? 
                                                                                                    (pl_I2C_400kHz_TICKS / 2) :
                                                                                                    (pl_I2C_100kHz_TICKS /2)
                                                                );

//----------------------------------------------------------------
assign SDA = r_SDA ? 1'bz : 1'b0;
assign SCK = r_SCK ? 1'bz : 1'b0;
assign s_axis_tready    = r_s_axis_tready;
assign m_axis_tdata     = r_m_axis_tdata;
assign m_axis_tvalit    = r_m_axis_tvalid;
assign m_axis_tlast     = r_m_axis_tlast;
//----------------------------------------------------------------
//------- Input_Filters
always @(posedge aclk, negedge aresetn) begin
     if(!aresetn)begin
          r_SDA_filter <= 3'b111;
          r_SCK_filter <= 3'b111;
     end 
     else begin
          if(reset)begin
                r_SDA_filter <= 3'b111;
                r_SCK_filter <= 3'b111;
          end 
          else begin
                r_SDA_filter[0] <= SDA;
                r_SCK_filter[0] <= SCK;
                
                r_SDA_filter[1] <= r_SDA_filter[0];
                r_SCK_filter[1] <= r_SCK_filter[0];  
                
                r_SDA_filter[2] <= r_SDA_filter[1];
                r_SCK_filter[2] <= r_SCK_filter[1];      
          end
     end            
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_i2c_busy <= 1'b0;
    end 
    else if(reset)begin
        r_i2c_busy <= 1'b0;
    end 
    else if(f_i2c_P)begin
        r_i2c_busy <= 1'b0;
    end 
    else if(f_i2c_S)begin
        r_i2c_busy <= 1'b1;
    end 
    else if((!r_i2c_busy) & (w_SCK_low | w_SDA_low))begin
        r_i2c_busy <= 1'b1;
    end else begin
        r_i2c_busy <= r_i2c_busy;
    end
end
//-----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_fsm_i2c <= STATE_I2C_BUSY;
    end
    else if(reset)begin
        r_fsm_i2c <= STATE_I2C_BUSY;
    end else begin
        r_fsm_i2c <= FSM_I2C;
    end
end
//-----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_I2C <= STATE_I2C_BUSY;
    end
    else if(reset)begin
        FSM_I2C <= STATE_I2C_BUSY;
    end else begin
        case (FSM_I2C)
        STATE_I2C_START :begin
            if(w_SCK_negedge)begin
                FSM_I2C <= STATE_I2C_ADDR;
            end
            else if(f_i2c_WD)begin
                FSM_I2C <= STATE_I2C_STOP;
            end
            else begin
                FSM_I2C <= STATE_I2C_START;
            end
        end
        STATE_I2C_ADDR  :begin
            if(f_i2c_fsm_next)begin
                FSM_I2C <= STATE_I2C_ACK;
            end 
            else if(f_i2c_WD)begin
                FSM_I2C <= STATE_I2C_STOP;
            end
            else begin
                FSM_I2C <= STATE_I2C_ADDR;
            end
        end
        STATE_I2C_DATA  :begin
            if(f_i2c_fsm_next)begin
                FSM_I2C <= STATE_I2C_ACK;
            end 
            else if(f_i2c_WD)begin
                FSM_I2C <= STATE_I2C_STOP;
            end
            else begin
                FSM_I2C <= STATE_I2C_DATA;
            end
        end
        STATE_I2C_ACK   :begin
            if(f_i2c_fsm_next)begin
                if(f_i2c_end)begin
                    FSM_I2C <= STATE_I2C_STOP;
                end
                else if(f_i2c_addr_ok)begin
                    FSM_I2C <= STATE_I2C_DATA;
                end
                else begin
                    FSM_I2C <= STATE_I2C_ADDR;
                end
            end 
            else if(f_i2c_WD)begin
                FSM_I2C <= STATE_I2C_STOP;
            end
            else begin
                FSM_I2C <= STATE_I2C_ACK;
            end
        end
        STATE_I2C_STOP  :begin
            if(f_i2c_to_start)begin
                FSM_I2C <= STATE_I2C_START;
            end
            else if(f_i2c_P)begin
                FSM_I2C <= STATE_I2C_WAIT;
            end 
            else if(f_i2c_WD)begin
                FSM_I2C <= STATE_I2C_BUSY;
            end
            else begin
                FSM_I2C <= STATE_I2C_STOP;
            end
        end
        STATE_I2C_WAIT  :begin
            if(r_i2c_busy)begin
                FSM_I2C <= STATE_I2C_BUSY;
            end 
            else if(f_i2c_to_start)begin
                FSM_I2C <= STATE_I2C_START;
            end            
            else begin
                FSM_I2C <= STATE_I2C_WAIT;
            end
        end
        STATE_I2C_BUSY  :begin
            if(f_i2c_WD | f_i2c_P)begin
                FSM_I2C <= STATE_I2C_WAIT;
            end 
            else begin
                FSM_I2C <= STATE_I2C_BUSY;
            end
        end
        STATE_I2C_ERR   :begin
            FSM_I2C <= STATE_I2C_ERR;
        end
        default         :begin
            FSM_I2C <= STATE_I2C_ERR;
        end
        endcase
    end
end
//-----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_fsm_main <= STATE_MAIN_RESET;
    end
    else if(reset)begin
        r_fsm_main <= STATE_MAIN_RESET;
    end else begin
        r_fsm_main <= FSM_MAIN;
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_MAIN <= STATE_MAIN_RESET;
    end
    else if(reset)begin
        FSM_MAIN <= STATE_MAIN_RESET;
    end
    else begin
        case (FSM_MAIN)
        STATE_MAIN_RESET    :begin
            FSM_MAIN <= STATE_MAIN_LISTEN;
        end
        STATE_MAIN_LISTEN   :begin
            if(f_main_to_set)begin
                FSM_MAIN <= STATE_MAIN_SETUP;
            end
            else if(f_s_axis_handshake)begin
                FSM_MAIN <= STATE_MAIN_TX;
            end
            else begin
                FSM_MAIN <= STATE_MAIN_LISTEN;
            end
        end
        STATE_MAIN_SETUP    :begin
            if(f_s_axis_handshake)begin
                FSM_MAIN <= STATE_MAIN_LISTEN;
            end
            else begin
                FSM_MAIN <= STATE_MAIN_SETUP;
            end
        end
        STATE_MAIN_TX       :begin
            if(f_main_end_message)begin
                FSM_MAIN <= STATE_MAIN_LISTEN;
            end
            else if(f_main_next_state)begin
                FSM_MAIN <= STATE_MAIN_RX;
            end
            else if(f_i2c_WD & (FSM_I2C < STATE_I2C_BUSY))begin
                FSM_MAIN <= STATE_MAIN_RESET;
            end
            else begin
                FSM_MAIN <= STATE_MAIN_TX;
            end
        end
        STATE_MAIN_RX       :begin
            if(f_main_end_message)begin
                FSM_MAIN <= STATE_MAIN_LISTEN;
            end
            else if(f_i2c_WD)begin
                FSM_MAIN <= STATE_MAIN_RESET;
            end
            else begin
                FSM_MAIN <= STATE_MAIN_RX;
            end
        end
        default             :begin
            FSM_MAIN <= STATE_MAIN_RESET;
        end
        endcase
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : BUF_inst
    if(!aresetn)begin
        r_buf_byte  <= 'd0;
        r_buf_valid <= 1'b0;
        r_buf_last  <= 1'b0;
    end
    else if(reset)begin
        r_buf_byte  <= 'd0;
        r_buf_valid <= 1'b0;
        r_buf_last  <= 1'b0;
    end
    else begin
        if(FSM_I2C == STATE_I2C_ACK)begin
            if((FSM_MAIN == STATE_MAIN_TX) | (f_i2c_end))begin       // axi edit mode
                if(w_SCK_negedge)begin
                    r_buf_byte  <= 'd0;
                    r_buf_valid <= 1'b0;
                    r_buf_last  <= 1'b0;
                end
                else begin
                    r_buf_byte  <= r_buf_byte;
                    r_buf_valid <= r_buf_valid;
                    r_buf_last  <= r_buf_last;
                end
            end
            else if(FSM_MAIN == STATE_MAIN_RX)begin // i2c edit mode
                if(w_SCK_negedge)begin
                    r_buf_byte  <= {8{1'b1}};
                    r_buf_valid <= 1'b0;
                    r_buf_last  <= 1'b0;
                end
                else if((w_SCK_posedge | w_SCK_high) & (m_axis_tready | (!r_m_axis_tvalid)))begin
                    r_buf_byte  <= {8{1'b1}};
                    r_buf_valid <= 1'b0;
                    r_buf_last  <= 1'b0;
                end
                else begin
                    r_buf_byte  <= r_buf_byte;
                    r_buf_valid <= r_buf_valid;
                    r_buf_last  <= r_buf_last;
                end
            end
            else begin
                r_buf_byte  <= 'd0;
                r_buf_valid <= 1'b0;
                r_buf_last  <= 1'b0;
            end
        end
        else if(FSM_MAIN == STATE_MAIN_LISTEN)begin
            if(f_main_to_set)begin
                r_buf_byte  <= s_axis_tdata;
                r_buf_valid <= 1'b0;
                r_buf_last  <= 1'b0;
            end
            else if(f_s_axis_handshake)begin
                r_buf_byte  <= s_axis_tdata;
                r_buf_valid <= s_axis_tvalid;
                r_buf_last  <= s_axis_tlast;
            end
            else begin
                r_buf_byte  <= r_buf_byte;
                r_buf_valid <= r_buf_valid;
                r_buf_last  <= r_buf_last;
            end
        end
        else if(FSM_MAIN == STATE_MAIN_TX)begin       // axi edit mode
            if(r_buf_valid)begin
                if((FSM_I2C == STATE_I2C_DATA) | (FSM_I2C == STATE_I2C_ADDR))begin
                    if(w_SCK_negedge)begin
                        r_buf_byte[00]      <= r_buf_byte[07];
                        r_buf_byte[07:01]   <= r_buf_byte[06:00];
                        r_buf_valid         <= r_buf_valid;
                        r_buf_last          <= r_buf_last;
                    end
                    else begin
                        r_buf_byte  <= r_buf_byte;
                        r_buf_valid <= r_buf_valid;
                        r_buf_last  <= r_buf_last;
                    end
                end
                else begin
                    r_buf_byte  <= r_buf_byte;
                    r_buf_valid <= r_buf_valid;
                    r_buf_last  <= r_buf_last;
                end
            end
            else begin
                if(f_s_axis_handshake)begin
                    r_buf_byte  <= s_axis_tdata;
                    r_buf_valid <= s_axis_tvalid;
                    r_buf_last  <= s_axis_tlast;
                end
                else begin
                    r_buf_byte  <= r_buf_byte;
                    r_buf_valid <= r_buf_valid;
                    r_buf_last  <= r_buf_last;
                end
            end
        end
        else if(FSM_MAIN == STATE_MAIN_RX)begin // i2c edit mode
            if(FSM_I2C == STATE_I2C_DATA)begin
                if(w_SCK_posedge)begin
                    r_buf_byte[00]      <= w_SDA_sync;
                    r_buf_byte[06:00]   <= r_buf_byte[07:01];
                    if(r_cnt_sda < 'd8)begin
                        r_buf_valid     <= 1'b0;
                        r_buf_last      <= 1'b0;
                    end 
                    else begin
                        r_buf_valid     <= 1'b1;
                        if(r_cnt_byte >= r_setup_length_rx)begin
                            r_buf_last  <= 1'b1;
                        end
                        else begin
                            r_buf_last  <= 1'b0;
                        end
                    end
                end
                else begin
                    r_buf_byte  <= r_buf_byte;
                    r_buf_valid <= r_buf_valid;
                    r_buf_last  <= r_buf_last;
                end
            end
            else begin
                r_buf_byte  <= r_buf_byte;
                r_buf_valid <= r_buf_valid;
                r_buf_last  <= r_buf_last;
            end
        end
        else begin                              //reset
            r_buf_byte  <= 'd0;
            r_buf_valid <= 1'b0;
            r_buf_last  <= 1'b0;
        end
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : SETUPs_inst
    if(!aresetn)begin
        r_setup_baudrate <= ('d100 / 'd4);
        r_setup_length_rx <= 'd1;
        r_setup_length_tx <= 'd1;
    end
    else if(reset)begin
        r_setup_baudrate <= ('d100 / 'd4);
        r_setup_length_rx <= 'd1;
        r_setup_length_tx <= 'd1;
    end
    else if(f_fsm_main_setup & f_s_axis_handshake)begin
        case (w_com_mask_filtered_data)
        pl_COM_SET_baudrate    : begin
            r_setup_baudrate <= s_axis_tdata;
            r_setup_length_rx <= r_setup_length_rx;
            r_setup_length_tx <= r_setup_length_tx;
        end
        pl_COM_SET_LENGTH_RX    : begin
            r_setup_baudrate <= r_setup_baudrate;
            r_setup_length_rx <= s_axis_tdata;
            r_setup_length_tx <= r_setup_length_tx;
        end
        /*
        pl_COM_SET_LENGTH_TX    : begin
            r_setup_baudrate <= r_setup_baudrate;
            r_setup_length_rx <= r_setup_length_rx;
            r_setup_length_tx <= s_axis_tdata;
        end
        */
        default                 : begin
            r_setup_baudrate <= r_setup_baudrate;
            r_setup_length_rx <= r_setup_length_rx;
            r_setup_length_tx <= r_setup_length_tx;
        end
        endcase
    end
    else begin
        r_setup_baudrate <= r_setup_baudrate;
        r_setup_length_rx <= r_setup_length_rx;
        r_setup_length_tx <= r_setup_length_tx;
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : WD_inst
    if(!aresetn)begin
        r_cnt_WD <= (w_baudrate_half_tick << 2);
    end
    else if(reset)begin
        r_cnt_WD <= (w_baudrate_half_tick << 2);
    end
    else if((FSM_I2C < STATE_I2C_WAIT) | (FSM_I2C == STATE_I2C_BUSY))begin
        if(w_SCK_negedge | w_SCK_posedge | w_SDA_negedge | w_SDA_posedge | f_state_changed)begin
            r_cnt_WD <= (w_baudrate_half_tick << 2);
        end
        else if(r_cnt_WD > 'd0)begin
            r_cnt_WD <= r_cnt_WD -'d1;
        end
        else begin
            r_cnt_WD <= r_cnt_WD;
        end
    end
    else begin
        r_cnt_WD <= (w_baudrate_half_tick << 2);
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : s_axis_tready_inst
    if(!aresetn)begin
        r_s_axis_tready <= 1'b0;
    end
    else if(reset)begin
        r_s_axis_tready <= 1'b0;
    end
    else begin
        case (FSM_MAIN)
        STATE_MAIN_RESET    : begin
            r_s_axis_tready <= 1'b0;
        end
        STATE_MAIN_LISTEN   : begin
            if(f_main_to_set)begin
                r_s_axis_tready <= 1'b1;
            end
            else if(f_s_axis_handshake)begin
                r_s_axis_tready <= 1'b0;
            end
            else if(r_buf_valid)begin
                r_s_axis_tready <= 1'b0;
            end
            else begin
                r_s_axis_tready <= 1'b1;
            end
        end
        STATE_MAIN_SETUP    : begin
            r_s_axis_tready <= 1'b1;
        end
        STATE_MAIN_TX       : begin
            if(f_s_axis_handshake | r_buf_valid)begin
                r_s_axis_tready <= 1'b0;
            end
            else begin
                r_s_axis_tready <= 1'b1;
            end
        end
        STATE_MAIN_RX       :begin
            if(f_main_end_message & (!r_buf_valid))begin
                r_s_axis_tready <= 1'b1;
            end
            else begin
                r_s_axis_tready <= 1'b0;
            end
        end
        default             :begin
            r_s_axis_tready <= 1'b0;
        end
        endcase
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : SDA_signal_inst
    if(!aresetn)begin
        r_SDA <= 1'b1;
    end
    else if(reset)begin
        r_SDA <= 1'b1;
    end
    else begin
        case (FSM_I2C)
        STATE_I2C_START :begin
            if(w_SCK_high)begin
                r_SDA <= 1'b0;
            end 
            else begin
                r_SDA <= 1'b1;
            end
        end
        STATE_I2C_ADDR, 
        STATE_I2C_DATA  :begin
            if(w_SCK_low)begin
                if(r_buf_valid)begin
                    r_SDA <= r_buf_byte[07]; 
                end
                else begin
                    r_SDA <= 1'b1; 
                end
            end 
            else begin
                r_SDA <= r_SDA;
            end
        end
        STATE_I2C_ACK   :begin
            r_SDA <= 1'b1;
        end
        STATE_I2C_STOP  :begin
            if(w_SCK_high)begin
                r_SDA <= 1'b1;
            end 
            else if(w_SCK_low)begin 
                if(w_SDA_high)begin
                    r_SDA <= 1'b0;
                end
                else begin
                    r_SDA <= r_SDA;
                end
            end
            else begin
                r_SDA <= r_SDA;
            end
        end
        STATE_I2C_WAIT,
        STATE_I2C_BUSY,
        STATE_I2C_ERR  :begin
            r_SDA <= 1'b1;
        end
        default         :begin
            r_SDA <= 1'b1;
        end
        endcase
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : CNT_SCK_inst
    if(!aresetn)begin
        r_cnt_sck <= 'd0;
    end
    else if(reset)begin
        r_cnt_sck <= 'd0;
    end
    else begin
        if(FSM_I2C < STATE_I2C_WAIT)begin
            if((FSM_MAIN == STATE_MAIN_TX) & (w_SCK_low) & (r_cnt_sck == (w_baudrate_half_tick -'d1)) & (!r_buf_valid) )begin
                if(FSM_I2C == STATE_I2C_STOP)begin
                    if(w_SDA_low)begin
                        r_cnt_sck <= r_cnt_sck + 'd1;
                    end else begin
                        r_cnt_sck <= r_cnt_sck;
                    end
                end
                else begin
                    r_cnt_sck <= r_cnt_sck;
                end
            end
            else if((r_cnt_sck < w_baudrate_half_tick) & (r_SCK == w_SCK_sync))begin
                r_cnt_sck <= r_cnt_sck + 'd1;
            end 
            else begin
                r_cnt_sck <= 'd0;
            end
        end
        else begin
        r_cnt_sck <= 'd0;
        end
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : SCK_signal_inst
    if(!aresetn)begin
        r_SCK <= 1'b1;
    end
    else if(reset)begin
        r_SCK <= 1'b1;
    end
    else begin
        if(FSM_I2C < STATE_I2C_WAIT)begin
            if(r_cnt_sck >= w_baudrate_half_tick)begin
                r_SCK <= ~r_SCK;
            end 
            else begin
                r_SCK <= r_SCK;
            end
        end
        else begin
            r_SCK <= 1'b1;
        end
    end
end
//----------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin : CNT_SDA_inst
    if(!aresetn)begin
        r_cnt_sda <= 'd0;
    end
    else if(reset)begin
        r_cnt_sda <= 'd0;
    end
    else begin
        if(w_SCK_posedge)begin
            if((FSM_I2C == STATE_I2C_ADDR) | (FSM_I2C == STATE_I2C_DATA) | (FSM_I2C == STATE_I2C_ACK))begin
                if(r_cnt_sda < 'd9)begin
                    r_cnt_sda <= r_cnt_sda +'d1;
                end
                else begin
                    r_cnt_sda <= r_cnt_sda;
                end
            end 
            else begin
                r_cnt_sda <= r_cnt_sda;
            end
        end 
        else if(w_SCK_negedge)begin
            if((r_cnt_sda >= 'd9) | (FSM_I2C == STATE_I2C_ACK))begin
                r_cnt_sda <= 'd0;
            end 
            else begin
                r_cnt_sda <= r_cnt_sda;
            end
        end 
        else begin
            r_cnt_sda <= r_cnt_sda;
        end       
    end 
end
//----------------------------------------------------------------
endmodule