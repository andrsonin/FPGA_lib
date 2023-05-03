//`timescale 1 ns / 1 ps
//===========================================================
module I2C_Slave_REGMAP#(
    //-----------------------
    // Users to add parameters here

    // User parameters ends
    //-----------------------
    // Module parameters here
    parameter p_ADDRESS_LENGTH  = 8,    // in BIT: 7bit or 10bit
    parameter p_COMMAND_LENGTH  = 1,    // in BYTE: range 1 to pl_I2C_MAX_LENGTH-1 (max range = pl_I2C_MAX_LENGTH - p_DATA_LENGT)
    parameter p_DATA_LENGTH     = 2     // in BYTE: range 1 to pl_I2C_MAX_LENGTH-1 (max range = pl_I2C_MAX_LENGTH - p_COMMAND_LENGTH)
    // Module parameters ends
    //-----------------------
)
//-----------------------------------------------------------
(
    //-----------------------
    // Users to add ports here

    // User ports ends
    //-----------------------
    //-----------------------------------------------------------
    // Module to add ports here
    //-----------------------
    // device address
    input  [(p_ADDRESS_LENGTH -1):00] address,
    //-----------------------
    // // device info
    input  [11:00] manufacture          ,
    input  [08:00] part_identificattion ,
    input  [02:00] revision             ,
    //-----------------------
    // I2C IO interface
    inout  SCK,
    inout  SDA,
    //-----------------------
    // I2C debug data
    output f_address_ok ,
    output f_busy       ,
    output f_active     ,
    output f_rw         ,
    output f_err        ,
	 
	output [07:00] w_byte_buf,
	output [31:00] w_data_buf,
	output [31:00] w_comand_buf,
    
    output [((p_DATA_LENGTH *8) -1):00]    f_data_out,
    output [((p_DATA_LENGTH *8) -1):00]    f_data_out_buf,
    output [15:00] f_cnt_reg,
    //-----------------------
    // system inpterface
    input  reset    ,
    input  aresetn  ,
    input  aclk     
    // Module ports ends
    //-----------------------
);
//-----------------------------------------------------------
    //-----------------------
    initial begin
        if((p_ADDRESS_LENGTH != 7) & (p_ADDRESS_LENGTH != 10))begin
            $display("!!!I2C Slave address length error!!!");
            $display("Parameter p_ADDRESS_LENGTH =  %d", p_ADDRESS_LENGTH);
            $display("You mast setup p_ADDRESS_LENGTH 7 or 10 only");
            $finish;
        end
        if((p_COMMAND_LENGTH + p_DATA_LENGTH) > pl_I2C_MAX_LENGTH)begin
            $display("!!!I2C Slave Parameters is invalid. Byte limit exceeded!!!");
            $finish;
        end
        if((p_COMMAND_LENGTH) == 0)begin
            $display("!!!I2C Slave Parameter is invalid!!!");
            $display("Parameter p_COMMAND_LENGTH =  %d", p_COMMAND_LENGTH);
            $display("You mast setup p_COMMAND_LENGTH > 0 only");
            $finish;
        end
        if((p_DATA_LENGTH) == 0)begin
            $display("!!!I2C Slave Parameter is invalid!!!");
            $display("Parameter p_DATA_LENGTH =  %d", p_DATA_LENGTH);
            $display("You mast setup p_DATA_LENGTH > 0 only");
            $finish;
        end
    end
    //-----------------------
    localparam pl_I2C_MAX_LENGTH = 128;
    localparam [07:00] 
                        STATE_START  = 8'd0,                  // 0
                        STATE_ADDR   = STATE_START  + 8'd1,   // 1
                        STATE_DATA   = STATE_ADDR   + 8'd1,   // 2
                        STATE_ACK    = STATE_DATA   + 8'd1,   // 3
                        STATE_STOP   = STATE_ACK    + 8'd1,   // 4
                        STATE_WAIT   = STATE_STOP   + 8'd1,   // 5
                        STATE_BUSY   = STATE_WAIT   + 8'd1,   // 6
                        STATE_ERROR  = STATE_BUSY   + 8'd1;   // 7
    //-----------------------
    reg [02:00] r_SCK_filter;
    reg [02:00] r_SDA_filter;

    initial begin
        r_SCK_filter = 3'b111;
        r_SDA_filter = 3'b111;
    end

	//------- Input_Filters
	always @(posedge aclk, negedge aresetn) begin
		 if(!aresetn)begin
			  r_SDA_filter <= 3'b111;
			  r_SCK_filter <= 3'b111;
		 end else begin
			  if(reset)begin
					r_SDA_filter <= 3'b111;
					r_SCK_filter <= 3'b111;
			  end else begin
					r_SDA_filter[0] <= SDA;
					r_SCK_filter[0] <= SCK;
					
					r_SDA_filter[1] <= r_SDA_filter[0];
					r_SCK_filter[1] <= r_SCK_filter[0];  
					
					r_SDA_filter[2] <= r_SDA_filter[1];
					r_SCK_filter[2] <= r_SCK_filter[1];      
			  end
		 end            
	end
	
    reg [09:00]                             r_addr_buf;
    reg                                     r_rw_buf;
    reg [((p_COMMAND_LENGTH * 8) -1) : 00]  r_comm_buf;
    reg [((p_DATA_LENGTH *8) -1) : 00]      r_data_buf;
    reg [07:00]                             r_byte_buf;  
	 
    assign w_byte_buf = r_addr_buf;
    assign w_comand_buf = r_comm_buf;
    assign w_data_buf = r_data_buf;

    initial begin
        r_addr_buf = {10{1'b1}};
        r_rw_buf   = 1'b1;
        r_comm_buf = {(p_COMMAND_LENGTH * 8){1'b1}};
        r_data_buf = {(p_DATA_LENGTH *8){1'b1}};
        r_byte_buf = {8{1'b1}};
    end
	 
    reg [((p_DATA_LENGTH *8) -1):00]    r_data_out;
    reg [((p_DATA_LENGTH *8) -1):00]    r_data_out_buf;
    reg                                 r_data_out_valid;
    
    assign f_data_out 		= r_data_out;
    assign f_data_out_buf 	= r_data_out_buf;

    initial begin
        r_data_out          = {(p_DATA_LENGTH *8){1'b1}};
        r_data_out_buf      = {(p_DATA_LENGTH *8){1'b1}};
        r_data_out_valid    = 1'b0;
    end

    assign f_rw = r_rw_buf;

    reg r_busy;

    initial begin
        r_busy = 1'b0;
    end
    //-----------------------
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

    wire w_start;
    assign w_start = (w_SCK_high & w_SDA_negedge);

    wire w_stop;
    assign w_stop = (w_SCK_high & w_SDA_posedge);
    //-----------------------
    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_busy <= 1'b0;
        end else if(w_stop)begin
            r_busy <= 1'b0;
        end else if(w_start)begin
            r_busy <= 1'b1;
        end else begin
            r_busy <= r_busy;
        end
    end

    assign f_busy = r_busy;

    reg [07:00] FSM_I2C;
    reg [07:00] FSM_I2C_last;
    initial begin
        FSM_I2C         = STATE_BUSY;
        FSM_I2C_last 	= STATE_BUSY;
    end

wire f_data_bad;
wire f_comand_bad;

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            FSM_I2C_last <= STATE_BUSY;
        end else if(w_SCK_negedge)begin
            FSM_I2C_last <= FSM_I2C;
        end else begin
            FSM_I2C_last <= FSM_I2C_last;
        end 
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            FSM_I2C <= STATE_BUSY;
        end else begin
            case (FSM_I2C)
            STATE_START:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else if(w_SCK_negedge)begin
                    FSM_I2C <= STATE_ADDR;
                end else begin
                    FSM_I2C <= STATE_START;
                end
            STATE_ADDR:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else if(w_SCK_negedge & (cnt >= 'd7))begin
                    FSM_I2C <= STATE_ACK;
                end else begin
                    FSM_I2C <= STATE_ADDR;
                end
            STATE_DATA:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else if(w_SCK_negedge & (cnt >= 'd7))begin
                    if(f_data_bad | f_comand_bad)begin
                        FSM_I2C <= STATE_BUSY;
                    end else begin
                        FSM_I2C <= STATE_ACK;
                    end
                end else begin
                    FSM_I2C <= STATE_DATA;
                end
            STATE_ACK:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else if(w_SCK_negedge)begin
                    if(r_addr_bad)begin
                        FSM_I2C <= STATE_BUSY;
                    end else if((FSM_I2C_last == STATE_ADDR) &(cnt_addr_bit == 'd2))begin
                        FSM_I2C <= STATE_ADDR;
                    end else begin
                        FSM_I2C <= STATE_DATA;
                    end
                end else begin
                    FSM_I2C <= STATE_ACK;
                end
            STATE_STOP:
                if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else begin
                    FSM_I2C <= STATE_WAIT;
                end
            STATE_WAIT:
                if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else if(w_SCK_low | w_SDA_low)begin
                    FSM_I2C <= STATE_BUSY;
                end else begin
                    FSM_I2C <= STATE_WAIT;
                end
            STATE_BUSY:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else if(w_start)begin
                    FSM_I2C <= STATE_START;
                end else begin
                    FSM_I2C <= STATE_BUSY;
                end
            STATE_ERROR: 
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else begin
                    FSM_I2C <= STATE_ERROR;
                end
            default:
                if(w_stop)begin
                    FSM_I2C <= STATE_STOP;
                end else begin
                    FSM_I2C <= FSM_I2C;
                end 
            endcase
        end
    end

    assign f_active = (FSM_I2C < STATE_WAIT) ? 1'b1 : 1'b0;

    reg [03:00] cnt;
    initial begin
        cnt = 'd0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            cnt <= 'd0;
        end else begin
            case (FSM_I2C)
            STATE_ADDR, STATE_DATA:
                if(w_SCK_negedge)begin 
                    cnt <= cnt + 'd1;
                end else begin
                    cnt <= cnt;
                end
            STATE_ACK: 
                if(w_SCK_negedge)begin 
                    cnt <= 'd0;
                end else begin
                    cnt <= cnt;
                end
            default: begin
                cnt <= 'd0;
            end
            endcase
        end 
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_byte_buf <= {8{1'b1}};
        end else begin
            case (FSM_I2C)
            STATE_ADDR, STATE_DATA:
                if(w_SCK_posedge)begin 
                    r_byte_buf[00]      <= w_SDA_sync;
                    r_byte_buf[07:01]   <= r_byte_buf[06:00];
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            STATE_ACK:
                if(w_SCK_negedge)begin
                    r_byte_buf <= {8{1'b1}};
                end else begin
                    r_byte_buf <= r_byte_buf;
                end
            default: begin
                r_byte_buf <= {8{1'b1}};
            end
            endcase
        end 
    end
    
    reg r_addr_bad;
    initial begin
        r_addr_bad = 1'b1;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_addr_bad <= 1'b1;
        end else if(w_stop)begin
            r_addr_bad <= 1'b1;
        end else if(w_start)begin
            r_addr_bad <= 1'b1;
        end else if(FSM_I2C >= STATE_STOP)begin
            r_addr_bad <= 1'b1;
        end else if(FSM_I2C == STATE_ADDR)begin
            if(w_SCK_negedge & (cnt == 'd7))begin
                if(cnt_addr_bit >= 'd9)begin
                    if({r_byte_buf[07:00], r_addr_buf[01:00]} == address)begin
                        r_addr_bad       <= 1'b0;
                    end else begin
                        r_addr_bad       <= 1'b1;
                    end
                end else begin
                    case (r_byte_buf[07:01])
                    7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                    begin
                        if(r_byte_buf[0])begin          // will fix (not implemented)
                            r_addr_bad    <= 1'b1;    // will fix (not implemented)
                        end else begin                  // will fix (not implemented)
                            r_addr_bad    <= 1'b1;    // will fix (not implemented)
                        end                             // will fix (not implemented)
                    end
                    7'b0000001: // CBUS address
                    begin
                        r_addr_bad    <= 1'b1;
                    end
                    7'b0000010: // reserved for different bus format
                    begin
                        r_addr_bad    <= 1'b1;
                    end
                    7'b0000011: // reserved for future purposes
                    begin
                        r_addr_bad    <= 1'b1;
                    end
                    default:
                        case (r_byte_buf[07:01] & 7'b1111100)
                        7'b0000100: // Hs-mode controller code
                        begin
                            r_addr_bad    <= 1'b1;
                        end
                        7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                        begin
                            if(r_byte_buf[0])begin          // will fix (not implemented)
                                r_addr_bad    <= 1'b1;    // will fix (not implemented)
                            end else begin                  // will fix (not implemented)
                                r_addr_bad    <= 1'b1;    // will fix (not implemented)
                            end
                        end
                        7'b1111000: // 10-bit target addressing
                        begin
                            r_addr_bad       <= 1'b1;
                        end
                        default: // 7bit address 
                        begin
                            if(r_byte_buf[07:01] == address[06:00])begin
                                r_addr_bad    <= 1'b0;
                            end else begin
                                r_addr_bad    <= 1'b1;
                            end
                        end
                        endcase
                    endcase
                end
            end else begin
                r_addr_bad <= r_addr_bad; 
            end
        end else begin
            r_addr_bad <= r_addr_bad;
        end 
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_addr_buf  <= 'h00;
            r_rw_buf    <= 1'b1;
        end else if(w_stop)begin
            r_addr_buf  <= 'h00;
            r_rw_buf    <= 1'b1;
        end else if(w_start)begin
            r_addr_buf  <= 'h00;
            r_rw_buf    <= 1'b1;
        end else if(FSM_I2C >= STATE_STOP)begin
            r_addr_buf  <= 'h00;
            r_rw_buf    <= 1'b1;
        end else if(FSM_I2C == STATE_ACK)begin
            if((w_SCK_posedge)&(FSM_I2C_last == STATE_ADDR))begin					 
                if(r_addr_bad)begin
                    r_addr_buf  <= 'h00;
                    r_rw_buf    <= 1'b1;
                end else begin
                    if(cnt_addr_bit >= 'd9)begin
                        r_addr_buf[09:02]   <= r_byte_buf[07:00];
                        r_rw_buf            <= r_rw_buf;
                    end else begin
                        case (r_byte_buf[07:01])
                        7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                        begin
                            if(r_byte_buf[0])begin              // will fix (not implemented)
                                r_addr_buf  <= address;         // will fix (not implemented)
                                r_rw_buf    <= r_byte_buf[0];   // will fix (not implemented)
                            end else begin                      // will fix (not implemented)
                                r_addr_buf  <= address;         // will fix (not implemented)
                                r_rw_buf    <= r_byte_buf[0];   // will fix (not implemented)
                            end                                 // will fix (not implemented)
                        end
                        7'b0000001: // CBUS address
                        begin
                            r_addr_buf  <= 'h00;
                            r_rw_buf    <= 1'b1;
                        end
                        7'b0000010: // reserved for different bus format
                        begin
                            r_addr_buf  <= 'h00;
                            r_rw_buf    <= 1'b1;
                        end
                        7'b0000011: // reserved for future purposes
                        begin
                            r_addr_buf  <= 'h00;
                            r_rw_buf    <= 1'b1;
                        end
                        default:
                            case (r_byte_buf[07:01] & 7'b1111100)
                            7'b0000100: // Hs-mode controller code
                            begin
                                r_addr_buf  <= 'h00;
                                r_rw_buf    <= 1'b1;
                            end
                            7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                            begin
                                if(r_byte_buf[0])begin      // will fix (not implemented)
                                    r_addr_buf  <= 'h00;    // will fix (not implemented)
                                    r_rw_buf    <= 1'b1;    // will fix (not implemented)
                                end else begin              // will fix (not implemented)
                                    r_addr_buf  <= 'h00;    // will fix (not implemented)
                                    r_rw_buf    <= 1'b1;    // will fix (not implemented)
                                end
                            end
                            7'b1111000: // 10-bit target addressing
                            begin
                                r_addr_buf[01:00]   <= r_byte_buf[02:01];
                                r_rw_buf            <= r_byte_buf[0];
                            end
                            default: // 7bit address 
                            begin
                                if(r_byte_buf[07:01] == address[06:00])begin
                                    r_addr_buf[06:00]   <= r_byte_buf[07:01];
                                    r_rw_buf            <= r_byte_buf[00];
                                end else begin
                                    r_addr_buf  <= 'h00;
                                    r_rw_buf    <= 1'b1;
                                end
                            end
                            endcase
                        endcase
                    end
                end
            end else begin
                r_addr_buf  <= r_addr_buf;
                r_rw_buf    <= r_rw_buf;
            end
        end else begin
            r_addr_buf  <= r_addr_buf;
            r_rw_buf    <= r_rw_buf;
        end 
    end

    reg [03:00] cnt_addr_bit;
    initial begin
        cnt_addr_bit = 'd0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            cnt_addr_bit <= 'd0;
        end else if(w_stop)begin
            cnt_addr_bit <= 'd0;
        end else if(w_start)begin
            cnt_addr_bit <= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            cnt_addr_bit <= 'd0;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_ADDR) )begin
            cnt_addr_bit <= cnt_addr_bit + 'd1;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_ACK) &(FSM_I2C_last == STATE_ADDR))begin
            if(r_addr_bad)begin
                cnt_addr_bit <= 'd0;
            end else begin
                if(cnt_addr_bit >= 'd10)begin
                    cnt_addr_bit <= cnt_addr_bit;
                end else begin
                    case (r_byte_buf[07:01])
                    7'b0000000: // rw == 0 - general call address; rw == 1 - START byte
                    begin
                        if(r_byte_buf[0])begin              // will fix (not implemented)
                            cnt_addr_bit <= cnt_addr_bit;   // will fix (not implemented)
                        end else begin                      // will fix (not implemented)
                            cnt_addr_bit <= cnt_addr_bit;   // will fix (not implemented)
                        end                                 // will fix (not implemented)
                    end
                    7'b0000001: // CBUS address
                    begin
                        cnt_addr_bit <= cnt_addr_bit;
                    end
                    7'b0000010: // reserved for different bus format
                    begin
                        cnt_addr_bit <= cnt_addr_bit;
                    end
                    7'b0000011: // reserved for future purposes
                    begin
                        cnt_addr_bit <= cnt_addr_bit;
                    end
                    default:
                        case (r_byte_buf[07:01] & 7'b1111100)
                        7'b0000100: // Hs-mode controller code
                        begin
                            cnt_addr_bit <= cnt_addr_bit;
                        end
                        7'b1111100: // rw == 0 - NON; rw == 1  - device ID 
                        begin
                            if(r_byte_buf[0])begin              // will fix (not implemented)
                                cnt_addr_bit <= cnt_addr_bit;   // will fix (not implemented)
                            end else begin                      // will fix (not implemented)
                                cnt_addr_bit <= cnt_addr_bit;   // will fix (not implemented)
                            end
                        end
                        7'b1111000: // 10-bit target addressing
                        begin
                            cnt_addr_bit <= 'd2;
                        end
                        default: // 7bit address 
                        begin
                            if(r_byte_buf[07:01] == address[06:00])begin
                                cnt_addr_bit <= 'd7;
                            end else begin
                                cnt_addr_bit <= 'd0;
                            end
                        end
                        endcase
                    endcase
                end
            end
        end else begin
            cnt_addr_bit <= cnt_addr_bit;
        end
    end
    
    reg [07:00] cnt_command_bit;

    initial begin
        cnt_command_bit = 'd0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            cnt_command_bit <= 'd0;
        end else if(w_stop)begin
            cnt_command_bit <= 'd0;
        end else if(w_start)begin
            cnt_command_bit <= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            cnt_command_bit <= 'd0;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_DATA) &((cnt_command_bit < ((p_COMMAND_LENGTH * 8)))  & (!r_rw_buf)))begin
            cnt_command_bit  <= cnt_command_bit + 'd1;
        end else begin
            cnt_command_bit <= cnt_command_bit;
        end
    end

    reg [07:00] cnt_data_bit;

    initial begin
        cnt_data_bit = 'd0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            cnt_data_bit <= 'd0;
        end else if(w_stop)begin
            cnt_data_bit <= 'd0;
        end else if(w_start)begin
            cnt_data_bit <= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            cnt_data_bit <= 'd0;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_DATA) &((cnt_command_bit >= ((p_COMMAND_LENGTH * 8))) | r_rw_buf)  &(cnt_data_bit < ((p_DATA_LENGTH * 8))))begin
            cnt_data_bit  <= cnt_data_bit + 'd1;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_ACK) &((cnt_command_bit >= ((p_COMMAND_LENGTH * 8))) | r_rw_buf)  &(cnt_data_bit >= ((p_DATA_LENGTH * 8))))begin
            cnt_data_bit <= 'd0;
        end else begin
            cnt_data_bit <= cnt_data_bit;
        end
    end
    
    reg [15:00] cnt_reg;

    initial begin
        cnt_reg = 'd0;
    end

    assign f_cnt_reg = cnt_reg;
    
    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            cnt_reg <= 'd0;
        end else if(w_stop)begin
            cnt_reg <= 'd0;
        end else if(w_start)begin
            cnt_reg <= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            cnt_reg <= 'd0;
        end else if((w_SCK_posedge) &(FSM_I2C == STATE_ACK) &((cnt_command_bit >= ((p_COMMAND_LENGTH * 8))) | r_rw_buf)  &(cnt_data_bit >= ((p_DATA_LENGTH * 8))))begin
            cnt_reg  <= cnt_reg + 'd2;
        end else begin
            cnt_reg <= cnt_reg;
        end
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_comm_buf <= {(p_COMMAND_LENGTH * 8){1'b1}};
        end else if((FSM_I2C == STATE_DATA) &((cnt_command_bit < ((p_COMMAND_LENGTH * 8)))  & (!r_rw_buf)))begin
            if(w_SCK_negedge)begin
                r_comm_buf <= r_comm_buf << 1;
            end else if(w_SCK_posedge)begin
                r_comm_buf[00] <= w_SDA_sync;
                if(cnt_command_bit == 'd0)begin
                    r_comm_buf[((p_COMMAND_LENGTH * 8) -1):01] <= {(p_COMMAND_LENGTH * 8 -1){1'b1}};
                end else begin
                    r_comm_buf[((p_COMMAND_LENGTH * 8) -1):01] <= r_comm_buf[((p_COMMAND_LENGTH * 8) -1):01];
                end
            end else begin
                r_comm_buf <= r_comm_buf;
            end
        end else begin
            r_comm_buf <= r_comm_buf;
        end
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_data_buf <= 'd0;
        end else if(w_stop)begin
            r_data_buf <= 'd0;
        end else if(w_start)begin
            r_data_buf <= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            r_data_buf <= 'd0;
        end else if((FSM_I2C == STATE_DATA) &((cnt_command_bit >= ((p_COMMAND_LENGTH * 8))) | r_rw_buf) &(cnt_data_bit < ((p_DATA_LENGTH * 8) -1)))begin
            if(w_SCK_negedge)begin
                r_data_buf <= r_data_buf << 1;
            end else if(w_SCK_posedge)begin
                r_data_buf[00] <= w_SDA_sync;
                r_data_buf[((p_DATA_LENGTH * 8) -1):01] <= r_data_buf[((p_DATA_LENGTH * 8) -1):01];
            end else begin
                r_data_buf <= r_data_buf;
            end
        end else begin
            r_data_buf <= r_data_buf;
        end
    end

    reg SDA_ctrl;

    initial begin
        SDA_ctrl = 1'b0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            SDA_ctrl <= 1'b0;
        end else if(w_stop)begin
            SDA_ctrl <= 1'b0;
        end else if(w_start)begin
            SDA_ctrl <= 1'b0;
        end else if(FSM_I2C >= STATE_STOP)begin
            SDA_ctrl <= 1'b0;
        end else begin
            case (FSM_I2C)
            STATE_START:begin
                SDA_ctrl <= 1'b0;
            end
            STATE_ADDR:begin
                SDA_ctrl <= 1'b0;               
            end
            STATE_DATA:begin
                if(r_ack_buf | r_addr_bad)begin
                    SDA_ctrl <= 1'b0;
                end else if(w_SCK_negedge & (cnt >= 'd7))begin 
                    if (r_rw_buf)begin
                        SDA_ctrl <= 1'b0;
                    end else begin
                        SDA_ctrl <= 1'b1; //<<<<<<<<<<<<
                    end
                end else begin
                    if (r_rw_buf)begin
                        if(r_data_out_valid)begin
                            SDA_ctrl <=  ~r_data_out_buf[((p_DATA_LENGTH *8) -1)]; //<<<<<<<<<<<<
                        end else begin
                            SDA_ctrl <= 1'b0; //<<<<<<<<<<<< 
                        end
                    end else begin
                        SDA_ctrl <= 1'b0;
                    end
                end
            end
            STATE_ACK:begin
                case (FSM_I2C_last)
                STATE_ADDR:begin
                    if(w_SCK_negedge)begin
                        if(r_ack_buf | r_addr_bad)begin
                            SDA_ctrl <= 1'b0;
                        end else if ((!r_rw_buf) | (cnt_addr_bit == 'd2))begin
                            SDA_ctrl <= 1'b0;
                        end else begin
                            SDA_ctrl <=  ~r_data_out_buf[((p_DATA_LENGTH *8) -1)]; //<<<<<<<<<<<<
                        end
                    end else begin
                        SDA_ctrl <= !r_addr_bad;
                    end
                end
                STATE_DATA:begin
                    if(w_SCK_negedge)begin
                        if(r_ack_buf | r_addr_bad)begin
                            SDA_ctrl <= 1'b0;
                        end else if(r_rw_buf)begin
                            if(r_data_out_valid)begin
                                SDA_ctrl <=  ~r_data_out_buf[((p_DATA_LENGTH *8) -1)]; //<<<<<<<<<<<<
                            end else begin
                                SDA_ctrl <= 1'b0; //<<<<<<<<<<<<
                            end
                        end else begin
                            SDA_ctrl <= 1'b0;
                        end
                    end else begin
                        if(r_ack_buf | r_addr_bad)begin
                            SDA_ctrl <= 1'b0;
                        end else if(r_rw_buf)begin
                            SDA_ctrl <= 1'b0;
                        end else begin
                            SDA_ctrl <= SDA_ctrl;
                        end
                    end
                end 
                default:begin
                    SDA_ctrl <= 1'b0;
                end
                endcase
            end
            default: begin
                SDA_ctrl <= 1'b0;
            end
            endcase
        end
    end    

    reg r_ack_buf;

    initial begin
       r_ack_buf = 1'b1;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
                r_ack_buf	<= 1'b1;
        end else if(w_stop)begin
                r_ack_buf	<= 1'b1;
        end else if(w_start)begin
                r_ack_buf	<= 1'b1;
        end else if(FSM_I2C >= STATE_STOP)begin
                r_ack_buf	<= 1'b1;
        end else if(FSM_I2C == STATE_ACK)begin
            if(w_SCK_posedge)begin
                    r_ack_buf	  <= w_SDA_sync;
            end else begin
                    r_ack_buf	 <= r_ack_buf;
            end
        end else begin
            r_ack_buf	<= r_ack_buf;
        end 
    end
    
    reg [((p_DATA_LENGTH *8) -1):00] r_data_in;

    initial begin
        r_data_in <= 'd0;
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_data_in	<= 'd0;
        end else if(w_stop)begin
            r_data_in	<= 'd0;
        end else if(w_start)begin
            r_data_in	<= 'd0;
        end else if(FSM_I2C >= STATE_STOP)begin
            r_data_in	<= 'd0;
        end else if(FSM_I2C == STATE_ACK)begin
            if((w_SCK_posedge) & (!r_rw_buf))begin
                r_data_in	  <= r_data_buf;
            end else begin
                r_data_in	 <= r_data_in;
            end
        end else begin
            r_data_in	<= r_data_in;
        end 
    end

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
        end else if(w_stop)begin
            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
        end else if(w_start)begin
            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
        end else if(FSM_I2C >= STATE_STOP)begin
            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
        end else begin
            case (FSM_I2C)
            STATE_ACK:begin
                case (FSM_I2C_last)
                STATE_ADDR:begin
                    if(w_SCK_negedge)begin
                        if(r_ack_buf | r_addr_bad)begin
                            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
                        end else if ((!r_rw_buf) | (cnt_addr_bit == 'd2))begin
                            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
                        end else begin
                            r_data_out_buf      <= r_data_out;
                        end
                    end else begin
                        r_data_out_buf      <= r_data_out_buf;
                    end
                end
                STATE_DATA:begin
                    if(w_SCK_negedge)begin
                        if(r_ack_buf | r_addr_bad)begin
                            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
                        end else if (!r_rw_buf)begin
                            r_data_out_buf      <= {(p_DATA_LENGTH *8){1'b1}};
                        end else if((cnt_command_bit == 'd0) &(cnt_data_bit == 'd0))begin
                            r_data_out_buf      <= r_data_out;
                        end else begin
                            r_data_out_buf      <= r_data_out_buf;
                        end
                    end else begin
                        r_data_out_buf      <= r_data_out_buf;
                    end
                end 
                default:begin
                    r_data_out_buf      <= r_data_out_buf;
                end
                endcase
            end
            STATE_DATA:begin
                if(r_rw_buf)begin
                    if(w_SCK_negedge)begin
                        r_data_out_buf[(p_DATA_LENGTH *8)-1:01]     <= r_data_out_buf[(p_DATA_LENGTH *8)-2:00];
                        r_data_out_buf[00]                          <= 1'b1;
                    end else begin
                        r_data_out_buf      <= r_data_out_buf;
                    end
                end else begin
                    r_data_out_buf      <= r_data_out_buf;
                end
            end
            default: begin
                r_data_out_buf      <= r_data_out_buf;
            end
            endcase
        end
    end

    wire [((p_COMMAND_LENGTH * 8) -1) : 00] w_reg_addr;

    assign w_reg_addr = r_comm_buf + cnt_reg;

    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            r_data_out          <= {(p_DATA_LENGTH *8){1'b1}};
            r_data_out_valid    <= 1'b0;
        end else begin
            case (w_reg_addr)
            'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h04    : begin
                r_data_out          <= 'hEFEF;
                r_data_out_valid    <= 1'b1;
            end
            'h06    : begin
                r_data_out          <= 'h5678;
                r_data_out_valid    <= 1'b1;
            end
            'h08    : begin
                r_data_out          <= 'h9ECD;
                r_data_out_valid    <= 1'b0;
            end
            'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h20 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h20 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h40 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h40 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h40 + 'h20*1 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h40 + 'h20*1 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            default :begin 
                r_data_out          <= {(p_DATA_LENGTH *8){1'b1}};
                r_data_out_valid    <= 1'b0;
            end
            endcase 
        end    
    end
/*
    always @(posedge aclk, negedge aresetn, posedge reset) begin
        if((!aresetn) | reset)begin
            ///
            // reg_0 <= 'd0;
            ///

            // r_data_in_valid <= 'd0;
        end else ((FSM_I2C == STATE_ACK) & (FSM_I2C_last == STATE_DATA) & w_SCK_negedge)begin
            case (w_reg_addr)
            'h00    : begin
                reg_0 <= r_data_in;
                r_data_in_valid    <= 1'b0;
            end
            'h02    : begin
                r_data_out          <= 'h1234;
                r_data_in_valid    <= 1'b0;
            end
            'h04    : begin
                r_data_out          <= 'hEFEF;
                r_data_in_valid    <= 1'b0;
            end
            'h06    : begin
                r_data_out          <= 'h5678;
                r_data_in_valid    <= 1'b0;
            end
            'h08    : begin
                r_data_out          <= 'h9ECD;
                r_data_out_valid    <= 1'b0;
            end
            'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b1;
            end
            'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h20 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h20 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h20 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h40 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h40 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            'h40 + 'h20*1 + 'h00    : begin
                r_data_out          <= 'hABCD;
                r_data_out_valid    <= 1'b1;
            end
            'h40 + 'h20*1 + 'h02    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h04    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h06    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h08    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h0E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h10    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h12    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h14    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h16    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h18    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1A    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1C    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            'h40 + 'h20*1 + 'h1E    : begin
                r_data_out          <= 'h1234;
                r_data_out_valid    <= 1'b0;
            end
            //-----------------------------------
            default :begin 
                r_data_out          <= {(p_DATA_LENGTH *8){1'b1}};
                r_data_out_valid    <= 1'b0;
            end
            endcase 
        end
    end
*/
    assign f_address_ok = !r_addr_bad;
//    assign f_active = SDA_ctrl;
    assign f_err = (FSM_I2C == STATE_ERROR) ? 1'b1 : 1'b0;

    assign SDA = SDA_ctrl ? 1'b0 : 1'bZ;
    assign SCK = 1'bZ;
    //-----------------------
    // Add user logic here

    // User logic ends
    //-----------------------
//-----------------------------------------------------------
endmodule
//===========================================================