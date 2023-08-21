
module spi_driver_master
#(
	parameter CPOL = 0, //future
	parameter CPHA = 0, //future
	parameter CLK_DIV = 2
)
(
    // flash IO
    CS_N    ,
    SCLK    ,
    SIO     ,
    // setup interface
	SPI_mode  ,
    // data input  interface
	s_ready ,
    s_data  ,
	s_valid ,
    // data output interface
	m_ready ,
	m_data  ,
	m_valid ,
	m_last  ,
    // system
    aresetn ,
    en      ,
    reset   ,
    aclk
);
 
output reg          CS_N ;
output wire         SCLK ;
inout  wire [03:00] SIO  ;

input  wire [02:00] SPI_mode; //

output reg          s_ready;
input  wire [31:00] s_data ;
input  wire         s_valid;

input  wire         m_ready;
output reg  [31:00] m_data ;
output wire         m_valid;
output reg          m_last ;

input  wire aresetn;
input  wire en     ;
input  wire reset  ;
input  wire aclk   ;
//------------------------------------------------------------
assign SIO[0] = MOSI;
assign SIO[1] = 1'bZ;
assign SIO[2] = 1'bZ;  //future
assign SIO[3] = 1'bZ;  //future

assign m_valid = (FSM_SPI_BUF_OUT == STATE_SPI_BUF_READ) ? (r_m_valid) : (1'b0);
//------------------------------------------------------------
reg w_SCLK;
always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		w_SCLK <= 'd0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			w_SCLK <= 'd0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			if(cnt_clk >= CLK_DIV)begin
				w_SCLK <= ~w_SCLK;
			end
			else begin
				w_SCLK <= w_SCLK;
			end
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		w_SCLK <= w_SCLK;
	end
end

reg [15:00] cnt_clk;
initial begin
	cnt_clk = 'd0;
end
always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		cnt_clk <= 'd0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			cnt_clk <= 'd0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			if(cnt_clk < CLK_DIV)begin
				cnt_clk <= cnt_clk + 'd1;
			end
			else begin
				cnt_clk <= 'd0;
			end
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		cnt_clk <= cnt_clk;
	end
end
//------------------------------------------------------------
localparam [2:0]
	SPI_MODE_ONE   = 'd0            + 'd0, // 0
	SPI_MODE_DUAL  = SPI_MODE_ONE   + 'd1, // 1 
	SPI_MODE_IO2   = SPI_MODE_DUAL  + 'd1, // 2
	SPI_MODE_QREAD = SPI_MODE_IO2   + 'd1, // 3
	SPI_MODE_IO4   = SPI_MODE_QREAD + 'd1, // 4
	SPI_MODE_QPI   = SPI_MODE_IO4   + 'd1  // 5
;
//------------------------------------------------------------
// SCLK
localparam [2:0]
	STATE_SPI_DRIVE_RESET = 'd0                   + 'd0, // 0 // Cброс
	STATE_SPI_DRIVE_WAIT  = STATE_SPI_DRIVE_RESET + 'd1, // 1 // Ждем входных данных на шинах
	STATE_SPI_DRIVE_INIT  = STATE_SPI_DRIVE_WAIT  + 'd1, // 2 // Запись инициализационных данных -> Начало транзакции
	STATE_SPI_DRIVE_RUN   = STATE_SPI_DRIVE_INIT  + 'd1, // 3 // Отправка и-или прием данных
	STATE_SPI_DRIVE_END   = STATE_SPI_DRIVE_RUN   + 'd1  // 4 // Конец транзакции
;
reg [2:0] FSM_SPI_DRIVE;
initial begin
	FSM_SPI_DRIVE = STATE_SPI_DRIVE_RESET;
end

always @(negedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		FSM_SPI_DRIVE <= STATE_SPI_DRIVE_RESET;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			FSM_SPI_DRIVE <= STATE_SPI_DRIVE_RESET;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				FSM_SPI_DRIVE <= STATE_SPI_DRIVE_WAIT;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				if(r_buf_rd & r_buf_tx_valid & (FSM_SPI_BUF == STATE_SPI_BUF_READ))begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_INIT;
				end
				else begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_WAIT;
				end
			end
			STATE_SPI_DRIVE_INIT  :begin
				if(r_buf_rd & r_buf_tx_valid & (FSM_SPI_BUF == STATE_SPI_BUF_READ))begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_RUN;
				end
				else begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_INIT;
				end
			end
			STATE_SPI_DRIVE_RUN  :begin
				if((r_rd_bits == 'd0) & (r_wr_bits == 'd0))begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_END;
				end
				else begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_RUN;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				if(CS_N)begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_WAIT;
				end
				else begin
					FSM_SPI_DRIVE <= STATE_SPI_DRIVE_END;
				end
			end
			default               :begin
				FSM_SPI_DRIVE <= STATE_SPI_DRIVE_RESET;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		FSM_SPI_DRIVE <= FSM_SPI_DRIVE;
	end
end

reg         r_buf_rd		; // SCLK

always @(negedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		r_buf_rd <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			r_buf_rd <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				r_buf_rd <= 1'b1;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				if(r_buf_rd & r_buf_tx_valid)begin
					r_buf_rd <= 1'b0;
				end
				else begin
					r_buf_rd <= 1'b1;
				end
			end
			STATE_SPI_DRIVE_INIT  :begin
				if(r_buf_rd & r_buf_tx_valid)begin
					r_buf_rd <= 1'b0;
				end
				else begin
					r_buf_rd <= 1'b1;
				end
			end
			STATE_SPI_DRIVE_RUN  :begin
				if(cnt == 'd6)begin
					r_buf_rd <= 1'b1;
				end
				else if(cnt >= 'd7)begin
					if(r_buf_rd & r_buf_tx_valid)begin
						r_buf_rd <= 1'b0;
					end
					else begin
						r_buf_rd <= 1'b1;
					end
				end
				else begin
					r_buf_rd <= 1'b0;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				r_buf_rd <= 1'b1;
			end
			default               :begin
				r_buf_rd <= 1'b0;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		r_buf_rd <= r_buf_rd;
	end
end

reg [15:00] r_rd_bits;
reg [15:00] r_wr_bits;

always @(negedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		r_rd_bits <= 'd0;
		r_wr_bits <= 'd0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			r_rd_bits <= 'd0;
			r_wr_bits <= 'd0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				r_rd_bits <= 'd0;
				r_wr_bits <= 'd0;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				if(r_buf_rd & r_buf_tx_valid)begin
					r_rd_bits <= {1'b0 ,r_buf_tx[27:16], 3'b000};
					r_wr_bits <= {1'b0 ,r_buf_tx[11:00], 3'b000};
				end
				else begin
					r_rd_bits <= r_rd_bits;
					r_wr_bits <= r_wr_bits;
				end
			end
			STATE_SPI_DRIVE_INIT  :begin
				r_rd_bits <= r_rd_bits;
				r_wr_bits <= r_wr_bits;
			end
			STATE_SPI_DRIVE_RUN  :begin
				if(r_wr_bits > 'd0)begin
					r_wr_bits <= r_wr_bits - 'd1;
					r_rd_bits <= r_rd_bits;
				end
				else if(r_rd_bits > 'd0)begin
					r_wr_bits <= r_wr_bits;
					r_rd_bits <= r_rd_bits - 'd1;
				end
				else begin
					r_wr_bits <= r_wr_bits;
					r_rd_bits <= r_rd_bits;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				r_rd_bits <= 'd0;
				r_wr_bits <= 'd0;
			end
			default               :begin
				r_rd_bits <= 'd0;
				r_wr_bits <= 'd0;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		r_rd_bits <= r_rd_bits;
		r_wr_bits <= r_wr_bits;
	end
end

reg [07:00] r_tx_buf;

always @(negedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		r_tx_buf <= 'd0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			r_tx_buf <= 'd0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				r_tx_buf <= 'd0;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				r_tx_buf <= 'd0;
			end
			STATE_SPI_DRIVE_INIT  :begin
				if(r_buf_rd & r_buf_tx_valid)begin
					r_tx_buf <= r_buf_tx[07:00];
				end
				else begin
					r_tx_buf <= r_tx_buf;
				end
			end
			STATE_SPI_DRIVE_RUN  :begin
				if(r_wr_bits > 'd0)begin
					if(cnt >= 'd7)begin
						if(r_buf_rd & r_buf_tx_valid)begin
							r_tx_buf <= r_buf_tx[07:00];
						end
						else begin
							r_tx_buf <= 'd0;
						end
					end
					else begin
						r_tx_buf[07:01] <= r_tx_buf[06:00];
						r_tx_buf[0]     <= r_tx_buf[7];
					end
				end
				else begin
					r_tx_buf <= 'd0;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				r_tx_buf <= 'd0;
			end
			default               :begin
				r_tx_buf <= 'd0;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		r_tx_buf <= r_tx_buf;
	end
end

reg [07:00] r_rx_buf;
reg         r_rx_buf_valid;
reg         r_rx_buf_last;

always @(posedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		r_rx_buf <= 'd0;
		r_rx_buf_valid <= 1'b0;
		r_rx_buf_last <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			r_rx_buf <= 'd0;
			r_rx_buf_valid <= 1'b0;
			r_rx_buf_last <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				r_rx_buf <= 'd0;
				r_rx_buf_valid <= 1'b0;
				r_rx_buf_last <= 1'b0;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				r_rx_buf <= 'd0;
				r_rx_buf_valid <= 1'b0;
				r_rx_buf_last <= 1'b0;
			end
			STATE_SPI_DRIVE_INIT  :begin
				r_rx_buf <= 'd0;
				r_rx_buf_valid <= 1'b0;
				r_rx_buf_last <= 1'b0;
			end
			STATE_SPI_DRIVE_RUN  :begin
				r_rx_buf[07:01] <= r_rx_buf[06:00];
				r_rx_buf[0]     <= SIO[1];

				if(cnt == 'd7)begin
					r_rx_buf_valid <= 1'b1;
					
					if((r_rd_bits < 'd7) & (r_wr_bits < 'd7))begin
						r_rx_buf_last <= 1'b1;
					end
					else begin
						r_rx_buf_last <= 1'b0;
					end
				end
				else begin
					r_rx_buf_valid <= 1'b0;
					r_rx_buf_last  <= 1'b0;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				r_rx_buf <= 'd0;
				r_rx_buf_valid <= 1'b0;
				r_rx_buf_last <= 1'b0;
			end
			default               :begin
				r_rx_buf <= 'd0;
				r_rx_buf_valid <= 1'b0;
				r_rx_buf_last <= 1'b0;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		r_rx_buf <= r_rx_buf;
		r_rx_buf_valid <= r_rx_buf_valid;
		r_rx_buf_last <= r_rx_buf_last;
	end
end

wire MOSI;
assign MOSI = (FSM_SPI_DRIVE == STATE_SPI_DRIVE_RUN) ? (r_tx_buf[07]) : (1'b0);

reg [04:00] cnt;

always @(negedge w_SCLK, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		cnt <= 'd0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			cnt <= 'd0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			if(FSM_SPI_DRIVE == STATE_SPI_DRIVE_RUN)begin
				if(cnt < 'd7)begin
					cnt <= cnt + 'd1;
				end
				else begin
					cnt <= 'd0;
				end
			end
			else begin
				cnt <= 'd0;
			end
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		cnt <= cnt;
	end
end
//------------------------------------------------------------//------------------------------------------------------------
reg [31:00] r_buf_tx		; // aclk
reg         r_buf_tx_valid	; // aclk
reg         r_buf_tx_ready	; // aclk

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		r_buf_tx       <= {32{1'bZ}};
		r_buf_tx_valid <= 1'b0;
		r_buf_tx_ready <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			r_buf_tx       <= {32{1'bZ}};
			r_buf_tx_valid <= 1'b0;
			r_buf_tx_ready <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_BUF)
			STATE_SPI_BUF_RESET  :begin
				r_buf_tx       <= {32{1'b0}};
				r_buf_tx_valid <= 1'b0;
				r_buf_tx_ready <= 1'b1;
			end
			STATE_SPI_BUF_AMPTY  :begin
				if(s_ready & s_valid)begin
					r_buf_tx       <= s_data;
					r_buf_tx_valid <= s_valid;
					r_buf_tx_ready <= 1'b0;
				end
				else begin
					r_buf_tx       <= {32{1'b0}};
					r_buf_tx_valid <= 1'b0;
					r_buf_tx_ready <= 1'b1;
				end
			end
			STATE_SPI_BUF_LOAD   :begin
				r_buf_tx       <= r_buf_tx;
				r_buf_tx_valid <= r_buf_tx_valid;
				r_buf_tx_ready <= 1'b0;
			end
			STATE_SPI_BUF_READ   :begin
				if(!r_buf_rd)begin
					r_buf_tx       <= {32{1'b0}};
					r_buf_tx_valid <= 1'b0;
					r_buf_tx_ready <= 1'b1;
				end
				else begin
					r_buf_tx       <= r_buf_tx;
					r_buf_tx_valid <= r_buf_tx_valid;
					r_buf_tx_ready <= 1'b0;
				end
			end
			default:begin
				r_buf_tx       <= {32{1'bZ}};
				r_buf_tx_valid <= 1'b0;
				r_buf_tx_ready <= 1'b0;
			end 
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		r_buf_tx       <= r_buf_tx;
		r_buf_tx_valid <= r_buf_tx_valid;
		r_buf_tx_ready <= r_buf_tx_ready;
	end
end

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		s_ready <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			s_ready <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_BUF)
			STATE_SPI_BUF_RESET  :begin
				s_ready <= 1'b1;
			end
			STATE_SPI_BUF_AMPTY  :begin
				if(s_ready & s_valid)begin
					s_ready <= 1'b0;
				end
				else begin
					s_ready <= 1'b1;
				end
			end
			STATE_SPI_BUF_LOAD   :begin
				s_ready <= 1'b0;
			end
			STATE_SPI_BUF_READ   :begin
				if(!r_buf_rd)begin
					s_ready <= 1'b1;
				end
				else begin
					s_ready <= 1'b0;
				end
			end
			default:begin
				s_ready <= 1'b0;
			end 
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		s_ready <= s_ready;
	end
end
localparam [1:0]
	STATE_SPI_BUF_RESET = 'd0                 + 'd0, // 0
	STATE_SPI_BUF_AMPTY = STATE_SPI_BUF_RESET + 'd1, // 1
	STATE_SPI_BUF_LOAD  = STATE_SPI_BUF_AMPTY + 'd1, // 2
	STATE_SPI_BUF_READ  = STATE_SPI_BUF_LOAD  + 'd1  // 3
;

reg [1:0] FSM_SPI_BUF;
initial begin
	FSM_SPI_BUF = STATE_SPI_BUF_RESET;
end

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		FSM_SPI_BUF <= STATE_SPI_BUF_RESET;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			FSM_SPI_BUF <= STATE_SPI_BUF_RESET;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_BUF)
			STATE_SPI_BUF_RESET  :begin
				FSM_SPI_BUF <= STATE_SPI_BUF_AMPTY;
			end
			STATE_SPI_BUF_AMPTY  :begin
				if(s_ready & s_valid)begin
					FSM_SPI_BUF <= STATE_SPI_BUF_LOAD;
				end
				else begin
					FSM_SPI_BUF <= STATE_SPI_BUF_AMPTY;
				end
			end
			STATE_SPI_BUF_LOAD   :begin
				if(r_buf_rd)begin
					FSM_SPI_BUF <= STATE_SPI_BUF_READ;
				end
				else begin
					FSM_SPI_BUF <= STATE_SPI_BUF_LOAD;
				end
			end
			STATE_SPI_BUF_READ   :begin
				if(!r_buf_rd)begin
					FSM_SPI_BUF <= STATE_SPI_BUF_AMPTY;
				end
				else begin
					FSM_SPI_BUF <= STATE_SPI_BUF_READ;
				end
			end
			default:begin
				FSM_SPI_BUF <= STATE_SPI_BUF_RESET;
			end 
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		FSM_SPI_BUF <= FSM_SPI_BUF;
	end
end

assign SCLK = (r_sclk_en) ? (w_SCLK) : (1'b0) ;
reg r_sclk_en;

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		CS_N <= 1'b1;
		r_sclk_en <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			CS_N <= 1'b1;
			r_sclk_en <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_DRIVE)
			STATE_SPI_DRIVE_RESET :begin
				CS_N <= 1'b1;
				r_sclk_en <= 1'b0;
			end
			STATE_SPI_DRIVE_WAIT  :begin
				CS_N <= 1'b1;
				r_sclk_en <= 1'b0;
			end
			STATE_SPI_DRIVE_INIT  :begin
				CS_N <= 1'b0;
				r_sclk_en <= 1'b0;
			end
			STATE_SPI_DRIVE_RUN  :begin
				CS_N <= 1'b0;
				if((!r_sclk_en) & (!w_SCLK))begin
					r_sclk_en <= 1'b1;
				end
				else begin
					r_sclk_en <= r_sclk_en;
				end
			end
			STATE_SPI_DRIVE_END   :begin
				CS_N <= 1'b1;
				r_sclk_en <= 1'b0;
			end
			default               :begin
				CS_N <= 1'b1;
				r_sclk_en <= 1'b0;
			end
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		CS_N <= CS_N;
		r_sclk_en <= r_sclk_en;
	end
end

reg [1:0] FSM_SPI_BUF_OUT;
initial begin
	FSM_SPI_BUF_OUT = STATE_SPI_BUF_RESET;
end


reg r_m_valid;

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		FSM_SPI_BUF_OUT <= STATE_SPI_BUF_RESET;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			FSM_SPI_BUF_OUT <= STATE_SPI_BUF_RESET;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_BUF_OUT)
			STATE_SPI_BUF_RESET  :begin
				FSM_SPI_BUF_OUT <= STATE_SPI_BUF_AMPTY;
			end
			STATE_SPI_BUF_AMPTY  :begin
				if(r_rx_buf_valid)begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_LOAD;
				end
				else begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_AMPTY;
				end
			end
			STATE_SPI_BUF_LOAD   :begin
				// FSM_SPI_BUF_OUT <= STATE_SPI_BUF_READ;
				if(r_m_valid)begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_READ;
				end
				else begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_LOAD;
				end
			end
			STATE_SPI_BUF_READ   :begin
				if((!r_m_valid)&(!r_rx_buf_valid))begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_AMPTY;
				end
				else begin
					FSM_SPI_BUF_OUT <= STATE_SPI_BUF_READ;
				end
			end
			default:begin
				FSM_SPI_BUF_OUT <= STATE_SPI_BUF_RESET;
			end 
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		FSM_SPI_BUF_OUT <= FSM_SPI_BUF_OUT;
	end
end

always @(posedge aclk, negedge aresetn) begin
	if(!aresetn)begin                         // => start async reset
		m_data  <= 'd0;
		r_m_valid <= 'b0;
		m_last  <= 1'b0;
	end                                       // <= end   async reset
	else if(en)begin                          // enable logic <-
		if(reset)begin                        // => start sync reset
			m_data  <= 'd0;
			r_m_valid <= 'b0;
			m_last  <= 1'b0;
		end                                   // <= end   sync reset
		else begin                            // => start run logic
			case (FSM_SPI_BUF_OUT)
			STATE_SPI_BUF_RESET  :begin
				m_data  <= 'd0;
				r_m_valid <= 'b0;
				m_last  <= 1'b0;
			end
			STATE_SPI_BUF_AMPTY  :begin
				if(r_rx_buf_valid)begin
					m_data  <= r_rx_buf;
					r_m_valid <= 1'b0;
					m_last  <= r_rx_buf_last;
				end
				else begin
					m_data  <= 'd0;
					r_m_valid <= 'b0;
					m_last  <= 1'b0;
				end
			end
			STATE_SPI_BUF_LOAD   :begin
				m_data  <= m_data;
				r_m_valid <= 1'b1;
				m_last  <= m_last;
			end
			STATE_SPI_BUF_READ   :begin
				if(m_ready)begin
					m_data  <= 'd0;
					r_m_valid <= 'b0;
					m_last  <= 1'b0;
				end
				else begin
					m_data  <= m_data;
					r_m_valid <= r_m_valid;
					m_last  <= m_last;
				end
			end
			default:begin
				m_data  <= 'd0;
				r_m_valid <= 'b0;
				m_last  <= 1'b0;
			end 
			endcase
		end                                   // <= end   run logic
	end
	else begin                                // pause logic <-
		m_data  <= m_data;
		r_m_valid <= r_m_valid;
		m_last  <= m_last;
	end
end
//------------------------------------------------------------//------------------------------------------------------------
endmodule