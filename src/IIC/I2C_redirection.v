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
assign SCK_wire_0 = r_SCK_wire_0 ? 1'bz : SCK_sync[1] ;
assign SCK_wire_1 = r_SCK_wire_1 ? 1'bz : SCK_sync[0] ;

assign SDA_wire_0 = r_SDA_wire_0 ? 1'bz : SDA_sync[1] ;
assign SDA_wire_1 = r_SDA_wire_1 ? 1'bz : SDA_sync[0] ;
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
initial begin
    f_wire_busy     = 1'b0;
    f_wire_master   = 1'b0;
    f_master_rw     = 1'b0;

    FSM_I2C_redir = state_WAIT;

    SDA_filter_0 = 3'd111;
    SCK_filter_0 = 3'd111;
    SDA_filter_1 = 3'd111;
    SCK_filter_1 = 3'd111;

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
                        FSM_I2C_redir <= state_WAIT;
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
                        FSM_I2C_redir <= state_WAIT;
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
                        FSM_I2C_redir <= state_WAIT;
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
                        FSM_I2C_redir <= state_WAIT;
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
                state_ERR:
                    if(f_stop)begin
                        FSM_I2C_redir <= state_WAIT;
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