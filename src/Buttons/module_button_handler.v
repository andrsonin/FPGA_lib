/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module m_button_handler#(
	parameter p_action_button_HOL 	    = 1'b0,     // 0 - LOW voltage action, 1 - HIGH voltage action
    parameter p_freq                    = 'd25000,  // frequency aclk
    parameter p_btn_long_timer_ticks	= 'd5000,	// 5 sec button activate long event for 25MHz
    parameter p_btn_short_timer_ticks	= 'd20		// 20 msec button activate short event for 25MHz
)(
    input  wire button,                             // input button pin
	output wire action_btn_event,                   // tick to HIGH if a button state change occurs
    output reg  action_btn_short,                   // tick to HIGH if there is a fast change in button state
	output reg  action_btn_long,                    // tick to HIGH if there is a long button state change
	output wire action_btn_release,                 // tick to HIGH if the button returned to its original state
	output reg  btn_long_lock,                      // change to HIGH state if long button press is detected, reset when button is released
	output wire [31:00] cnt_btn_press,              // last click length in tacts
    input  wire aclk                                // clocking
);
//---------------------------------------------------------------
parameter p_btn_long_timer_ns	= (p_btn_long_timer_ms * p_freq);
parameter p_btn_short_timer_ns	= (p_btn_short_timer_ms * p_freq);
//---------------------------------------------------------------
wire f_btn_posedge;
wire f_btn_negedge;
wire f_btn_up;
wire f_btn_down;
wire f_btn_short;
wire f_btn_long;
wire f_cnt_resolution;
wire f_cnt_realese;
wire f_cnt_output_clear;
//---------------------------------------------------------------
reg [31:00] cnt;
reg [02:00] btn_filter;
reg [31:00] r_cnt_btn_press;
//---------------------------------------------------------------
initial begin
	action_btn_short	= 1'b0;
	action_btn_long		= 1'b0;
	btn_long_lock	    = 1'b0;

	cnt 			= 'd0;
	btn_filter 		= {~p_action_button_HOL, ~p_action_button_HOL, ~p_action_button_HOL};
	r_cnt_btn_press = 'd0;
end
//---------------------------------------------------------------
assign f_btn_posedge 	= ((btn_filter[1] == 1'b1)&(btn_filter[0] == 1'b0)) ? 1'b1 : 1'b0;
assign f_btn_negedge 	= ((btn_filter[1] == 1'b0)&(btn_filter[0] == 1'b1)) ? 1'b1 : 1'b0;
assign f_btn_up 		= ((btn_filter[1] == 1'b1)&(btn_filter[0] == 1'b1)) ? 1'b1 : 1'b0;
assign f_btn_down 		= ((btn_filter[1] == 1'b0)&(btn_filter[0] == 1'b0)) ? 1'b1 : 1'b0;

assign f_btn_short		= ((cnt >= p_btn_short_timer_ns) & (cnt <= p_btn_long_timer_ns)) 	? 1'b1 : 1'b0;
assign f_btn_long		= (cnt >= p_btn_long_timer_ns) 										? 1'b1 : 1'b0;

assign f_cnt_resolution		= p_action_button_HOL ? f_btn_up 		: f_btn_down;
assign f_cnt_realese		= p_action_button_HOL ? f_btn_negedge 	: f_btn_posedge;
assign f_cnt_output_clear	= p_action_button_HOL ? f_btn_posedge 	: f_btn_negedge;

assign action_btn_event		= (f_btn_posedge | f_btn_negedge) 	? 1'b1 			: 1'b0;
assign action_btn_release	= (p_action_button_HOL) 			? f_btn_negedge : f_btn_posedge;

assign cnt_btn_press		= r_cnt_btn_press;
//---------------------------------------------------------------
always@(posedge aclk)begin
	btn_filter[02] 		<= button;
	btn_filter[01:00] 	<= btn_filter[02:01];
end 
//---------------------------------------------------------------
always@(posedge aclk)begin
	if(f_cnt_resolution)begin
		if(cnt < 'hFFFFFFFF)begin
			cnt <= cnt +'d1;
		end else begin
			cnt <= cnt;
		end
	end else begin
		cnt <= 'd0;
	end
end 
//---------------------------------------------------------------
always@(posedge aclk)begin
	if(f_cnt_realese)begin
		r_cnt_btn_press <= cnt;
	end else if(f_cnt_output_clear)begin
		r_cnt_btn_press <= 'd0;
	end else begin
		r_cnt_btn_press <= r_cnt_btn_press;
	end
end 
//---------------------------------------------------------------
always@(posedge aclk)begin
	if(f_cnt_realese)begin
		if(f_btn_short)begin
			action_btn_short 	<= 1'b1;
		end else begin
			action_btn_short 	<= 1'b0;
		end
	end else begin
		action_btn_short 	<= 1'b0;
	end
end 
//---------------------------------------------------------------
always@(posedge aclk)begin
	if(f_cnt_realese)begin
		if(f_btn_long)begin
			action_btn_long 	<= 1'b1;
		end else begin
			action_btn_long 	<= 1'b0;
		end
	end else begin
		action_btn_long 	<= 1'b0;
	end
end 
//---------------------------------------------------------------
always@(posedge aclk)begin
	if(f_btn_long)begin
		btn_long_lock 	<= 1'b1;
	end else begin
		btn_long_lock 	<= 1'b0;
	end
end 
//---------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////