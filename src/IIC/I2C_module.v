//===========================================================
module I2C_module
  (
    // I2C control setup
    input  wire 			i_I2C_Master,				// master or slave_n
    //	 input  wire [15:00] i_I2C_ACK_timeout_ms,	// speaker: timeout wait ACK; // listener: timeout wait s_axis_complete when ACK state;
    // I2C phisical line
    inout  tri1 I2C_SDA,								// I2C data  line
    inout  tri1 I2C_SCL,								// I2C clock line
    // I2C statuses
    output wire o_I2C_RX,								// flag when listener
    output wire o_I2C_TX,								// flag when speaker
    output wire o_I2C_ACK,								// flag when ACK bit state
    output wire o_I2C_ERR,								// flag when I2C control phisical line is bad
    output wire o_I2C_BUSY,							// flag when I2C control outside master modeule
    output wire o_I2C_WAIT,							// flag when I2C wait ACK posedge clk
    // to I2C_Tranceiver
    output wire         m_axis_tready, 			// to Tranceiver ready
    input  wire [07:00] m_axis_tdata, 				// to Tranceiver data
    input  wire         m_axis_tvalid,				// to Tranceiver valid
    input  wire         m_axis_tlast,				// to Tranceiver last
    // from I2C_Reseiver
    input  wire         s_axis_tready, 			// from Reseiver ready
    output wire [07:00] s_axis_tdata, 				// from Reseiver data
    output wire         s_axis_tvalid,				// from Reseiver valid
    // s_axis answer
    input  wire 			s_axis_complete, 			// from Reseiver RW_EN
    input  wire 			s_axis_ok,					// from Reseiver data is ok
    // stop I2C transaction communication
    input  wire 			i_communication_end, 	// flag to STATE STOP
    //
    output wire [08:00] o_b_data,
    output wire o_s_scl,
    output wire o_s_sda,
    output wire o_m_scl,
    output wire o_m_sda,
    // system
    input  wire en,
    input  wire reset,
    input  wire aresetn,
    input  wire aclk
  );
  //-----------------------------------------------------------
  reg [01:00] FSM_i2c;

  parameter st_WAIT   = 2'd0;
  parameter st_START  = 2'd1;
  parameter st_DATA   = 2'd2;
  parameter st_ACK    = 2'd3;

  wire f_ACK;
  wire f_START;
  wire f_STOP;
  wire f_POSEDGE;
  wire f_NEGEDGE;
  wire f_SAVE;
  wire f_CHANGE;
  wire f_BUSY;
  wire f_WAIT;

  wire w_I2C_Master;
  wire w_I2C_Speaker;

  reg f_I2C_Speaker;
  reg f_I2C_Master;
  reg r_START;
  reg r_err;
  reg r_STOP;

  reg m_sda;
  reg m_scl;
  reg s_sda;
  reg s_scl;

  reg [01:00]	f_I2C_SCL;
  reg [01:00]	f_I2C_SDA;
  reg 			w_I2C_SCL;
  reg 			w_I2C_SDA;
  reg 			d_I2C_SCL;
  reg 			d_I2C_SDA;

  reg [07:00] cnt;

  reg [08:00] b_data;
  reg 			b_valid;
  reg			b_last;


  reg [07:00] s_axis_tdata_r;
  reg 			s_axis_tvalid_r;
  reg			s_axis_tlast_r;
  reg [00:00]	s_axis_tkeep_r;

  reg f_axis_complete;
  reg f_axis_ok;

  initial
  begin
    FSM_i2c = st_WAIT;

    f_I2C_Speaker 	= 1'b0;
    f_I2C_Master	= 1'b0;
    r_START 			= 1'b0;
    r_err				= 1'b0;
    r_STOP			= 1'b0;

    m_sda = 1'b1;
    m_scl	= 1'b1;
    s_sda = 1'b1;
    s_scl = 1'b1;

    f_I2C_SCL = 2'b11;
    f_I2C_SDA = 2'b11;
    w_I2C_SCL = 1'b1;
    w_I2C_SDA = 1'b1;
    d_I2C_SCL = 1'b1;
    d_I2C_SDA = 1'b1;

    cnt = 'd0;

    b_data = 9'h1FF;
    b_valid = 1'b0;
    b_last = 1'b0;

    s_axis_tdata_r 	= 'd0;
    s_axis_tvalid_r	= 1'b1;
    s_axis_tlast_r 	= 1'b0;
    s_axis_tkeep_r		= 'd0;

    f_axis_complete 	= 1'b0;
    f_axis_ok 			= 1'b0;
  end
  //-----------------------------------------------------------
  assign I2C_SDA = w_I2C_Master ? (w_I2C_Speaker ? (f_ACK ? 1'bz : m_sda) : (f_ACK ? m_sda : 1'bz)) 	: (w_I2C_Speaker ? (f_ACK ? 1'bz : s_sda) : (f_ACK ? s_sda : 1'bz));
  assign I2C_SCL = w_I2C_Master ? m_scl 																					: (w_I2C_Speaker ? (f_ACK ? 1'bz : s_scl) : (f_ACK ? s_scl : 1'bz));

  assign o_I2C_RX	= w_I2C_Speaker ? (f_ACK ? r_START 	: 1'b0) 		: (f_ACK ? 1'b0 		: r_START);
  assign o_I2C_TX	= w_I2C_Speaker ? (f_ACK ? 1'b0 		: r_START) 	: (f_ACK ? r_START 	: 1'b0);
  assign o_I2C_ACK	= r_START & f_ACK;
  assign o_I2C_ERR	= r_err;
  assign o_I2C_BUSY = f_BUSY;
  assign o_I2C_WAIT	= f_WAIT;

  assign s_axis_tdata	= s_axis_tdata_r;
  assign s_axis_tvalid	= s_axis_tvalid_r;

  assign m_axis_tready = 1'b1;
  //-----------------------------------------------------------
  assign f_ACK 		= 	(cnt == 'd8) 						? 	((!w_I2C_SCL)|(w_I2C_SCL & (!d_I2C_SCL))) & (!(f_BUSY | r_err))	:
         (cnt == 'd9)						? 	w_I2C_SCL 	 & (!(f_BUSY | r_err))											:
         1'b0;
  assign f_START 	= (w_I2C_SDA < d_I2C_SDA) 			? (w_I2C_SCL & d_I2C_SCL) : 1'b0;
  assign f_STOP  	= (w_I2C_SDA > d_I2C_SDA) 			? (w_I2C_SCL & d_I2C_SCL) : 1'b0;
  assign f_POSEDGE	= (w_I2C_SCL > d_I2C_SCL) 			? 1'b1 : 1'b0;
  assign f_NEGEDGE	= (w_I2C_SCL < d_I2C_SCL) 			? 1'b1 : 1'b0;
  assign f_SAVE		= (w_I2C_SCL & d_I2C_SCL) 			? 1'b1 : 1'b0;
  assign f_CHANGE	= ((!w_I2C_SCL) & (!d_I2C_SCL)) 	? 1'b1 : 1'b0;
  assign f_BUSY		= (!r_START)							? ((!w_I2C_SCL) | ((!w_I2C_SDA) & (!d_I2C_SDA))) : 1'b0;
  assign f_WAIT		= r_START 								? (i_I2C_Master ? (m_scl != I2C_SCL) : (w_I2C_Speaker ? (s_scl != I2C_SCL)  : (f_ACK ? (s_scl != I2C_SCL) : 1'b0))) : 1'b0;

  assign w_I2C_Master	= (!(f_BUSY | r_err)) & f_I2C_Master;
  assign w_I2C_Speaker	= (!(f_BUSY | r_err)) & f_I2C_Speaker;
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      f_axis_complete 	<= 1'b0;
      f_axis_ok			<= 1'b0;
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset)
        begin 						// RESET
          f_axis_complete 	<= 1'b0;
          f_axis_ok			<= 1'b0;
        end
        else if(!f_I2C_Speaker)
        begin
          if((f_POSEDGE & (cnt == 'd7)) | (f_NEGEDGE & (cnt == 'd9)) | f_START | f_STOP)
          begin
            f_axis_complete 	<= 1'b0;
            f_axis_ok			<= 1'b0;
          end
          else if((cnt >= 'd7) & (!f_axis_complete))
          begin
            f_axis_complete 	<= s_axis_complete;
            f_axis_ok			<= s_axis_ok;
          end
          else
          begin
            f_axis_complete 	<= f_axis_complete;
            f_axis_ok			<= f_axis_ok;
          end
        end
        else
        begin
          f_axis_complete 	<= 1'b0;
          f_axis_ok			<= 1'b0;
        end
      end
      else
      begin
        f_axis_complete 	<= 1'b0;
        f_axis_ok			<= 1'b0;
      end
    end
  end

  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      s_axis_tdata_r 	<= 'd0;
      s_axis_tvalid_r 	<= 1'b0;
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset)
        begin 						// RESET
          s_axis_tdata_r 	<= 'd0;
          s_axis_tvalid_r 	<= 1'b0;
        end
        else if(s_axis_tready | (!s_axis_tvalid_r))
        begin
          if(!f_I2C_Speaker)
          begin
            if(f_POSEDGE & (cnt == 'd7))
            begin
              s_axis_tdata_r		<= {b_data[06:00], w_I2C_SDA};
              s_axis_tvalid_r 	<= 1'b1;
            end
            else if(b_valid)
            begin
              s_axis_tdata_r		<= b_data[07:00];
              s_axis_tvalid_r 	<= 1'b1;
            end
            else
            begin
              s_axis_tdata_r 	<= 'd0;
              s_axis_tvalid_r 	<= 1'b0;
            end
          end
          else
          begin
            s_axis_tdata_r 	<= 'd0;
            s_axis_tvalid_r 	<= 1'b0;
          end
        end
        else
        begin
          s_axis_tdata_r 	<= s_axis_tdata_r;
          s_axis_tvalid_r 	<= s_axis_tvalid_r;
        end
      end
      else
      begin
        s_axis_tdata_r 	<= 'd0;
        s_axis_tvalid_r 	<= 1'b0;
      end
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      f_I2C_Master 	<= i_I2C_Master & (!(f_BUSY | r_err));
      f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset)
        begin 						// RESET
          f_I2C_Master	<= i_I2C_Master & (!(f_BUSY | r_err));
          f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
        end
        else if(f_STOP)
        begin			// END COMMUNICATE
          f_I2C_Master	<= i_I2C_Master & (!(f_BUSY | r_err));
          f_I2C_Speaker	<= i_I2C_Master & (!(f_BUSY | r_err));
        end
        else if(!r_START)
        begin 		// WAIT START
          f_I2C_Master	<= i_I2C_Master & (!(f_BUSY | r_err));
          f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
        end
        else
        begin							// COMMUNICATE process
          f_I2C_Master <= f_I2C_Master;
          if(f_I2C_Master)
          begin				// MASTER
            if(f_I2C_Speaker)
            begin			// SPEAKER
              f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
            end
            else
            begin						// LISTENER
              f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
            end
          end
          else
          begin							// SLAVE
            if(f_I2C_Speaker)
            begin			// SPEAKER
              if(f_NEGEDGE & (cnt == 'd9) & b_last)
              begin
                f_I2C_Speaker <= 1'b1;
              end
              else
              begin
                f_I2C_Speaker <= f_I2C_Speaker;
              end
            end
            else
            begin						// LISTENER
              if(f_NEGEDGE & (cnt == 'd9) & b_valid)
              begin
                f_I2C_Speaker <= 1'b1;
              end
              else
              begin
                f_I2C_Speaker <= f_I2C_Speaker;
              end
            end
          end
        end
      end
      else
      begin								// <- NOT ENABLE ->
        f_I2C_Master	<= i_I2C_Master & (!(f_BUSY | r_err));
        f_I2C_Speaker 	<= i_I2C_Master & (!(f_BUSY | r_err));
      end											// <-
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      b_data <= 9'h1FF;
      b_last <= 1'b0;
      b_valid <= 1'b0;
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset)
        begin 	// RESET
          b_data <= 9'h1FF;
          b_last <= 1'b0;
          b_valid <= 1'b0;
        end
        else if(f_I2C_Master)
        begin							// MASTER
          if(f_I2C_Speaker)
          begin									// MASTER SPEAKER
            b_data <= 9'h1FF;
            b_last <= 1'b0;
            b_valid <= 1'b0;
          end
          else
          begin												// MASTER LISTENER
            b_data <= 9'h1FF;
            b_last <= 1'b0;
            b_valid <= 1'b0;
          end
        end
        else
        begin													// SLAVE
          if(!r_START)
          begin
            b_data 	<= 9'h1FF;
            b_last 	<= 1'b0;
            b_valid 	<= 1'b0;
          end
          else if(f_I2C_Speaker)
          begin						// SLAVE SPEAKER
            if((((cnt == 'd8) & f_POSEDGE) | ((cnt == 'd9) & (f_SAVE | f_NEGEDGE | f_CHANGE))) & (!b_valid))
            begin	// save m_axis_data
              b_data  <= {m_axis_tdata, 1'b1};
              b_last  <= m_axis_tlast;
              b_valid <= m_axis_tvalid;
            end
            else if(((cnt == 'd7) & f_POSEDGE) | (cnt == 'd8))
            begin
              if(s_axis_tready | (!s_axis_tvalid_r))
              begin
                b_data 	<= 9'h1FF;
                b_last 	<= 1'b0;
                b_valid 	<= 1'b0;
              end
              else
              begin
                b_data	<= b_data;
                b_last	<= b_last;
                b_valid	<= b_valid;
              end
            end
            else if((f_POSEDGE) & ((cnt < 'd7) | (cnt == 'd9)))
            begin	// I2C CLK
              b_data	<= {b_data[07:00], w_I2C_SDA};
              b_last 	<= 1'b0;
              b_valid 	<= 1'b0;
            end
            else
            begin
              b_valid 	<= b_valid;
              b_last 	<= b_last;
              b_valid 	<= b_valid;
            end
          end
          else
          begin												// SLAVE LISTENER
            if(f_POSEDGE & (cnt == 'd8))
            begin				// save m_axis
              b_data  <= {m_axis_tdata, 1'b1};
              b_last  <= m_axis_tlast;
              b_valid <= m_axis_tvalid;
            end
            else if((cnt == 'd8) & b_valid)
            begin		// wait read data from s_axi
              if(s_axis_tready | (!s_axis_tvalid_r))
              begin
                b_data 	<= 9'h1FF;
                b_last 	<= 1'b0;
                b_valid 	<= 1'b0;
              end
              else
              begin
                b_data  <= b_data;
                b_last  <= b_last;
                b_valid <= b_valid;
              end
            end
            else if(f_POSEDGE)
            begin						// shift data
              if(cnt == 'd7)
              begin
                if(s_axis_tready | (!s_axis_tvalid_r))
                begin
                  b_data 	<= 9'h1FF;
                  b_last 	<= 1'b0;
                  b_valid 	<= 1'b0;
                end
                else
                begin
                  b_data	<= {b_data[07:00], w_I2C_SDA};
                  b_last	<= 1'b1;
                  b_valid	<= 1'b1;
                end
              end
              else if(cnt < 'd7)
              begin
                b_data	<= {b_data[07:00], w_I2C_SDA};
                b_last	<= 1'b0;
                b_valid	<= 1'b0;
              end
              else
              begin
                b_valid 	<= b_valid;
                b_last 	<= b_last;
                b_valid 	<= b_valid;
              end
            end
            else
            begin
              b_data 	<= b_data;
              b_last 	<= b_last;
              b_valid 	<= b_valid;
            end
          end
        end
      end
      else
      begin								// <- NOT ENABLE ->
        b_data 	<= 9'h1FF;
        b_last 	<= 1'b0;
        b_valid 	<= 1'b0;
      end											// <-
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      s_sda <= 1'b1;
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset | w_I2C_Master)
        begin 	// RESET
          s_sda <= 1'b1;
        end
        else if(w_I2C_Speaker)
        begin 	// SPEAKER
          if((f_NEGEDGE) & (cnt == 'd9))
          begin // to data
            s_sda <= 1'b0;
          end
          else if((f_NEGEDGE) & (cnt == 'd8))
          begin // to ack
            s_sda <= 1'b1;	// +++++++++++++++++++
          end
          else if(!f_ACK)
          begin		// data
            if(f_CHANGE)
            begin
              s_sda <= b_data[08] & (!(i_communication_end | r_STOP));
            end
            else if((!s_sda) & (!w_I2C_SDA) & (i_communication_end | r_STOP))
            begin
              s_sda <= 1'b1;
            end
            else
            begin
              s_sda <= s_sda;
            end
          end
          else
          begin						// ack
            s_sda <= 1'b1;
          end
        end
        else
        begin 						// LISTENER
          if((f_NEGEDGE) & (cnt == 'd9))
          begin // to data
            s_sda <= 1'b1;
          end
          else if((f_NEGEDGE) & (cnt == 'd8))
          begin // to ack
            s_sda <= 1'b1;
          end
          else if(f_ACK)
          begin					// ack
            if(f_CHANGE)
            begin
              if(s_sda)
              begin
                s_sda <= (!(s_axis_ok | f_axis_ok)) & (!(i_communication_end | r_STOP));
              end
              else
              begin
                s_sda <= s_sda & (!(i_communication_end | r_STOP));
              end
            end
            else if(f_SAVE)
            begin
              s_sda <= s_sda;
            end
            else if((!s_sda) & (f_SAVE) & (i_communication_end | r_STOP))
            begin
              s_sda <= 1'b1;
            end
            else
            begin
              s_sda <= s_sda;
            end
          end
          else
          begin								// data
            s_sda <= 1'b1;
          end
        end
      end
      else
      begin								// <- NOT ENABLE ->
        s_sda <= 1'b1;
      end											// <-
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      s_scl <= 1'b1;
    end
    else
    begin
      if(en)
      begin									// ENABLE ->
        if(reset | w_I2C_Master)
        begin 	// RESET
          s_scl <= 1'b1;
        end
        else if(w_I2C_Speaker)
        begin 	// SPEAKER
          if((f_NEGEDGE) & (cnt == 'd9))
          begin
            s_scl <= 1'b0;
          end
          else if((cnt == 'd0) & (!w_I2C_SCL))
          begin
            s_scl <= b_valid;
          end
          else if(f_ACK)
          begin
            s_scl <= 1'b1;
          end
          else
          begin
            s_scl <= s_scl;
          end
        end
        else
        begin 						// LISTENER
          if((f_NEGEDGE) & (cnt == 'd8))
          begin
            s_scl <= 1'b0;
          end
          else if(f_ACK)
          begin
            if((!w_I2C_SCL) & (!s_scl))
            begin
              if(s_axis_complete | f_axis_complete)
              begin
                s_scl <= 1'b1;
              end
              else
              begin
                s_scl <= s_scl;
              end
            end
            else
            begin
              s_scl <= s_scl;
            end
          end
          else
          begin
            s_scl <= 1'b1;
          end
        end
      end
      else
      begin								// <- NOT ENABLE ->
        s_scl <= 1'b1;
      end											// <-
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      r_err <= 1'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          r_err <= 1'b0;
        end
        else if((f_START) & (!f_BUSY))
        begin
          r_err <= 1'b0;
        end
        else if(f_STOP)
        begin
          case(FSM_i2c)
            st_WAIT	:
            begin
              r_err <= 1'b1;
            end
            st_START	:
            begin
              r_err <= 1'b1;
            end
            st_DATA	:
            begin
              if(cnt != 'd1)
              begin
                r_err <= 1'b1;
              end
              else
              begin
                r_err <= 1'b0;
              end
            end
            st_ACK	:
            begin
              r_err <= 1'b0;
            end
            default	:
            begin
              r_err <= 1'b1;
            end
          endcase
          ;
        end
        else
        begin
          r_err <= r_err;
        end
      end
      else
      begin
        r_err <= 1'b0;
      end
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      cnt <= 'd0;
    end
    else
    begin
      if(en)
      begin
        if(reset | (!r_START) | f_STOP)
        begin
          cnt <= 'd0;
        end
        else if(f_POSEDGE)
        begin
          case(FSM_i2c)
            st_WAIT	:
            begin
              cnt <= 'd0;
            end
            st_START	:
            begin
              cnt <= 'd0;
            end
            st_DATA	:
            begin
              if(cnt < 'd9)
              begin
                cnt <= cnt + 'd1;
              end
              else
              begin
                cnt <= 'd1;
              end
            end
            st_ACK	:
            begin
              if(cnt < 'd9)
              begin
                cnt <= cnt + 'd1;
              end
              else
              begin
                cnt <= 'd0;
              end
            end
            default	:
            begin
              cnt <= 'd01;
            end
          endcase
          ;
        end
        else
        begin
          cnt <= cnt;
        end
      end
      else
      begin
        cnt <= 'd0;
      end
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      FSM_i2c <= st_WAIT;
    end
    else
    begin
      if(en)
      begin
        if((reset) | (f_STOP))
        begin
          FSM_i2c <= st_WAIT;
        end
        else if((f_START) & (!f_BUSY))
        begin
          FSM_i2c <= st_START;
        end
        else if((f_NEGEDGE) & (r_START))
        begin
          case(FSM_i2c)
            st_START	:
            begin
              FSM_i2c <= st_DATA;
            end
            st_DATA	:
            begin
              if(cnt == 'd8)
              begin
                FSM_i2c <= st_ACK;
              end
              else
              begin
                FSM_i2c <= st_DATA;
              end
            end
            st_ACK	:
            begin
              FSM_i2c <= st_DATA;
            end
            default	:
            begin
              FSM_i2c <= st_WAIT;
            end
          endcase
          ;
        end
        else
        begin
          FSM_i2c <= FSM_i2c;
        end
      end
      else
      begin
        FSM_i2c <= st_WAIT;
      end
    end
  end
  //-----------------------------------------------------------
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      r_START <= 1'b0;
      r_STOP  <= 1'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          r_START <= 1'b0;
          r_STOP  <= 1'b0;
        end
        else if(f_STOP)
        begin
          r_START <= 1'b0;
          r_STOP  <= 1'b0;
        end
        else if((f_START) & (!f_BUSY))
        begin
          r_START <= 1'b1;
          r_STOP  <= i_communication_end | r_err;
        end
        else
        begin
          r_START <= r_START;
          if(!r_STOP)
          begin
            r_STOP  <= i_communication_end | r_err;
          end
          else
          begin
            r_STOP  <= r_STOP;
          end
        end
      end
      else
      begin
        r_START <= 1'b0;
        r_STOP  <= 1'b0;
      end
    end
  end
  //-----------------------------------------------------------
  // delay i2c wire
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      f_I2C_SCL   <= 2'b11;
      w_I2C_SCL	  <= 1'b1;
      d_I2C_SCL	  <= 1'b1;

      f_I2C_SDA   <= 2'b11;
      w_I2C_SDA	  <= 1'b1;
      d_I2C_SDA	  <= 1'b1;

    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          f_I2C_SCL   <= 2'b11;
          w_I2C_SCL	 <= 1'b1;
          d_I2C_SCL	 <= 1'b1;

          f_I2C_SDA   <= 2'b11;
          w_I2C_SDA	 <= 1'b1;
          d_I2C_SDA	 <= 1'b1;

        end
        else
        begin
          f_I2C_SCL   <= {f_I2C_SCL[0], I2C_SCL};

          if(w_I2C_SCL)
          begin
            w_I2C_SCL	 <= (|f_I2C_SCL) | I2C_SCL;
          end
          else
          begin
            w_I2C_SCL	 <= (&f_I2C_SCL) & I2C_SCL;
          end
          d_I2C_SCL	  <= w_I2C_SCL;

          f_I2C_SDA   <= {f_I2C_SDA[0],I2C_SDA};
          if(w_I2C_SDA)
          begin
            w_I2C_SDA	 <= (|f_I2C_SDA) | I2C_SDA;
          end
          else
          begin
            w_I2C_SDA	 <= (&f_I2C_SDA) & I2C_SDA;
          end
          d_I2C_SDA	  <= w_I2C_SDA;

        end
      end
      else
      begin
        f_I2C_SCL   <= 2'b11;
        w_I2C_SCL	<= 1'b1;
        d_I2C_SCL	<= 1'b1;

        f_I2C_SDA   <= 2'b11;
        w_I2C_SDA	<= 1'b1;
        d_I2C_SDA	<= 1'b1;

      end
    end
  end
  //-----------------------------------------------------------
endmodule
//===========================================================
module I2C_logger_convert_to_UART
  (
    input  wire			i_tx_all,
    input  wire			i_tx_filter,
    input  wire 			i_tx_status,
    // to Tranceiver
    input  wire         s_axis_tready, // ready
    output wire [07:00] s_axis_tdata, 	// data
    output wire         s_axis_tvalid,	// valid
    // from Reseiver
    output wire         m_axis_tready, // ready
    input  wire [15:00] m_axis_tdata, 	// data
    input  wire         m_axis_tvalid,	// valid
    // system
    input  wire en,
    input  wire reset,
    input  wire aresetn,
    input  wire aclk
  );

  reg [07:00] s_axis_tdata_r;
  reg         s_axis_tvalid_r;

  reg [07:00] b_data;
  reg 			b_valid;

  initial
  begin
    s_axis_tdata_r = 'd0;
    s_axis_tvalid_r = 'b0;
    b_data = 'd0;
    b_valid = 'b0;
  end


  assign m_axis_tready 		= s_axis_tready & (!b_valid);

  assign s_axis_tdata			= s_axis_tdata_r;
  assign s_axis_tvalid			= s_axis_tvalid_r;
  //-----------------------------------------------------------
  //
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      b_data		<= 'd0;
      b_valid	<= 'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          b_data		<= 'd0;
          b_valid	<= 'b0;
        end
        else if(s_axis_tready | (!s_axis_tvalid_r))
        begin
          if(!b_valid)
          begin
            b_data	<= m_axis_tdata[07:00];
            b_valid	<= m_axis_tvalid & (i_tx_all | ((!i_tx_all) & (((i_tx_filter & m_axis_tdata[08]) | (!i_tx_filter)))));
          end
          else
          begin
            b_data	<= 'd0;
            b_valid	<= 'b0;
          end
        end
        else
        begin
          b_data		<= b_data;
          b_valid	<= b_valid;
        end
      end
      else
      begin
        b_data		<= 'd0;
        b_valid	<= 'b0;
      end
    end
  end

  //-----------------------------------------------------------
  //
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      s_axis_tdata_r	<= 'd0;
      s_axis_tvalid_r	<= 'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          s_axis_tdata_r	<= 'd0;
          s_axis_tvalid_r	<= 'b0;
        end
        else if(s_axis_tready | (!s_axis_tvalid_r))
        begin
          if(b_valid)
          begin
            s_axis_tdata_r	<= b_data;
            s_axis_tvalid_r	<= b_valid;
          end
          else
          begin
            s_axis_tdata_r	<= m_axis_tdata[15:08];
            s_axis_tvalid_r	<= m_axis_tvalid & i_tx_status & ((i_tx_filter & m_axis_tdata[08]) | (!i_tx_filter));
          end
        end
        else
        begin
          s_axis_tdata_r	<= s_axis_tdata_r;
          s_axis_tvalid_r	<= s_axis_tvalid_r;
        end
      end
      else
      begin
        s_axis_tdata_r	<= 'd0;
        s_axis_tvalid_r	<= 'b0;
      end
    end
  end

  //-----------------------------------------------------------
endmodule
//===========================================================
//===========================================================
module I2C_logger_convert_data
  (
    // to Tranceiver
    input  wire         s_axis_tready, // ready
    output wire [15:00] s_axis_tdata, 	// data
    output wire         s_axis_tvalid,	// valid
    // from Reseiver
    output wire         m_axis_tready, // ready
    input  wire [07:00] m_axis_tdata, 	// data
    input  wire [00:00] m_axis_tkeep,	// keep
    input  wire         m_axis_tvalid,	// valid
    input  wire         m_axis_tlast	// last
  );

  assign m_axis_tready 		= s_axis_tready;
  assign s_axis_tdata[07:00] = m_axis_tdata;
  assign s_axis_tdata[08]		= m_axis_tkeep[0];
  assign s_axis_tdata[09]		= m_axis_tlast;
  assign s_axis_tdata[15:10]	= 'd0;
  assign s_axis_tvalid			= m_axis_tvalid;
  //-----------------------------------------------------------
endmodule
//===========================================================
module I2C_logger
  (
    //phisical line
    inout  tri1 I2C_SDA,
    inout  tri1 I2C_SCL,
    //statuses
    output wire I2C_RX,
    output reg  I2C_ERR,
    // from Reseiver
    input  wire         s_axis_tready, // ready
    output wire [07:00] s_axis_tdata, 	// data
    output wire [00:00] s_axis_tkeep,	// ACK result
    output wire         s_axis_tvalid,	// valid
    output wire         s_axis_tlast,	// last
    // system
    input  wire en,
    input  wire reset,
    input  wire aresetn,
    input  wire aclk
  );
  //-----------------------------------------------------------
  reg [01:00] FSM_i2c;

  parameter st_WAIT   = 2'd0;
  parameter st_START  = 2'd1;
  parameter st_DATA   = 2'd2;
  parameter st_ACK    = 2'd3;

  reg [01:00]f_I2C_SCL;
  reg [01:00]f_I2C_SDA;

  reg w_I2C_SCL;
  reg w_I2C_SDA;

  reg d_I2C_SCL;
  reg d_I2C_SDA;

  reg [03:00] cnt;

  reg [08:00] b_data;
  reg			b_keep;
  reg 			b_valid;
  reg 			b_last;

  reg [07:00] s_axi_tdata_r;
  reg         s_axi_tvalid_r;
  reg         s_axi_tkeep_r;
  reg         s_axi_tlast_r;

  initial
  begin
    FSM_i2c = st_WAIT;
    f_I2C_SCL = 2'b11;
    f_I2C_SDA = 2'b11;
    w_I2C_SCL = 1'b1;
    w_I2C_SDA = 1'b1;
    d_I2C_SCL = 1'b1;
    d_I2C_SDA = 1'b1;
    cnt = 'd0;
    b_data = 'd0;
    b_keep = 'b0;
    b_valid = 'b0;
    b_last = 'b1;

    s_axi_tdata_r = 'd0;
    s_axi_tvalid_r = 'b0;
    s_axi_tkeep_r = 'b0;
    s_axi_tlast_r = 'b0;
  end


  //-----------------------------------------------------------
  assign I2C_SDA = 1'bz;
  assign I2C_SCL = 1'bz;
  assign I2C_RX	= (FSM_i2c > st_WAIT) ? 1'b1 : 1'b0;

  assign s_axis_tdata  = s_axi_tdata_r;
  assign s_axis_tvalid = s_axi_tvalid_r;
  assign s_axis_tlast  = s_axi_tlast_r;
  assign s_axis_tkeep	= s_axi_tkeep_r;
  //-----------------------------------------------------------
  // delay i2c wire
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      f_I2C_SCL   <= 2'b11;
      w_I2C_SCL	  <= 1'b1;
      d_I2C_SCL	  <= 1'b1;

      f_I2C_SDA   <= 2'b11;
      w_I2C_SDA	  <= 1'b1;
      d_I2C_SDA	  <= 1'b1;

    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          f_I2C_SCL   <= 2'b11;
          w_I2C_SCL	 <= 1'b1;
          d_I2C_SCL	 <= 1'b1;

          f_I2C_SDA   <= 2'b11;
          w_I2C_SDA	 <= 1'b1;
          d_I2C_SDA	 <= 1'b1;

        end
        else
        begin
          f_I2C_SCL   <= {f_I2C_SCL[0], I2C_SCL};

          if(w_I2C_SCL)
          begin
            w_I2C_SCL	 <= (|f_I2C_SCL) | I2C_SCL;
          end
          else
          begin
            w_I2C_SCL	 <= (&f_I2C_SCL) & I2C_SCL;
          end
          d_I2C_SCL	  <= w_I2C_SCL;

          f_I2C_SDA   <= {f_I2C_SDA[0],I2C_SDA};
          if(w_I2C_SDA)
          begin
            w_I2C_SDA	 <= (|f_I2C_SDA) | I2C_SDA;
          end
          else
          begin
            w_I2C_SDA	 <= (&f_I2C_SDA) & I2C_SDA;
          end
          d_I2C_SDA	  <= w_I2C_SDA;

        end
      end
      else
      begin
        f_I2C_SCL   <= 2'b11;
        w_I2C_SCL	<= 1'b1;
        d_I2C_SCL	<= 1'b1;

        f_I2C_SDA   <= 2'b11;
        w_I2C_SDA	<= 1'b1;
        d_I2C_SDA	<= 1'b1;

      end
    end
  end


  // state mashine I2C
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      FSM_i2c <= st_WAIT;
      I2C_ERR <= 1'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          FSM_i2c <= st_WAIT;
          I2C_ERR <= 1'b0;
        end
        else if((w_I2C_SDA > d_I2C_SDA) & (w_I2C_SCL & d_I2C_SCL))
        begin
          FSM_i2c <= st_WAIT;
          if((cnt === 'd9)|(cnt == 'd1))
          begin
            I2C_ERR <= 1'b0;
          end
          else
          begin
            I2C_ERR <= 1'b1;
          end
        end
        else if((w_I2C_SDA < d_I2C_SDA) & (w_I2C_SCL & d_I2C_SCL))
        begin
          FSM_i2c <= st_START;
          if((FSM_i2c != st_WAIT)&(cnt > 'd0))
          begin
            I2C_ERR <= 1'b1;
          end
          else
          begin
            I2C_ERR <= 1'b0;
          end
        end
        else if((FSM_i2c == st_START) && (w_I2C_SCL < d_I2C_SCL))
        begin
          FSM_i2c <= st_DATA;
          I2C_ERR <= I2C_ERR;
        end
        else if(w_I2C_SCL > d_I2C_SCL)
        begin
          case (FSM_i2c)
            st_DATA:
            begin
              if(cnt >= 4'd8)
              begin
                FSM_i2c <= st_ACK;
              end
              else
              begin
                FSM_i2c <= st_DATA;
              end
              I2C_ERR <= I2C_ERR;
            end
            st_ACK:
            begin
              FSM_i2c <= st_DATA;
              I2C_ERR <= 1'b0;
            end
            default:
            begin
              FSM_i2c <= st_WAIT;
              I2C_ERR <= 1'b1;
            end
          endcase
        end
        else
        begin
          FSM_i2c <= FSM_i2c;
          I2C_ERR <= I2C_ERR;
        end
      end
      else
      begin
        FSM_i2c <= st_WAIT;
        I2C_ERR <= 1'b0;
      end
    end
  end

  // bit counter I2C
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      cnt <= 'd0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          cnt <= 'd0;
        end
        else if(((w_I2C_SDA > d_I2C_SDA) | (w_I2C_SDA < d_I2C_SDA)) & (w_I2C_SCL & d_I2C_SCL))
        begin
          cnt <= 'd0;
          //				end else if((w_I2C_SCL < d_I2C_SCL) & (cnt >= 'd9))begin
          //					 cnt <= 'd0;
        end
        else if(w_I2C_SCL > d_I2C_SCL)
        begin
          case (FSM_i2c)
            st_WAIT:
              cnt <= 'd0;
            st_START:
              cnt <= 'd0;
            st_DATA:
              if(cnt >= 'd9)
              begin
                cnt <= 'd1;
              end
              else
              begin
                cnt <= cnt +'d1;
              end
            st_ACK:
              if(cnt >= 'd9)
              begin
                cnt <= 'd1;
              end
              else
              begin
                cnt <= cnt +'d1;
              end
            default:
              cnt <= 'd0;
          endcase
        end
        else
        begin
          cnt <= cnt;
        end
      end
      else
      begin
        cnt <= 'd0;
      end
    end
  end

  // data bit from I2C to shift buf reg RECEIVER - I2C SLAVE
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      b_data  <= 9'h1FF;
      b_keep  <= 1'b0;
      b_last  <= 1'b1;
      b_valid <= 1'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset | ((FSM_i2c == st_START) & (w_I2C_SCL < d_I2C_SCL)))
        begin // reset
          b_data  <= 9'h1FF;
          b_keep  <= 1'b0;
          b_last  <= 1'b1;
          b_valid <= 1'b0;
        end
        else if((w_I2C_SCL & d_I2C_SCL) & (w_I2C_SDA > d_I2C_SDA))
        begin // END MESSAGE
          if((s_axis_tready) | (!s_axi_tvalid_r) | (!b_valid))
          begin
            b_data  <= 9'h1FF;
            b_keep  <= 1'b0;
            b_last  <= 1'b1;
            b_valid <= 1'b0;
          end
          else
          begin
            b_data  <= b_data;
            b_keep  <= b_keep;
            b_last  <= 1'b1;
            b_valid <= b_valid;
          end
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt == 'd0))
        begin // save First input Bit
          if((s_axis_tready) | (!s_axi_tvalid_r))
          begin
            b_data[08:00]  <= {8'hFF, w_I2C_SDA};
            b_keep  		 <= 1'b0;
            b_last			 <= 1'b1;
            b_valid			 <= 1'b0;
          end
          else
          begin
            b_data[08:00]  <= {b_data[07:00], w_I2C_SDA};
            b_keep  		 <= b_keep;
            b_last  		 <= b_last;
            b_valid			 <= b_valid;
          end
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt == 'd9))
        begin
          b_data[08:00]  <= {b_data[07:00], w_I2C_SDA};
          b_keep  		 <= b_keep;
          b_last			 <= b_last;
          b_valid			 <= b_valid;
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt == 'd1))
        begin // clear output data and save input bit
          b_data[08:00]	<= {7'hFF, b_data[00], w_I2C_SDA};
          b_keep  		 	<= 1'b0;
          b_last			<= 1'b0;
          b_valid			<= 1'b0;
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt < 'd7))
        begin
          b_data[08:00]  <= {b_data[07:00], w_I2C_SDA};
          b_keep  		 <= 1'b0;
          b_last			 <= 1'b0;
          b_valid			 <= 1'b0;
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt == 'd7))
        begin
          b_data[08:00]  <= {b_data[07:00], w_I2C_SDA};
          b_keep  		 <= 1'b0;
          b_last			 <= 1'b0;
          b_valid			 <= 1'b1;
        end
        else if((w_I2C_SCL > d_I2C_SCL) & (cnt == 'd8))
        begin // read ACK
          b_data			 <= b_data;
          b_keep			 <= (!w_I2C_SDA);
          b_last			 <= 1'b0;
          b_valid			 <= b_valid;
        end
        else
        begin
          if(s_axis_tready)
          begin
            if(cnt == 'd0)
            begin
              b_data	<= 9'h1FF;
              b_keep	<= 1'b0;
              b_last	<= 1'b1;
              b_valid	<= 1'b0;
            end
            else
            begin
              b_data  <= b_data;

              if((!w_I2C_SCL)&(cnt == 'd1))
              begin
                b_keep	<= 1'b0;
                b_last	<= 1'b1;
                b_valid	<= 1'b0;
              end
              else
              begin
                b_keep	<= b_keep;
                b_last	<= b_last;
                b_valid	<= b_valid;

              end
            end
          end
          else
          begin
            b_data  <= b_data;
            b_keep  <= b_keep;
            b_last  <= b_last;
            b_valid	<= b_valid;
          end
        end
      end
      else
      begin
        b_data   <= 9'h1FF;
        b_keep	<= 1'b0;
        b_last	<= 1'b1;
        b_valid	<= 1'b0;
      end
    end
  end

  //-----------------------------------------------------------
  // data from shift buf reg to s_axi RECEIVER - I2C SLAVE
  always @(posedge aclk, negedge aresetn)
  begin
    if(!aresetn)
    begin
      s_axi_tdata_r		<= 'd0;
      s_axi_tvalid_r		<= 1'b0;
      s_axi_tkeep_r		<= 'd0;
      s_axi_tlast_r		<= 1'b0;
    end
    else
    begin
      if(en)
      begin
        if(reset)
        begin
          s_axi_tdata_r		<= 'd0;
          s_axi_tvalid_r	<= 1'b0;
          s_axi_tkeep_r		<= 'd0;
          s_axi_tlast_r		<= 1'b0;
        end
        else if(s_axis_tready)
        begin
          if((w_I2C_SCL & d_I2C_SCL) & (w_I2C_SDA > d_I2C_SDA) & ((cnt < 'd2) | (cnt == 'd9)))
          begin // look last data
            if(b_valid)
            begin
              if((cnt == 'd0)|(cnt == 'd8)|(cnt == 'd9))
              begin // normal data
                s_axi_tdata_r		<= b_data[07:00];
                s_axi_tvalid_r		<= b_valid;
                s_axi_tkeep_r		<= b_keep;
                s_axi_tlast_r		<= 1'b1;
              end
              else if(cnt == 'd1)
              begin // save First input Bit data
                s_axi_tdata_r		<= b_data[08:01];
                s_axi_tvalid_r		<= b_valid;
                s_axi_tkeep_r		<= b_keep;
                s_axi_tlast_r		<= 1'b1;
              end
              else
              begin
                s_axi_tdata_r		<= 'd0;
                s_axi_tvalid_r		<= 1'b0;
                s_axi_tkeep_r		<= 'd0;
                s_axi_tlast_r		<= 1'b0;
              end
            end
            else
            begin
              s_axi_tdata_r		<= 'd0;
              s_axi_tvalid_r	<= 1'b0;
              s_axi_tkeep_r		<= 'd0;
              s_axi_tlast_r		<= 1'b0;
            end
          end
          else if(b_valid & (cnt < 'd2))
          begin // look data
            if(cnt == 'd1)
            begin
              if((w_I2C_SCL > d_I2C_SCL)|(!w_I2C_SCL))
              begin
                s_axi_tdata_r		<= b_data[08:01];
                s_axi_tvalid_r	<= b_valid;
                s_axi_tkeep_r		<= b_keep;
                s_axi_tlast_r		<= b_last;
              end
              else
              begin
                s_axi_tdata_r		<= 'd0;
                s_axi_tvalid_r	<= 1'b0;
                s_axi_tkeep_r		<= 'd0;
                s_axi_tlast_r		<= 1'b0;
              end
            end
            else
            begin
              s_axi_tdata_r		<= b_data[07:00];
              s_axi_tvalid_r		<= b_valid;
              s_axi_tkeep_r		<= b_keep;
              s_axi_tlast_r		<= b_last;
            end
          end
          else
          begin
            s_axi_tdata_r		<= 'd0;
            s_axi_tvalid_r		<= 1'b0;
            s_axi_tkeep_r		<= 'd0;
            s_axi_tlast_r		<= 1'b0;
          end
        end
        else
        begin
          s_axi_tdata_r		<= s_axi_tdata_r;
          s_axi_tvalid_r		<= s_axi_tvalid_r;
          s_axi_tkeep_r		<= s_axi_tkeep_r;
          s_axi_tlast_r		<= s_axi_tlast_r;
        end
      end
      else
      begin
        s_axi_tdata_r	<= 'd0;
        s_axi_tvalid_r	<= 1'b0;
        s_axi_tkeep_r	<= 'd0;
        s_axi_tlast_r	<= 1'b0;
      end

    end
  end
  //-----------------------------------------------------------
endmodule
