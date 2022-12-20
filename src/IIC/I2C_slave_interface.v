//===========================================================
module I2C_Slave_to_AXI4_Stream #(
    // Device address length : 7bit(used) or 10bit(not used)
    parameter P_DEV_ADDR_LENGTH     = 7,
    // Register interface address lengh in byte
    parameter P_REG_ADDR_BYTE_NUM   = 1,
    // Register space start address 
    parameter P_REG_ADDR_START      = 'h00,  // for future
    // Register space stop address 
    parameter P_REG_ADDR_STOP       = 'hFF,  // for future
    // Register space stop address 
    parameter P_REG_ADDR_RESTRICT   = 1'b0,  // for future
    // Register interface data length in byte
    parameter P_REG_DATA_BYTE_NUM   = 1,
    // can module sent data next addr ?
    parameter P_REG_DATA_NEXT       = 1'b0,    // for future
    // can module sent P_REG_ADDR_START addr after P_REG_ADDR_STOP addr ?
    parameter P_REG_ADDR_ROTATE     = 1'b0,    // for future
    // can module sent ACK when P_REG_DATA_NEXT == 1 ?
    parameter P_REG_DATA_NEXT_ACK   = 1'b0,    // for future
    // can module sent ACK when P_REG_ADDR_START addr after P_REG_ADDR_STOP addr ?
    parameter P_REG_ADDR_ROTETE_ACK = 1'b0     // for future
) (
    // device address
    input  tri1 [(P_DEV_ADDR_LENGTH -1):00] address,

    // // device info
    // input  wire [11:00] manufacture,            // not used
    // input  wire [08:00] part_identificattion,   // not used
    // input  wire [02:00] revision,               // not used

    // I2C IO interface
    inout  tri1 SCK,
    inout  tri1 SDA, 

    // register address interface
    input  wire                                     reg_ready,
    output wire [((P_REG_ADDR_BYTE_NUM *8) -1):00]  reg_addr,
    output wire                                     reg_rw,
    output wire                                     reg_valid,

    // register output interface
    input  wire                                     wr_ready,
    output wire [((P_REG_DATA_BYTE_NUM *8) -1):00]  wr_data,
    output wire                                     wr_valid,

    // register input interface
    output wire                                     rd_ready,
    input  wire [((P_REG_DATA_BYTE_NUM *8) -1):00]  rd_data,
    input  wire                                     rd_valid,

    // logging interface
//    output wire [07:00] log_data,
//    output wire         log_dir,
//    output wire         log_valid,

    // // I2C debug data
    // output wire I2C_TX,
    // output wire I2C_RX,
    // output wire I2C_BUSY,
    // output wire I2C_START,
    // output wire I2C_START_REPEAT,
    // output wire I2C_ADDR,
    // output wire I2C_RW,
    // output wire I2C_REG,
    // output wire I2C_DATA,
    // output wire I2C_ACK,
    // output wire I2C_STOP,
    // output wire I2C_ERR,

    // I2c statistic data
    // output wire [15:00] I2C_cnt_mes,
    // output wire [15:00] I2C_cnt_mes_tx,
    // output wire [15:00] I2C_cnt_mes_rx,
    // output wire [15:00] I2C_cnt_err,
    // output wire [15:00] I2C_cnt_no_ACK,
    // output wire [15:00] I2C_cnt_Start,
    // output wire [15:00] I2C_cnt_Stop,
    // output wire [15:00] I2C_cnt_Bytes,
    // output wire [15:00] I2C_cnt_Bytes_reg_rx,
    // output wire [15:00] I2C_cnt_Bytes_data_rx,
    // output wire [15:00] I2C_cnt_Bytes_tx,
    // output wire [15:00] I2C_cnt_Bytes_rx,
    // output wire [15:00] I2C_cnt_addr_ok,
    // output wire [07:00] I2C_saw_addr_unique,
    // output wire [15:00] I2C_mean_busy_tick,
    // output wire [15:00] I2C_mean_mes_tick,
    // output wire [15:00] I2C_mean_scl_period_tick,
    // output wire [15:00] I2C_mean_scl_down_tick,
    // output wire [15:00] I2C_mean_scl_up_tick,
    // input  wire reset_stat,

    // system inpterface
    input  wire aresetn,
    input  wire reset,
    input  wire aclk
);
//===========================================================
// initial port registers
// initial begin
//     I2C_TX          = 1'd0;
//     I2C_RX          = 1'd0;
//     I2C_BUSY        = 1'd0;
//     I2C_ADDR        = 1'd0;
//     I2C_RW          = 1'd0;
//     I2C_REG         = 1'd0;
//     I2C_DATA        = 1'd0;
//     I2C_ACK         = 1'd0;
// end
//-----------------------------------------------------------
localparam [07:00] 
    state_WAIT   = 'd0,                  // 0
    state_START  = state_WAIT   + 'd1,   // 1
    state_ADDR   = state_START  + 'd1,   // 2
    state_ACK    = state_ADDR   + 'd1,   // 3
    state_DATA   = state_ACK    + 'd1,   // 4
    state_BUSY   = state_DATA   + 'd1,   // 5
    state_ERR    = state_BUSY   + 'd1,   // 6
    state_STOP   = state_ERR    + 'd1;   // 7

localparam [01:00]
    state_REG_WAIT  = 'd0,                    // 0
    state_REG_ADDR  = state_REG_WAIT +'d1,    // 1
    state_REG_DATA  = state_REG_ADDR +'d1,    // 2
    state_REG_ERR   = state_REG_DATA +'d1;    // 3
//-----------------------------------------------------------
wire f_negedge_sck;
wire f_posedge_sck;
wire f_up_sck;
wire f_down_sck;

wire f_negedge_sda;
wire f_posedge_sda;
wire f_up_sda;
wire f_down_sda;

wire f_busy;
wire f_start;
wire f_stop;
wire f_ack;
wire f_nack;

wire f_firt_bit;
wire f_byte_end;

wire f_addr_ok;

wire f_addr_end;
wire f_reg_end;
wire f_data_end;

//wire f_reg_over;
//wire f_reg_under;
//wire f_reg_last;

wire f_start_repeated;
wire f_addr_full;

wire f_2ack;
wire f_2addr;
wire f_2bytes;

wire f_2end;
wire f_2err;
wire f_2write;
wire f_2read;
wire f_2data;
wire f_cnt_bit_en;

wire f_end;
//-----------------------------------------------------------
// I2C IO interface
reg SCK_r;
reg SDA_r;
//-------
reg [07:00]FSM_I2C;
reg [02:00]FSM_I2C_REG;
//-------
reg r_rw;
reg SCK_last;
reg SDA_last;
//-------
reg[03:00] cnt_bit;
reg[07:00] cnt;
//-------
reg [07:00] r_byte_buf;
//-------
reg [(P_DEV_ADDR_LENGTH -1):00]         r_address;
reg [09:00]                             r_addr;
reg                                     r_addr_valid;
//-------
reg [((P_REG_ADDR_BYTE_NUM *8) -1):00]  r_reg_buf;
reg                                     r_reg_valid;
//-------
reg [((P_REG_DATA_BYTE_NUM *8) -1):00]  r_data_tx_buf;
reg                                     r_data_tx_valid_buf;
//-------
reg                                     r_data_tx_ready;
reg [((P_REG_DATA_BYTE_NUM *8) -1):00]  r_data_rx_buf;
reg                                     r_data_rx_valid_buf;
//-----------------------------------------------------------
initial begin 
    SCK_r = 1'bZ;
    SDA_r = 1'bZ;
//-------
    FSM_I2C = state_WAIT;
    FSM_I2C_REG = state_REG_WAIT;
//-------
    r_rw = 1'b0;
    SCK_last = 1'b1;
    SDA_last = 1'b1;
//-------
    cnt_bit = 'd0;
    cnt = 'd0;
//-------
    r_address = 'h000;
    r_addr = 10'h000;
    r_addr_valid = 1'b0;
//-------
    r_byte_buf = 'd0;
//-------
    r_reg_buf = 'd0;
    r_reg_valid = 1'b0;
//-------
    r_data_tx_buf = 'd0;
    r_data_tx_valid_buf = 1'b0;
//-------
    r_data_tx_ready = 1'b0;
    r_data_rx_buf = 'd0;
    r_data_rx_valid_buf = 1'b0;
end
//-----------------------------------------------------------
assign SDA  = SDA_r;
assign SCK  = SCK_r;
//-------
assign reg_addr     = r_reg_buf;
assign reg_rw       = r_rw;
assign reg_valid    = r_reg_valid;
//-------
assign wr_data  = r_data_rx_buf;
assign wr_valid = r_data_rx_valid_buf;
//-------
assign rd_ready = r_data_tx_ready;
//-------
assign f_negedge_sck    = (((SCK == 1'b0)&(SCK_last != 1'b0)))          ? 1'b1 : 1'b0;
assign f_posedge_sck    = (((SCK != 1'b0)&(SCK_last == 1'b0)))          ? 1'b1 : 1'b0;     
assign f_up_sck         = (((SCK != 1'b0)&(SCK_last != 1'b0)))         ? 1'b1 : 1'b0; 
assign f_down_sck       = (((SCK == 1'b0)&(SCK_last == 1'b0)))          ? 1'b1 : 1'b0;
//-------
assign f_negedge_sda    = (SDA_last > SDA)          ? 1'b1 : 1'b0;
assign f_posedge_sda    = (SDA_last < SDA)          ? 1'b1 : 1'b0;
assign f_up_sda         = (SDA_last & SDA)          ? 1'b1 : 1'b0;
assign f_down_sda       = ((!SDA_last) & (!SDA))    ? 1'b1 : 1'b0;
//-------
assign f_busy   = (f_down_sda | f_down_sck | f_posedge_sck| f_negedge_sck) ? 1'b1 : 1'b0;
//-------
assign f_start  = (f_up_sck & f_negedge_sda)    ? 1'b1 : 1'b0;
assign f_stop   = (f_up_sck & f_posedge_sda)    ? 1'b1 : 1'b0;
//-------
assign f_ack    =  (FSM_I2C == state_ACK) ? f_down_sda    : 1'b0;
assign f_nack   =  (FSM_I2C == state_ACK) ? f_up_sda      : 1'b0;
//-------
assign f_addr_ok = (r_addr == r_address)    ? 1'b1 : 1'b0;
//-------
assign f_firt_bit   = (cnt_bit == 0)    ? 1'b1 : 1'b0;
assign f_byte_end   = (cnt_bit == 8)    ? 1'b1 : 1'b0;
//-------
assign f_addr_end   = (cnt >= P_DEV_ADDR_LENGTH)        ? 1'b1 : 1'b0;
assign f_reg_end    = (cnt >= (P_REG_ADDR_BYTE_NUM *8)) ? 1'b1 : 1'b0;
assign f_data_end   = (cnt >= (P_REG_DATA_BYTE_NUM *8)) ? 1'b1 : 1'b0;
//-------
//assign f_reg_over   = (r_reg_addr > P_REG_ADDR_STOP)    ? 1'b1 : 1'b0;
//assign f_reg_under  = (r_reg_addr < P_REG_ADDR_START)   ? 1'b1 : 1'b0;
//assign f_reg_last   = (r_reg_addr >= P_REG_ADDR_STOP)   ? 1'b1 : 1'b0;
//-------
assign f_start_repeated = (f_start & f_firt_bit)        ? 1'b1 : 1'b0;
assign f_addr_full      = (P_DEV_ADDR_LENGTH == 'd10)   ? 1'b1 : 1'b0;
//-------
assign f_2ack           = (f_byte_end)                  ? f_negedge_sck : 1'b0;
assign f_2addr          = (f_addr_full & (!f_addr_end)) ? f_negedge_sck : 1'b0;
assign f_2bytes         = (f_addr_ok)                   ? f_negedge_sck : 1'b0;
//-------
assign f_2end           = (f_stop | f_start_repeated)   ? 1'b1 : 1'b0;
assign f_2err           = (FSM_I2C > state_ADDR) ? (f_start | (!f_addr_ok)) : 1'b0;
assign f_2write         = ((FSM_I2C == state_ACK) & (!r_rw) & f_addr_ok)    ? f_negedge_sck : 1'b0;
assign f_2read          = ((FSM_I2C == state_ACK) & r_rw & f_addr_ok)       ? f_negedge_sck : 1'b0;
assign f_2data          = ((FSM_I2C == state_ACK) & f_reg_end & f_addr_ok)  ? f_negedge_sck : 1'b0;

assign f_end            = ((FSM_I2C == state_ACK) & f_data_end & (r_rw))    ? f_negedge_sck : 1'b0;
//-------
assign f_cnt_bit_en     = ((FSM_I2C == state_START)|(FSM_I2C == state_STOP)|(FSM_I2C == state_WAIT)|(FSM_I2C == state_ERR)) ? 1'b0 : 1'b1;
//-------
//-----------------------------------------------------------
// buffers
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SCK_last    <= 1'b1;
        SDA_last    <= 1'b1;
        r_address   <= 'h000;
    end else begin
        if(reset)begin
            SCK_last    <= 1'b1;
            SDA_last    <= 1'b1;
            r_address   <= 'h000;
        end else begin
            SCK_last    <= SCK;
            SDA_last    <= SDA;
            
            if(FSM_I2C > state_WAIT)begin
                r_address   <= r_address;
            end else if(((r_address > 'h007) & (r_address < 'h078))|((r_address > 'h08F) & (r_address < 'h3FF)))begin
                r_address   <= address;
            end else begin
                r_address   <= 'h000;
            end
        end 
    end
end
//-------
// I2C STATE MACHINE
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_I2C <= state_WAIT;
    end else begin
        if(reset)begin
            FSM_I2C <= state_WAIT;
        end else begin
            case (FSM_I2C)
                state_WAIT:
                    if(f_busy)begin
                        FSM_I2C <= state_BUSY;
                    end else if(f_start)begin
                        FSM_I2C <= state_START;
                    // end else begin
                    //     FSM_I2C <= state_WAIT;
                    end
                state_START:
                    if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    end else if(f_negedge_sck)begin
                        FSM_I2C <= state_ADDR;
                    // end else begin
                    //     FSM_I2C <= state_START;
                    end
                state_ADDR:
                    if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    end else if(f_start)begin
                        FSM_I2C <= state_ERR;
                    end else if(f_2ack)begin
                        FSM_I2C <= state_ACK;
                    // end else begin
                    //     FSM_I2C <= state_ADDR;
                    end
                state_ACK:
                    if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    end else if(f_start_repeated)begin
                        FSM_I2C <= state_START;
                    end else if(f_2addr)begin
                        FSM_I2C <= state_ADDR;
                    end else if(f_end)begin
                        FSM_I2C <= state_BUSY;
                    end else if(f_2bytes)begin
                        FSM_I2C <= state_DATA;
                    end else if(f_nack & f_negedge_sck)begin
                        FSM_I2C <= state_BUSY;
                    // end else begin
                    //     FSM_I2C <= state_ACK;
                    end
                state_DATA:
                    if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    end else if(f_start_repeated)begin
                        FSM_I2C <= state_START;
                    end else if(f_start)begin
                        FSM_I2C <= state_ERR;
                    end else if(f_2ack)begin
                        FSM_I2C <= state_ACK;
                    // end else begin
                    //     FSM_I2C <= state_DATA;
                    end
                state_STOP:
                    if(f_start)begin
                        FSM_I2C <= state_START;
                    end else begin
                        FSM_I2C <= state_WAIT;
                    end
                state_BUSY:
                    if(f_start)begin
                        FSM_I2C <= state_START;
                    end else if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    // end else begin
                    //     FSM_I2C <= state_BUSY;
                    end
                state_ERR:
                    if(f_stop)begin
                        FSM_I2C <= state_STOP;
                    // end else begin
                    //     FSM_I2C <= state_ERR;
                    end
                default:
                    FSM_I2C <= state_ERR;
            endcase
        end
    end
end
//-------
// I2C REGISTER SPACE STATE MACHINE
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_I2C_REG <= state_REG_WAIT;
    end else begin
        if(reset)begin
            FSM_I2C_REG <= state_REG_WAIT;
        end else begin
            case (FSM_I2C_REG)
                state_REG_WAIT:
                    if(f_2read)begin
                        FSM_I2C_REG <= state_REG_DATA;
                    end else if(f_2write)begin
                        FSM_I2C_REG <= state_REG_ADDR;
                    // end else begin
                    //     FSM_I2C_REG <= state_WAIT;
                    end
                state_REG_ADDR:
                    if(f_2end/*f_stop |f_start_repeated*/)begin
                        FSM_I2C_REG <= state_REG_WAIT;
                    end else if(f_2err)begin
                        FSM_I2C_REG <= state_REG_ERR;
                    end else if(f_2data)begin
                        FSM_I2C_REG <= state_REG_DATA;
                    // end else begin
                    //     FSM_I2C_REG <= state_REG;
                    end
                state_REG_DATA:
                    if(f_2end/*f_stop |f_start_repeated*/)begin
                        FSM_I2C_REG <= state_REG_WAIT;
                    end else if(f_2err)begin
                        FSM_I2C_REG <= state_REG_ERR;
                    end else if(f_end)begin
                        FSM_I2C_REG <= state_REG_WAIT;
                    // end else begin
                    //     FSM_I2C_REG <= state_REG;
                    end
                state_REG_ERR:
                    if(f_2end)begin
                        FSM_I2C_REG <= state_REG_WAIT;
                    // end else begin
                    //     FSM_I2C_REG <= state_ERR;
                    end
                default:
                    FSM_I2C_REG <= state_ERR;
            endcase
        end
    end
end
//-------
// counter bit in byte
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        cnt_bit <= 'd0;
    end else begin
        if(reset)begin
            cnt_bit <= 'd0;
        end else if(!f_cnt_bit_en)begin
            cnt_bit <= 'd0;
        end else if((FSM_I2C == state_ACK) & (f_negedge_sck))begin
            cnt_bit <= 'd0;
        end else if(f_posedge_sck)begin
            cnt_bit <= cnt_bit +'d1;
        end else begin
            cnt_bit <= cnt_bit;
        end
    end
end
//-------
// byte buffer load
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_byte_buf <= 'h00;
    end else begin
        if(reset)begin
            r_byte_buf <= 'h00;
        end else if(!f_cnt_bit_en)begin
            r_byte_buf <= 'h00;
        end else if(FSM_I2C == state_ADDR)begin
            if(f_posedge_sck)begin
                r_byte_buf[00] <= SDA;
                r_byte_buf[07:01] <= r_byte_buf[06:00];
            end else begin
                r_byte_buf <= r_byte_buf;
            end
        end else if(FSM_I2C == state_ACK)begin
            if(r_rw & f_addr_ok)begin
                if(f_posedge_sck)begin
                    r_byte_buf <= r_data_rx_buf[07:00];
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            end else begin
                if(f_negedge_sck)begin
                    r_byte_buf <= 'h00;
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            end
        end else if(FSM_I2C == state_DATA)begin
            if(r_rw)begin
                if(f_negedge_sck)begin
                    r_byte_buf <= r_byte_buf;
//                    r_byte_buf[00] <= SDA;
//                    r_byte_buf[07:01] <= r_byte_buf[06:00];
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            end else begin
                if(f_posedge_sck)begin
                    r_byte_buf[00] <= SDA;
                    r_byte_buf[07:01] <= r_byte_buf[06:00];
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            end
        end else begin
            r_byte_buf <= r_byte_buf;
        end
    end
end
//-------
// dev address read
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_addr          <= 'h000;
        r_addr_valid    <= 1'b0;
        r_rw            <= 1'b1;
    end else begin
        if(reset)begin
            r_addr          <= 'h000;
            r_addr_valid    <= 1'b0;      
            r_rw            <= 1'b1;
        end else if(!f_cnt_bit_en)begin
            r_addr          <= 'h000;
            r_addr_valid    <= 1'b0;
            r_rw            <= 1'b1;
        end else if(FSM_I2C == state_ADDR)begin
            if(f_negedge_sck)begin
                if(cnt_bit >= 'd8)begin
                    if(cnt == 'd8)begin
                        r_rw    <= r_byte_buf[0];
                        case (r_byte_buf[07:01])
                        7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                        begin
                            r_addr <= 10'h000;                // will fix (not implemented)
                            if(r_byte_buf[0])begin          // will fix (not implemented)
                                r_addr_valid    <= 1'b1;    // will fix (not implemented)
                            end else begin                  // will fix (not implemented)
                                r_addr_valid    <= 1'b1;    // will fix (not implemented)
                            end                             // will fix (not implemented)
                        end
                        7'b0000001: // CBUS address
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                        end
                        7'b0000010: // reserved for different bus format
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                        end
                        7'b0000011: // reserved for future purposes
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                        end
                        default:
                            case (r_byte_buf[07:01] & 7'b1111100)
                            7'b0000100: // Hs-mode controller code
                            begin
                                r_addr          <= 'h000;
                                r_addr_valid    <= 1'b0;
                            end
                            7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                            begin
                                r_addr  <= 'h000;               // will fix (not implemented)
                                if(r_byte_buf[0])begin          // will fix (not implemented)
                                    r_addr_valid    <= 1'b1;    // will fix (not implemented)
                                end else begin                  // will fix (not implemented)
                                    r_addr_valid    <= 1'b0;    // will fix (not implemented)
                                end
                            end
                            7'b1111000: // 10-bit target addressing
                            begin
                                r_addr[01:00]   <= r_byte_buf[02:01];
                                r_addr_valid    <= 1'b0;
                            end
                            default: // 7bit address 
                            begin
                                r_addr[06:00]   <= r_byte_buf[07:01];
                                r_addr_valid    <= 1'b1;
                            end
                            endcase
                        endcase
                    end else if(cnt == 'd10)begin
                        r_addr          <= {(r_addr << 8), r_byte_buf};
                        r_addr_valid    <= 1'b1;
                        r_rw            <= r_rw;
                    end else begin
                        r_addr          <= r_addr;
                        r_addr_valid    <= r_addr_valid;
                        r_rw            <= r_rw;
                    end                    
                end else begin
                    r_addr          <= r_addr; 
                    r_addr_valid    <= r_addr_valid; 
                    r_rw            <= r_rw;
                end
            end else begin
                r_addr          <= r_addr;
                r_addr_valid    <= r_addr_valid;
                r_rw            <= r_rw;
            end
        end else if(FSM_I2C == state_ACK)begin
            if(f_posedge_sck)begin
                if(cnt == 'd2)begin
                    r_addr          <= r_addr;
                    r_addr_valid    <= r_addr_valid;
                    r_rw            <= r_rw;
                end else if(cnt == 'd7) begin
                    case (r_addr[06:00])
                        7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                        begin
                            r_addr          <= r_addr;
                            r_addr_valid    <= r_addr_valid;
                            r_rw            <= r_rw;
                        end
                        7'b0000001: // CBUS address 
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                            r_rw            <= 1'b1;
                        end
                        7'b0000010: // reserved for different bus format
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                            r_rw            <= 1'b1;
                        end
                        7'b0000011: // reserved for future purposes 
                        begin
                            r_addr          <= 'h000;
                            r_addr_valid    <= 1'b0;
                            r_rw            <= 1'b1;
                        end
                        default:
                            case (r_addr[06:00] & 7'b1111100)
                                7'b0000100: // Hs-mode controller code
                                begin
                                    r_addr          <= 'h000;
                                    r_addr_valid    <= 1'b0;
                                    r_rw            <= 1'b1;
                                end
                                7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                                begin
                                    r_addr          <= r_addr;
                                    r_addr_valid    <= r_addr_valid;
                                    r_rw            <= r_rw;
                                end
                                7'b1111000: // 10-bit target addressing
                                begin
                                    r_addr          <= 'h000;
                                    r_addr_valid    <= 1'b0;
                                    r_rw            <= 1'b1;
                                end
                                default: // 7bit address
                                    if(f_addr_ok)begin
                                        r_addr          <= r_addr;
                                        r_addr_valid    <= r_addr_valid;
                                        r_rw            <= r_rw;
                                    end else begin
                                        r_addr          <= 'h000;
                                        r_addr_valid    <= 1'b0;
                                        r_rw            <= 1'b1;
                                    end
                            endcase
                    endcase
                end else if(cnt == 'd10) begin
                    if(f_addr_ok)begin
                        r_addr          <= r_addr;
                        r_addr_valid    <= r_addr_valid;
                        r_rw            <= r_rw;
                    end else begin
                        r_addr          <= 'h000;
                        r_addr_valid    <= 1'b0;
                        r_rw            <= 1'b1;
                    end
                end
            end else begin
                r_addr          <= r_addr;
                r_addr_valid    <= r_addr_valid;
                r_rw            <= r_rw;
            end
        end else begin
            r_addr          <= r_addr;
            r_addr_valid    <= r_addr_valid;
            r_rw            <= r_rw;
        end
    end
end
//-------
// cnt bit for FSM_I2C_REG
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        cnt <= 'd0;
    end else begin
        if(reset)begin
            cnt <= 'd0;
        end else if(!f_cnt_bit_en)begin
            cnt <= 'd0;
        end else if(FSM_I2C == state_ADDR)begin
            if(f_posedge_sck)begin
                cnt <= cnt + 'd1;
            end else if(f_negedge_sck & (cnt == 'd8))begin
                case (r_byte_buf[07:01])
                    7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                        cnt <= 'd0;
                    7'b0000001: // CBUS address
                        cnt <= 'd0;
                    7'b0000010: // reserved for different bus format
                        cnt <= 'd0;
                    7'b0000011: // reserved for future purposes
                        cnt <= 'd0;
                    default:
                        case (r_byte_buf[07:01] & 7'b1111100)
                        7'b0000100: // Hs-mode controller code
                            cnt <= 'd0;
                        7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                            cnt <= 'd0;
                        7'b1111000: // 10-bit target addressing
                            cnt <= 'd2;
                        default: // 7bit address 
                            cnt <= 'd7;
                        endcase
                endcase
            end else begin
                cnt <= cnt;
            end
        end else if(FSM_I2C == state_ACK)begin
            if(f_negedge_sck)begin
                if(cnt == 'd2)begin
                    cnt <= cnt;
                end else if(cnt == 'd7) begin
                    cnt <= 'd0;
                end else if(cnt == 'd10) begin
                    cnt <= 'd0;
                end else if(FSM_I2C_REG == state_REG_ADDR)begin
                    if(f_reg_end)begin
                        cnt <= 'd0;
                    end else begin
                        cnt <= cnt;
                    end
                end else if(FSM_I2C_REG == state_REG_DATA)begin
                    if(f_data_end)begin
                        cnt <= 'd0;
                    end else begin
                        cnt <= cnt;
                    end
                end
            end else begin
                cnt <= cnt;
            end
        end else if(FSM_I2C == state_DATA)begin
            if(f_posedge_sck)begin
                cnt <= cnt + 'd1;
            end else begin
                cnt <= cnt;
            end
        end else begin
            cnt <= 'd0;
        end
    end   
end
//-------
//reg address buffer to write
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_reg_buf   <= 'd0;
        r_reg_valid <= 1'b0;
    end else begin
        if(reset)begin
            r_reg_buf   <= 'd0;
            r_reg_valid <= 1'b0;
        end else if(!f_cnt_bit_en)begin
            if(reg_ready)begin
                r_reg_buf   <= 'd0;
                r_reg_valid <= 1'b0;
            end else begin
                r_reg_buf   <= r_reg_buf;
                r_reg_valid <= r_reg_valid;
            end
        end else if(r_rw)begin  //read
            if(reg_ready)begin
                r_reg_buf   <= 'd0;
                r_reg_valid <= 1'b0;
            end else begin
                r_reg_buf   <= r_reg_buf;
                r_reg_valid <= r_reg_valid;
            end
        end else begin
            if((FSM_I2C == state_DATA) & (FSM_I2C_REG == state_REG_ADDR))begin
                if(f_negedge_sck & f_byte_end & f_reg_end)begin
                    if((({(r_reg_buf << 8), r_byte_buf} > P_REG_ADDR_START) & ({(r_reg_buf << 8), r_byte_buf} < P_REG_ADDR_STOP))|(P_REG_ADDR_RESTRICT == 1'b0))begin
                        r_reg_buf <= {(r_reg_buf << 8), r_byte_buf};
                        r_reg_valid <= 1'b1;
                    end else if(reg_ready)begin
                        r_reg_buf   <= 'd0;
                        r_reg_valid <= 1'b0;
                    end else begin
                        r_reg_buf   <= r_reg_buf;
                        r_reg_valid <= r_reg_valid;
                    end
                end else if(reg_ready)begin
                    r_reg_buf   <= 'd0;
                    r_reg_valid <= 1'b0;
                end else begin
                    r_reg_buf <= r_reg_buf;
                    r_reg_valid <= r_reg_valid;
                end
            end else if(reg_ready)begin
                r_reg_buf   <= 'd0;
                r_reg_valid <= 1'b0;
            end else begin
                r_reg_buf <= r_reg_buf;
                r_reg_valid <= r_reg_valid;
            end
        end
    end
end
//-------
//data rx buffer to write
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_data_rx_buf       <= 'd0;
        r_data_rx_valid_buf <= 1'b0;
    end else begin
        if(reset)begin
            r_data_rx_buf       <= 'd0;
            r_data_rx_valid_buf <= 1'b0;
        end else if(!f_cnt_bit_en)begin
            r_data_rx_buf       <= 'd0;
            r_data_rx_valid_buf <= 1'b0;
        end else if(r_rw)begin //read
            r_data_rx_buf       <= 'd0;
            r_data_rx_valid_buf <= 1'b0;
        end else if((FSM_I2C == state_DATA) & (FSM_I2C_REG == state_REG_DATA))begin
            if(f_negedge_sck & f_byte_end)begin
                if(f_data_end)begin
                    r_data_rx_buf       <= {(r_data_rx_buf << 8), r_byte_buf};
                    r_data_rx_valid_buf <= 1'b1;
                end else if(wr_ready)begin
                    r_data_rx_buf       <= 'd0;
                    r_data_rx_valid_buf <= 1'b0;
                end else begin
                    r_data_rx_buf       <= r_data_rx_buf;
                    r_data_rx_valid_buf <= r_data_rx_valid_buf;
                end
            end else if(wr_ready)begin
                r_data_rx_buf       <= 'd0;
                r_data_rx_valid_buf <= 1'b0;
            end else begin
                r_data_rx_buf       <= r_data_rx_buf;
                r_data_rx_valid_buf <= r_data_rx_valid_buf;
            end
        end else if(wr_ready)begin
            r_data_rx_buf       <= 'd0;
            r_data_rx_valid_buf <= 1'b0;
        end else begin
            r_data_rx_buf       <= r_data_rx_buf;
            r_data_rx_valid_buf <= r_data_rx_valid_buf;
        end
    end
end
//-------
// data tx buffer to write
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_data_tx_ready     <= 1'b0;
        r_data_tx_buf       <= 'd0;
        r_data_tx_valid_buf <= 1'b0;
    end else begin
        if(reset)begin
            r_data_tx_ready     <= 1'b0;
            r_data_tx_buf       <= 'd0;
            r_data_tx_valid_buf <= 1'b0;
        end else if(!f_cnt_bit_en)begin
            r_data_tx_ready     <= 1'b0;
            r_data_tx_buf       <= 'd0;
            r_data_tx_valid_buf <= 1'b0;
        end else if(r_rw)begin  //read
            if((FSM_I2C_REG == state_REG_WAIT)|(FSM_I2C_REG == state_REG_ADDR))begin
                if(rd_ready & rd_valid)begin
                    r_data_tx_ready     <= 1'b0;
                    r_data_tx_buf       <= rd_data;
                    r_data_tx_valid_buf <= 1'b1;
                end else begin
                    if(r_data_tx_valid_buf)begin
                        r_data_tx_ready     <= 1'b0;
                    end else begin
                        r_data_tx_ready     <= 1'b1;
                    end
                    r_data_tx_buf       <= r_data_tx_buf;
                    r_data_tx_valid_buf <= r_data_tx_valid_buf;
                end
            end else if(FSM_I2C_REG == state_REG_DATA)begin
                if(f_negedge_sck & (FSM_I2C == state_DATA))begin
                    if(f_data_end)begin
                        if(rd_ready & rd_valid)begin
                            r_data_tx_ready     <= 1'b0;
                            r_data_tx_buf       <= rd_data;
                            r_data_tx_valid_buf <= 1'b1;
                        end else begin
                            r_data_tx_ready     <= 1'b1;
                            r_data_tx_buf       <= 'd0;
                            r_data_tx_valid_buf <= 1'b0;
                        end
                    end else begin
                        r_data_tx_ready     <= 1'b0;
                        r_data_tx_buf       <= r_data_tx_buf <<< 1;
                        r_data_tx_valid_buf <= r_data_tx_valid_buf;
                    end
                end else begin
                    if(rd_ready & rd_valid)begin
                        r_data_tx_ready     <= 1'b0;
                        r_data_tx_buf       <= rd_data;
                        r_data_tx_valid_buf <= 1'b1;
                    end else begin
                        if(r_data_tx_valid_buf)begin
                            r_data_tx_ready     <= 1'b0;
                        end else begin
                            r_data_tx_ready     <= 1'b1;
                        end
                        r_data_tx_buf       <= r_data_tx_buf;
                        r_data_tx_valid_buf <= r_data_tx_valid_buf;
                    end
                end
            end else begin
                r_data_tx_ready     <= r_data_tx_ready;
                r_data_tx_buf       <= r_data_tx_buf;
                r_data_tx_valid_buf <= r_data_tx_valid_buf;
            end
        end else begin  //write
                    if(rd_ready & rd_valid)begin
                        r_data_tx_ready     <= 1'b0;
                        r_data_tx_buf       <= rd_data;
                        r_data_tx_valid_buf <= 1'b1;
                    end else begin
                        if(r_data_tx_valid_buf)begin
                            r_data_tx_ready     <= 1'b0;
                        end else begin
                            r_data_tx_ready     <= 1'b1;
                        end
                        r_data_tx_buf       <= r_data_tx_buf;
                        r_data_tx_valid_buf <= r_data_tx_valid_buf;
                    end
        end
    end
end
//-------
// I2C interface SCL controller
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SCK_r <= 'dZ;
    end else begin
        if(reset)begin
            SCK_r <= 'dZ;
        end else if(!f_cnt_bit_en)begin
            SCK_r <= 'dZ;
        end else if(f_2ack)begin
            if(FSM_I2C == state_ADDR)begin
                if(f_addr_end & (!r_data_tx_valid_buf))begin
                    if(((r_byte_buf[0])&(P_DEV_ADDR_LENGTH == 'd7)) | (r_rw &(P_DEV_ADDR_LENGTH == 'd10)))begin
                        SCK_r <= 'd0;
                    end else begin
                        SCK_r <= 'dZ;
                    end
                end else begin
                    SCK_r <= 'dZ;
                end
            end else if(FSM_I2C == state_DATA)begin
                if(r_rw)begin
                    if(f_data_end & (!r_data_tx_valid_buf))begin
                        SCK_r <= 'd0;
                    end else begin
                        SCK_r <= 'dZ;
                    end
                end else if(FSM_I2C_REG == state_REG_ADDR)begin //----------------------?????????
                    if(reg_ready | (!reg_valid))begin
                        SCK_r <= 'dZ;
                    end else begin
                        SCK_r <= 'd0;
                    end
                end else if(FSM_I2C_REG == state_REG_DATA)begin //----------------------?????????
                    if(wr_ready | (!wr_valid))begin
                        SCK_r <= 'dZ;
                    end else begin
                        SCK_r <= 'd0;
                    end
                end else begin
                    SCK_r <= 'dZ;
                end
            end else begin
                SCK_r <= 'dZ;
            end
        end else begin
            SCK_r <= 'dZ;
        end
    end
end
//-------
// I2C interface SDA controller
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SDA_r <= 'dZ;
    end else begin
        if(reset)begin
            SDA_r <= 'dZ;
        end else if(!f_cnt_bit_en)begin
            SDA_r <= 'dZ;
        end else if(FSM_I2C == state_ADDR)begin
            if(f_2ack)begin
                if(f_addr_end)begin
                    if(r_byte_buf[07:01] == r_address)begin
                        SDA_r <= 'd0;
                    end else begin
                        SDA_r <= 'dZ;
                    end
                end else begin
                    SDA_r <= 'd0;
                end
            end else begin
                SDA_r <= 'dZ;
            end
        end else if(FSM_I2C == state_ACK)begin
            if(f_negedge_sck)begin
                SDA_r <= 'dZ;
            end else begin
                SDA_r <= SDA_r;
            end
        end else if(FSM_I2C == state_DATA)begin
            if(f_2ack)begin
               if(r_rw)begin
                    SDA_r <= 'dZ;
               end else begin
                    SDA_r <= 'd0;
               end
            end else if(r_rw)begin
                SDA_r <= r_data_tx_buf[7];
            end else begin
                SDA_r <= 'dZ;
            end
        end else begin
            SDA_r <= SDA_r;
        end
    end
end
//-------
//===========================================================
endmodule
//===========================================================