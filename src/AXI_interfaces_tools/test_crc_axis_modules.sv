`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module test_crc_axis_modules(  );
    //----------------------------
    reg   	aclk;
    reg 	aresetn;
    
    reg	[07:00]	data;
    reg 		valid;
    reg			last;
    
    reg	[07:00]	data_out;
    reg			valid_out;
    reg			last_out;
    
    reg crc_en;
    reg crc_rstn;
    
    reg	[07:00][00:07]	data0  = {8'h9D, 8'h00, 8'h0E, 8'h00, 8'h00, 8'h0E, 8'h00, 8'h2C}; //8'h2C
    reg	[07:00][00:07]	data1  = {8'hA6, 8'h00, 8'h0E, 8'h00, 8'h00, 8'h0E, 8'h00, 8'h74}; //8'h74
    reg	[07:00][00:07]	data2  = {8'hC0, 8'h00, 8'h00, 8'h04, 8'h00, 8'h00, 8'h04, 8'h5F}; //8'h5F
    
    enum {
    	st_data0,
    	st_data1,
    	st_data2
    }state;
    
    integer cnt;
    //----------------------------
    initial  begin
        aclk  = 0;
        forever  #1 aclk = ~aclk;
    end
    //----------------------------
    initial  begin
             aresetn  = 1;
        #200 aresetn  = 0;
        #20  aresetn  = 1;
    end
    //----------------------------
    always begin
        @(posedge aclk)
       	begin
       		if(aresetn == 0)begin
       			data = 0;
       			valid = 0;
       			last = 0;
       			crc_en = 0;
       			crc_rstn = 0;
       			state = st_data0;
       			cnt <= 0;
       			
       		end else begin
       			if(cnt > 7)begin       				
       				crc_rstn <= 0;
       				cnt <= 0;	 
       				valid <= 0;
       				last <= 1;
       				
       			end else begin       				
       				crc_rstn <= 1;	
       				valid <= 1;	
       				
       				if(cnt == 6)begin
       					last <= 1;
       					cnt <= cnt+1;
       					
       				end else begin
       					last <= 0;
       					cnt <= cnt +1;
       					
       				end	
       			end    			
       			
       				crc_en = 1;
       			if(cnt <= 7)begin
					case(state)
					st_data0: begin 
						data = data0[7-cnt];
						
						if(cnt == 7)begin
							state = st_data1;
						end else begin
							state = state;
						end
					end
					st_data1: begin
						data = data1[7-cnt];
						
						if(cnt == 7)begin
							state = st_data2;
						end else begin
							state = state;
						end
					end
					st_data2: begin
						data = data2[7-cnt];
						
						if(cnt == 7)begin
							state = st_data0;
						end else begin
							state = state;
						end
					end
					default: begin 
						data = data0[7-cnt];
						
						if(cnt == 7)begin
							state = st_data0;
						end else begin
							state = state;
						end
					end
					endcase
				end else begin
					data = 0;
				end
			end
		end
    end
    //----------------------------
crc8 crc8_inst(
    .s_axis_tready(),
    .s_axis_tdata(data),
    .s_axis_tvalid(valid),
    .s_axis_tlast(last),

    .crc_en(1),
    .aresetn(crc_rstn),
    .aclk(aclk),

    .m_axis_tready(1),
    .m_axis_tdata(data_out),
    .m_axis_tvalid(valid_out),
    .m_axis_tlast(last_out)
    );
    //----------------------------
endmodule
