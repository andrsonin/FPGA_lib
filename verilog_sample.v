/**
* @file    If it is needed.
* @author  MatR
* @date    2021-05-05
* @brief   This is a brief document description
*
* This is a detailed description. It should be separated from
* the brief description with one blank line
* 
* ПОЛЕЗНЫЕ ССЫЛКИ:
* https://sutherland-hdl.com/pdfs/verilog_2001_ref_guide.pdf - Спецификация языка Verilog версии 2001
* http://fpgacpu.ca/fpga/verilog.html - Verilog Coding Standard - Основной документ по принятому код-стайл'у
* https://course.cutm.ac.in/wp-content/uploads/2020/06/Lec-4.pdf - Verilog FSM Style - Основной документ по принятому код-стайл'у машин состояний
* http://socdsp.ee.nchu.edu.tw/class/download/vlsi_dsp_102/night/DSP/Advanced%20Verilog%20coding.pdf - Полезное о Verilog
* https://www.microsemi.com/document-portal/doc_view/130823-hdl-coding-style-guide - Спецификация языка VHDL
* 
* --------------------------------------------------------------------
* ------------------------ ПРИНЯТЫЕ СОКРАЩЕНИЯ -----------------------
* --------------------------------------------------------------------
* name          short   | name          short   | name          short
* ----------------------|-----------------------|---------------------
* acknowledge   ack     | error         err     | ready         rdy
* adress        addr    | enable	    en      | receive	    rx
* arbiter	    arb     | frame	        frm     | request	    req
* check	        chk     | generate	    gen     | resest	    rst
* clock	        clk     | grant	        gnt     | segment	    seg
* config	    cfg     | increase	    inc     | source	    src
* control	    ctrl    | input	        in      | statistic	    stat
* counter	    cnt     | length	    len     | switcher	    sf
* data in	    din     | output	    out     | timer	        tmr
* data out      dout    | packet	    pkt     | tmporary	    tmp
* decode	    de      | priority	    pri     | transmit	    tx
* decrease	    dec     | pointer	    ptr     | valid	        vld
* delay	        dly     | read	        rd      | write	        wr
* disable	    dis     | read enbale	rd_en   | write enable	wr_en
* --------------------------------------------------------------------
* ПРИНЯТЫЕ ПРЕФИКСЫ: 
* g_        Generic (VHDL only)
* t_        User-Defined Type  
* p_        Global parameter
* i_        Input signal 
* o_        Output signal 
* s_        Slave interface
* m_        Master interface
* stat_     Statistics interface
* dbg_      Debug interface
* pl_       Local patameter
* w_        Local wires
* f_        Local flags
* c_        Constant 
* cnt_      Local counter
* tick_     Local timers
* clk_      Local clock
* r_        Local registers
* --------------------------------------------------------------------
* Generics, User-Definedes, Parameters - Пишутся заглавными буквами, не считая пристаки.
* Названия TOP модулей, состоящих из нескольких слов, разделяются '_'.
* Названия второстипенных модулей, состоящих из нескольких слов, пишутся слитно,
*   где каждое новое слово пишется с Заглавной буквы.
* Все остальное пишется строчными буквами.
* Любое 'if' должно сопровождаться 'else'.
* У каждого 'CASE' дожен быть 'default:'.
* Любое условие должно быть обраслено в '( )'.
* Любое логическое действие в условиях должно быть обраслено в '( )'
* Между логическими действиями дожен быть ' '.
* Действия с регистрами, стараться разделять в разные always,
*   в зависимости от логики/действия/операции, связанные одиним смыслом.
* --------------------------------------------------------------------
*   @param a    A description of a
*   @param b    A description of b
*
*   @return     A return module description
*/
//===========================================================
//-----------------------------------------------------------
// global includes

//-----------------------------------------------------------
module verilog_sample 
#(
    /*
        префиксы: 
        p_  global parameter
    */
    parameter                   p_A = 1'b1,
    parameter   reg     [01:00] p_B =  'h2,
    parameter           [01:00] p_C = 2'd3,
    parameter   integer         p_D =    4
) 
(
    /*
        префиксы: 
        i_      Input signal 
        o_      Output signal 
        s_      Slave interface
        m_      Master interface
        stat_   statistics interface
        dbg_    debug interface
    */

    // custom input interfaces
    input   wire            i_a,
    input   wire    [01:00] i_b,

    // standart interface
    inout   wire            i2c_sda,
    inout   tri1            i2c_scl,

    // standart slave interface
    input   wire            s_axis_tready,
    output  wire    [07:00] s_axis_tdata,
    output  wire    [03:00] s_axis_tkeep,
    output  wire            s_axis tvalid,
    output  wire            s_axis_tlast,

    // standart master interface
    input   wire            m_axis_tready,
    output  wire    [07:00] m_axis_tdata,
    output  wire    [03:00] m_axis_tkeep,
    output  wire            m_axis tvalid,
    output  wire            m_axis_tlast,
    
    // custom output interfaces
    output  wire            o_a,
    output  wire    [01:00] o_b,
    output  reg     [01:00] o_c,

    // statistics data
    output  wire            stat_a,
    output  wire    [01:00] stat_b,
    output  reg     [01:00] stat_c,
    
    // debug data
    output  wire            dbg_a,
    output  wire    [01:00] dbg_b,
    output  reg     [01:00] dbg_c,

    // SYSTEM's wires
    /// system timer
    input   wire            tick_10Mhz,
    /// system timer
    input   wire            tick_1us,
    /// system secondary clocking
    input   wire            aclk_20Mhz,
    /// synchronous reset
    input   wire            reset,
    /// asynchronous reset
    input   wire            aresen,
    /// system main clocking in XXXMhz
    input   wire            aclk
);
//-----------------------------------------------------------
// local includes
`include "local_include.vh"
//-----------------------------------------------------------
// local parameters
/*
    префиксы: 
    pl_ Local patameter
*/

localparam                  pl_A    = 1'b1;
localparam  reg     [01:00] pl_B    =  'h2;
localparam          [01:00] pl_C    = 2'd3;
localparam  integer         pl_D    =    4;
//-----------------------------------------------------------
// FSM and STATES
localparam FSM_LENGTH = 2;

localparam [(FSM_LENGTH -1):00]
    STATE_A =   2'h0,
    STATE_B =   STATE_A + 'd1;

reg [(FSM_LENGTH -1):00] FSM_LOCAL;
wire                     f_next_state;

initial begin
    FSM_LOCAL = STATE_A;
end
//-----------------------------------------------------------
// wires and assign
/*
    префиксы: 
    w_ Local wires
    f_ Local flags
*/
wire            w_a;
wire    [01:00] w_b;
wire            w_c [01:00];
wire    [01:00] w_d [01:00];

wire f_a;
wire f_b [01:00];
//-----------------------------------------------------------
// conters, timers and clocks and initial
/*
    префиксы: 
    cnt_    Local counter
    tick_   Local timers
    clk_    Local clock
*/
integer         cnt_a;
integer         cnt_b   [01:00];
reg     [01:00] cnt_c;
reg     [01:00] cnt_d   [01:00];

integer         tick_a_us;
integer         tick_b_ms   [01:00];
reg     [01:00] tick_c_kHz;
reg     [01:00] tick_d_s    [01:00];

reg             clk_a_XXkhz;

initial begin
    cnt_a               = 64;
    cnt_b[0]            = 1024:
    cnt_b[1]            = 'd128;
    cnt_c   [01:00]     = 2'b11;
    cnt_d   [01:00][0]  = 2'hff;
    cnt_d   [01:00][1]  = 2'd58;

    tick_a_us               = 256;
    tick_b_ms[0]            = 8;
    tick_b_ms[1]            = 4;
    tick_c_kHz  [01:00]     = 'd2;
    tick_d_s    [01:00][0]  = 2'h3;
    tick_d_s    [01:00][1]  = 2'b11;

    clk_a_XXkhz = 1'b0;
end
//-----------------------------------------------------------
// registers and initial
/*
    префиксы: 
    r_ Local registers
*/
reg             r_a;
reg     [01:00] r_b;
reg             r_c [01:00];
reg     [01:00] r_d [01:00];

initial begin
    r_a                 = 1'b0;
    r_b                 =  'd0;
    r_c[0]              = 1'h1;
    r_c[1]              = 1'd1;
    r_d     [01:00][0]  = 'hff;
    r_d     [01:00][1]  = {2{1'b1}}; 
end
//-----------------------------------------------------------
// instantiate sub module 
subModule
#(
    .p_A    (p_A),
    .p_B    (1),
    .p_C    ('d0),
    .p_E    (5'h20),
)
subModule_inst
(
    .i_a    (w_a),
    .i_b    (i_b),

    .o_a    (o_a),
    .o_b    (w_b),

    .stat_a (),
    .dbg_a  (),

    .reset  (reset),
    .aresen (aresetn),
    .aclk   (aclk)
)

//-----------------------------------------------------------
// combinational logic
assign f_a = r_a ? 1'b1 : r_b[0];

always @(*) begin
    if(o_c)begin : flag_b_true
        f_b [0] = o_a;
    end : flag_b_true
    else begin : flag_b_false
        f_b [0] = 1'b0;
    end : flag_b_false
end
//-----------------------------------------------------------
// LOGIC
always @(*) begin
    case (FSM_LOCAL)
        STATE_A: begin 
            if(i_a)begin
                f_next_state  = 1'b1;
            end
            else begin
                f_next_state = 1'b0;
            end            
        end
        STATE_B: begin
            if(i_b[0])begin
                f_next_state  = 1'b1;
            end
            else begin
                f_next_state = 1'b0;
            end    
        end        
        default: f_next_state  = 1'b1;
    endcase
end
always @(posedge aclk, negedge aresetn) begin
    if(!aresetn)begin
        FSM_LOCAL <= STATE_A;
    end
    else if(reset)begin
        FSM_LOCAL <= STATE_A;
    end
    else begin
        case (FSM_LOCAL)
            STATE_A: begin
                if(f_next_state)begin
                    FSM_LOCAL <= STATE_B;
                end
                else begin
                    FSM_LOCAL <= STATE_A;
                end
            end
            STATE_B: begin
                if(f_next_state)begin
                    FSM_LOCAL <= STATE_A;
                end
                else begin
                    FSM_LOCAL <= FSM_LOCAL;
                end
            end
            default: FSM_LOCAL <= STATE_A;
        endcase
    end
end

always @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin : reset_async
        // areset
        r_a         <= 1'b0;
        clk_a_XXkhz <= 1'b1;
    end : reset_async
    else if(reset) begin : reset_sync
        // reset
        r_a         <= 1'b0;
        clk_a_XXkhz <= 1'b0;
    end : reset_sync
    else begin : GO_CODE
        // do something
        r_a         <= 1'b1;
        clk_a_XXkhz <= ~clk_a_XXkhz;
    end : GO_CODE
end
//-----------------------------------------------------------
// assign output ports
assign i2c_sda  = (f_a) ? (1'bZ) : (1'b0);
assign i2c_scl  = (f_b) ? (1'bZ) : (1'b0);
//-----------------------------------------------------------
endmodule
//===========================================================