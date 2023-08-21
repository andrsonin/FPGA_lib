module I2C_M_CTRL
(
    // slave interface
    output wire         s_axis_tready,
    input  wire [07:00] s_axis_tdata,
    input  wire         s_axis_tvalid,
    input  wire         s_axis_tlast,
    // master interface
    input  wire         m_axis_tready,
    output reg  [07:00] m_axis_tdata,
    output reg          m_axis_tvalid,
    output reg          m_axis_tlast,
    // 
    input  wire reset,
    input  wire aresetn,
    input  wire aclk
);

localparam lp_COM_NUM       = 9;
localparam lp_COM_REPEAT    = 0;

reg [07:00] axi_commands[lp_COM_NUM-1:00] ;

initial begin
    axi_commands[0] = 8'b11111010; // write speed
    axi_commands[1] = 8'b01100100; // 400
    axi_commands[2] = 8'b11111000; // write length
    axi_commands[3] = 8'b00000010; // 2
    axi_commands[4] = 8'b10101110; // write addr 0'hAE
    axi_commands[5] = 8'b11001101; // write 0'hCD
    axi_commands[6] = 8'b10101110; // write addr 0'hAE
    axi_commands[7] = 8'b11001101; // write 0'hCD
    axi_commands[8] = 8'b11101010;  // read addr 0'hAE
end

assign s_axis_tready = 1'b1;

integer cnt;

initial begin
    cnt = 0;
end

always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        cnt             <= 0;
        m_axis_tdata    <= 'd0;
        m_axis_tvalid   <= 1'b0;
        m_axis_tlast    <= 1'b0;
    end
    else if(reset)begin
        cnt             <= 0;
        m_axis_tdata    <= 'd0;
        m_axis_tvalid   <= 1'b0;
        m_axis_tlast    <= 1'b0;
    end
    else begin
        if((!m_axis_tvalid) | m_axis_tready)begin
            if((cnt == (lp_COM_NUM -1)) | (cnt == 'd5)) begin
                cnt             <= cnt +1;
                m_axis_tdata    <= axi_commands [cnt];
                m_axis_tvalid   <= 1'b1;
                m_axis_tlast    <= 1'b1;
            end
            else if(cnt < (lp_COM_NUM -1))begin
                cnt             <= cnt +1;
                m_axis_tdata    <= axi_commands [cnt];
                m_axis_tvalid   <= 1'b1;
                m_axis_tlast    <= 1'b0;
            end
            else begin
                if(lp_COM_REPEAT)begin
                    cnt             <= 0;
                end
                else begin
                    cnt             <= cnt;
                end
                m_axis_tdata    <= 'd0;
                m_axis_tvalid   <= 1'b0;
                m_axis_tlast    <= 1'b0;
            end
        end
        else begin
            cnt             <= cnt;
            m_axis_tdata    <= m_axis_tdata;
            m_axis_tvalid   <= m_axis_tvalid;
            m_axis_tlast    <= m_axis_tlast;
        end
    end
end
endmodule
