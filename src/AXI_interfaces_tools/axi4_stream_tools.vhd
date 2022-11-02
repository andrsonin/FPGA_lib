----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity LOOP_AXI4_STREAM_vhd is
  port (
    s_axis_i_tready : out std_logic;
    s_axis_i_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_i_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_i_tvalid : in std_logic;
    s_axis_i_tlast  : in std_logic;

    m_axis_i_tready : in std_logic;
    m_axis_i_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_i_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_i_tvalid : out std_logic;
    m_axis_i_tlast  : out std_logic;

    s_axis_o_tready : out std_logic;
    s_axis_o_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_o_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_o_tvalid : in std_logic;
    s_axis_o_tlast  : in std_logic;

    m_axis_o_tready : in std_logic;
    m_axis_o_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_o_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_o_tvalid : out std_logic;
    m_axis_o_tlast  : out std_logic;

    config_port : in std_logic_vector(01 downto 00);

    clk : in std_logic
  );
end LOOP_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of LOOP_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  m_axis_i_tdata <=
    s_axis_o_tdata when (config_port(1 downto 0) = "11") else
    (others => '0') when (config_port(1 downto 0) = "01") else
    s_axis_o_tdata when (config_port(1 downto 0) = "10") else
    s_axis_i_tdata;

  m_axis_i_tvalid <=
    s_axis_o_tvalid when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    s_axis_o_tvalid when (config_port(1 downto 0) = "10") else
    s_axis_i_tvalid;

  m_axis_i_tlast <=
    s_axis_o_tlast when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    s_axis_o_tlast when (config_port(1 downto 0) = "10") else
    s_axis_i_tlast;

  m_axis_i_tkeep <=
    s_axis_o_tkeep when (config_port(1 downto 0) = "11") else
    (others => '0') when (config_port(1 downto 0) = "01") else
    s_axis_o_tkeep when (config_port(1 downto 0) = "10") else
    s_axis_i_tkeep;

  s_axis_o_tready <=
    m_axis_i_tready when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    m_axis_i_tready when (config_port(1 downto 0) = "10") else
    m_axis_o_tready;

  s_axis_i_tready <=
    m_axis_o_tready when (config_port(1 downto 0) = "11") else
    m_axis_o_tready when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    m_axis_i_tready;

  m_axis_o_tdata <=
    s_axis_i_tdata when (config_port(1 downto 0) = "11") else
    s_axis_i_tdata when (config_port(1 downto 0) = "01") else
    (others => '0') when (config_port(1 downto 0) = "10") else
    s_axis_o_tdata;

  m_axis_o_tvalid <=
    s_axis_i_tvalid when (config_port(1 downto 0) = "11") else
    s_axis_i_tvalid when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    s_axis_o_tvalid;

  m_axis_o_tkeep <=
    s_axis_i_tkeep when (config_port(1 downto 0) = "11") else
    s_axis_i_tkeep when (config_port(1 downto 0) = "01") else
    (others => '0') when (config_port(1 downto 0) = "10") else
    s_axis_o_tkeep;

  m_axis_o_tlast <=
    s_axis_i_tlast when (config_port(1 downto 0) = "11") else
    s_axis_i_tlast when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    s_axis_o_tlast;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity MUX_2in1_AXI4_STREAM_vhd is
  port (
    s_axis_0_tready : out std_logic;
    s_axis_0_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_0_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_0_tvalid : in std_logic;
    s_axis_0_tlast  : in std_logic;

    s_axis_1_tready : out std_logic;
    s_axis_1_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_1_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_1_tvalid : in std_logic;
    s_axis_1_tlast  : in std_logic;

    m_axis_tready : in std_logic;
    m_axis_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_tvalid : out std_logic;
    m_axis_tlast  : out std_logic;

    config_port : in std_logic;

    clk : in std_logic
  );
end MUX_2in1_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of MUX_2in1_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  m_axis_tdata <=
    s_axis_0_tdata when (config_port = '0') else
    s_axis_1_tdata;

  m_axis_tvalid <=
    s_axis_0_tvalid when (config_port = '0') else
    s_axis_1_tvalid;

  m_axis_tlast <=
    s_axis_0_tlast when (config_port = '0') else
    s_axis_1_tlast;

  m_axis_tkeep <=
    s_axis_0_tkeep when (config_port = '0') else
    s_axis_1_tkeep;

  s_axis_0_tready <=
    m_axis_tready when (config_port = '0') else
    '0';

  s_axis_1_tready <=
    m_axis_tready when (config_port = '1') else
    '0';
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity MUX_1in2_AXI4_STREAM_vhd is
  port (
    s_axis_tready : out std_logic;
    s_axis_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_tvalid : in std_logic;
    s_axis_tlast  : in std_logic;

    m_axis_0_tready : in std_logic;
    m_axis_0_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_0_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_0_tvalid : out std_logic;
    m_axis_0_tlast  : out std_logic;

    m_axis_1_tready : in std_logic;
    m_axis_1_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_1_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_1_tvalid : out std_logic;
    m_axis_1_tlast  : out std_logic;

    config_port : in std_logic;

    clk : in std_logic
  );
end MUX_1in2_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of MUX_1in2_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  m_axis_0_tdata <=
    s_axis_tdata when (config_port = '0') else
    (others => '0');

  m_axis_0_tvalid <=
    s_axis_tvalid when (config_port = '0') else
    '0';

  m_axis_0_tlast <=
    s_axis_tlast when (config_port = '0') else
    '0';

  m_axis_0_tkeep <=
    s_axis_tkeep when (config_port = '0') else
    (others => '0');

  m_axis_1_tdata <=
    s_axis_tdata when (config_port = '1') else
    (others => '0');

  m_axis_1_tvalid <=
    s_axis_tvalid when (config_port = '1') else
    '0';

  m_axis_1_tlast <=
    s_axis_tlast when (config_port = '1') else
    '0';

  m_axis_1_tkeep <=
    s_axis_tkeep when (config_port = '1') else
    (others => '0');

  s_axis_tready <=
    m_axis_0_tready when (config_port = '0') else
    m_axis_1_tready;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity FORWARD_AXI4_STREAM_vhd is
  port (
    s_axis_tready : out std_logic;
    s_axis_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_tvalid : in std_logic;
    s_axis_tlast  : in std_logic;

    s_axis_dev_tready : out std_logic;
    s_axis_dev_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_dev_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_dev_tvalid : in std_logic;
    s_axis_dev_tlast  : in std_logic;

    m_axis_dev_tready : in std_logic;
    m_axis_dev_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_dev_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_dev_tvalid : out std_logic;
    m_axis_dev_tlast  : out std_logic;

    m_axis_tready : in std_logic;
    m_axis_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_tvalid : out std_logic;
    m_axis_tlast  : out std_logic;

    config_port : in std_logic;
    dev_resetn  : out std_logic;

    clk : in std_logic
  );
end FORWARD_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of FORWARD_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  component MUX_1in2_AXI4_STREAM_vhd is
    port (
      s_axis_tready : out std_logic;
      s_axis_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      s_axis_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      s_axis_tvalid : in std_logic;
      s_axis_tlast  : in std_logic;

      m_axis_0_tready : in std_logic;
      m_axis_0_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      m_axis_0_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      m_axis_0_tvalid : out std_logic;
      m_axis_0_tlast  : out std_logic;

      m_axis_1_tready : in std_logic;
      m_axis_1_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      m_axis_1_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      m_axis_1_tvalid : out std_logic;
      m_axis_1_tlast  : out std_logic;

      config_port : in std_logic;

      clk : in std_logic
    );
  end component MUX_1in2_AXI4_STREAM_vhd;
  ----------------------------------------------------------------------------------
  component MUX_2in1_AXI4_STREAM_vhd is
    port (
      s_axis_0_tready : out std_logic;
      s_axis_0_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      s_axis_0_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      s_axis_0_tvalid : in std_logic;
      s_axis_0_tlast  : in std_logic;

      s_axis_1_tready : out std_logic;
      s_axis_1_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      s_axis_1_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      s_axis_1_tvalid : in std_logic;
      s_axis_1_tlast  : in std_logic;

      m_axis_tready : in std_logic;
      m_axis_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
      m_axis_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
      m_axis_tvalid : out std_logic;
      m_axis_tlast  : out std_logic;

      config_port : in std_logic;

      clk : in std_logic
    );
  end component MUX_2in1_AXI4_STREAM_vhd;
  ----------------------------------------------------------------------------------
  signal axis_1_tready : std_logic                                                   := '0';
  signal axis_1_tdata  : std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00) := (others => '0');
  signal axis_1_tkeep  : std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00)       := (others => '0');
  signal axis_1_tvalid : std_logic                                                   := '0';
  signal axis_1_tlast  : std_logic                                                   := '0';
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  dev_resetn <= not config_port;
  ----------------------------------------------------------------------------------
  u_MUX_1in2_AXI4_STREAM_vhd : MUX_1in2_AXI4_STREAM_vhd
  port map(
    s_axis_tready => s_axis_tready,
    s_axis_tdata  => s_axis_tdata,
    s_axis_tkeep  => s_axis_tkeep,
    s_axis_tvalid => s_axis_tvalid,
    s_axis_tlast  => s_axis_tlast,

    m_axis_0_tready => m_axis_dev_tready,
    m_axis_0_tdata  => m_axis_dev_tdata,
    m_axis_0_tkeep  => m_axis_dev_tkeep,
    m_axis_0_tvalid => m_axis_dev_tvalid,
    m_axis_0_tlast  => m_axis_dev_tlast,

    m_axis_1_tready => axis_1_tready,
    m_axis_1_tdata  => axis_1_tdata,
    m_axis_1_tkeep  => axis_1_tkeep,
    m_axis_1_tvalid => axis_1_tvalid,
    m_axis_1_tlast  => axis_1_tlast,

    config_port => config_port,

    clk => clk
  );
  ----------------------------------------------------------------------------------
  u_MUX_2in1_AXI4_STREAM_vhd : MUX_2in1_AXI4_STREAM_vhd
  port map(
    s_axis_0_tready => s_axis_dev_tready,
    s_axis_0_tdata  => s_axis_dev_tdata,
    s_axis_0_tkeep  => s_axis_dev_tkeep,
    s_axis_0_tvalid => s_axis_dev_tvalid,
    s_axis_0_tlast  => s_axis_dev_tlast,

    s_axis_1_tready => axis_1_tready,
    s_axis_1_tdata  => axis_1_tdata,
    s_axis_1_tkeep  => axis_1_tkeep,
    s_axis_1_tvalid => axis_1_tvalid,
    s_axis_1_tlast  => axis_1_tlast,

    m_axis_tready => m_axis_tready,
    m_axis_tdata  => m_axis_tdata,
    m_axis_tkeep  => m_axis_tkeep,
    m_axis_tvalid => m_axis_tvalid,
    m_axis_tlast  => m_axis_tlast,

    config_port => config_port,

    clk => clk
  );
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity STAT_BIT_AXI4_STREAM_vhd is
  port (
    axis_tready : in std_logic;
    axis_tdata  : in std_logic_vector(07 downto 00);
    axis_tvalid : in std_logic;
    axis_tlast  : in std_logic;

    Bits_Pack_Last : out std_logic_vector(31 downto 00);
    Bits_Pack_MAx  : out std_logic_vector(31 downto 00);
    Bits_Pack_MIn  : out std_logic_vector(31 downto 00);
    Bits_Total     : out std_logic_vector(31 downto 00);
    Packs_Total    : out std_logic_vector(31 downto 00);

    Ticks      : out std_logic_vector(31 downto 00);
    Counter_rd : out std_logic_vector(31 downto 00);

    interrapt_f : out std_logic_vector(07 downto 00);
    -- Counter_rd - 0
    -- Ticks - 1
    -- Bits_Pack_Last - 2
    -- Bits_Total - 3
    -- Packs_Total - 4

    rd_en   : in std_logic;
    aresetn : in std_logic;
    aclk    : in std_logic
  );
end STAT_BIT_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of STAT_BIT_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal s_Bits_Pack_Last_s : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bits_Pack_MAx_s  : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bits_Pack_MIn_s  : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bits_Total_s     : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Packs_Total_s    : std_logic_vector(31 downto 00) := (others => '0');

  signal Ticks_s      : std_logic_vector(31 downto 00) := (others => '0');
  signal Counter_rd_s : std_logic_vector(31 downto 00) := (others => '0');

  signal s_Bits_Pack_Last_o : std_logic_vector(31 downto 00) := (others => '0');

  signal Ticks_o      : std_logic_vector(31 downto 00) := (others => '0');
  signal Counter_rd_o : std_logic_vector(31 downto 00) := (others => '0');

  signal interrapt_f_s : std_logic_vector(07 downto 00) := (others => '0');

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------

  Bits_Pack_Last <= s_Bits_Pack_Last_o;
  Bits_Pack_MAx  <= s_Bits_Pack_MAx_s;
  Bits_Pack_MIn  <= s_Bits_Pack_MIn_s;
  Bits_Total     <= s_Bits_Total_s;
  Packs_Total    <= s_Packs_Total_s;

  Ticks      <= Ticks_s;
  Counter_rd <= Counter_rd_s;

  interrapt_f <= interrapt_f_s;
  ----------------------------------------------------------------------------------
  MAIN_PROCESS :
  process (aclk, aresetn)
  begin
    if (aresetn = '0') then -- reset

      s_Bits_Pack_Last_s <= (others => '0');
      s_Bits_Pack_MAx_s  <= (others => '0');
      s_Bits_Pack_MIn_s  <= (others => '1');
      s_Bits_Total_s     <= (others => '0');
      s_Packs_Total_s    <= (others => '0');

      Ticks_s      <= (others => '0');
      Counter_rd_s <= (others => '0');

      interrapt_f_s(07 downto 00) <= (others => '0');

      s_Bits_Pack_Last_o <= (others => '0');

    elsif (aclk'event and aclk = '1') then -- run
      if (rd_en = '1') then

        if ((axis_tready = '1') and (axis_tvalid = '1')) then

          s_Bits_Pack_MAx_s <= X"00000001";
          s_Bits_Pack_MIn_s <= (others => '1');
          s_Bits_Total_s    <= X"00000001";

          if (axis_tlast = '1') then
            s_Bits_Pack_Last_s <= (others => '0');
            s_Packs_Total_s    <= X"00000001";
            s_Bits_Pack_Last_o <= conv_std_logic_vector(unsigned(s_Bits_Pack_Last_s) + 1, s_Bits_Pack_Last_o'length);
          else
            s_Bits_Pack_Last_s <= unsigned(s_Bits_Pack_Last_s) + 1;
            s_Packs_Total_s    <= (others => '0');
            s_Bits_Pack_Last_o <= s_Bits_Pack_Last_o;
          end if;

        else
          s_Bits_Pack_Last_s <= (others => '0');
          s_Bits_Pack_MAx_s  <= (others => '0');
          s_Bits_Pack_MIn_s  <= (others => '1');
          s_Bits_Total_s     <= (others => '0');
          s_Packs_Total_s    <= (others => '0');
        end if;

        Ticks_s <= (others => '0');
        -- Counter_rd - 0
        -- Ticks - 1
        -- Bits_Pack_Last - 2
        -- Bits_Total - 3
        -- Packs_Total - 4
        if (Counter_rd_s < X"FFFFFFFF") then
          Counter_rd_s      <= unsigned(Counter_rd_s) + 1;
          interrapt_f_s(00) <= '0';
        else
          Counter_rd_s      <= (others => '0');
          interrapt_f_s(00) <= '1';
        end if;

        interrapt_f_s(07 downto 01) <= (others => '0');

      else

        if ((axis_tready = '1') and (axis_tvalid = '1')) then
          -- Counter_rd - 0
          -- Ticks - 1
          -- Bits_Pack_Last - 2
          -- Bits_Total - 3
          -- Packs_Total - 4
          if (s_Bits_Total_s < X"FFFFFFFF") then
            s_Bits_Total_s    <= unsigned(s_Bits_Total_s) + 1;
            interrapt_f_s(03) <= interrapt_f_s(03);
          else
            s_Bits_Total_s    <= (others => '0');
            interrapt_f_s(03) <= '1';
          end if;

          if (axis_tlast = '1') then

            if (s_Bits_Pack_Last_o > s_Bits_Pack_MAx_s) then
              s_Bits_Pack_MAx_s <= s_Bits_Pack_Last_o;
            else
              s_Bits_Pack_MAx_s <= s_Bits_Pack_MAx_s;
            end if;

            if ((s_Bits_Pack_Last_o < s_Bits_Pack_MIn_s) and (unsigned(s_Bits_Pack_Last_o) > 0)) then
              s_Bits_Pack_MIn_s <= s_Bits_Pack_Last_o;
            else
              s_Bits_Pack_MIn_s <= s_Bits_Pack_MIn_s;
            end if;

            s_Bits_Pack_Last_s <= (others => '0');
            s_Bits_Pack_Last_o <= conv_std_logic_vector(unsigned(s_Bits_Pack_Last_s) + 1, s_Bits_Pack_Last_o'length);
            -- Counter_rd - 0
            -- Ticks - 1
            -- Bits_Pack_Last - 2
            -- Bits_Total - 3
            -- Packs_Total - 4
            if (s_Packs_Total_s < X"FFFFFFFF") then
              s_Packs_Total_s   <= unsigned(s_Packs_Total_s) + 1;
              interrapt_f_s(04) <= interrapt_f_s(04);
            else
              s_Packs_Total_s   <= (others => '0');
              interrapt_f_s(04) <= '1';
            end if;

          else
            -- Counter_rd - 0
            -- Ticks - 1
            -- Bits_Pack_Last - 2
            -- Bits_Total - 3
            -- Packs_Total - 4
            if (s_Bits_Pack_Last_s < X"FFFFFFFF") then
              s_Bits_Pack_Last_s <= unsigned(s_Bits_Pack_Last_s) + 1;
              interrapt_f_s(02)  <= interrapt_f_s(02);
              s_Bits_Pack_Last_o <= s_Bits_Pack_Last_o;
            else
              s_Bits_Pack_Last_s <= (others => '0');
              interrapt_f_s(02)  <= '1';
              s_Bits_Pack_Last_o <= s_Bits_Pack_Last_s;
            end if;

            s_Packs_Total_s <= s_Packs_Total_s;

            s_Bits_Pack_MAx_s <= s_Bits_Pack_MAx_s;
            s_Bits_Pack_MIn_s <= s_Bits_Pack_MIn_s;

          end if;

        else
          s_Bits_Pack_Last_s <= s_Bits_Pack_Last_s;
          interrapt_f_s(02)  <= interrapt_f_s(02);
          s_Bits_Pack_MAx_s  <= s_Bits_Pack_MAx_s;
          s_Bits_Pack_MIn_s  <= s_Bits_Pack_MIn_s;
          s_Bits_Total_s     <= s_Bits_Total_s;
          interrapt_f_s(03)  <= interrapt_f_s(03);
          s_Packs_Total_s    <= s_Packs_Total_s;
          interrapt_f_s(04)  <= interrapt_f_s(04);
        end if;

        if (Ticks_s < X"FFFFFFFF") then
          Ticks_s           <= unsigned(Ticks_s) + 1;
          interrapt_f_s(01) <= interrapt_f_s(01);
        else
          Ticks_s           <= (others => '0');
          interrapt_f_s(01) <= '1';
        end if;

        Counter_rd_s <= Counter_rd_s;

        interrapt_f_s(00) <= interrapt_f_s(00);

      end if;
    end if;
  end process MAIN_PROCESS;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity STAT_DELAY_AXI4_STREAM_vhd is
  port (
    s_axis_tready : in std_logic;
    s_axis_tdata  : in std_logic_vector(31 downto 00);
    s_axis_tvalid : in std_logic;
    s_axis_tlast  : in std_logic;

    m_axis_tready : in std_logic;
    m_axis_tdata  : in std_logic_vector(31 downto 00);
    m_axis_tvalid : in std_logic;
    m_axis_tlast  : in std_logic;

    Front_Delay_Ticks : out std_logic_vector(31 downto 00);
    Last_Delay_Ticks  : out std_logic_vector(31 downto 00);

    interrapt_f : out std_logic_vector(01 downto 00);
    -- Front_Delay_Ticks - 0
    -- Last_Delay_Ticks - 1

    aresetn : in std_logic;
    aclk    : in std_logic
  );
end STAT_DELAY_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of STAT_DELAY_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal Front_Delay_Ticks_s : std_logic_vector(31 downto 00) := (others => '0');
  signal Last_Delay_Ticks_s  : std_logic_vector(31 downto 00) := (others => '0');

  signal Front_Delay_start  : std_logic := '0';
  signal Front_Delay_finish : std_logic := '0';

  signal Last_Delay_start  : std_logic := '0';
  signal Last_Delay_finish : std_logic := '0';

  signal interrapt_f_s : std_logic_vector(01 downto 00) := (others => '0');

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  Front_Delay_start <= aresetn when ((s_axis_tready = '1')
    and (s_axis_tvalid = '1')
    and (Front_Delay_start = '0')
    and (aresetn = '1'))
    else (Front_Delay_start and aresetn);
  ----------------------------------------------------------------------------------
  Front_Delay_finish <= aresetn when ((m_axis_tready = '1')
    and (m_axis_tvalid = '1')
    and (Front_Delay_finish = '0')
    and (aresetn = '1'))
    else (Front_Delay_finish and aresetn);
  ----------------------------------------------------------------------------------
  Last_Delay_start <= aresetn when ((s_axis_tready = '1')
    and (s_axis_tvalid = '1')
    and (s_axis_tlast = '1')
    and (Last_Delay_start = '0')
    and (aresetn = '1'))
    else (Last_Delay_start and aresetn);
  ----------------------------------------------------------------------------------
  Last_Delay_finish <= aresetn when ((m_axis_tready = '1')
    and (m_axis_tvalid = '1')
    and (m_axis_tlast = '1')
    and (Last_Delay_finish = '0')
    and (aresetn = '1'))
    else (Last_Delay_finish and aresetn);
  ----------------------------------------------------------------------------------
  Front_Delay_Ticks <= Front_Delay_Ticks_s when ((Front_Delay_start = '1') and (Front_Delay_finish = '1')) else (others => '0');
  Last_Delay_Ticks  <= Last_Delay_Ticks_s when ((Last_Delay_start = '1') and (Last_Delay_finish = '1')) else (others    => '0');
  ----------------------------------------------------------------------------------
  interrapt_f <= interrapt_f_s;
  ----------------------------------------------------------------------------------
  MAIN_PROCESS :
  process (aclk, aresetn)
  begin
    if (aresetn = '0') then -- reset

      Front_Delay_Ticks_s         <= (others => '0');
      Last_Delay_Ticks_s          <= (others => '0');
      interrapt_f_s(01 downto 00) <= (others => '0');

    elsif (aclk'event and aclk = '1') then -- run
      if (Front_Delay_start = '1') then
        if (Front_Delay_finish = '1') then
          Front_Delay_Ticks_s <= Front_Delay_Ticks_s;
          interrapt_f_s(00)   <= interrapt_f_s(00);
        else
          if (Front_Delay_Ticks_s < X"FFFFFFFF") then
            Front_Delay_Ticks_s <= unsigned(Front_Delay_Ticks_s) + 1;
            interrapt_f_s(00)   <= interrapt_f_s(00);
          else
            Front_Delay_Ticks_s <= (others => '0');
            interrapt_f_s(00)   <= '1';
          end if;
        end if;
      else
        Front_Delay_Ticks_s <= (others => '0');
        interrapt_f_s(00)   <= '0';
      end if;

      if (Last_Delay_start = '1') then
        if (Last_Delay_finish = '1') then
          Last_Delay_Ticks_s <= Last_Delay_Ticks_s;
          interrapt_f_s(01)  <= interrapt_f_s(01);
        else
          if (Front_Delay_Ticks_s < X"FFFFFFFF") then
            Last_Delay_Ticks_s <= unsigned(Last_Delay_Ticks_s) + 1;
            interrapt_f_s(01)  <= interrapt_f_s(01);
          else
            Last_Delay_Ticks_s <= (others => '0');
            interrapt_f_s(01)  <= '1';
          end if;
        end if;
      else
        Last_Delay_Ticks_s <= (others => '0');
        interrapt_f_s(01)  <= '0';
      end if;

    end if;
  end process MAIN_PROCESS;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity STAT_BYTE_AXI4_STREAM_vhd is
  port (
    axis_tready : in std_logic;
    axis_tdata  : in std_logic_vector(31 downto 00);
    axis_tkeep  : in std_logic_vector(03 downto 00);
    axis_tvalid : in std_logic;
    axis_tlast  : in std_logic;

    Bytes_Pack_Last : out std_logic_vector(31 downto 00);
    Bytes_Pack_MAx  : out std_logic_vector(31 downto 00);
    Bytes_Pack_MIn  : out std_logic_vector(31 downto 00);
    Bytes_Total     : out std_logic_vector(31 downto 00);
    Packs_Total     : out std_logic_vector(31 downto 00);

    Ticks      : out std_logic_vector(31 downto 00);
    Counter_rd : out std_logic_vector(31 downto 00);

    interrapt_f : out std_logic_vector(07 downto 00);
    -- Counter_rd - 0
    -- Ticks - 1
    -- Bytes_Pack_Last - 2
    -- Bytes_Total - 3
    -- Packs_Total - 4
    -- err_keep - 5

    rd_en   : in std_logic;
    aresetn : in std_logic;
    aclk    : in std_logic
  );
end STAT_BYTE_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of STAT_BYTE_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal s_Bytes_Pack_Last_s : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bytes_Pack_MAx_s  : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bytes_Pack_MIn_s  : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Bytes_Total_s     : std_logic_vector(31 downto 00) := (others => '0');
  signal s_Packs_Total_s     : std_logic_vector(31 downto 00) := (others => '0');

  signal Ticks_s      : std_logic_vector(31 downto 00) := (others => '0');
  signal Counter_rd_s : std_logic_vector(31 downto 00) := (others => '0');

  signal s_Bytes_Pack_Last_o : std_logic_vector(31 downto 00) := (others => '0');

  signal Ticks_o      : std_logic_vector(31 downto 00) := (others => '0');
  signal Counter_rd_o : std_logic_vector(31 downto 00) := (others => '0');

  signal interrapt_f_s : std_logic_vector(07 downto 00) := (others => '0');

  signal num_bytes  : std_logic_vector(03 downto 00) := (others => '0');
  signal err_keep_s : std_logic                      := '0';
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  Bytes_Pack_Last <= s_Bytes_Pack_Last_o;
  Bytes_Pack_MAx  <= s_Bytes_Pack_MAx_s;
  Bytes_Pack_MIn  <= s_Bytes_Pack_MIn_s;
  Bytes_Total     <= s_Bytes_Total_s;
  Packs_Total     <= s_Packs_Total_s;

  Ticks      <= Ticks_s;
  Counter_rd <= Counter_rd_s;

  interrapt_f <= interrapt_f_s;

  with axis_tkeep select
    num_bytes <= X"0" when "0000",
    X"1"when "0001" | "0010" | "0100" | "1000",
    X"2"when "0011" | "0110" | "1100" | "1001" | "0101" | "1010",
    X"3"when "0111" | "1110" | "1101" | "1011",
    X"4"when "1111",
    X"0" when others;

  with axis_tkeep select
    err_keep_s <= '0' when "0000" | "0001" | "0011" | "0111" | "1111",
    '1' when others;
  ----------------------------------------------------------------------------------
  MAIN_PROCESS :
  process (aclk, aresetn)
  begin
    if (aresetn = '0') then -- reset

      s_Bytes_Pack_Last_s <= (others => '0');
      s_Bytes_Pack_MAx_s  <= (others => '0');
      s_Bytes_Pack_MIn_s  <= (others => '1');
      s_Bytes_Total_s     <= (others => '0');
      s_Packs_Total_s     <= (others => '0');

      Ticks_s      <= (others => '0');
      Counter_rd_s <= (others => '0');

      interrapt_f_s(07 downto 00) <= (others => '0');

      s_Bytes_Pack_Last_o <= (others => '0');

    elsif (aclk'event and aclk = '1') then -- run
      if (rd_en = '1') then

        s_Bytes_Pack_MAx_s <= (others => '0');
        s_Bytes_Pack_MIn_s <= (others => '1');

        if ((axis_tready = '1') and (axis_tvalid = '1')) then

          s_Bytes_Total_s(03 downto 00) <= num_bytes;

          if (axis_tlast = '1') then
            s_Bytes_Pack_Last_s           <= (others => '0');
            s_Packs_Total_s               <= X"00000001";

            -- Counter_rd - 0
            -- Ticks - 1
            -- Bytes_Pack_Last - 2
            -- Bytes_Total - 3
            -- Packs_Total - 4
            -- err_keep - 5

            if (s_Bytes_Pack_Last_s < X"FFFFFFFF") then
              s_Bytes_Pack_Last_o <= conv_std_logic_vector(unsigned(s_Bytes_Pack_Last_s) + 1, s_Bytes_Pack_Last_o'length);
              interrapt_f_s(02)   <= '1';
            else
              s_Bytes_Pack_Last_o <= s_Bytes_Pack_Last_s;
              interrapt_f_s(02)   <= '0';
            end if;

          else
            s_Bytes_Pack_Last_s <= unsigned(s_Bytes_Pack_Last_s) + unsigned(num_bytes);
            s_Packs_Total_s     <= (others => '0');
            s_Bytes_Pack_Last_o <= s_Bytes_Pack_Last_o;
            interrapt_f_s(02)   <= '0';
          end if;

        else
          s_Bytes_Pack_Last_s <= (others => '0');
          s_Bytes_Total_s     <= (others => '0');
          s_Packs_Total_s     <= (others => '0');
          interrapt_f_s(02)   <= '0';
        end if;

        Ticks_s <= (others => '0');
        -- Counter_rd - 0
        -- Ticks - 1
        -- Bytes_Pack_Last - 2
        -- Bytes_Total - 3
        -- Packs_Total - 4
        -- err_keep - 5

        if (Counter_rd_s < X"FFFFFFFF") then
          Counter_rd_s      <= unsigned(Counter_rd_s) + 1;
          interrapt_f_s(00) <= '0';
        else
          Counter_rd_s      <= (others => '0');
          interrapt_f_s(00) <= '1';
        end if;
        -- Counter_rd - 0
        -- Ticks - 1
        -- Bytes_Pack_Last - 2
        -- Bytes_Total - 3
        -- Packs_Total - 4
        -- err_keep - 5

        interrapt_f_s(07 downto 03) <= (others => '0');
        interrapt_f_s(01)           <= '0';

      else

        if ((axis_tready = '1') and (axis_tvalid = '1')) then
          -- Counter_rd - 0
          -- Ticks - 1
          -- Bytes_Pack_Last - 2
          -- Bytes_Total - 3
          -- Packs_Total - 4
          -- err_keep - 5

          if (conv_std_logic_vector(unsigned(s_Bytes_Total_s) + unsigned(num_bytes), s_Bytes_Total_s'length + 1) < X"FFFFFFFF") then
            s_Bytes_Total_s   <= unsigned(s_Bytes_Total_s) + unsigned(num_bytes);
            interrapt_f_s(03) <= interrapt_f_s(03);
          else
            s_Bytes_Total_s   <= unsigned(s_Bytes_Total_s) + unsigned(num_bytes);
            interrapt_f_s(03) <= '1';
          end if;

          if (axis_tlast = '1') then
            -- Counter_rd - 0
            -- Ticks - 1
            -- Bytes_Pack_Last - 2
            -- Bytes_Total - 3
            -- Packs_Total - 4
            -- err_keep - 5

            if (s_Bytes_Pack_Last_o > s_Bytes_Pack_MAx_s) then
              s_Bytes_Pack_MAx_s <= s_Bytes_Pack_Last_o;
            else
              s_Bytes_Pack_MAx_s <= s_Bytes_Pack_MAx_s;
            end if;

            if ((s_Bytes_Pack_Last_o < s_Bytes_Pack_MIn_s) and (unsigned(s_Bytes_Pack_Last_o) > 0)) then
              s_Bytes_Pack_MIn_s <= s_Bytes_Pack_Last_o;
            else
              s_Bytes_Pack_MIn_s <= s_Bytes_Pack_MIn_s;
            end if;

            if (s_Bytes_Pack_Last_s < X"FFFFFFFF") then
              s_Bytes_Pack_Last_s <= (others => '0');
              interrapt_f_s(02)   <= interrapt_f_s(02);
              s_Bytes_Pack_Last_o <= conv_std_logic_vector(unsigned(s_Bytes_Pack_Last_s) + 1, s_Bytes_Pack_Last_o'length);
            else
              s_Bytes_Pack_Last_s <= unsigned(s_Bytes_Pack_Last_s) + unsigned(num_bytes);
              interrapt_f_s(02)   <= '1';
              s_Bytes_Pack_Last_o <= s_Bytes_Pack_Last_s;
            end if;
            -- Counter_rd - 0
            -- Ticks - 1
            -- Bytes_Pack_Last - 2
            -- Bytes_Total - 3
            -- Packs_Total - 4
            -- err_keep - 5

            if (s_Packs_Total_s < X"FFFFFFFF") then
              s_Packs_Total_s   <= unsigned(s_Packs_Total_s) + 1;
              interrapt_f_s(04) <= interrapt_f_s(04);
            else
              s_Packs_Total_s   <= (others => '0');
              interrapt_f_s(04) <= '1';
            end if;

          else
            -- Counter_rd - 0
            -- Ticks - 1
            -- Bytes_Pack_Last - 2
            -- Bytes_Total - 3
            -- Packs_Total - 4
            -- err_keep - 5

            if (s_Bytes_Pack_Last_s < X"FFFFFFFF") then
              s_Bytes_Pack_Last_s <= unsigned(s_Bytes_Pack_Last_s) + 1;
              interrapt_f_s(02)   <= interrapt_f_s(02);
              s_Bytes_Pack_Last_o <= s_Bytes_Pack_Last_o;
            else
              s_Bytes_Pack_Last_s <= (others => '0');
              interrapt_f_s(02)   <= '1';
              s_Bytes_Pack_Last_o <= s_Bytes_Pack_Last_s;
            end if;

            s_Packs_Total_s <= s_Packs_Total_s;

            s_Bytes_Pack_MAx_s <= s_Bytes_Pack_MAx_s;
            s_Bytes_Pack_MIn_s <= s_Bytes_Pack_MIn_s;

          end if;

        else

          -- Counter_rd - 0
          -- Ticks - 1
          -- Bytes_Pack_Last - 2
          -- Bytes_Total - 3
          -- Packs_Total - 4
          -- err_keep - 5
          s_Bytes_Pack_Last_s <= s_Bytes_Pack_Last_s;
          interrapt_f_s(02)   <= interrapt_f_s(02);
          s_Bytes_Pack_MAx_s  <= s_Bytes_Pack_MAx_s;
          s_Bytes_Pack_MIn_s  <= s_Bytes_Pack_MIn_s;
          s_Bytes_Total_s     <= s_Bytes_Total_s;
          interrapt_f_s(03)   <= interrapt_f_s(03);
          s_Packs_Total_s     <= s_Packs_Total_s;
          interrapt_f_s(04)   <= interrapt_f_s(04);
        end if;
        -- Counter_rd - 0
        -- Ticks - 1
        -- Bytes_Pack_Last - 2
        -- Bytes_Total - 3
        -- Packs_Total - 4
        -- err_keep - 5

        if (Ticks_s < X"FFFFFFFF") then
          Ticks_s           <= unsigned(Ticks_s) + 1;
          interrapt_f_s(01) <= interrapt_f_s(01);
        else
          Ticks_s           <= (others => '0');
          interrapt_f_s(01) <= '1';
        end if;

        Counter_rd_s <= Counter_rd_s;
        -- Counter_rd - 0
        -- Ticks - 1
        -- Bytes_Pack_Last - 2
        -- Bytes_Total - 3
        -- Packs_Total - 4
        -- err_keep - 5

        interrapt_f_s(00) <= interrapt_f_s(00);

      end if;
    end if;
  end process MAIN_PROCESS;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
entity LOOP_AXI4_STREAM_vhd is
  port (
    s_axis_i_tready : out std_logic;
    s_axis_i_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_i_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_i_tvalid : in std_logic;
    s_axis_i_tlast  : in std_logic;

    m_axis_i_tready : in std_logic;
    m_axis_i_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_i_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_i_tvalid : out std_logic;
    m_axis_i_tlast  : out std_logic;

    s_axis_o_tready : out std_logic;
    s_axis_o_tdata  : in std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    s_axis_o_tkeep  : in std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    s_axis_o_tvalid : in std_logic;
    s_axis_o_tlast  : in std_logic;

    m_axis_o_tready : in std_logic;
    m_axis_o_tdata  : out std_logic_vector((((((32 - 1) /8) + 1) * 8) - 1) downto 00);
    m_axis_o_tkeep  : out std_logic_vector(((((32 - 1) /8) + 1) - 1) downto 00);
    m_axis_o_tvalid : out std_logic;
    m_axis_o_tlast  : out std_logic;

    config_port : in std_logic_vector(01 downto 00);
    clk         : in std_logic
  );
end LOOP_AXI4_STREAM_vhd;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of LOOP_AXI4_STREAM_vhd is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  m_axis_i_tdata <=
    s_axis_o_tdata when (config_port(1 downto 0) = "11") else
    (others => '0') when (config_port(1 downto 0) = "01") else
    s_axis_o_tdata when (config_port(1 downto 0) = "10") else
    s_axis_i_tdata;

  m_axis_i_tvalid <=
    s_axis_o_tvalid when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    s_axis_o_tvalid when (config_port(1 downto 0) = "10") else
    s_axis_i_tvalid;

  m_axis_i_tlast <=
    s_axis_o_tlast when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    s_axis_o_tlast when (config_port(1 downto 0) = "10") else
    s_axis_i_tlast;

  m_axis_i_tkeep <=
    s_axis_o_tkeep when (config_port(1 downto 0) = "11") else
    (others => '0') when (config_port(1 downto 0) = "01") else
    s_axis_o_tkeep when (config_port(1 downto 0) = "10") else
    s_axis_i_tkeep;

  s_axis_o_tready <=
    m_axis_i_tready when (config_port(1 downto 0) = "11") else
    '0' when (config_port(1 downto 0) = "01") else
    m_axis_i_tready when (config_port(1 downto 0) = "10") else
    m_axis_o_tready;

  s_axis_i_tready <=
    m_axis_o_tready when (config_port(1 downto 0) = "11") else
    m_axis_o_tready when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    m_axis_i_tready;

  m_axis_o_tdata <=
    s_axis_i_tdata when (config_port(1 downto 0) = "11") else
    s_axis_i_tdata when (config_port(1 downto 0) = "01") else
    (others => '0') when (config_port(1 downto 0) = "10") else
    s_axis_o_tdata;

  m_axis_o_tvalid <=
    s_axis_i_tvalid when (config_port(1 downto 0) = "11") else
    s_axis_i_tvalid when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    s_axis_o_tvalid;

  m_axis_o_tkeep <=
    s_axis_i_tkeep when (config_port(1 downto 0) = "11") else
    s_axis_i_tkeep when (config_port(1 downto 0) = "01") else
    (others => '0') when (config_port(1 downto 0) = "10") else
    s_axis_o_tkeep;

  m_axis_o_tlast <=
    s_axis_i_tlast when (config_port(1 downto 0) = "11") else
    s_axis_i_tlast when (config_port(1 downto 0) = "01") else
    '0' when (config_port(1 downto 0) = "10") else
    s_axis_o_tlast;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------