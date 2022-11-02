
/*
//! \title      AXI4 STREAM shared interface
//! \file       axi4_stream_if.sv
//! \author     RTI_command_409
//! \version    0.1
//! \date       2020-03
//!
//! \copyright  Copyright (c) 2021
//!
//! \brief AXI4 интерфейс для использования в верхнем ровне сабмодулей
//! ---
//!
//! \details ***Details***
//! шина данных кратна 8, входной параметр BUS_WIDTH округляется до верха при делении на 8
//! ---
//!
//! \bug none
//! ---
//! 
//! \warning none
//! ---
//! 
//! \todo hm...
//! ---
//!
*/
`ifndef AXI4_STREAM_IF
`define AXI4_STREAM_IF
    /*
    //! AXI4 STREAM интерфейс
    //! \param[in] BUS_WIDTH Входной параметр - разрядность шины данных
    //! \param[in] clk Тактирование шины
    //! \param[in] arst_n Сброс шины 
    //! \return master or slave
    */
    interface axi4_stream_if #(
        //! разрядность tdata
        parameter int BUS_WIDTH = 32
    )(
        //! bus clock
        input bit aclk,
        //! bus asynchronous reset, active level - low
        input logic aresetn
    );

        //! time parameter for signal rise time 
        // parameter setup_time = 1ns;
        //! time parameter for signal decay duration 
        // parameter hold_time  = 1ns;

        //! tvalid - data relevance in bus
        logic                                       tvalid;
        //! tready - readiness of the bus for data processing
        logic                                       tready;
        //! tdata - data  subbus, bus width is a multiple of 8, rounded up
        logic [(((((BUS_WIDTH-1) /8) +1) *8)-1):0]  tdata;
        //! tkeep - validation bytes in tdata
        logic [((((BUS_WIDTH-1) /8) +1) -1):0]      tkeep;
        //! tlast - pointer to the last word in the data packet
        logic                                       tlast;

        //! master clocking block
        // clocking m_cb @(posedge clk);
        //     // default input #setup_time output #hold_time;
        //     input  tready;
        //     output tvalid;
        //     output tdata;
        //     output tkeep;
        //     output tlast;
        // endclocking : m_cb

        //! slave clocking block
        // clocking s_cb @(posedge clk);
        //     // default input #setup_time output #hold_time;
        //     output tready;
        //     input  tvalid;            
        //     input  tdata;
        //     input  tkeep;
        //     input  tlast;
        // endclocking : s_cb

        //! modport master
        modport master (
            input    tready,
            output   tdata,
            output   tkeep,
            output   tlast,
            output   tvalid
        );
        //! modport slave
        modport slave  (
            output  tready,
            input   tdata,
            input   tkeep,
            input   tlast,
            input   tvalid
        );

    endinterface : axi4_stream_if

`endif
//*end file*/
