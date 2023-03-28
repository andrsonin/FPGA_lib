//===========================================================
module I2C_redirection(
    // I2C IO interface
    // 
    inout  wire SCK_wire_0,
    inout  wire SDA_wire_0,
    // 
    inout  wire SCK_wire_1,
    inout  wire SDA_wire_1, 
    // debug data
    output reg  f_wire_busy,
    output reg  f_wire_master,
    output reg  f_master_rw,
    // system inpterface
    input  wire aresetn,
    input  wire reset,
    input  wire aclk
);
//===========================================================
//-----------------------------------------------------------
localparam [07:00] 
    state_WAIT   = 8'd0,                  // 0
    state_START  = state_WAIT   + 8'd1,   // 1
    state_ADDR   = state_START  + 8'd1,   // 2
    state_ACK    = state_ADDR   + 8'd1,   // 3
    state_DATA   = state_ACK    + 8'd1,   // 4
    state_ERR    = state_DATA   + 8'd1,   // 6
    state_STOP   = state_ERR    + 8'd1,   // 7
    state_BUSY   = state_STOP   + 8'd1;   // 5
//-----------------------------------------------------------
//-------------------//
wire [01:00] SDA_sync;
assign SDA_sync = {SDA_filter_1[1], SDA_filter_0[1]};

wire [01:00] SCK_sync;
assign SCK_sync = {SCK_filter_1[1], SCK_filter_0[1]};

wire [01:00] SDA_sync_last;
assign SDA_sync_last = {SDA_filter_1[2], SDA_filter_0[2]};

wire [01:00] SCK_sync_last;
assign SCK_sync_last = {SCK_filter_1[2], SCK_filter_0[2]};
//-------------------//
wire SDA;
assign SDA = SDA_sync[0] & SDA_sync[1];

wire SCK;
assign SCK = SCK_sync[0] & SCK_sync[1];

wire SDA_last;
assign SDA_last = SDA_sync_last[0] & SDA_sync_last[1];

wire SCK_last;
assign SCK_last = SCK_sync_last[0] & SCK_sync_last[1];
//-------------------//
wire SDA_pos;
assign SDA_pos = SDA & SDA_last;

wire SDA_neg;
assign SDA_neg = (!SDA) & (!SDA_last);

wire posedge_SDA;
assign posedge_SDA = SDA & (!SDA_last);

wire negedge_SDA;
assign negedge_SDA = (!SDA) & SDA_last;

wire SCK_pos;
assign SCK_pos = SCK & SCK_last;

wire SCK_neg;
assign SCK_neg = (!SCK) & (!SCK_last);

wire posedge_SCK;
assign posedge_SCK = SCK & (!SCK_last);

wire negedge_SCK;
assign negedge_SCK = (!SCK) & SCK_last;
//-----------------------------------------------------------
reg [07:00] FSM_I2C_redir;

reg [02:00] SDA_filter_0;
reg [02:00] SCK_filter_0;

reg [02:00] SDA_filter_1;
reg [02:00] SCK_filter_1;

reg r_addr10_detect;
reg [03:00] cnt;
reg [07:00] Byte_buf;
// 
reg r_SCK_wire_0;
reg r_SDA_wire_0;
// 
reg r_SCK_wire_1;
reg r_SDA_wire_1; 
//
reg f_FSM_ADR_last;
//-------------------//
wire f_start;
assign f_start = SCK_pos & negedge_SDA;

wire f_start_s;
assign f_start_s = ((FSM_I2C_redir != state_WAIT) & (cnt <= 'd1)) ? f_start : 1'b0;

wire f_stop;
assign f_stop = SCK_pos & posedge_SDA;

wire f_Byte_end;
assign f_Byte_end = (cnt >= 'd8) ?  negedge_SCK : 1'b0;

wire f_addr10_detect;
assign f_addr10_detect = ((Byte_buf & 8'b11111000) == 8'b11111000) ? 1'b1 : 1'b0;
//-------------------//
assign SCK_wire_0 = r_SCK_wire_0 ? 1'bz : (SCK_sync[1] ? 1'bz : SCK_sync[1]);
assign SCK_wire_1 = r_SCK_wire_1 ? 1'bz : (SCK_sync[0] ? 1'bz : SCK_sync[0]);

assign SDA_wire_0 = r_SDA_wire_0 ? 1'bz : (SDA_sync[1] ? 1'bz : SDA_sync[1]);
assign SDA_wire_1 = r_SDA_wire_1 ? 1'bz : (SDA_sync[0] ? 1'bz : SDA_sync[0]);
//-------------------//
initial begin
    f_wire_busy     = 1'b0;
    f_wire_master   = 1'b0;
    f_master_rw     = 1'b0;

    FSM_I2C_redir = state_WAIT;

    SDA_filter_0 = 3'b111;
    SCK_filter_0 = 3'b111;
    SDA_filter_1 = 3'b111;
    SCK_filter_1 = 3'b111;

    r_addr10_detect = 1'b0;
    cnt             = 'd0;
    Byte_buf        = 'd0;
    // 
    r_SCK_wire_0 = 1'b1;
    r_SDA_wire_0 = 1'b1;
    // 
    r_SCK_wire_1 = 1'b1;
    r_SDA_wire_1 = 1'b1;
    //
    f_FSM_ADR_last = 1'b0;
end
//-----------------------------------------------------------
//------- Input_Filters
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SDA_filter_0 <= 3'b111;
        SCK_filter_0 <= 3'b111;
        SDA_filter_1 <= 3'b111;
        SCK_filter_1 <= 3'b111;
    end else begin
        if(reset)begin
            SDA_filter_0 <= 3'b111;
            SCK_filter_0 <= 3'b111;
            SDA_filter_1 <= 3'b111;
            SCK_filter_1 <= 3'b111;
        end else begin
            SDA_filter_0[0] <= SDA_wire_0;
            SCK_filter_0[0] <= SCK_wire_0;
            SDA_filter_1[0] <= SDA_wire_1;
            SCK_filter_1[0] <= SCK_wire_1;
            
            SDA_filter_0[1] <= SDA_filter_0[0];
            SCK_filter_0[1] <= SCK_filter_0[0];
            SDA_filter_1[1] <= SDA_filter_1[0];
            SCK_filter_1[1] <= SCK_filter_1[0];  
            
            SDA_filter_0[2] <= SDA_filter_0[1];
            SCK_filter_0[2] <= SCK_filter_0[1];
            SDA_filter_1[2] <= SDA_filter_1[1];
            SCK_filter_1[2] <= SCK_filter_1[1];       
        end
    end            
end
//-----------------------------------------------------------
//------- FSM_MAIN
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_I2C_redir <= state_WAIT;
        f_FSM_ADR_last <= 1'b0;
    end else begin
        if(reset)begin
            FSM_I2C_redir <= state_WAIT;
            f_FSM_ADR_last <= 1'b0;
        end else begin
            case (FSM_I2C_redir)
                state_WAIT:
                    if(f_start)begin
                        FSM_I2C_redir <= state_START;
                        f_FSM_ADR_last <= 1'b0;
                    end else begin
                        FSM_I2C_redir <= state_WAIT;
                        f_FSM_ADR_last <= 1'b0;
                    end                   
                state_START:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_STOP;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(negedge_SCK)begin
                        FSM_I2C_redir <= state_ADDR;
                        f_FSM_ADR_last <= 1'b0;
                    end else begin
                        FSM_I2C_redir <= state_START;
                        f_FSM_ADR_last <= 1'b0;
                    end
                state_ADDR:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_STOP;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_start_s)begin
                        FSM_I2C_redir <= state_START;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_start)begin
                        FSM_I2C_redir <= state_ERR;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_Byte_end)begin
                        FSM_I2C_redir <= state_ACK;
                        f_FSM_ADR_last <= 1'b1;
                    end else begin
                        FSM_I2C_redir <= state_ADDR;
                        f_FSM_ADR_last <= 1'b0;
                    end
                state_ACK:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_STOP;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_start)begin
                        FSM_I2C_redir <= state_START;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(negedge_SCK)begin
                        if(r_addr10_detect)begin
                            FSM_I2C_redir <= state_ADDR;
                        end else begin
                            FSM_I2C_redir <= state_DATA;
                        end
                        f_FSM_ADR_last <= 1'b1;
                    end else begin
                        FSM_I2C_redir <= state_ACK;
                        f_FSM_ADR_last <= f_FSM_ADR_last;
                    end
                state_DATA:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_STOP;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_start_s)begin
                        FSM_I2C_redir <= state_START;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_start)begin
                        FSM_I2C_redir <= state_ERR;
                        f_FSM_ADR_last <= 1'b0;
                    end else if(f_Byte_end)begin
                        FSM_I2C_redir <= state_ACK;
                        f_FSM_ADR_last <= 1'b0;
                    end else begin
                        FSM_I2C_redir <= state_DATA;
                        f_FSM_ADR_last <= f_FSM_ADR_last;
                    end
                state_STOP:begin
                    FSM_I2C_redir <= state_WAIT;
                    f_FSM_ADR_last <= 1'b0;
                end
                state_ERR:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_STOP;
                        f_FSM_ADR_last <= 1'b0;
                    end else begin
                        FSM_I2C_redir <= state_ERR;
                        f_FSM_ADR_last <= 1'b0;
                    end
                default: begin
                    FSM_I2C_redir <= state_ERR;
                    f_FSM_ADR_last <= 1'b0;
                end
            endcase
        end
    end            
end
//-----------------------------------------------------------
//------- SCK_control
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_SCK_wire_0 = 1'b1;
        r_SCK_wire_1 = 1'b1;
    end else begin
        if(reset)begin
            r_SCK_wire_0 = 1'b1;
            r_SCK_wire_1 = 1'b1;
        end else begin
            case (FSM_I2C_redir)
                state_WAIT:begin
                    r_SCK_wire_0 = 1'b1;
                    r_SCK_wire_1 = 1'b1;
				end
                state_START:
                    if(f_wire_master)begin
                        r_SCK_wire_0 = 1'b0;
                        r_SCK_wire_1 = 1'b1;
                    end else begin
                        r_SCK_wire_0 = 1'b1;
                        r_SCK_wire_1 = 1'b0;
                    end
                state_ADDR:
                    if(f_wire_master)begin
                        r_SCK_wire_0 = 1'b0;
                        r_SCK_wire_1 = 1'b1;
                    end else begin
                        r_SCK_wire_0 = 1'b1;
                        r_SCK_wire_1 = 1'b0;
                    end
                state_DATA:
                    if(f_wire_master)begin
                        r_SCK_wire_0 = 1'b0;
                        r_SCK_wire_1 = 1'b1;
                    end else begin
                        r_SCK_wire_0 = 1'b1;
                        r_SCK_wire_1 = 1'b0;
                    end
                state_ACK:
                    if(f_wire_master)begin
                        r_SCK_wire_0 = 1'b0;
                        r_SCK_wire_1 = 1'b1;
                    end else begin
                        r_SCK_wire_0 = 1'b1;
                        r_SCK_wire_1 = 1'b0;
                    end
                state_STOP:
                    if(f_wire_master)begin
                        r_SCK_wire_0 = 1'b0;
                        r_SCK_wire_1 = 1'b1;
                    end else begin
                        r_SCK_wire_0 = 1'b1;
                        r_SCK_wire_1 = 1'b0;
                    end
                default:begin
                    r_SCK_wire_0 = 1'b1;
                    r_SCK_wire_1 = 1'b1;
				end
            endcase
        end
    end
end
//-----------------------------------------------------------
//------- SDA_control
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_SDA_wire_0 = 1'b1;
        r_SDA_wire_1 = 1'b1;
    end else begin
        if(reset)begin
            r_SDA_wire_0 = 1'b1;
            r_SDA_wire_1 = 1'b1;
        end else begin
            case (FSM_I2C_redir)
                state_WAIT:begin
                    r_SDA_wire_0 = 1'b1;
                    r_SDA_wire_1 = 1'b1;
				end
                state_START, state_ADDR:
                    if(f_wire_master)begin
                        r_SDA_wire_0 = SDA;
                        r_SDA_wire_1 = 1'b1;
                    end else begin
                        r_SDA_wire_0 = 1'b1;
                        r_SDA_wire_1 = SDA;
                    end
                state_DATA:
                    if(f_wire_master)begin
                        if(f_master_rw)begin
                            r_SDA_wire_0 = 1'b1;
                            r_SDA_wire_1 = SDA;
                        end else begin
                            r_SDA_wire_0 = SDA;
                            r_SDA_wire_1 = 1'b1;
                        end
                    end else begin
                        if(f_master_rw)begin
                            r_SDA_wire_0 = SDA;
                            r_SDA_wire_1 = 1'b1;
                        end else begin
                            r_SDA_wire_0 = 1'b1;
                            r_SDA_wire_1 = SDA;
                        end
                    end
                state_ACK: 
                    if(f_FSM_ADR_last)begin
                        if(f_wire_master)begin
                            r_SDA_wire_0 = 1'b1;
                            r_SDA_wire_1 = SDA;
                        end else begin
                            r_SDA_wire_0 = SDA;
                            r_SDA_wire_1 = 1'b1;
                        end
                    end else begin
                        if(f_wire_master)begin
                            if(f_master_rw)begin
                                r_SDA_wire_0 = SDA;
                                r_SDA_wire_1 = 1'b1;
                            end else begin
                                r_SDA_wire_0 = 1'b1;
                                r_SDA_wire_1 = SDA;
                            end
                        end else begin
                            if(f_master_rw)begin
                                r_SDA_wire_0 = 1'b1;
                                r_SDA_wire_1 = SDA;
                            end else begin
                                r_SDA_wire_0 = SDA;
                                r_SDA_wire_1 = 1'b1;
                            end
                        end
                    end
                state_STOP:
                    if(f_wire_master)begin
                        if(f_master_rw)begin
                            r_SDA_wire_0 = 1'b1;
                            r_SDA_wire_1 = SDA;
                        end else begin
                            r_SDA_wire_0 = SDA;
                            r_SDA_wire_1 = 1'b1;
                        end
                    end else begin
                        if(f_master_rw)begin
                            r_SDA_wire_0 = SDA;
                            r_SDA_wire_1 = 1'b1;
                        end else begin
                            r_SDA_wire_0 = 1'b1;
                            r_SDA_wire_1 = SDA;
                        end
                    end
                default:begin
                    r_SDA_wire_0 = 1'b1;
                    r_SDA_wire_1 = 1'b1;
				end
            endcase
        end
    end
end
//-----------------------------------------------------------
//------- 
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        f_wire_busy <= 1'b0;
        f_wire_master <= 1'b0;
    end else begin
        if(reset)begin
            f_wire_busy <= 1'b0;
            f_wire_master <= 1'b0;
        end else if(f_start)begin
            case (SDA_sync)
                2'b10:begin
                    f_wire_busy <= 1'b1;
                    f_wire_master <= 1'b0;
                end
                2'b01:begin 
                    f_wire_busy <= 1'b1;
                    f_wire_master <= 1'b1;
                end
                default:begin 
                    f_wire_busy <= 1'b1;
                    f_wire_master <= 1'b0;
                end
            endcase
        end else if(f_wire_busy)begin
            if(f_stop)begin
                f_wire_busy <= 1'b0;
                f_wire_master <= 1'b0;
            end else begin
                f_wire_busy <= f_wire_busy;
                f_wire_master <= f_wire_master;
            end
        end else begin
            f_wire_busy <= 1'b0;
            f_wire_master <= 1'b0;
        end
    end
end
//-----------------------------------------------------------
//-------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        r_addr10_detect <= 1'b0;
        f_master_rw <= 1'b0;
    end else begin
        if(reset)begin
            r_addr10_detect <= 1'b0;
            f_master_rw <= 1'b0;
        end else begin
            case (FSM_I2C_redir)
                state_ADDR:
                    if(f_Byte_end)begin
                        if(r_addr10_detect)begin
                            r_addr10_detect <= 1'b0;
                            f_master_rw <= f_master_rw;
                        end else if(f_addr10_detect)begin
                            r_addr10_detect <= 1'b1;
                            f_master_rw <= Byte_buf[0];
                        end else begin
                            r_addr10_detect <= 1'b0;
                            f_master_rw <= Byte_buf[0];
                        end
                    end else begin
                        r_addr10_detect <= r_addr10_detect;
                        f_master_rw <= f_master_rw;
                    end
                state_ACK: begin
                    r_addr10_detect <= r_addr10_detect;
                    f_master_rw <= f_master_rw;
					 end
                state_DATA: begin
                    r_addr10_detect <= 1'b0;
                    f_master_rw <= f_master_rw;
                end
                state_STOP:begin
                    r_addr10_detect <= 1'b0;
                    f_master_rw <= f_master_rw;
                end
                default: begin
                    r_addr10_detect <= 1'b0;
                    f_master_rw <= 1'b0;
					 end
            endcase
        end
    end            
end
//-----------------------------------------------------------
//-------
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        cnt <= 'd0;
        Byte_buf <= 'd0;
    end else begin
        if(reset)begin
            cnt <= 'd0;
            Byte_buf <= 'd0;
        end else begin
            case (FSM_I2C_redir)
                state_ADDR:
                    if(posedge_SCK) begin
                        cnt <= cnt +'d1;
                        Byte_buf[0] <= SDA;
                        Byte_buf[07:01] <= Byte_buf[06:00];
                    end else begin
                        cnt <= cnt;
                        Byte_buf <= Byte_buf;
                    end
                state_DATA:
                    if(posedge_SCK) begin
                        cnt <= cnt +'d1;
                        Byte_buf[0]     <= SDA;
                        Byte_buf[07:01] <= Byte_buf[06:00];
                    end else begin
                        cnt <= cnt;
                        Byte_buf <= Byte_buf;
                    end
                state_ACK:begin
                    cnt <= 'd0;
                    Byte_buf <= 'd0;
				end
                state_STOP:begin
                    cnt <= 'd0;
                    Byte_buf <= 'd0;
                end
                default: begin
                    cnt <= 'd0;
                    Byte_buf <= 'd0;
				end
            endcase
        end
    end            
end
//-----------------------------------------------------------
//===========================================================
endmodule
//===========================================================

//===========================================================
module I2C_redirection_v2(
    // I2C IO interface
    // 
    inout  wire SCK_wire_0,
    inout  wire SDA_wire_0,
    // 
    inout  wire SCK_wire_1,
    inout  wire SDA_wire_1, 
    // debug data
    output reg  [01:00] wire_busy,
    output reg  action,
    output reg  wire_master,
    output reg  wire_master_rw,
    
    output reg [15:00] i2c_clk_det,
    output reg [09:00] i2c_addr_det,
    output reg i2c_det_valid,
    // system inpterface
    input  wire aresetn,
    input  wire reset,
    input  wire aclk
);
//===========================================================
//-----------------------------------------------------------
localparam [07:00] 
    state_WAIT   = 8'd0,                  // 0
    state_START  = state_WAIT   + 8'd1,   // 1
    state_ADDR   = state_START  + 8'd1,   // 2
    state_ACK    = state_ADDR   + 8'd1,   // 3
    state_DATA   = state_ACK    + 8'd1,   // 4
    state_ERR    = state_DATA   + 8'd1,   // 6
    state_STOP   = state_ERR    + 8'd1,   // 7
    state_BUSY   = state_STOP   + 8'd1;   // 5
//-----------------------------------------------------------
reg [07:00] FSM_I2C_redir [01:00];

reg [02:00] SDA_filter_0;
reg [02:00] SCK_filter_0;

reg [02:00] SDA_filter_1;
reg [02:00] SCK_filter_1;

reg aresetn_sync;

reg [31:00] cnt_frec;
reg [31:00] cnt_frec_min;
reg [07:00] cnt [01:00];
//-------------------//
wire [01:00] SDA_sync;
assign SDA_sync = {SDA_filter_1[1], SDA_filter_0[1]};

wire [01:00] SCK_sync;
assign SCK_sync = {SCK_filter_1[1], SCK_filter_0[1]};

wire [01:00] SDA_sync_last;
assign SDA_sync_last = {SDA_filter_1[2], SDA_filter_0[2]};

wire [01:00] SCK_sync_last;
assign SCK_sync_last = {SCK_filter_1[2], SCK_filter_0[2]};

wire [01:00] SCK_sync_posedge;
assign SCK_sync_posedge[0] = ((SCK_sync[0] == 1'b1)&(SCK_sync_last[0] == 1'b0)) ? 1'b1 : 1'b0;
assign SCK_sync_posedge[1] = ((SCK_sync[1] == 1'b1)&(SCK_sync_last[1] == 1'b0)) ? 1'b1 : 1'b0;

wire [01:00] SDA_sync_posedge;
assign SDA_sync_posedge[0] = ((SDA_sync[0] == 1'b1)&(SDA_sync_last[0] == 1'b0)) ? 1'b1 : 1'b0;
assign SDA_sync_posedge[1] = ((SDA_sync[1] == 1'b1)&(SDA_sync_last[1] == 1'b0)) ? 1'b1 : 1'b0;

wire [01:00] SCK_sync_negedge;
assign SCK_sync_negedge[0] = ((SCK_sync[0] == 1'b0)&(SCK_sync_last[0] == 1'b1)) ? 1'b1 : 1'b0;
assign SCK_sync_negedge[1] = ((SCK_sync[1] == 1'b0)&(SCK_sync_last[1] == 1'b1)) ? 1'b1 : 1'b0;

wire [01:00] SDA_sync_negedge;
assign SDA_sync_negedge[0] = ((SDA_sync[0] == 1'b0)&(SDA_sync_last[0] == 1'b1)) ? 1'b1 : 1'b0;
assign SDA_sync_negedge[1] = ((SDA_sync[1] == 1'b0)&(SDA_sync_last[1] == 1'b1)) ? 1'b1 : 1'b0;

wire [01:00] SCK_sync_high;
assign SCK_sync_high[0] = ((SCK_sync[0] == 1'b1)&(SCK_sync_last[0] == 1'b1)) ? 1'b1 : 1'b0;
assign SCK_sync_high[1] = ((SCK_sync[1] == 1'b1)&(SCK_sync_last[1] == 1'b1)) ? 1'b1 : 1'b0;

wire [01:00] SDA_sync_high;
assign SDA_sync_high[0] = ((SDA_sync[0] == 1'b1)&(SDA_sync_last[0] == 1'b1)) ? 1'b1 : 1'b0;
assign SDA_sync_high[1] = ((SDA_sync[1] == 1'b1)&(SDA_sync_last[1] == 1'b1)) ? 1'b1 : 1'b0;

wire [01:00] SCK_sync_low;
assign SCK_sync_low[0] = ((SCK_sync[0] == 1'b0)&(SCK_sync_last[0] == 1'b0)) ? 1'b1 : 1'b0;
assign SCK_sync_low[1] = ((SCK_sync[1] == 1'b0)&(SCK_sync_last[1] == 1'b0)) ? 1'b1 : 1'b0;

wire [01:00] SDA_sync_low;
assign SDA_sync_low[0] = ((SCK_sync_low[0] == 1'b0)&(SDA_sync_last[0] == 1'b0)) ? 1'b1 : 1'b0;
assign SDA_sync_low[1] = ((SCK_sync_low[1] == 1'b0)&(SDA_sync_last[1] == 1'b0)) ? 1'b1 : 1'b0;

wire [01:00] f_START_sync;
assign f_START_sync[0] = ((SCK_sync_high[0] == 1'b1)&(SDA_sync_negedge[0] == 1'b1)) ? 1'b1 : 1'b0; 
assign f_START_sync[1] = ((SCK_sync_high[1] == 1'b1)&(SDA_sync_negedge[1] == 1'b1)) ? 1'b1 : 1'b0; 

wire [01:00] f_STOP_sync;
assign f_STOP_sync[0] = ((SCK_sync_high[0] == 1'b1)&(SDA_sync_posedge[0] == 1'b1)) ? 1'b1 : 1'b0; 
assign f_STOP_sync[1] = ((SCK_sync_high[1] == 1'b1)&(SDA_sync_posedge[1] == 1'b1)) ? 1'b1 : 1'b0; 
//-------------------//
wire SDA;
assign SDA = SDA_sync[0] & SDA_sync[1];

wire SCK;
assign SCK = SCK_sync[0] & SCK_sync[1];
//-------------------//
wire f_wire_busy;
assign f_wire_busy = wire_busy[0] | wire_busy[1];
//-------------------//
initial begin
    wire_busy       = 2'b00;
    action          = 1'b0;
    wire_master     = 1'b0;
    wire_master_rw  = 1'b1; // 1'b1 - read; 1'b0 - write;
    
    FSM_I2C_redir[0] = state_WAIT;
    FSM_I2C_redir[1] = state_WAIT;
    
    aresetn_sync    = 1'b1;
    
    cnt_frec        = 'd0;
    cnt_frec_min    = 'd0;
    cnt[0]             = 'd0;
    cnt[1]             = 'd0;

    SDA_filter_0 = 3'b111;
    SCK_filter_0 = 3'b111;
    SDA_filter_1 = 3'b111;
    SCK_filter_1 = 3'b111;
end
//-----------------------------------------------------------
always @(posedge aclk) begin
    aresetn_sync <= aresetn;
end
//-----------------------------------------------------------
//------- Input_Filters
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SDA_filter_0 <= 3'b111;
        SCK_filter_0 <= 3'b111;
        SDA_filter_1 <= 3'b111;
        SCK_filter_1 <= 3'b111;
    end else begin
        if(reset)begin
            SDA_filter_0 <= 3'b111;
            SCK_filter_0 <= 3'b111;
            SDA_filter_1 <= 3'b111;
            SCK_filter_1 <= 3'b111;
        end else begin
            SDA_filter_0[0] <= SDA_wire_0;
            SCK_filter_0[0] <= SCK_wire_0;
            SDA_filter_1[0] <= SDA_wire_1;
            SCK_filter_1[0] <= SCK_wire_1;
            
            SDA_filter_0[1] <= SDA_filter_0[0];
            SCK_filter_0[1] <= SCK_filter_0[0];
            SDA_filter_1[1] <= SDA_filter_1[0];
            SCK_filter_1[1] <= SCK_filter_1[0];  
            
            SDA_filter_0[2] <= SDA_filter_0[1];
            SCK_filter_0[2] <= SCK_filter_0[1];
            SDA_filter_1[2] <= SDA_filter_1[1];
            SCK_filter_1[2] <= SCK_filter_1[1];       
        end
    end            
end
//-----------------------------------------------------------
always@(SDA_sync[0])begin
    if(SCK_sync[0] & SDA_sync[0])begin
        wire_busy[0] <= 1'b0;
    end else if(SCK_sync[0] & (!SDA_sync[0]))begin
        wire_busy[0] <= 1'b1;
    end else begin
        wire_busy[0] <= wire_busy[0];
    end
end
always@(SDA_sync[1])begin
    if(SCK_sync[1] & SDA_sync[1])begin
        wire_busy[1] <= 1'b0;
    end else if(SCK_sync[1] & (!SDA_sync[1]))begin
        wire_busy[1] <= 1'b1;
    end else begin
        wire_busy[1] <= wire_busy[1];
    end
end
//-----------------------------------------------------------
always@(f_wire_busy)begin
    if(!f_wire_busy)begin
        wire_master <= 1'b0;
    end else begin
        case (wire_busy)
            2'b01:begin
                wire_master <= 1'b0;
            end
            2'b10:begin 
                wire_master <= 1'b1;
            end
            default:begin 
                wire_master <= 1'b0;
            end
        endcase
    end
end
//-----------------------------------------------------------
reg [01:00] reg_start;

initial begin
    reg_start[0] <= 1'b0;
    reg_start[1] <= 1'b0;
end

always@(negedge SDA_sync[0], negedge SCK_sync[0], negedge aresetn)begin
    if((!aresetn)|(!SCK_sync[0]))begin
        reg_start[0] <= 1'b0;
    end else begin
        reg_start[0] <= SCK_sync[0];
    end
end

always@(negedge SDA_sync[1], negedge SCK_sync[1], negedge aresetn)begin
    if((!aresetn)|(!SCK_sync[1]))begin
        reg_start[1] <= 1'b0;
    end else begin
        reg_start[1] <= SCK_sync[1];
    end
end

wire f_start;
assign f_start = reg_start[0] | reg_start[1];
//-----------------------------------------------------------
reg [01:00] reg_stop;

initial begin
    reg_stop[0] <= 1'b0;
    reg_stop[1] <= 1'b0;
end

always@(posedge SDA_sync[0], negedge SCK_sync[0], negedge aresetn)begin
    if((!aresetn)|(!SCK_sync[0]))begin
        reg_stop[0] <= 1'b0;
    end else begin
        reg_stop[0] <= SCK_sync[0];
    end
end

always@(posedge SDA_sync[1], negedge SCK_sync[1], negedge aresetn)begin
    if((!aresetn)|(!SCK_sync[1]))begin
        reg_stop[1] <= 1'b0;
    end else begin
        reg_stop[1] <= SCK_sync[1];
    end
end
//-----------------------------------------------------------
always@(posedge SCK_sync[0], posedge reg_start[0], posedge reg_stop[0], negedge aresetn)begin
    if(reg_start[0] | reg_stop[0] | (!aresetn))begin
        cnt[0] <= 'd0;
    end else begin
        if(FSM_I2C_redir[0] > state_WAIT)begin
            if((cnt[0] > 'd7)|(FSM_I2C_redir[0] == state_ACK))begin
                cnt[0] <= 'd0;
            end else begin
                cnt[0] <= cnt[0] +'d1;
            end
        end else begin
            cnt[0] <= 'd0;
        end
    end
end

always@(posedge SCK_sync[1], posedge reg_start[1], posedge reg_stop[1], negedge aresetn)begin
    if(reg_start[1] | reg_stop[1] | (!aresetn))begin
        cnt[1] <= 'd0;
    end else begin
        if(FSM_I2C_redir[1] > state_WAIT)begin
            if((cnt[1] > 'd7)|(FSM_I2C_redir[1] == state_ACK))begin
                cnt[1] <= 'd0;
            end else begin
                cnt[1] <= cnt[1] +'d1;
            end
        end else begin
            cnt[1] <= 'd0;
        end
    end
end
//-----------------------------------------------------------
reg r_add10bit_det[01:00];
initial begin
    r_add10bit_det[0] = 1'b0;
    r_add10bit_det[0] = 1'b1;
end

always@(negedge SCK_sync[0], posedge reg_start[0], posedge reg_stop[0], negedge aresetn)begin
    if(reg_start[0] | reg_stop[0] | (!aresetn))begin
        if(!aresetn)begin
            if(FSM_I2C_redir[0] > state_WAIT)begin
                FSM_I2C_redir[0] <= state_STOP;
            end else begin
                FSM_I2C_redir[0] <= state_WAIT;
            end
        end else if(reg_start[0])begin
            if(FSM_I2C_redir[0] == state_START)begin
                FSM_I2C_redir[0] <= state_ADDR;
            end else if(
                (FSM_I2C_redir[0] == state_WAIT)
                |(FSM_I2C_redir[0] == state_ACK)
                |((FSM_I2C_redir[0] == state_DATA) & (cnt[0] <= 'd1))
                |(FSM_I2C_redir[0] == state_ERR)
                |(FSM_I2C_redir[0] == state_BUSY)
            )begin
                FSM_I2C_redir[0] <= state_START;
            end else begin
                FSM_I2C_redir[0] <= state_BUSY;
            end
        end else begin
            FSM_I2C_redir[0] <= state_WAIT;
        end
    end else begin
        case(FSM_I2C_redir[0])
            state_START:begin
                FSM_I2C_redir[0] <= state_ADDR;
            end
            state_ADDR:begin
                if(cnt[0] > 'd7)begin
                    FSM_I2C_redir[0] <= state_ACK;
                end else begin
                    FSM_I2C_redir[0] <= state_ADDR;
                end
            end
            state_ACK:begin
                if(r_add10bit_det[0])begin
                    FSM_I2C_redir[0] <= state_DATA;
                end else begin
                    FSM_I2C_redir[0] <= state_ADDR;
                end
            end
            state_DATA:begin
                if(cnt[0] > 'd7)begin
                    FSM_I2C_redir[0] <= state_ACK;
                end else begin
                    FSM_I2C_redir[0] <= state_DATA;
                end
            end
            state_ERR:begin
                FSM_I2C_redir[0] <= state_ERR;
            end
            state_STOP:begin
                FSM_I2C_redir[0] <= state_WAIT;
            end
            state_BUSY:begin
                FSM_I2C_redir[0] <= state_BUSY;
            end
            default:
                FSM_I2C_redir[0] <= state_WAIT;
        endcase
    end
end

always@(negedge SCK_sync[1], posedge reg_start[1], posedge reg_stop[1], negedge aresetn)begin
    if(reg_start[1] | reg_stop[1] | (!aresetn))begin
        if(!aresetn)begin
            if(FSM_I2C_redir[1] > state_WAIT)begin
                FSM_I2C_redir[1] <= state_STOP;
            end else begin
                FSM_I2C_redir[1] <= state_WAIT;
            end
        end else if(reg_start[1])begin
            if(FSM_I2C_redir[1] == state_START)begin
                FSM_I2C_redir[1] <= state_ADDR;
            end else if(
                (FSM_I2C_redir[1] == state_WAIT)
                |(FSM_I2C_redir[1] == state_ACK)
                |((FSM_I2C_redir[1] == state_DATA) & (cnt[1] <= 'd1))
                |(FSM_I2C_redir[1] == state_ERR)
                |(FSM_I2C_redir[1] == state_BUSY)
            )begin
                FSM_I2C_redir[1] <= state_START;
            end else begin
                FSM_I2C_redir[1] <= state_BUSY;
            end
        end else begin
            FSM_I2C_redir[1] <= state_WAIT;
        end
    end else begin
        case(FSM_I2C_redir[1])
            state_START:begin
                FSM_I2C_redir[1] <= state_ADDR;
            end
            state_ADDR:begin
                if(cnt[1] > 'd7)begin
                    FSM_I2C_redir[1] <= state_ACK;
                end else begin
                    FSM_I2C_redir[1] <= state_ADDR;
                end
            end
            state_ACK:begin
                if(r_add10bit_det[1])begin
                    FSM_I2C_redir[1] <= state_DATA;
                end else begin
                    FSM_I2C_redir[1] <= state_ADDR;
                end
            end
            state_DATA:begin
                if(cnt[1] > 'd7)begin
                    FSM_I2C_redir[1] <= state_ACK;
                end else begin
                    FSM_I2C_redir[1] <= state_DATA;
                end
            end
            state_ERR:begin
                FSM_I2C_redir[1] <= state_ERR;
            end
            state_STOP:begin
                FSM_I2C_redir[1] <= state_WAIT;
            end
            state_BUSY:begin
                FSM_I2C_redir[1] <= state_BUSY;
            end
            default:
                FSM_I2C_redir[1] <= state_WAIT;
        endcase
    end
end
//-----------------------------------------------------------
always@(posedge aclk, negedge f_wire_busy)begin
    if((!f_wire_busy)|(!aresetn))begin
        cnt_frec <= 'd0;
        cnt_frec_min <= 'd0;
    end else if((FSM_I2C_redir[wire_master] > state_WAIT)&(FSM_I2C_redir[wire_master] < state_ERR))begin
        if((SCK_sync_posedge[wire_master]))begin
            cnt_frec <= 'd0;
            
            if(cnt_frec_min == 'd0)begin
                cnt_frec_min <= cnt_frec;
            end else if(cnt_frec_min < cnt_frec)begin
                cnt_frec_min <= cnt_frec;
            end else begin
                cnt_frec_min <= cnt_frec_min;
            end
        end else if(!SCK_sync[wire_master])begin
            cnt_frec <= cnt_frec +'d1;
            cnt_frec_min <= cnt_frec_min;
        end else begin
            cnt_frec <= cnt_frec;
            cnt_frec_min <= cnt_frec_min;
        end
    end else begin
        cnt_frec <= 'd0;
        cnt_frec_min <= 'd0;
    end
end

wire [31:00] cnt_frec_min_div2;
assign cnt_frec_min_div2 = (cnt_frec_min > 'd0) ? (cnt_frec_min >> 1) : 'd0;
wire [31:00] cnt_frec_min_div4;
assign cnt_frec_min_div4 = (cnt_frec_min > 'd0) ? (cnt_frec_min >> 2) : 'd0;
wire [31:00] cnt_frec_min_div8;
assign cnt_frec_min_div8 = (cnt_frec_min > 'd0) ? (cnt_frec_min >> 3) : 'd0;
wire [31:00] cnt_frec_min_div16;
assign cnt_frec_min_div16 = (cnt_frec_min > 'd0) ? (cnt_frec_min >> 4) : 'd0;
wire [31:00] cnt_frec_min_div32;
assign cnt_frec_min_div32 = (cnt_frec_min > 'd0) ? (cnt_frec_min >> 5) : 'd0;
wire [31:00] cnt_frec_min_sum_min;
assign cnt_frec_min_sum_min = (cnt_frec_min > 'd0) ? (cnt_frec_min_div2 + cnt_frec_min_div4) : 'd0;
wire [31:00] cnt_frec_min_sum_max;
assign cnt_frec_min_sum_max = (cnt_frec_min > 'd0) ? (cnt_frec_min_div2 + cnt_frec_min_div4 + cnt_frec_min_div8 + cnt_frec_min_div16 + cnt_frec_min_div32) : 'd0;

wire [31:00] cnt_frec_low_mst_min;
assign cnt_frec_low_mst_min = (cnt_frec_min > 'd0) ? cnt_frec_min_sum_max : 'd0;
wire [31:00] cnt_frec_low_mst_max;
assign cnt_frec_low_mst_max = (cnt_frec_min > 'd0) ? cnt_frec_min_sum_max : 'd0;
//-----------------------------------------------------------
reg reg_SCK_ctrl [01:00];

always@(posedge aclk)begin
    if(SCK_sync[wire_master])begin
        reg_SCK_ctrl[wire_master] <= 1'b1;
        reg_SCK_ctrl[~wire_master] <= 1'b1;
    end else begin
        if((cnt_frec < cnt_frec_low_mst_min)|(cnt_frec_min == 'd0))begin
            reg_SCK_ctrl[wire_master] <= 1'b1;
            reg_SCK_ctrl[~wire_master] <= 1'b0;
        end else if(cnt_frec == cnt_frec_low_mst_min)begin
            reg_SCK_ctrl[wire_master] <= 1'b1;
            reg_SCK_ctrl[~wire_master] <= 1'b1;
        end else if(cnt_frec >= (cnt_frec_low_mst_min + 'd3))begin
            reg_SCK_ctrl[wire_master] <= SCK_sync[~wire_master];
            reg_SCK_ctrl[~wire_master] <= 1'b1;
        end else begin
            reg_SCK_ctrl[wire_master] <= reg_SCK_ctrl[wire_master];
            reg_SCK_ctrl[~wire_master] <= reg_SCK_ctrl[~wire_master];
        end
    end
end

reg reg_SDA_ctrl [01:00];
reg FSM_I2C_redir_last; //*********************************
always@(posedge aclk)begin
    if(FSM_I2C_redir[wire_master] == state_ACK)begin
        if(FSM_I2C_redir_last == state_ADDR)begin
            reg_SDA_ctrl[wire_master] <= 1'b1;
            reg_SDA_ctrl[~wire_master] <= 1'b0;
        end else begin
            if(wire_master_rw)begin
                reg_SDA_ctrl[wire_master] <= 1'b0;
                reg_SDA_ctrl[~wire_master] <= 1'b1;
            end else begin
                reg_SDA_ctrl[wire_master] <= 1'b1;
                reg_SDA_ctrl[~wire_master] <= 1'b0;
            end
        end
    end else if(FSM_I2C_redir[wire_master] > state_WAIT)begin
            if(wire_master_rw)begin
                reg_SDA_ctrl[wire_master] <= 1'b1;
                reg_SDA_ctrl[~wire_master] <= 1'b0;
            end else begin
                reg_SDA_ctrl[wire_master] <= 1'b0;
                reg_SDA_ctrl[~wire_master] <= 1'b1;
            end
    end else begin
        reg_SDA_ctrl[wire_master] <= 1'b1;
        reg_SDA_ctrl[~wire_master] <= 1'b1;
    end
end
//-------------------//

assign SCK_wire_0 = reg_SCK_ctrl[0] ? 1'bZ : 1'b0;
assign SCK_wire_1 = reg_SCK_ctrl[1] ? 1'bZ : 1'b0;

assign SDA_wire_0 = reg_SDA_ctrl[0] ? 1'bZ : SDA_wire_1;
assign SDA_wire_1 = reg_SDA_ctrl[1] ? 1'bZ : SDA_wire_0;
//-----------------------------------------------------------
//===========================================================
endmodule
//===========================================================
//===========================================================
//===========================================================
//===========================================================
module I2C_redirection_v3(
    // I2C IO interface
    // 
    inout  wire SCK_wire_0,
    inout  wire SDA_wire_0,
    // 
    inout  wire SCK_wire_1,
    inout  wire SDA_wire_1, 
    // debug data
    output reg [01:00] wire_busy,
    output reg  wire_master,
    output reg  wire_master_rw,
	 
	 output wire [31:00] frec_min_tact,
	 output wire [31:00] frec_max_tact,
	 output wire [31:00] frec_med_tact,
    
    // system inpterface
    input  wire aresetn,
    input  wire reset,
    input  wire aclk
);
//===========================================================
//-----------------------------------------------------------
localparam [07:00] 
    state_WAIT   = 8'd0,                  // 0
    state_START  = state_WAIT   + 8'd1,   // 1
    state_ADDR   = state_START  + 8'd1,   // 2
    state_ACK    = state_ADDR   + 8'd1,   // 3
    state_DATA   = state_ACK    + 8'd1,   // 4
    state_STOP   = state_DATA   + 8'd1,   // 5
    state_ERR    = state_STOP   + 8'd1,   // 6
    state_BUSY   = state_ERR    + 8'd1;   // 7
//-----------------------------------------------------------
initial begin
	 wire_busy		  = 2'b00;
    wire_master     = 1'b0;
    wire_master_rw  = 1'b1; // 1'b1 - read; 1'b0 - write;
end
//-----------------------------------------------------------
reg [02:00] SDA_filter_0;
reg [02:00] SCK_filter_0;

reg [02:00] SDA_filter_1;
reg [02:00] SCK_filter_1;

initial begin
    SDA_filter_0 = 3'b111;
    SCK_filter_0 = 3'b111;
    SDA_filter_1 = 3'b111;
    SCK_filter_1 = 3'b111;
end

//------- Input_Filters
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        SDA_filter_0 <= 3'b111;
        SCK_filter_0 <= 3'b111;
        SDA_filter_1 <= 3'b111;
        SCK_filter_1 <= 3'b111;
    end else begin
        if(reset)begin
            SDA_filter_0 <= 3'b111;
            SCK_filter_0 <= 3'b111;
            SDA_filter_1 <= 3'b111;
            SCK_filter_1 <= 3'b111;
        end else begin
            SDA_filter_0[0] <= SDA_wire_0;
            SCK_filter_0[0] <= SCK_wire_0;
            SDA_filter_1[0] <= SDA_wire_1;
            SCK_filter_1[0] <= SCK_wire_1;
            
            SDA_filter_0[1] <= SDA_filter_0[0];
            SCK_filter_0[1] <= SCK_filter_0[0];
            SDA_filter_1[1] <= SDA_filter_1[0];
            SCK_filter_1[1] <= SCK_filter_1[0];  
            
            SDA_filter_0[2] <= SDA_filter_0[1];
            SCK_filter_0[2] <= SCK_filter_0[1];
            SDA_filter_1[2] <= SDA_filter_1[1];
            SCK_filter_1[2] <= SCK_filter_1[1];       
        end
    end            
end

wire [01:00] SDA_sync;
assign SDA_sync = {SDA_filter_1[1], SDA_filter_0[1]};

wire [01:00] SCK_sync;
assign SCK_sync = {SCK_filter_1[1], SCK_filter_0[1]};

wire [01:00] SDA_sync_last;
assign SDA_sync_last = {SDA_filter_1[2], SDA_filter_0[2]};

wire [01:00] SCK_sync_last;
assign SCK_sync_last = {SCK_filter_1[2], SCK_filter_0[2]};

wire [01:00] SCK_sync_posedge;
assign SCK_sync_posedge[0] = SCK_sync[0] & !SCK_sync_last[0];
assign SCK_sync_posedge[1] = SCK_sync[1] & !SCK_sync_last[1];

wire [01:00] SCK_sync_negedge;
assign SCK_sync_negedge[0] = !SCK_sync[0] & SCK_sync_last[0];
assign SCK_sync_negedge[1] = !SCK_sync[1] & SCK_sync_last[1];

wire [01:00] SCK_sync_low;
assign SCK_sync_low[0] = !SCK_sync[0] & !SCK_sync_last[0];
assign SCK_sync_low[1] = !SCK_sync[1] & !SCK_sync_last[1];

wire [01:00] SCK_sync_high;
assign SCK_sync_high[0] = SCK_sync[0] & SCK_sync_last[0];
assign SCK_sync_high[1] = SCK_sync[1] & SCK_sync_last[1];

wire [01:00] SDA_sync_posedge;
assign SDA_sync_posedge[0] = SDA_sync[0] & !SDA_sync_last[0];
assign SDA_sync_posedge[1] = SDA_sync[1] & !SDA_sync_last[1];

wire [01:00] SDA_sync_negedge;
assign SDA_sync_negedge[0] = !SDA_sync[0] & SDA_sync_last[0];
assign SDA_sync_negedge[1] = !SDA_sync[1] & SDA_sync_last[1];

wire [01:00] SDA_sync_low;
assign SDA_sync_low[0] = !SDA_sync[0] & !SDA_sync_last[0];
assign SDA_sync_low[1] = !SDA_sync[1] & !SDA_sync_last[1];

wire [01:00] SDA_sync_high;
assign SDA_sync_high[0] = SDA_sync[0] & SDA_sync_last[0];
assign SDA_sync_high[1] = SDA_sync[1] & SDA_sync_last[1];

wire [01:00] wire_start;
assign wire_start[0] = SDA_sync_negedge[0] & SCK_sync_high[0];
assign wire_start[1] = SDA_sync_negedge[1] & SCK_sync_high[1];

wire [01:00] wire_stop;
assign wire_stop[0] = SDA_sync_posedge[0] & SCK_sync_high[0];
assign wire_stop[1] = SDA_sync_posedge[1] & SCK_sync_high[1];

wire [01:00] wire_fsm_clk;
assign wire_fsm_clk[0] = wire_start[0] | wire_stop[0] | SCK_sync_negedge[0];
assign wire_fsm_clk[1] = wire_start[1] | wire_stop[1] | SCK_sync_negedge[1];

wire f_start;
assign f_start = wire_start[0] | wire_start[1];

wire f_stop;
assign f_stop = wire_stop[0] | wire_stop[1];

wire ff_stop;
assign ff_stop = busy_wire ? (wire_master ? wire_stop[0] : wire_stop[1]) : 1'b0;

wire busy_wire;
assign busy_wire = wire_busy[0] | wire_busy[1];
//-----------------------------------------------------------
always@(posedge wire_start[0], posedge wire_stop[0])begin
	if(wire_stop[0])begin
		wire_busy[0] <= 1'b0;
	end else begin
		wire_busy[0] <= 1'b1;
	end
end

always@(posedge wire_start[1], posedge wire_stop[1])begin
	if(wire_stop[1])begin
		wire_busy[1] <= 1'b0;
	end else begin
		wire_busy[1] <= 1'b1;
	end
end
//-----------------------------------------------------------


wire clk_fsm;
assign clk_fsm = busy_wire ? (wire_master ? wire_fsm_clk[1] : wire_fsm_clk[0]) : 1'b0;

wire SDA;
assign SDA = busy_wire ? (wire_master ? SDA_sync[1] : SDA_sync[0]) : 1'b1;

wire SCK;
assign SCK = busy_wire ? (wire_master ? SCK_sync[1] : SCK_sync[0]) : 1'b1;
//-----------------------------------------------------------
always@(posedge f_start)begin
	case(wire_start)
		01:	wire_master <= 1'b0;
		10:	wire_master <= 1'b1;
		default: wire_master <= 1'b0;
	endcase
end
//-----------------------------------------------------------
reg [07:00] FSM_I2C_redir;
reg [07:00] FSM_I2C_redir_last;
reg [07:00] cnt;
reg reg_det10bit;

initial begin
	FSM_I2C_redir = state_WAIT;
	FSM_I2C_redir_last = state_WAIT;
	cnt = 'd0;
	reg_det10bit = 1'b0;
end

always@(posedge clk_fsm, negedge aresetn, negedge busy_wire)begin
	if((!aresetn) | (!busy_wire)) begin
		cnt <= 'd0;
	end else begin
		if((FSM_I2C_redir > state_START) & (FSM_I2C_redir < state_STOP))begin
			if((cnt >= 8)|(FSM_I2C_redir == state_ACK))begin
				cnt <= 'd0;
			end else begin
				cnt <= cnt +'d1;
			end
		end else begin
			cnt <= 'd0;
		end
	end
end 

always@(posedge clk_fsm, negedge aresetn /*, negedge busy_wire*/)begin
	if((!aresetn) /*| (!busy_wire)*/) begin
		FSM_I2C_redir <= state_BUSY;
		FSM_I2C_redir_last <= state_BUSY;
		
	end else begin
		if(ff_stop)begin
			FSM_I2C_redir <= state_WAIT;
			FSM_I2C_redir_last <= state_WAIT;
			
		end else if(f_start)begin
			FSM_I2C_redir <= state_START;
			FSM_I2C_redir_last <= state_START;
			
		end else begin
			FSM_I2C_redir_last <= FSM_I2C_redir;
			
			case(FSM_I2C_redir)
			state_WAIT:
				FSM_I2C_redir <= state_WAIT;
				
			state_START:
				FSM_I2C_redir <= state_ADDR;
				
			state_ADDR:
				if(cnt >= 7)begin
					FSM_I2C_redir <= state_ACK;
				end else begin
					FSM_I2C_redir <= state_ADDR;
				end
				
			state_ACK:
				if(reg_det10bit)begin
					FSM_I2C_redir <= state_ADDR;
				end else begin
					FSM_I2C_redir <= state_DATA;
				end
				
			state_DATA:
				if(cnt >= 7)begin
					FSM_I2C_redir <= state_ACK;
				end else begin
					FSM_I2C_redir <= state_DATA;
				end
				
			default:
				FSM_I2C_redir <= state_BUSY;
				
			endcase
		end
	end
end
//-----------------------------------------------------------
reg [07:00] byte_buf;
reg ack_buf;

initial begin
    byte_buf <= {8{1'b1}};
	 ack_buf	 <= 1'b1;
end

wire cnt_clk;
assign cnt_clk = busy_wire ? (wire_master ? SCK_sync_posedge[1] : SCK_sync_posedge[0]) : 1'b0;

always@(posedge cnt_clk, negedge aresetn, negedge busy_wire)begin
    if((!aresetn)|(!busy_wire))begin
        byte_buf <= {8{1'b1}};
		  ack_buf	 <= 1'b1;
    end else begin
        if((FSM_I2C_redir > state_START) & (FSM_I2C_redir < state_STOP))begin
            if(FSM_I2C_redir == state_ACK)begin
                byte_buf <= {8{1'b1}};
					 ack_buf	 <= SDA;
            end else begin
					if(cnt == 0)begin
						byte_buf[00]	 <= SDA;
						byte_buf[07:01] <= {7{1'b1}};
						ack_buf	 <= 1'b1;
					end else begin
						byte_buf[00] 	 <= SDA;
						byte_buf[07:01] <= byte_buf[06:00];
						ack_buf	 <= 1'b1;
					end
            end
        end else begin
            byte_buf <= {8{1'b1}};
				ack_buf <= 1'b1;
        end
    end
end
//-----------------------------------------------------------
wire f_addr10_detect;
assign f_addr10_detect = ((byte_buf & 8'b11111000) == 8'b11111000) ? 1'b1 : 1'b0;

reg reg_rw_flag_ok;
reg addr_ok;
initial begin
    reg_rw_flag_ok = 1'b0;
    addr_ok = 1'b0;
end

wire f_addr_end;
assign f_addr_end  = (FSM_I2C_redir == state_ACK) ? (reg_rw_flag_ok ? 1'b1 : ~reg_det10bit) : reg_rw_flag_ok;

always@(posedge clk_fsm, negedge aresetn, negedge busy_wire)begin
    if((!aresetn)|(!busy_wire))begin
        reg_rw_flag_ok <= 1'b0;
        reg_det10bit <= 1'b0;
        addr_ok <= 1'b0;
    end else begin
        if((FSM_I2C_redir > state_START) & (FSM_I2C_redir < state_STOP))begin
            reg_rw_flag_ok <= reg_rw_flag_ok;
            if(FSM_I2C_redir == state_ADDR)begin
                if(cnt == 7)begin
                    if(!reg_rw_flag_ok)begin
                        if(f_addr10_detect)begin
                            reg_det10bit <= 1'b1;
                        end else begin
                            reg_det10bit <= 1'b0;
                        end
                    end else begin
                        reg_det10bit <= reg_det10bit;
                    end
                end else begin
                    reg_det10bit <= reg_det10bit;
                end
                addr_ok <= addr_ok;
            end else if(FSM_I2C_redir == state_ACK)begin
                reg_rw_flag_ok <= 1'b1;
                reg_det10bit <= reg_det10bit;
                if(addr_ok)begin
                    addr_ok <= addr_ok;
                end else begin
                    addr_ok <= f_addr_end;
                end
            end else begin
                reg_rw_flag_ok <= reg_rw_flag_ok;
                reg_det10bit <= reg_det10bit;
                addr_ok <= addr_ok;
            end
        end else begin
            reg_rw_flag_ok <= 1'b0;
            reg_det10bit <= 1'b0;
            addr_ok <= 1'b0;
        end
    end
end
//-----------------------------------------------------------
always@(posedge clk_fsm, negedge aresetn, negedge busy_wire)begin
    if((!aresetn)|(!busy_wire))begin
        wire_master_rw <= 1'b0;
    end else begin
        if((FSM_I2C_redir > state_START) & (FSM_I2C_redir < state_STOP))begin
            if((cnt == 7)&(FSM_I2C_redir == state_ADDR))begin
                wire_master_rw <= byte_buf[0];
            end else begin
                wire_master_rw <= wire_master_rw;
            end
        end else begin
            wire_master_rw <= 1'b0;
        end
    end
end
//-----------------------------------------------------------
reg[31:00] cnt_frec;
reg[31:00] cnt_frec_min;
reg[31:00] cnt_frec_max;
reg[31:00] cnt_frec_med;

initial begin
    cnt_frec     = 'd0;
    cnt_frec_min = {32{1'b1}};
    cnt_frec_max = 'd0;
    cnt_frec_med = 'd0;
end

wire [32:00] cnt_frec_sum;
assign cnt_frec_sum = cnt_frec_med + cnt_frec;

always@(posedge aclk, negedge aresetn, negedge busy_wire)begin
    if((!aresetn)|(!busy_wire))begin
        cnt_frec <= 'd0;
        cnt_frec_min <= {32{1'b1}};
        cnt_frec_max <= {32{1'b0}};
        cnt_frec_med <= {32{1'b0}};
    end else if((FSM_I2C_redir > state_START) & (FSM_I2C_redir < state_STOP))begin
        if(!SCK)begin
            if(cnt_frec < {32{1'b1}})begin
                cnt_frec <= cnt_frec +'d1;
            end else begin
                cnt_frec <= cnt_frec;
            end
                cnt_frec_min <= cnt_frec_min;
                cnt_frec_max <= cnt_frec_max;
                cnt_frec_med <= cnt_frec_med;
        end else begin
            cnt_frec <= 'd0;
            if(cnt_frec != 'd0)begin
                if(cnt_frec_min > cnt_frec)begin
                    cnt_frec_min <= cnt_frec;
                end else begin
                    cnt_frec_min <= cnt_frec_min;
                end
                if(cnt_frec_max < cnt_frec)begin
                    cnt_frec_max <= cnt_frec;
                end else begin
                    cnt_frec_max <= cnt_frec_max;
                end
                if(cnt_frec_med == 'd0)begin
                    cnt_frec_med <= cnt_frec;
                end else begin
                    cnt_frec_med <= cnt_frec_sum >> 1;
                end
            end else begin
                cnt_frec_min <= cnt_frec_min;
                cnt_frec_max <= cnt_frec_max;
                cnt_frec_med <= cnt_frec_med;
            end
        end
    end else begin
        cnt_frec <= 'd0;
        cnt_frec_min <= {32{1'b1}};
        cnt_frec_max <= {32{1'b0}};
        cnt_frec_med <= {32{1'b0}};
    end
end

wire [32:00] cnt_frec_min_mul;
assign cnt_frec_min_mul = cnt_frec_min << 1;

wire [32:00] cnt_frec_max_mul;
assign cnt_frec_max_mul = cnt_frec_max << 1;

wire [32:00] cnt_frec_med_mul;
assign cnt_frec_med_mul = cnt_frec_med << 1;

assign frec_min_tact = (cnt_frec_min != {32{1'b1}}) ? cnt_frec_min_mul[31:00] : 32'd0;
assign frec_max_tact = cnt_frec_max_mul[31:00];
assign frec_med_tact = cnt_frec_med_mul[31:00];
//-----------------------------------------------------------

//-----------------------------------------------------------
reg[01:00] SDA_wire_ctrl;
reg[01:00] SCK_wire_ctrl;

initial begin
    SDA_wire_ctrl <= 2'b00;
    SCK_wire_ctrl <= 2'b00;
end

always@(posedge clk_fsm, negedge aresetn, negedge busy_wire)begin
	if((!aresetn)|(!busy_wire))begin
        SDA_wire_ctrl <= 2'b00;
        SCK_wire_ctrl <= 2'b00;
	end else begin
		if(ff_stop)begin
            SDA_wire_ctrl <= 2'b00;
            SCK_wire_ctrl <= 2'b00;
		end else if(f_start)begin
		    case(wire_start)
		    01:begin
                SDA_wire_ctrl <= 2'b10;
                SCK_wire_ctrl <= 2'b10;
            end
		    10:begin
                SDA_wire_ctrl <= 2'b01;
                SCK_wire_ctrl <= 2'b01;
            end
		    default:begin
                SDA_wire_ctrl <= 2'b00;
                SCK_wire_ctrl <= 2'b00;
		    end
            endcase
		end else begin
			case(FSM_I2C_redir)
			state_WAIT:begin
                SDA_wire_ctrl <= 2'b00;
                SCK_wire_ctrl <= 2'b00;
			end	
			state_START:begin
                SDA_wire_ctrl <= SDA_wire_ctrl;
                SCK_wire_ctrl <= SCK_wire_ctrl;
			end	
			state_ADDR:begin
				if(cnt >= 7)begin
                    SDA_wire_ctrl <= ~SDA_wire_ctrl;
                    SCK_wire_ctrl <= SCK_wire_ctrl;
				end else begin
                    SDA_wire_ctrl <= SDA_wire_ctrl;
                    SCK_wire_ctrl <= SCK_wire_ctrl;
				end
			end	
			state_ACK:begin
				if(addr_ok)begin // data
						if(ack_buf)begin // NACK
							if(wire_master_rw)begin
								SDA_wire_ctrl <= SDA_wire_ctrl;
							end else begin
								SDA_wire_ctrl <= ~SDA_wire_ctrl;
							end
						end else begin	// ACK
							SDA_wire_ctrl <= ~SDA_wire_ctrl;
						end
									 
                    SCK_wire_ctrl <= SCK_wire_ctrl;
				end else if(f_addr_end)begin	// addr ok
						if(ack_buf)begin // NACK
							SDA_wire_ctrl <= ~SDA_wire_ctrl;
						end else begin	// ACK
							if(wire_master_rw)begin
								SDA_wire_ctrl <= SDA_wire_ctrl;
							end else begin
								SDA_wire_ctrl <= ~SDA_wire_ctrl;
							end
						end
                  SCK_wire_ctrl <= SCK_wire_ctrl;
				end else begin	// addr not ok
                  SDA_wire_ctrl <= ~SDA_wire_ctrl;
                  SCK_wire_ctrl <= SCK_wire_ctrl;
				end
			end	
			state_DATA:begin
				if(cnt >= 7)begin
                    SDA_wire_ctrl <= ~SDA_wire_ctrl;
                    SCK_wire_ctrl <= SCK_wire_ctrl;
				end else begin
                    SDA_wire_ctrl <= SDA_wire_ctrl;
                    SCK_wire_ctrl <= SCK_wire_ctrl;
				end
			end	
			default:begin
                SDA_wire_ctrl <= 2'b00;
                SCK_wire_ctrl <= 2'b00;
			end	
			endcase
		end
	end
end
//-----------------------------------------------------------
reg clk_low_ctrl;

initial begin
    clk_low_ctrl = 1'b0;
end

wire [31:00] cnt_frec_min_div22;
assign cnt_frec_min_div22 = (cnt_frec_min >> 2);

wire [31:00] cnt_frec_low_ctrl_level;
assign cnt_frec_low_ctrl_level = cnt_frec_min - cnt_frec_min_div22;

always@(posedge aclk, negedge aresetn, negedge busy_wire)begin
	if((!aresetn)|(!busy_wire))begin
        clk_low_ctrl <= 1'b0;
    end else begin
        if((!SCK) & ((FSM_I2C_redir == state_ACK) | ((FSM_I2C_redir == state_DATA) & (cnt == 'd0))))begin
            if(cnt_frec_min != 'd0)begin
                if(cnt_frec < cnt_frec_low_ctrl_level)begin
                    clk_low_ctrl <= 1'b0;
                end else begin
                    clk_low_ctrl <= 1'b1;
                end
            end else begin
                clk_low_ctrl <= 1'b0;
            end
        end else begin
            clk_low_ctrl <= 1'b0;
        end
    end
end
//-----------------------------------------------------------
//-------------------//
wire [01:00] SCK_xor;
wire [01:00] SDA_xor;
assign SCK_xor[0] = SCK_wire_0 ^ SCK;
assign SCK_xor[1] = SCK_wire_1 ^ SCK;
assign SDA_xor[0] = SDA_wire_0 ^ SDA;
assign SDA_xor[1] = SDA_wire_1 ^ SDA; 
//-----------------------------------------------------------
//assign SCK_wire_0 = (SCK_wire_ctrl[0] ^ clk_low_ctrl) ? (SCK_wire_ctrl[1] ? 1'bZ : (SCK_sync[1] ? 1'bZ : 1'b0)) : 1'bZ;
//assign SCK_wire_1 = (SCK_wire_ctrl[1] ^ clk_low_ctrl) ? (SCK_wire_ctrl[0] ? 1'bZ : (SCK_sync[0] ? 1'bZ : 1'b0)) : 1'bZ;

assign SCK_wire_0 = (SCK_wire_ctrl[0] ^ clk_low_ctrl) ? ((SCK_wire_ctrl[1] ^ clk_low_ctrl) ? 1'bZ : (SCK_sync[1] ? 1'bZ : 1'b0)) : 1'bZ;
assign SCK_wire_1 = (SCK_wire_ctrl[1] ^ clk_low_ctrl) ? ((SCK_wire_ctrl[0] ^ clk_low_ctrl) ? 1'bZ : (SCK_sync[0] ? 1'bZ : 1'b0)) : 1'bZ;

assign SDA_wire_0 = SDA_wire_ctrl[0] ? (SDA_wire_ctrl[1] ? 1'bZ : (SDA_sync[1] ? 1'bZ : 1'b0)) : 1'bZ;
assign SDA_wire_1 = SDA_wire_ctrl[1] ? (SDA_wire_ctrl[0] ? 1'bZ : (SDA_sync[0] ? 1'bZ : 1'b0)) : 1'bZ;
//-----------------------------------------------------------
//===========================================================
endmodule
//===========================================================