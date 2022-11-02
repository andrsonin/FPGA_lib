--/////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
--/////////////////////////////////////////////////////////////////////
entity Serializer_pack_v2 is
  port (
    s_axis_tready : out std_logic;
    s_axis_tdata : in std_logic_vector(31 downto 00);
    s_axis_tkeep : in std_logic_vector(03 downto 00);
    s_axis_tvalid : in std_logic;
    s_axis_tlast : in std_logic;

    m_axis_tready : in std_logic;
    m_axis_tdata : out std_logic_vector(07 downto 00);
    m_axis_tvalid : out std_logic;
    m_axis_tlast : out std_logic;

    m_axis_size_tdata : out std_logic_vector(31 downto 00);
    m_axis_size_tvalid : out std_logic;
    m_axis_size_tlast : out std_logic;

    --! системные такты
    aclk : in std_logic;
    --! системный ассинхронный сброс активный уровень низкий 
    aresetn : in std_logic
  );
end Serializer_pack_v2;
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
architecture etl of Serializer_pack_v2 is
  -----------------------------------------------------------------------
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
component Serializer_Size_logic is
  port (
    s_axis_tready 		:in std_logic;
    s_axis_tdata 		:in std_logic_vector(31 downto 00);
    s_axis_tkeep 		:in std_logic_vector(03 downto 00);
    s_axis_tvalid 		:in std_logic;
    s_axis_tlast 		:in std_logic;
    
    s_size_axis_tready 	:out std_logic;
    s_size_axis_tdata 	:in std_logic_vector(15 downto 00);
    s_size_axis_tvalid 	:in std_logic;
    
    m_size_axis_tdata 	:out std_logic_vector(31 downto 00);
    m_size_axis_tvalid 	:out std_logic;
    m_size_axis_tlast 	:out std_logic;
    
	bit_pointer			:in std_logic_vector(15 downto 00);
	flag_new_word_next	:in std_logic;
	
	first_bit_en		:out std_logic;
	
    --! системные такты
    aclk 			:in std_logic;
    --! системный ассинхронный сброс активный уровень низкий 
    aresetn 		:in std_logic
  );
end component Serializer_Size_logic;
  -----------------------------------------------------------------------
signal s_axis_tready_s 		: std_logic;
signal s_axis_tdata_s 		: std_logic_vector(31 downto 00);
signal s_axis_tkeep_s 		: std_logic_vector(03 downto 00);
signal s_axis_tvalid_s 		: std_logic;
signal s_axis_tlast_s 		: std_logic;
  -----------------------------------------------------------------------
signal s_size_axis_tready_s : std_logic;
signal s_size_axis_tdata_s 	: std_logic_vector(15 downto 00);
signal s_size_axis_tvalid_s	: std_logic;
  -----------------------------------------------------------------------
signal first_bit_en			: std_logic;
signal bit_pointer			: std_logic_vector(15 downto 00);
signal flag_new_word_next	: std_logic;
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
begin
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
 s_axis_tready <= s_axis_tready_s;
 s_axis_tdata_s <= s_axis_tdata;
 s_axis_tkeep_s <= s_axis_tkeep;
 s_axis_tvalid_s <= s_axis_tvalid;
 s_axis_tlast_s <= s_axis_tlast;
  -----------------------------------------------------------------------
 s_axis_size_tready <= s_size_axis_tready_s;
 s_size_axis_tdata_s <= s_axis_size_tdata;
 s_size_axis_tvalid_s <= s_axis_size_tvalid;
  -----------------------------------------------------------------------
  Serializer_Size_logic_inst: Serializer_Size_logic port map(
    s_axis_tready	=> s_axis_tready_s,
    s_axis_tdata 	=> s_axis_tdata_s,
    s_axis_tkeep	=> s_axis_tkeep_s,
    s_axis_tvalid 	=> s_axis_tvalid_s,
    s_axis_tlast	=> s_axis_tlast_s,
    
    s_size_axis_tready	=> s_size_axis_tready_s,
    s_size_axis_tdata	=> s_size_axis_tdata_s,
    s_size_axis_tvalid	=> s_size_axis_tvalid_s,
    
    m_size_axis_tdata	=> m_axis_size_tdata,
    m_size_axis_tvalid	=> m_axis_size_tvalid,
    m_size_axis_tlast	=> m_axis_size_tlast,
    
	bit_pointer			=> bit_pointer,
	flag_new_word_next	=> flag_new_word_next,
	
	first_bit_en		=> first_bit_en,
	
    aclk	=> aclk,
    aresetn	=> aresetn
  );
  -----------------------------------------------------------------------
Serializer_v2_vhd_inst: Serializer_v2_vhd port map(
    s_axis_tready	=> s_axis_tready_s,
    s_axis_tdata 	=> s_axis_tdata_s,
    s_axis_tkeep	=> s_axis_tkeep_s,
    s_axis_tvalid 	=> s_axis_tvalid_s,
    s_axis_tlast	=> s_axis_tlast_s,

    m_axis_tready 	=> m_axis_tready,
    m_axis_tdata 	=> m_axis_tdata,
    m_axis_tvalid 	=> m_axis_tvalid,
    m_axis_tlast 	=> m_axis_tlast,
    
	bit_pointer			=> bit_pointer,
	flag_new_word_next	=> flag_new_word_next,
	
	first_bit_en		=> first_bit_en,
	
    aclk	=> aclk,
    aresetn	=> aresetn
  );
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
end etl;
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
