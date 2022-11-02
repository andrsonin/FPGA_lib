--/////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
--/////////////////////////////////////////////////////////////////////
entity BLOCK_SDS_vhd is port (
  --! 
  s_data_axis_tready : out std_logic;
  s_data_axis_tdata  : in std_logic_vector(31 downto 00);
  s_data_axis_tkeep  : in std_logic_vector(03 downto 00);
  s_data_axis_tvalid : in std_logic;
  s_data_axis_tlast  : in std_logic;

  --!
  m_sl_axis_tready : in std_logic;
  m_sl_axis_tdata  : out std_logic_vector(07 downto 00);
  m_sl_axis_tvalid : out std_logic;
  m_sl_axis_tlast  : out std_logic;

  --!
  s_sl_axis_tready : out std_logic;
  s_sl_axis_tdata  : in std_logic_vector(07 downto 00);
  s_sl_axis_tvalid : in std_logic;
  s_sl_axis_tlast  : in std_logic;

  --! 
  m_data_axis_tready : in std_logic;
  m_data_axis_tdata  : out std_logic_vector(31 downto 00);
  m_data_axis_tkeep  : out std_logic_vector(03 downto 00);
  m_data_axis_tvalid : out std_logic;
  m_data_axis_tlast  : out std_logic;

  --!
  config_reg : in std_logic_vector(07 downto 00);
  --! системное тактирование
  aclk : in std_logic;
  --! системный ассинхронный сброс, активный уровень - низкий
  aresetn : in std_logic

);
end BLOCK_SDS_vhd;

architecture rtl of BLOCK_SDS_vhd is
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------  
  signal arstn_tx 					:std_logic;
  signal arstn_rx 					:std_logic;
  -----------------------------------------------------------------------
  signal s_tx_2_axis_tready 		:std_logic                     ;
  signal s_tx_2_axis_tdata  		:std_logic_vector(31 downto 00);
  signal s_tx_2_axis_tkeep  		:std_logic_vector(03 downto 00);
  signal s_tx_2_axis_tvalid 		:std_logic                     ;
  signal s_tx_2_axis_tlast  		:std_logic                     ;
  
  signal m_tx_2_axis_tready 		:std_logic                     ;
  signal m_tx_2_axis_tdata  		:std_logic_vector(31 downto 00);
  signal m_tx_2_axis_tkeep  		:std_logic_vector(03 downto 00);
  signal m_tx_2_axis_tvalid 		:std_logic                     ;
  signal m_tx_2_axis_tlast  		:std_logic                     ;
  -----------------------------------------------------------------------
  signal s_rx_2_axis_tready 		:std_logic                     ;
  signal s_rx_2_axis_tdata  		:std_logic_vector(31 downto 00);
  signal s_rx_2_axis_tkeep  		:std_logic_vector(03 downto 00);
  signal s_rx_2_axis_tvalid 		:std_logic                     ;
  signal s_rx_2_axis_tlast  		:std_logic                     ;
  
  signal m_rx_2_axis_tready 		:std_logic                     ;
  signal m_rx_2_axis_tdata  		:std_logic_vector(31 downto 00);
  signal m_rx_2_axis_tkeep  		:std_logic_vector(03 downto 00);
  signal m_rx_2_axis_tvalid 		:std_logic                     ;
  signal m_rx_2_axis_tlast  		:std_logic                     ;
  -----------------------------------------------------------------------
  signal s_tx_axis_tready 			:std_logic                     ;
  signal s_tx_axis_tdata  			:std_logic_vector(31 downto 00);
  signal s_tx_axis_tkeep  			:std_logic_vector(03 downto 00);
  signal s_tx_axis_tvalid 			:std_logic                     ;
  signal s_tx_axis_tlast  			:std_logic                     ;
  
  signal m_tx_axis_tready 			:std_logic                     ;
  signal m_tx_axis_tdata  			:std_logic_vector(07 downto 00);
  signal m_tx_axis_tvalid 			:std_logic                     ;
  signal m_tx_axis_tlast  			:std_logic                     ;
  -----------------------------------------------------------------------
  signal s_rx_axis_tready 			:std_logic                     ;
  signal s_rx_axis_tdata  			:std_logic_vector(31 downto 00);
  signal s_rx_axis_tkeep  			:std_logic_vector(03 downto 00);
  signal s_rx_axis_tvalid 			:std_logic                     ;
  signal s_rx_axis_tlast  			:std_logic                     ;
  -----------------------------------------------------------------------
  signal m_sl_axis_tready_out : std_logic;
  signal m_sl_axis_tdata_out  : std_logic_vector(31 downto 00);
  signal m_sl_axis_tkeep_out  : std_logic_vector(03 downto 00);
  signal m_sl_axis_tvalid_out : std_logic;
  signal m_sl_axis_tlast_out  : std_logic;
  -----------------------------------------------------------------------
  signal u0_loop_config_reg			:std_logic_vector(01 downto 00);
  signal u1_loop_config_reg			:std_logic_vector(01 downto 00);
  -----------------------------------------------------------------------
  component LOOP_AXI4_STREAM_vhd is
    port (
      s_axis_i_tready : out std_logic;
      s_axis_i_tdata  : in std_logic_vector(31 downto 00);
      s_axis_i_tkeep  : in std_logic_vector(03 downto 00);
      s_axis_i_tvalid : in std_logic;
      s_axis_i_tlast  : in std_logic;

      m_axis_i_tready : in std_logic;
      m_axis_i_tdata  : out std_logic_vector(31 downto 00);
      m_axis_i_tkeep  : out std_logic_vector(03 downto 00);
      m_axis_i_tvalid : out std_logic;
      m_axis_i_tlast  : out std_logic;

      s_axis_o_tready : out std_logic;
      s_axis_o_tdata  : in std_logic_vector(31 downto 00);
      s_axis_o_tkeep  : in std_logic_vector(03 downto 00);
      s_axis_o_tvalid : in std_logic;
      s_axis_o_tlast  : in std_logic;

      m_axis_o_tready : in std_logic;
      m_axis_o_tdata  : out std_logic_vector(31 downto 00);
      m_axis_o_tkeep  : out std_logic_vector(03 downto 00);
      m_axis_o_tvalid : out std_logic;
      m_axis_o_tlast  : out std_logic;

      config_port : in std_logic_vector(01 downto 00);
      clk         : in std_logic
    );
  end component LOOP_AXI4_STREAM_vhd;
  -----------------------------------------------------------------------
component Serializer_v2_vhd is
  port (
    s_axis_tready 	:out std_logic;
    s_axis_tdata 	:in std_logic_vector(31 downto 00);
    s_axis_tkeep 	:in std_logic_vector(03 downto 00);
    s_axis_tvalid 	:in std_logic;
    s_axis_tlast 	:in std_logic;

    m_axis_tready 	:in std_logic;
    m_axis_tdata 	:out std_logic_vector(07 downto 00);
    m_axis_tvalid 	:out std_logic;
    m_axis_tlast 	:out std_logic;
    
    first_bit_en	:in std_logic;
    
	bit_pointer			:out std_logic_vector(15 downto 00);
	flag_new_word_next	:out std_logic;
    --! системные такты
    aclk 			:in std_logic;
    --! системный ассинхронный сброс активный уровень низкий 
    aresetn 		:in std_logic
  );
end component Serializer_v2_vhd;
  -----------------------------------------------------------------------
  component DeSerializer_vhd is
    port (
      s_axis_tready 	: out std_logic;
      s_axis_tdata 		: in std_logic_vector(07 downto 00);
      s_axis_tvalid 	: in std_logic;
      s_axis_tlast 		: in std_logic;
      
      m_axis_tready 	: in std_logic;
      m_axis_tdata 		: out std_logic_vector(31 downto 00);
      m_axis_tkeep 		: out std_logic_vector(03 downto 00);
      m_axis_tvalid 	: out std_logic;
      m_axis_tlast 		: out std_logic;

      clk 				: in std_logic;
      resetn 			: in std_logic
    );
  end component DeSerializer_vhd;  
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
begin
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------  
  arstn_tx 				<= aresetn and (not config_reg(0));
  arstn_rx 				<= aresetn and (not config_reg(1));
  
  u0_loop_config_reg 	<= config_reg(03 downto 02);
  u1_loop_config_reg 	<= config_reg(05 downto 04);
  -----------------------------------------------------------------------
  m_sl_axis_tready_out 	<= m_sl_axis_tready;
  m_sl_axis_tdata 		<= m_sl_axis_tdata_out(07 downto 00);
  m_sl_axis_tvalid		<= m_sl_axis_tvalid_out;
  m_sl_axis_tlast		<= m_sl_axis_tlast_out;
  -----------------------------------------------------------------------
  u0_LOOP_AXI4_STREAM_vhd : LOOP_AXI4_STREAM_vhd
  port map(
    s_axis_i_tready              	=> s_data_axis_tready,
    s_axis_i_tdata					=> s_data_axis_tdata,
    s_axis_i_tkeep 					=> s_data_axis_tkeep,
    s_axis_i_tvalid              	=> s_data_axis_tvalid,
    s_axis_i_tlast               	=> s_data_axis_tlast,

    m_axis_i_tready              	=> m_tx_2_axis_tready,
    m_axis_i_tdata 				 	=> m_tx_2_axis_tdata,
    m_axis_i_tkeep               	=> m_tx_2_axis_tkeep,
    m_axis_i_tvalid              	=> m_tx_2_axis_tvalid,
    m_axis_i_tlast               	=> m_tx_2_axis_tlast,

    s_axis_o_tready              	=> s_rx_2_axis_tready,
    s_axis_o_tdata 				 	=> s_rx_2_axis_tdata,
    s_axis_o_tkeep 					=> s_rx_2_axis_tkeep,
    s_axis_o_tvalid              	=> s_rx_2_axis_tvalid,
    s_axis_o_tlast               	=> s_rx_2_axis_tlast,

    m_axis_o_tready 				=> m_data_axis_tready,
    m_axis_o_tdata 					=> m_data_axis_tdata,
    m_axis_o_tkeep  				=> m_data_axis_tkeep,
    m_axis_o_tvalid 				=> m_data_axis_tvalid,
    m_axis_o_tlast  				=> m_data_axis_tlast,

    config_port => u0_loop_config_reg,
    clk         => aclk
  );
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  u_Serializer_v2_vhd: Serializer_v2_vhd
  port map(
    s_axis_tready 		=> m_tx_2_axis_tready,
    s_axis_tdata  		=> m_tx_2_axis_tdata,
    s_axis_tkeep  		=> m_tx_2_axis_tkeep,
    s_axis_tvalid 		=> m_tx_2_axis_tvalid,
    s_axis_tlast  		=> m_tx_2_axis_tlast,

    m_axis_tready       => m_tx_axis_tready,
    m_axis_tdata		=> m_tx_axis_tdata,
    m_axis_tvalid       => m_tx_axis_tvalid,
    m_axis_tlast        => m_tx_axis_tlast,
        
    first_bit_en		=> '1',    
--	bit_pointer			=> ,
--	flag_new_word_next	=> ,

    aclk    => aclk,
    aresetn => arstn_tx
  );
  -----------------------------------------------------------------------
  u_DeSerializer_vhd : DeSerializer_vhd
  port map(
    s_axis_tready => s_rx_axis_tready,
    s_axis_tdata  => s_rx_axis_tdata(07 downto 00),
    s_axis_tvalid => s_rx_axis_tvalid,
    s_axis_tlast  => s_rx_axis_tlast,

    m_axis_tready => s_rx_2_axis_tready,
    m_axis_tdata  => s_rx_2_axis_tdata,
    m_axis_tkeep  => s_rx_2_axis_tkeep,
    m_axis_tvalid => s_rx_2_axis_tvalid,
    m_axis_tlast  => s_rx_2_axis_tlast,

    clk  => aclk,
    resetn => arstn_rx
  );
  -----------------------------------------------------------------------
  u1_LOOP_AXI4_STREAM_vhd : LOOP_AXI4_STREAM_vhd
  port map(
  s_axis_i_tready              	=> m_tx_axis_tready,
  s_axis_i_tdata(31 downto 08)	=> (others => '0'),
  s_axis_i_tdata(07 downto 00)	=> m_tx_axis_tdata,
  s_axis_i_tkeep 				=> "0001",
  s_axis_i_tvalid              	=> m_tx_axis_tvalid,
  s_axis_i_tlast               	=> m_tx_axis_tlast,

  m_axis_i_tready              	=> m_sl_axis_tready_out,
  m_axis_i_tdata				=> m_sl_axis_tdata_out,
  m_axis_i_tkeep                => m_sl_axis_tkeep_out,
  m_axis_i_tvalid              	=> m_sl_axis_tvalid_out,
  m_axis_i_tlast               	=> m_sl_axis_tlast_out,

  s_axis_o_tready              	=> s_sl_axis_tready,
  s_axis_o_tdata(31 downto 08)	=> (others => '0'),
  s_axis_o_tdata(07 downto 00)	=> s_sl_axis_tdata,
  s_axis_o_tkeep 				=> "0001",
  s_axis_o_tvalid              	=> s_sl_axis_tvalid,
  s_axis_o_tlast               	=> s_sl_axis_tlast,

  m_axis_o_tready 				=> s_rx_axis_tready,
  m_axis_o_tdata				=> s_rx_axis_tdata,
  m_axis_o_tkeep  				=> s_rx_axis_tkeep,
  m_axis_o_tvalid 				=> s_rx_axis_tvalid,
  m_axis_o_tlast  				=> s_rx_axis_tlast,

  config_port => u1_loop_config_reg,
  clk         => aclk
  );
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
end rtl;
--/////////////////////////////////////////////////////////////////////
