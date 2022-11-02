`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2020 14:08:53
// Design Name: 
// Module Name: axis_switch
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axis_pup_loop #(
    parameter DATA_WIDTH = 32,
    parameter PUP_MODE = 2
)(
    input clk,
    input arst_n,
    
    // loop bit
    input loop_bit,
    
    // AXIS slave interface (input)
    input [DATA_WIDTH-1 : 0]     s_axis_tdata,
    input [(DATA_WIDTH/8)-1 : 0] s_axis_tkeep,
    input                        s_axis_tlast,
    input                        s_axis_tvalid,
    output logic                 s_axis_tready,
    
    // AXIS master interface (output)    
    output logic [DATA_WIDTH-1 : 0]     m_axis_tdata,
    output logic [(DATA_WIDTH/8)-1 : 0] m_axis_tkeep,
    output logic                        m_axis_tlast,
    output logic                        m_axis_tvalid,
    input                               m_axis_tready,
    
    // AXIS packer interface
    output logic [DATA_WIDTH-1 : 0]     packer_axis_tdata,
    output logic [(DATA_WIDTH/8)-1 : 0] packer_axis_tkeep,
    output logic                        packer_axis_tlast,
    output logic                        packer_axis_tvalid,
    input                               packer_axis_tready,
    
    // AXIS unpacker interface            
    input [DATA_WIDTH-1 : 0]     unpacker_axis_tdata, 
    input [(DATA_WIDTH/8)-1 : 0] unpacker_axis_tkeep,
    input                        unpacker_axis_tlast,
    input                        unpacker_axis_tvalid,
    output logic                 unpacker_axis_tready
);

/* *********************************************************
 *  Declaration of internal signals
 * *********************************************************/
logic [DATA_WIDTH-1 : 0]     packer_axis_tdata_i;
logic [(DATA_WIDTH/8)-1 : 0] packer_axis_tkeep_i; 
logic                        packer_axis_tlast_i; 
logic                        packer_axis_tvalid_i;
logic                        packer_axis_tready_i;

logic [DATA_WIDTH-1 : 0]     unpacker_axis_tdata_i;
logic [(DATA_WIDTH/8)-1 : 0] unpacker_axis_tkeep_i; 
logic                        unpacker_axis_tlast_i; 
logic                        unpacker_axis_tvalid_i;
logic                        unpacker_axis_tready_i;

/* *********************************************************
 *  Input skid buffer
 * *********************************************************/
assign packer_axis_tdata    = (loop_bit) ?                     '0 : packer_axis_tdata_i; 
assign packer_axis_tkeep    = (loop_bit) ?                     '0 : packer_axis_tkeep_i;
assign packer_axis_tlast    = (loop_bit) ?                     '0 : packer_axis_tlast_i; 
assign packer_axis_tvalid   = (loop_bit) ?                     '0 : packer_axis_tvalid_i;
assign packer_axis_tready_i = (loop_bit) ? unpacker_axis_tready_i : packer_axis_tready;

// input skid buffer
skid_buffer #(
    .DATA_WIDTH (DATA_WIDTH)
) skid_buf_input (
    .clk,
    .arst_n,
    
    // input interface
    .valid_i    (s_axis_tvalid),  
    .data_i     (s_axis_tdata),  
    .keep_i     (s_axis_tkeep),  
    .last_i     (s_axis_tlast),  
    .ready_o    (s_axis_tready),  

    // output interface
    .valid_o    (packer_axis_tvalid_i),
    .data_o     (packer_axis_tdata_i),
    .keep_o     (packer_axis_tkeep_i),
    .last_o     (packer_axis_tlast_i),
    .ready_i    (packer_axis_tready_i)
);

/* *********************************************************
 *  Output skid buffer
 * *********************************************************/
assign unpacker_axis_tkeep_i  = (loop_bit) ? packer_axis_tkeep_i  : unpacker_axis_tkeep;
assign unpacker_axis_tlast_i  = (loop_bit) ? packer_axis_tlast_i  : unpacker_axis_tlast;
assign unpacker_axis_tvalid_i = (loop_bit) ? packer_axis_tvalid_i : unpacker_axis_tvalid;
assign unpacker_axis_tready   = (loop_bit) ?                   '0 : unpacker_axis_tready_i;

generate
    if (PUP_MODE == 0) begin
        always_comb begin
            if (loop_bit) begin
                case (unpacker_axis_tkeep_i)
                    4'h1 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[3:0]};
                    4'h3 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[7:0]};
                    4'h7 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[11:0]};
                    4'hf : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[15:0]};
                    default : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[15:0]};
                endcase
            end else begin
                unpacker_axis_tdata_i = unpacker_axis_tdata;
            end
        end
    end else if (PUP_MODE == 1) begin
        always_comb begin
            if (loop_bit) begin
                case (unpacker_axis_tkeep_i)
                    4'h1 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[7:4]};
                    4'h3 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[15:8]};
                    4'h7 : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[23:12]};
                    4'hf : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[31:16]};
                    default : unpacker_axis_tdata_i = {'0, packer_axis_tdata_i[31:16]};
                endcase
            end else begin
                unpacker_axis_tdata_i = unpacker_axis_tdata;
            end
        end
    end else begin
        assign unpacker_axis_tdata_i = loop_bit ? packer_axis_tdata_i : unpacker_axis_tdata;
    end
endgenerate

// output skid buffer
skid_buffer #(
    .DATA_WIDTH (DATA_WIDTH)
) skid_buf_output (
    .clk,
    .arst_n,
    
    // input interface
    .valid_i    (unpacker_axis_tvalid_i),  
    .data_i     (unpacker_axis_tdata_i),  
    .keep_i     (unpacker_axis_tkeep_i),  
    .last_i     (unpacker_axis_tlast_i),  
    .ready_o    (unpacker_axis_tready_i),  

    // output interface
    .valid_o    (m_axis_tvalid),
    .data_o     (m_axis_tdata),
    .keep_o     (m_axis_tkeep),
    .last_o     (m_axis_tlast),
    .ready_i    (m_axis_tready)
);

endmodule
