//`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
//'ifndef _interfaces_sv_
//'define _interfaces_sv_
///////////////////////////////////////////////////////////////////////
interface AXI4_STREAM_IO #(
    parameter int BUS_WIDTH = 32
  )(
    input bit clk,
    input bit rst
  );
  //------------------------------
  bit                                           tready;
  bit   [(((((BUS_WIDTH-1) /8) +1) *8)-1):0]    tdata;
  bit   [((((BUS_WIDTH-1) /8) +1) -1):0]        tkeep;
  bit                                           tlast;
  bit                                           tvalid;
  //------------------------------
  modport slave(
            output  tready,
            input   tdata,
            input   tkeep,
            input   tlast,
            input   tvalid
          );
  //------------------------------
  modport master(
            input    tready,
            output   tdata,
            output   tkeep,
            output   tlast,
            output   tvalid
          );
  //------------------------------
endinterface
///////////////////////////////////////////////////////////////////////
//'else
/////////////////////////////////////////////////////////////////////////
//'endif
///////////////////////////////////////////////////////////////////////
