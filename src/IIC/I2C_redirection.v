//===========================================================
module I2C_redirection#(
	parameter p_port_conf 		= 2'b11,	// 0 - slave only port, 			1 - master or slave port
	parameter p_WD_ticks 		= 32'd8000

)(
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
	 
	 output wire [09:00] addr_detect,
    
    // system inpterface
    input  wire aresetn,
    input  wire reset,
    input  wire aclk
);
//===========================================================
//-----------------------------------------------------------
localparam [07:00] 
    state_START  = 8'd0,   					// 0
    state_ADDR   = state_START  + 8'd1,   // 1
    state_DATA   = state_ADDR   + 8'd1,   // 2
    state_ACK    = state_DATA   + 8'd1,   // 3
    state_WAIT   = state_ACK    + 8'd1,   // 4
    state_STOP   = state_WAIT   + 8'd1,   // 5
    state_BUSY   = state_STOP   + 8'd1,   // 6
    state_ERR    = state_BUSY   + 8'd1;   // 7
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
//-- reconect
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

//----------------------------------------------------------
wire [01:00] wire_start;
assign wire_start[0] = SDA_sync_negedge[0] & SCK_sync_high[0] & p_port_conf;
assign wire_start[1] = SDA_sync_negedge[1] & SCK_sync_high[1] & p_port_conf;

wire [01:00] wire_stop;
assign wire_stop[0] = SDA_sync_posedge[0] & SCK_sync_high[0];
assign wire_stop[1] = SDA_sync_posedge[1] & SCK_sync_high[1];
//----------------------------------------------------------
wire busy_wire;
assign busy_wire 	= (wire_busy[0] | wire_busy[1]) ? 1'b1 : 1'b0;
//----------------------------------------------------------
wire f_addr10_detect;
assign f_addr10_detect = ((buf_byte & 8'b11111000) == 8'b11111000) ? 1'b1 : 1'b0;
//-----------------------------------------------------------
always@(posedge wire_start[0], posedge wire_stop[0], negedge aresetn, posedge reset)begin
	if(wire_stop[0] | (!aresetn) | reset)begin
		wire_busy[0] <= 1'b0;
	end else begin
		wire_busy[0] <= 1'b1;
	end
end

always@(posedge wire_start[1], posedge wire_stop[1], negedge aresetn, posedge reset)begin
	if(wire_stop[1] | (!aresetn) | reset)begin
		wire_busy[1] <= 1'b0;
	end else begin
		wire_busy[1] <= 1'b1;
	end
end
//-----------------------------------------------------------
reg [31:00] cnt_WD;
initial begin
	cnt_WD = p_WD_ticks;
end

wire f_WD;
assign f_WD = (cnt_WD == 'd0) ? 1'b1 : 1'b0;

always@(posedge aclk, negedge aresetn, posedge reset)begin
	if((!aresetn) | reset)begin
		cnt_WD <= p_WD_ticks;
	end else begin
		if(FSM_IIC < state_WAIT)begin 	//
			if(SCK_sync_posedge[wire_master] | SCK_sync_negedge[wire_master] | SDA_sync_posedge[wire_master] | SDA_sync_negedge[wire_master])begin
				cnt_WD <= p_WD_ticks;
			end else if(cnt_WD > 'd0)begin
				cnt_WD <= cnt_WD -'d1;
			end else begin
				cnt_WD <= cnt_WD;
			end
		end else if(FSM_IIC == state_STOP)begin
			if(SDA_sync_low[~wire_master])begin
				if(cnt_WD > 'd0)begin
					cnt_WD <= cnt_WD -'d1;
				end else begin
					cnt_WD <= cnt_WD;
				end
			end else begin
				cnt_WD <= p_WD_ticks;
			end
		end else begin
			cnt_WD <= p_WD_ticks;
		end
	end
end
//-----------------------------------------------------------
always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		wire_master <= 1'b0;
	end else begin
		if(FSM_IIC >= state_WAIT)begin 	// wire not BUSY wait master start
			case(wire_start[01:00])
				2'b00: wire_master <= 1'b0;
				2'b01: wire_master <= 1'b0;
				2'b10: wire_master <= 1'b1;
				2'b11: wire_master <= wire_master;
			endcase
		end else begin							// wire BUSY wait wire_master stop
			wire_master <= wire_master;
		end
	end
end
//-----------------------------------------------------------
reg [03:00] cnt;
initial begin
	cnt = 'd0;
end 

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin // reset counter
		cnt <= 'd0;
	end else begin
		if((FSM_IIC > state_START) & (FSM_IIC < state_WAIT))begin	// count
			if(SCK_sync_negedge[wire_master])begin
				if(FSM_IIC == state_ACK)begin
					cnt <= 'd0;
				end else begin
					cnt <= cnt +'d1;
				end
			end else begin
				cnt <= cnt;
			end
		end else begin // reset counter
			cnt <= 'd0;
		end
	end
end
//-----------------------------------------------------------
reg [07:00] cnt_data;
initial begin
	cnt_data = 'd0;
end 
always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin	// reset counter
		cnt_data <= 'd0;
	end else begin
		if(FSM_IIC == state_ACK)begin // next STATE
			if(SCK_sync_posedge[wire_master])begin
				if(buf_ack)begin
					cnt_data <= 'd0;
				end else begin
					if(FSM_IIC_last == state_ADDR)begin
						if(cnt_data > 'd7)begin	// add 10bit end
							cnt_data <= cnt_data;
						end else if(f_addr10_detect)begin		// add 10bit detect
							cnt_data <= 'd2;
						end else begin				// add 7bit end
							cnt_data <= cnt_data;
						end
					end else begin
						cnt_data <= cnt_data;
					end
				end
			end else if(SCK_sync_negedge[wire_master])begin
					if(FSM_IIC_last == state_ADDR)begin
						if(cnt_data > 'd7)begin	// add 10bit end
							cnt_data <= 'd0;
						end else if(f_addr10_detect)begin		// add 10bit detect
							cnt_data <= 'd2;
						end else begin				// add 7bit end
							cnt_data <= 'd0;
						end
					end else begin
						cnt_data <= cnt_data;
					end
			end else begin
				cnt_data <= cnt_data;
			end
		end else if((FSM_IIC > state_START) & ((FSM_IIC < state_WAIT)))begin // count
			if(SCK_sync_posedge[wire_master])begin
				cnt_data <= cnt_data +'d1;
			end else begin
				cnt_data <= cnt_data;
			end
		end else begin	// reset counter
			cnt_data <= 'd0;
		end
	end
end
//-----------------------------------------------------------
reg [31:00] cnt_frec;

reg [31:00] reg_frec_zero_min;
reg [31:00] reg_frec_zero_max;
reg [31:00] reg_frec_zero_med;

initial begin
	cnt_frec = 'd0;
	reg_frec_zero_min = {32{1'b1}};
	reg_frec_zero_max = 'd0;
	reg_frec_zero_med = 'd0;
end

wire [31:00] frec_sda_zero;
assign frec_sda_zero = (reg_frec_zero_med[31:00] >> 4);

wire [31:00] frec_zero;
assign frec_zero = reg_frec_zero_min - frec_sda_zero;

wire [32:00] cnt_frec_sum;
assign cnt_frec_sum = reg_frec_zero_med + cnt_frec;

wire [32:00] cnt_frec_min_mul;
assign cnt_frec_min_mul = reg_frec_zero_min << 1;

wire [32:00] cnt_frec_max_mul;
assign cnt_frec_max_mul = reg_frec_zero_max << 1;

wire [32:00] cnt_frec_med_mul;
assign cnt_frec_med_mul = reg_frec_zero_med << 1;

assign frec_min_tact = (reg_frec_zero_med != {32{1'b1}}) ? reg_frec_zero_med[31:00] : 32'd0;
assign frec_max_tact = cnt_frec_max_mul[31:00];
assign frec_med_tact = cnt_frec_med_mul[31:00];

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
        cnt_frec <= 'd0;
        reg_frec_zero_min <= {32{1'b1}};
        reg_frec_zero_max <= {32{1'b0}};
        reg_frec_zero_med <= {32{1'b0}};
	end else if(FSM_IIC >= state_WAIT)begin // reset buf_addr
        cnt_frec <= 'd0;
        reg_frec_zero_min <= {32{1'b1}};
        reg_frec_zero_max <= {32{1'b0}};
        reg_frec_zero_med <= {32{1'b0}};
	end else if(SCK_sync_posedge[wire_master] )begin
		cnt_frec <= 'd0;
		if(cnt_frec != 'd0)begin
			if(reg_frec_zero_min > cnt_frec)begin
				reg_frec_zero_min <= cnt_frec;
			end else begin
				reg_frec_zero_min <= reg_frec_zero_min;
			end
			
			if(reg_frec_zero_max < cnt_frec)begin
				reg_frec_zero_max <= cnt_frec;
			end else begin
				reg_frec_zero_max <= reg_frec_zero_max;
			end
			
			if(reg_frec_zero_med == 'd0)begin
				reg_frec_zero_med <= cnt_frec;
			end else begin
				reg_frec_zero_med <= cnt_frec_sum >> 1;
			end
			
		end else begin
			reg_frec_zero_min <= reg_frec_zero_min;
			reg_frec_zero_max <= reg_frec_zero_max;
			reg_frec_zero_med <= reg_frec_zero_med;
		end
	end else if(SCK_sync[wire_master] == 1'b0)begin
		if(cnt_frec < {32{1'b1}})begin
			cnt_frec <= cnt_frec +'d1;
		end else begin
			cnt_frec <= cnt_frec;
		end
		reg_frec_zero_min <= reg_frec_zero_min;
		reg_frec_zero_max <= reg_frec_zero_max;
		reg_frec_zero_med <= reg_frec_zero_med;
	end else begin
		cnt_frec <= 'd0;
		reg_frec_zero_min <= reg_frec_zero_min;
		reg_frec_zero_max <= reg_frec_zero_max;
		reg_frec_zero_med <= reg_frec_zero_med;
	end
end
//-----------------------------------------------------------
always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		wire_master_rw <= 1'b1;
	end else begin
		if((FSM_IIC >= state_WAIT) | (FSM_IIC == state_START))begin
			wire_master_rw <= 1'b1;
		end else if((FSM_IIC == state_ADDR) & (cnt == 'd7) & (cnt_data == 'd7) & (SCK_sync_posedge[wire_master]))begin
//			wire_master_rw <= buf_byte[0];
			wire_master_rw <= SDA_sync[wire_master];
		end else begin
			wire_master_rw <= wire_master_rw;
		end
	end
end
//-----------------------------------------------------------

reg [07:00] FSM_IIC;
reg [07:00] FSM_IIC_last;
initial begin
	FSM_IIC 			= state_WAIT;
	FSM_IIC_last 	= state_WAIT;
end

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		FSM_IIC_last <= state_WAIT;
	end else if(SCK_sync_negedge[wire_master])begin
		FSM_IIC_last <= FSM_IIC;
	end else begin
		FSM_IIC_last <= FSM_IIC_last;
	end
end
always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		FSM_IIC <= state_WAIT;
	end else begin
		case(FSM_IIC)			
			state_START:begin	// START
				if(wire_stop[wire_master])begin
					FSM_IIC <= state_STOP; // --> to STOP
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					FSM_IIC <= state_ADDR; // --> to ADDR
				end else begin
					FSM_IIC <= state_START; // --> <--
				end
			end
			state_ADDR:begin
				if(wire_stop[wire_master])begin
					FSM_IIC <= state_STOP;	// --> to STOP
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin
						FSM_IIC <= state_ERR;	// --> ERROR (slave START)
					end else begin
						if(cnt > 'd1)begin
							FSM_IIC <= state_ERR;	// --> ERROR (false START)
						end else begin
							FSM_IIC <= state_START; // --> to RESTART
						end
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(cnt >= 'd7)begin
						FSM_IIC <= state_ACK; // --> to ACK
					end else begin
						FSM_IIC <= state_ADDR; // --> <--
					end
				end else begin
					FSM_IIC <= state_ADDR; // --> <--
				end
			end
			state_DATA:begin
				if(wire_stop[wire_master])begin
					FSM_IIC <= state_STOP;	// --> to STOP
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin
						FSM_IIC <= state_ERR;	// --> ERROR (slave START)
					end else begin
						if(cnt > 'd1)begin
							FSM_IIC <= state_ERR;	// --> ERROR (false START)
						end else begin
							FSM_IIC <= state_START; // --> to RESTART
						end
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(cnt >= 'd7)begin
						FSM_IIC <= state_ACK; // --> to ACK
					end else begin
						FSM_IIC <= state_DATA; // --> <--
					end
				end else begin
					FSM_IIC <= state_DATA; // --> <--
				end
			end
			state_ACK:begin
				if(wire_stop[wire_master])begin
					FSM_IIC <= state_STOP;	// --> to STOP
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin
						FSM_IIC <= state_ERR;	// --> ERROR (slave START)
					end else begin
						FSM_IIC <= state_START; // --> to RESTART
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(cnt_data > 'd0)begin
						FSM_IIC <= state_ADDR; // --> to ADDR
					end else begin
						FSM_IIC <= state_DATA; // --> to DATA
					end
				end else begin
					FSM_IIC <= state_ACK; // --> <--
				end
			end
			state_WAIT:begin
				if((wire_start > 2'b00) & (wire_start < 2'b11))begin
					FSM_IIC <= state_START; // --> to START
				end else begin
					FSM_IIC <= state_WAIT; // --> <--
				end
			end
			state_STOP:begin
				if((wire_start > 2'b00) & (wire_start < 2'b11))begin
					FSM_IIC <= state_START; // --> to START
				end else if(wire_stop > 2'b00)begin
					FSM_IIC <= state_WAIT; // --> to WAIT start
				end else begin
					FSM_IIC <= state_STOP; // --> <--
				end			
			end
			state_BUSY:begin
				if(wire_stop > 2'b00)begin
					FSM_IIC <= state_WAIT; // --> to WAIT start
				end else if((wire_start > 2'b00) & (wire_start < 2'b11))begin
					FSM_IIC <= state_START; // --> to WAIT start
				end else begin
					FSM_IIC <= state_BUSY; // --> <--
				end
			end
			state_ERR:begin
				if(wire_stop > 2'b00)begin
					FSM_IIC <= state_WAIT; // --> to WAIT start
				end else begin
					FSM_IIC <= state_ERR; // --> <--
				end
			end
			default:begin
					FSM_IIC <= state_ERR;	// --> ERROR (other)
			end
		endcase
	end
end
//-----------------------------------------------------------
reg [07:00] buf_byte;
reg [09:00] buf_addr;
reg buf_ack;
initial begin
	buf_byte = 8'b11111111;
	buf_addr = 'd0;
	buf_ack  = 1'b1;
end 

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		buf_ack <= 1'b1;
	end else begin
		if((FSM_IIC >= state_WAIT) | (FSM_IIC == state_START))begin
			buf_ack <= 1'b1;
		end else if(FSM_IIC == state_ACK)begin
			if(SCK_sync_posedge[wire_master])begin
				buf_ack <= SDA_sync[wire_master];
			end else if(SCK_sync_negedge[wire_master])begin
				buf_ack <= buf_ack;
			end
		end else begin
			buf_ack <= 1'b1;
		end
	end
end

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		buf_addr <= 10'd0;
	end else begin
		if((FSM_IIC >= state_WAIT) | (FSM_IIC == state_START))begin // reset buf_addr
			buf_addr <= 10'd0;
		end else if((FSM_IIC == state_ACK) & (FSM_IIC_last == state_ADDR))begin
			if(SCK_sync_posedge[wire_master])begin
				if(cnt_data >= 'd9)begin					// end 10bit addr
					buf_addr[01:00] <= buf_addr[01:00];
					buf_addr[09:02] <= buf_byte[07:00];
				end else if(f_addr10_detect)begin		// detect 10bit addr
					buf_addr[01:00] <= buf_byte[02:01];
					buf_addr[09:02] <= buf_addr[09:02];
				end else begin									// end 7bit addr
					buf_addr[06:00] <= buf_byte[07:01];
					buf_addr[09:07] <= 3'b000;
				end
			end else begin
				buf_addr <= buf_addr;
			end
		end else begin
			buf_addr <= buf_addr;
		end
	end
end

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		buf_byte <= 8'b11111111;
	end else begin
		if((FSM_IIC >= state_WAIT) | (FSM_IIC == state_START))begin
			buf_byte <= 8'b11111111;
		end else if(FSM_IIC == state_ACK)begin
			if(SCK_sync_posedge[wire_master])begin
				buf_byte <= buf_byte;
			end else if(SCK_sync_negedge[wire_master])begin
				buf_byte <= 8'b11111111;
			end
		end else begin
			if(SCK_sync_posedge[wire_master])begin
				buf_byte[00] 		<= SDA_sync[wire_master];
				buf_byte[07:01] 	<= buf_byte[06:00];
			end else begin
				buf_byte <= buf_byte;
			end
		end
	end
end
//********************************************************************************
reg [01:00] ctrl_SCK; //0 - triz; 1 - control from master
reg [01:00] ctrl_SDA; //0 - triz; 1 - control from master
reg [01:00] ctrl_SDA_copy; //0 - triz; 1 - control from master

initial begin
	ctrl_SCK = 2'b00;
	ctrl_SDA = 2'b00;
	ctrl_SDA_copy = 2'b00;
end

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		ctrl_SDA_copy <= 2'b00;
	end else begin
		if(ctrl_SDA != ctrl_SDA_copy)begin
			if(cnt_frec == frec_sda_zero)begin
				ctrl_SDA_copy <= ctrl_SDA;
			end else begin
				ctrl_SDA_copy <= ctrl_SDA_copy;
			end
		end else begin
			ctrl_SDA_copy <= ctrl_SDA_copy;
		end
	end
end
always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		ctrl_SCK <= 2'b00;
	end else begin
		case(FSM_IIC)
			state_STOP:begin	// START
				if(wire_start == 2'b11)begin
					ctrl_SCK <= 2'b00;
				end else begin
					ctrl_SCK <= ctrl_SCK;
				end
			end
			state_START:begin	// STOP
				ctrl_SCK <= ctrl_SCK;
			end
	 
			state_ADDR, state_DATA, state_ACK:begin
				if(cnt_data <= 'd1)begin
					ctrl_SCK <= ctrl_SCK;
				end else if(SCK_sync_negedge[wire_master])begin
					if(wire_master)begin
						ctrl_SCK <= 2'b01;
					end else begin
						ctrl_SCK <= 2'b10;
					end
				end else if(SCK_sync_posedge[wire_master])begin
					if(wire_master)begin
						ctrl_SCK <= 2'b01;
					end else begin
						ctrl_SCK <= 2'b10;
					end
				end else if(cnt_frec == frec_zero)begin
					ctrl_SCK[01:00] <= ~ctrl_SCK[01:00];
				end else begin
					ctrl_SCK <= ctrl_SCK;
				end
			end
			default:begin
				if(wire_start > 2'b00)begin
					ctrl_SCK <= ~wire_start;
				end else begin
					ctrl_SCK <= 2'b00;
				end
			end		
		endcase
	end
end

always@(posedge aclk, negedge aresetn, posedge reset, posedge f_WD)begin
	if((!aresetn) | reset | f_WD)begin
		ctrl_SDA <= 2'b00;
	end else begin
		case(FSM_IIC)
			state_START:begin	// START
				if(wire_stop[wire_master])begin
					if(wire_master)begin
						ctrl_SDA <= 2'b01;
					end else begin
						ctrl_SDA <= 2'b10;
					end // --> to STOP
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					ctrl_SDA <= ctrl_SDA; // --> to ADDR
				end else begin
					ctrl_SDA <= ctrl_SDA; // --> <--
				end
			end
			state_ADDR:begin
				if(wire_stop[wire_master])begin
					if(wire_master)begin
						ctrl_SDA <= 2'b01;
					end else begin
						ctrl_SDA <= 2'b10;
					end	// --> to STOP
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin
						ctrl_SDA <= 2'b00;	// --> ERROR (slave START)
					end else begin
						if(cnt > 'd1)begin
							ctrl_SDA <= 2'b00;	// --> ERROR (false START)
						end else begin
							ctrl_SDA <= ctrl_SDA; // --> to RESTART
						end
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(cnt >= 'd7)begin // --> to ACK
							ctrl_SDA <= ~ctrl_SDA; 
					end else begin
						ctrl_SDA <= ctrl_SDA; // --> <--
					end
				end else begin
					ctrl_SDA <= ctrl_SDA; // --> <--
				end
			end
			state_DATA:begin
				if(wire_stop[wire_master])begin
					if(wire_master)begin
						ctrl_SDA <= 2'b01;
					end else begin
						ctrl_SDA <= 2'b10;
					end	// --> to STOP
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin
						ctrl_SDA <= 2'b00;	// --> ERROR (slave START)
					end else begin
						if(cnt > 'd1)begin
							ctrl_SDA <= 2'b00;	// --> ERROR (false START)
						end else begin
							if(wire_master)begin
								ctrl_SDA <= 2'b01;
							end else begin
								ctrl_SDA <= 2'b10;
							end // --> to RESTART
						end
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(cnt >= 'd7)begin // --> to ACK
							ctrl_SDA <= ~ctrl_SDA; 
					end else begin
						ctrl_SDA <= ctrl_SDA; // --> <--
					end
				end else begin
					ctrl_SDA <= ctrl_SDA; // --> <--
				end
			end
			state_ACK:begin
				if(wire_stop[wire_master])begin // --> to STOP
					if(wire_master)begin
						ctrl_SDA <= 2'b01;
					end else begin
						ctrl_SDA <= 2'b10;
					end	
				end else if(wire_start > 2'b00)begin
					if(wire_start[~wire_master])begin // --> ERROR (slave START)
						ctrl_SDA <= 2'b00;	
					end else begin // --> to RESTART
						if(wire_master)begin
							ctrl_SDA <= 2'b01;
						end else begin
							ctrl_SDA <= 2'b10;
						end	
					end
				end else if(SCK_sync_negedge[wire_master])begin // negedge I2C_SCK (next state)
					if(FSM_IIC_last == state_ADDR)begin
						if(buf_ack)begin 	// if NACK
								ctrl_SDA <= ~ctrl_SDA;
						end else begin
							if(cnt_data > 'd0)begin // --> to ADDR
									ctrl_SDA <= ~ctrl_SDA; 
							end else if(wire_master_rw)begin // --> to DATA if READ data
								ctrl_SDA <= ctrl_SDA;
							end else begin // --> to DATA if WRITE data
									ctrl_SDA <= ~ctrl_SDA; 
							end 
						end
					end else begin
						if(buf_ack)begin	// if NACK
							if(wire_master_rw)begin
								ctrl_SDA <= ctrl_SDA;
							end else begin
								ctrl_SDA <= ~ctrl_SDA;
							end
						end else begin // if READ data
							ctrl_SDA <= ~ctrl_SDA;
						end
					end
				end else begin
					ctrl_SDA <= ctrl_SDA; // --> <--
				end
			end
			state_STOP:begin
				if((wire_start > 2'b00) & (wire_start < 2'b11))begin// --> to START
					ctrl_SDA <= ~wire_start;
				end else if(wire_stop > 2'b00)begin // --> to WAIT start
					ctrl_SDA <= 2'b00;
				end else begin // --> <--
					ctrl_SDA <= ctrl_SDA;
				end
			end
			default:begin
				if(wire_start > 2'b00)begin
					ctrl_SDA <= ~wire_start;
				end else begin
					ctrl_SDA <= 2'b00;
				end
			end		
		endcase
	end
end
//********************************************************************************
assign addr_detect = buf_addr;

assign SCK_wire_0 = ctrl_SCK[0] ? (SCK_sync[1] ? 1'bz : 1'b0) : 1'bZ;
assign SCK_wire_1 = ctrl_SCK[1] ? (SCK_sync[0] ? 1'bz : 1'b0) : 1'bZ;

assign SDA_wire_0 = ctrl_SDA_copy[0] ? (SDA_sync[1] ? 1'bz : 1'b0) : 1'bZ;
assign SDA_wire_1 = ctrl_SDA_copy[1] ? (SDA_sync[0] ? 1'bz : 1'b0) : 1'bZ;
//-----------------------------------------------------------
//===========================================================
endmodule
//===========================================================