----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
entity axis_retention is port (
  s_axis_tready : out std_logic;
  s_axis_tdata : in std_logic_vector (07 downto 00);
  s_axis_tvalid : in std_logic;
  s_axis_tlast : in std_logic;

  delay_setup : in std_logic_vector(07 downto 00);
  aresetn : in std_logic;
  aclk : in std_logic;

  m_axis_tready : in std_logic;
  m_axis_tdata : out std_logic_vector(07 downto 00);
  m_axis_tvalid : out std_logic;
  m_axis_tlast : out std_logic
);
end axis_retention;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of axis_retention is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal cnt : std_logic_vector(07 downto 00);
  signal delay_setup_reg : std_logic_vector(07 downto 00);

  signal s_axis_tready_reg : std_logic;

  signal m_axis_tdata_reg : std_logic_vector(07 downto 00);
  signal m_axis_tvalid_reg : std_logic;
  signal m_axis_tlast_reg : std_logic;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  s_axis_tready <= s_axis_tready_reg;
  m_axis_tdata <= m_axis_tdata_reg;
  m_axis_tvalid <= m_axis_tvalid_reg;
  m_axis_tlast <= m_axis_tlast_reg;
  ----------------------------------------------------------------------------------
  main_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      cnt <= (others => '0');
      delay_setup_reg <= (others => '0');

      m_axis_tdata_reg <= (others => '0');
      m_axis_tvalid_reg <= '0';
      m_axis_tlast_reg <= '0';

      s_axis_tready_reg <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if ((m_axis_tready = '1') or (m_axis_tvalid_reg = '0')) then
        if ((unsigned(cnt) = 0) and ((s_axis_tvalid = '1') and (s_axis_tready_reg = '1'))) then
          if (unsigned(delay_setup) = 0) then
            cnt <= (others => '0');
            delay_setup_reg <= (others => '0');

            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tvalid_reg <= s_axis_tvalid;
            m_axis_tlast_reg <= s_axis_tlast;

            s_axis_tready_reg <= m_axis_tready;

          else
            cnt <= unsigned(cnt) + 1;
            delay_setup_reg <= delay_setup;

            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tvalid_reg <= s_axis_tvalid;
            m_axis_tlast_reg <= s_axis_tlast;

            s_axis_tready_reg <= '0';

          end if;
        elsif ((unsigned(cnt) < unsigned(delay_setup_reg))) then
          cnt <= unsigned(cnt) + 1;
          delay_setup_reg <= delay_setup_reg;

          m_axis_tdata_reg <= m_axis_tdata_reg;
          m_axis_tvalid_reg <= m_axis_tvalid_reg;
          m_axis_tlast_reg <= m_axis_tlast_reg;

          s_axis_tready_reg <= '0';

        else
          cnt <= (others => '0');
          delay_setup_reg <= (others => '0');

          m_axis_tdata_reg <= m_axis_tdata_reg;
          m_axis_tvalid_reg <= m_axis_tvalid_reg;
          m_axis_tlast_reg <= m_axis_tlast_reg;

          s_axis_tready_reg <= m_axis_tready;

        end if;
      elsif (s_axis_tready_reg = '1') then
        if ((unsigned(cnt) = 0) and (s_axis_tvalid = '1')) then
          if (unsigned(delay_setup) = 0) then
            cnt <= (others => '0');
            delay_setup_reg <= (others => '0');

            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tvalid_reg <= s_axis_tvalid;
            m_axis_tlast_reg <= s_axis_tlast;

            s_axis_tready_reg <= m_axis_tready;

          else
            cnt <= unsigned(cnt) + 1;
            delay_setup_reg <= delay_setup;

            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tvalid_reg <= s_axis_tvalid;
            m_axis_tlast_reg <= s_axis_tlast;

            s_axis_tready_reg <= '0';

          end if;
        elsif ((unsigned(cnt) < unsigned(delay_setup_reg))) then
          cnt <= unsigned(cnt) + 1;
          delay_setup_reg <= delay_setup_reg;

          m_axis_tdata_reg <= m_axis_tdata_reg;
          m_axis_tvalid_reg <= m_axis_tvalid_reg;
          m_axis_tlast_reg <= m_axis_tlast_reg;

          s_axis_tready_reg <= '0';

        else
          cnt <= (others => '0');
          delay_setup_reg <= (others => '0');

          m_axis_tdata_reg <= m_axis_tdata_reg;
          m_axis_tvalid_reg <= m_axis_tvalid_reg;
          m_axis_tlast_reg <= m_axis_tlast_reg;

          s_axis_tready_reg <= m_axis_tready;

        end if;
      else
        cnt <= cnt;
        delay_setup_reg <= delay_setup_reg;

        m_axis_tdata_reg <= m_axis_tdata_reg;
        m_axis_tvalid_reg <= m_axis_tvalid_reg;
        m_axis_tlast_reg <= m_axis_tlast_reg;

        s_axis_tready_reg <= s_axis_tready_reg;

      end if;
    end if;
  end process main_proc;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
entity axis_t_trigger is port (
  s_axis_tready : out std_logic;
  s_axis_tdata : in std_logic_vector (15 downto 00);
  s_axis_tvalid : in std_logic;
  s_axis_tlast : in std_logic;

  aresetn : in std_logic;
  aclk : in std_logic;

  m_axis_tready : in std_logic;
  m_axis_tdata : out std_logic_vector(15 downto 00);
  m_axis_tvalid : out std_logic;
  m_axis_tlast : out std_logic
);
end axis_t_trigger;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of axis_t_trigger is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal ready : std_logic;
  ----------------------------------------------------------------------------------
  signal s_axis_tready_reg : std_logic;

  signal m_axis_tdata_reg : std_logic_vector(15 downto 00);
  signal m_axis_tvalid_reg : std_logic;
  signal m_axis_tlast_reg : std_logic;
  ----------------------------------------------------------------------------------
  signal tdata_reg0 : std_logic_vector(15 downto 00);
  signal tvalid_reg0 : std_logic;
  signal tlast_reg0 : std_logic;

  signal tdata_reg1 : std_logic_vector(15 downto 00);
  signal tvalid_reg1 : std_logic;
  signal tlast_reg1 : std_logic;

  signal tdata_reg2 : std_logic_vector(15 downto 00);
  signal tvalid_reg2 : std_logic;
  signal tlast_reg2 : std_logic;

  signal tdata_reg3 : std_logic_vector(15 downto 00);
  signal tvalid_reg3 : std_logic;
  signal tlast_reg3 : std_logic;

  signal tdata_reg4 : std_logic_vector(15 downto 00);
  signal tvalid_reg4 : std_logic;
  signal tlast_reg4 : std_logic;

  signal tdata_reg5 : std_logic_vector(15 downto 00);
  signal tvalid_reg5 : std_logic;
  signal tlast_reg5 : std_logic;

  signal tdata_reg6 : std_logic_vector(15 downto 00);
  signal tvalid_reg6 : std_logic;
  signal tlast_reg6 : std_logic;

  signal tdata_reg7 : std_logic_vector(15 downto 00);
  signal tvalid_reg7 : std_logic;
  signal tlast_reg7 : std_logic;

  signal tdata_reg8 : std_logic_vector(15 downto 00);
  signal tvalid_reg8 : std_logic;
  signal tlast_reg8 : std_logic;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  s_axis_tready <= s_axis_tready_reg;
  s_axis_tready_reg <= m_axis_tready or (not m_axis_tvalid_reg);

  ready <= m_axis_tready or (not m_axis_tvalid_reg);

  m_axis_tdata <= m_axis_tdata_reg;
  m_axis_tvalid <= m_axis_tvalid_reg;
  m_axis_tlast <= m_axis_tlast_reg;
  ----------------------------------------------------------------------------------
  main_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      m_axis_tdata_reg <= (others => '0');
      m_axis_tvalid_reg <= '0';
      m_axis_tlast_reg <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if (ready = '1') then
        if (tvalid_reg0 = '1') then
          m_axis_tdata_reg <= tdata_reg0;
          m_axis_tvalid_reg <= tvalid_reg0;
          m_axis_tlast_reg <= tlast_reg0;
        else
          m_axis_tdata_reg <= (others => '0');
          m_axis_tvalid_reg <= '0';
          m_axis_tlast_reg <= '0';

        end if;

      else
        m_axis_tdata_reg <= m_axis_tdata_reg;
        m_axis_tvalid_reg <= m_axis_tvalid_reg;
        m_axis_tlast_reg <= m_axis_tlast_reg;

      end if;
    end if;
  end process main_proc;
  ----------------------------------------------------------------------------------
  regs_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      tdata_reg0 <= (others => '0');
      tvalid_reg0 <= '0';
      tlast_reg0 <= '0';

      tdata_reg1 <= (others => '0');
      tvalid_reg1 <= '0';
      tlast_reg1 <= '0';

      tdata_reg2 <= (others => '0');
      tvalid_reg2 <= '0';
      tlast_reg2 <= '0';

      tdata_reg3 <= (others => '0');
      tvalid_reg3 <= '0';
      tlast_reg3 <= '0';

      tdata_reg4 <= (others => '0');
      tvalid_reg4 <= '0';
      tlast_reg4 <= '0';

      tdata_reg5 <= (others => '0');
      tvalid_reg5 <= '0';
      tlast_reg5 <= '0';

      tdata_reg6 <= (others => '0');
      tvalid_reg6 <= '0';
      tlast_reg6 <= '0';

      tdata_reg7 <= (others => '0');
      tvalid_reg7 <= '0';
      tlast_reg7 <= '0';

      tdata_reg8 <= (others => '0');
      tvalid_reg8 <= '0';
      tlast_reg8 <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if (ready = '1') then
        tdata_reg0 <= tdata_reg1;
        tvalid_reg0 <= tvalid_reg1;
        tlast_reg0 <= tlast_reg1;

        tdata_reg1 <= tdata_reg2;
        tvalid_reg1 <= tvalid_reg2;
        tlast_reg1 <= tlast_reg2;

        tdata_reg2 <= tdata_reg3;
        tvalid_reg2 <= tvalid_reg3;
        tlast_reg2 <= tlast_reg3;

        tdata_reg3 <= tdata_reg4;
        tvalid_reg3 <= tvalid_reg4;
        tlast_reg3 <= tlast_reg4;

        tdata_reg4 <= tdata_reg5;
        tvalid_reg4 <= tvalid_reg5;
        tlast_reg4 <= tlast_reg5;

        tdata_reg5 <= tdata_reg6;
        tvalid_reg5 <= tvalid_reg6;
        tlast_reg5 <= tlast_reg6;

        --			tdata_reg6 <= tdata_reg7;
        --			tvalid_reg6 <= tvalid_reg7;
        --			tlast_reg6 <= tlast_reg7;

        if (s_axis_tvalid = '1') then
          tdata_reg6 <= s_axis_tdata;
          tvalid_reg6 <= s_axis_tvalid;
          tlast_reg6 <= s_axis_tlast;

        else
          tdata_reg6 <= (others => '0');
          tvalid_reg6 <= '0';
          tlast_reg6 <= '0';

        end if;

        tdata_reg7 <= tdata_reg8;
        tvalid_reg7 <= tvalid_reg8;
        tlast_reg7 <= tlast_reg8;

        --			tdata_reg7 <= s_axis_tdata;
        --			tvalid_reg7 <= s_axis_tvalid;
        --			tlast_reg7 <= s_axis_tlast;

        if (s_axis_tvalid = '1') then
          tdata_reg8 <= s_axis_tdata;
          tvalid_reg8 <= s_axis_tvalid;
          tlast_reg8 <= s_axis_tlast;

        else
          tdata_reg8 <= (others => '0');
          tvalid_reg8 <= '0';
          tlast_reg8 <= '0';

        end if;

      else
        tdata_reg0 <= tdata_reg0;
        tvalid_reg0 <= tvalid_reg0;
        tlast_reg0 <= tlast_reg0;

        tdata_reg1 <= tdata_reg1;
        tvalid_reg1 <= tvalid_reg1;
        tlast_reg1 <= tlast_reg1;

        tdata_reg2 <= tdata_reg2;
        tvalid_reg2 <= tvalid_reg2;
        tlast_reg2 <= tlast_reg2;

        tdata_reg3 <= tdata_reg3;
        tvalid_reg3 <= tvalid_reg3;
        tlast_reg3 <= tlast_reg3;

        tdata_reg4 <= tdata_reg4;
        tvalid_reg4 <= tvalid_reg4;
        tlast_reg4 <= tlast_reg4;

        tdata_reg5 <= tdata_reg5;
        tvalid_reg5 <= tvalid_reg5;
        tlast_reg5 <= tlast_reg5;

        tdata_reg6 <= tdata_reg6;
        tvalid_reg6 <= tvalid_reg6;
        tlast_reg6 <= tlast_reg6;

        tdata_reg7 <= tdata_reg7;
        tvalid_reg7 <= tvalid_reg7;
        tlast_reg7 <= tlast_reg7;

        tdata_reg8 <= tdata_reg8;
        tvalid_reg8 <= tvalid_reg8;
        tlast_reg8 <= tlast_reg8;

      end if;
    end if;
  end process regs_proc;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
entity axis_t_trigger_special is port (
  s_axis_tready : out std_logic;
  s_axis_tdata : in std_logic_vector (15 downto 00);
  s_axis_tvalid : in std_logic;
  s_axis_tlast : in std_logic;

  clk_ce : in std_logic;
  aresetn : in std_logic;
  aclk : in std_logic;

  m_axis_tready : in std_logic;
  m_axis_tdata : out std_logic_vector(15 downto 00);
  m_axis_tvalid : out std_logic;
  m_axis_tlast : out std_logic
);
end axis_t_trigger_special;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of axis_t_trigger_special is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal s_axis_tready_reg : std_logic;

  signal m_axis_tdata_reg : std_logic_vector(15 downto 00);
  signal m_axis_tvalid_reg : std_logic;
  signal m_axis_tlast_reg : std_logic;
  ----------------------------------------------------------------------------------
  signal tdata_reg0 : std_logic_vector(15 downto 00);
  signal tvalid_reg0 : std_logic;
  signal tlast_reg0 : std_logic;

  signal tdata_reg1 : std_logic_vector(15 downto 00);
  signal tvalid_reg1 : std_logic;
  signal tlast_reg1 : std_logic;

  signal tdata_reg2 : std_logic_vector(15 downto 00);
  signal tvalid_reg2 : std_logic;
  signal tlast_reg2 : std_logic;

  signal tdata_reg3 : std_logic_vector(15 downto 00);
  signal tvalid_reg3 : std_logic;
  signal tlast_reg3 : std_logic;

  signal tdata_reg4 : std_logic_vector(15 downto 00);
  signal tvalid_reg4 : std_logic;
  signal tlast_reg4 : std_logic;

  signal tdata_reg5 : std_logic_vector(15 downto 00);
  signal tvalid_reg5 : std_logic;
  signal tlast_reg5 : std_logic;

  signal tdata_reg6 : std_logic_vector(15 downto 00);
  signal tvalid_reg6 : std_logic;
  signal tlast_reg6 : std_logic;

  signal tdata_reg7 : std_logic_vector(15 downto 00);
  signal tvalid_reg7 : std_logic;
  signal tlast_reg7 : std_logic;

  signal tdata_reg8 : std_logic_vector(15 downto 00);
  signal tvalid_reg8 : std_logic;
  signal tlast_reg8 : std_logic;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  s_axis_tready <= s_axis_tready_reg;
  s_axis_tready_reg <= m_axis_tready or (not m_axis_tvalid_reg);

  m_axis_tdata <= m_axis_tdata_reg;
  m_axis_tvalid <= m_axis_tvalid_reg;
  m_axis_tlast <= m_axis_tlast_reg;
  ----------------------------------------------------------------------------------
  main_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      m_axis_tdata_reg <= (others => '0');
      m_axis_tvalid_reg <= '0';
      m_axis_tlast_reg <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if (clk_ce = '1') then
        if (tvalid_reg0 = '1') then
          m_axis_tdata_reg <= tdata_reg0;
          m_axis_tvalid_reg <= tvalid_reg0;
          m_axis_tlast_reg <= tlast_reg0;
        else
          m_axis_tdata_reg <= (others => '0');
          m_axis_tvalid_reg <= '0';
          m_axis_tlast_reg <= '0';

        end if;

      elsif (m_axis_tready = '1') then
        m_axis_tdata_reg <= (others => '0');
        m_axis_tvalid_reg <= '0';
        m_axis_tlast_reg <= '0';

      else
        m_axis_tdata_reg <= m_axis_tdata_reg;
        m_axis_tvalid_reg <= m_axis_tvalid_reg;
        m_axis_tlast_reg <= m_axis_tlast_reg;

      end if;
    end if;
  end process main_proc;
  ----------------------------------------------------------------------------------
  regs_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      tdata_reg0 <= (others => '0');
      tvalid_reg0 <= '0';
      tlast_reg0 <= '0';

      tdata_reg1 <= (others => '0');
      tvalid_reg1 <= '0';
      tlast_reg1 <= '0';

      tdata_reg2 <= (others => '0');
      tvalid_reg2 <= '0';
      tlast_reg2 <= '0';

      tdata_reg3 <= (others => '0');
      tvalid_reg3 <= '0';
      tlast_reg3 <= '0';

      tdata_reg4 <= (others => '0');
      tvalid_reg4 <= '0';
      tlast_reg4 <= '0';

      tdata_reg5 <= (others => '0');
      tvalid_reg5 <= '0';
      tlast_reg5 <= '0';

      tdata_reg6 <= (others => '0');
      tvalid_reg6 <= '0';
      tlast_reg6 <= '0';

      tdata_reg7 <= (others => '0');
      tvalid_reg7 <= '0';
      tlast_reg7 <= '0';

      tdata_reg8 <= (others => '0');
      tvalid_reg8 <= '0';
      tlast_reg8 <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if (clk_ce = '1') then
        tdata_reg0 <= tdata_reg1;
        tvalid_reg0 <= tvalid_reg1;
        tlast_reg0 <= tlast_reg1;

        tdata_reg1 <= tdata_reg2;
        tvalid_reg1 <= tvalid_reg2;
        tlast_reg1 <= tlast_reg2;

        tdata_reg2 <= tdata_reg3;
        tvalid_reg2 <= tvalid_reg3;
        tlast_reg2 <= tlast_reg3;

        tdata_reg3 <= tdata_reg4;
        tvalid_reg3 <= tvalid_reg4;
        tlast_reg3 <= tlast_reg4;

        tdata_reg4 <= tdata_reg5;
        tvalid_reg4 <= tvalid_reg5;
        tlast_reg4 <= tlast_reg5;

        tdata_reg5 <= tdata_reg6;
        tvalid_reg5 <= tvalid_reg6;
        tlast_reg5 <= tlast_reg6;

        --			tdata_reg6 <= tdata_reg7;
        --			tvalid_reg6 <= tvalid_reg7;
        --			tlast_reg6 <= tlast_reg7;

        tdata_reg6 <= s_axis_tdata;
        tvalid_reg6 <= s_axis_tvalid;
        tlast_reg6 <= s_axis_tlast;

        tdata_reg7 <= tdata_reg8;
        tvalid_reg7 <= tvalid_reg8;
        tlast_reg7 <= tlast_reg8;

        --			tdata_reg7 <= s_axis_tdata;
        --			tvalid_reg7 <= s_axis_tvalid;
        --			tlast_reg7 <= s_axis_tlast;

        tdata_reg8 <= s_axis_tdata;
        tvalid_reg8 <= s_axis_tvalid;
        tlast_reg8 <= s_axis_tlast;

      else
        tdata_reg0 <= tdata_reg0;
        tvalid_reg0 <= tvalid_reg0;
        tlast_reg0 <= tlast_reg0;

        tdata_reg1 <= tdata_reg1;
        tvalid_reg1 <= tvalid_reg1;
        tlast_reg1 <= tlast_reg1;

        tdata_reg2 <= tdata_reg2;
        tvalid_reg2 <= tvalid_reg2;
        tlast_reg2 <= tlast_reg2;

        tdata_reg3 <= tdata_reg3;
        tvalid_reg3 <= tvalid_reg3;
        tlast_reg3 <= tlast_reg3;

        tdata_reg4 <= tdata_reg4;
        tvalid_reg4 <= tvalid_reg4;
        tlast_reg4 <= tlast_reg4;

        tdata_reg5 <= tdata_reg5;
        tvalid_reg5 <= tvalid_reg5;
        tlast_reg5 <= tlast_reg5;

        tdata_reg6 <= tdata_reg6;
        tvalid_reg6 <= tvalid_reg6;
        tlast_reg6 <= tlast_reg6;

        tdata_reg7 <= tdata_reg7;
        tvalid_reg7 <= tvalid_reg7;
        tlast_reg7 <= tlast_reg7;

        tdata_reg8 <= tdata_reg8;
        tvalid_reg8 <= tvalid_reg8;
        tlast_reg8 <= tlast_reg8;

      end if;
    end if;
  end process regs_proc;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
entity axis_retention_special is port (
  s_axis_tready : out std_logic;
  s_axis_tdata : in std_logic_vector (07 downto 00);
  s_axis_tvalid : in std_logic;
  s_axis_tlast : in std_logic;

  clk_en : in std_logic;
  delay_setup : in std_logic_vector(07 downto 00);
  aresetn : in std_logic;
  aclk : in std_logic;

  m_axis_tready : in std_logic;
  m_axis_tdata : out std_logic_vector(07 downto 00);
  m_axis_tvalid : out std_logic;
  m_axis_tlast : out std_logic
);
end axis_retention_special;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of axis_retention_special is
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal cnt : std_logic_vector(07 downto 00);
  signal delay_setup_reg : std_logic_vector(07 downto 00);

  signal s_axis_tready_reg : std_logic;

  signal m_axis_tdata_reg : std_logic_vector(07 downto 00);
  signal m_axis_tvalid_reg : std_logic;
  signal m_axis_tlast_reg : std_logic;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  s_axis_tready <= s_axis_tready_reg;
  m_axis_tdata <= m_axis_tdata_reg;
  m_axis_tvalid <= m_axis_tvalid_reg;
  m_axis_tlast <= m_axis_tlast_reg;
  ----------------------------------------------------------------------------------
  main_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      cnt <= (others => '0');
      delay_setup_reg <= (others => '0');

      m_axis_tdata_reg <= (others => '0');
      m_axis_tvalid_reg <= '0';
      m_axis_tlast_reg <= '0';

      s_axis_tready_reg <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if ((unsigned(cnt) = 0) and (s_axis_tvalid = '1')) then
        if (unsigned(delay_setup) = 0) then
          cnt <= (others => '0');
          delay_setup_reg <= (others => '0');

          m_axis_tdata_reg <= s_axis_tdata;
          m_axis_tvalid_reg <= s_axis_tvalid;
          m_axis_tlast_reg <= s_axis_tlast;

          s_axis_tready_reg <= m_axis_tready;

        else
          cnt <= unsigned(cnt) + 1;
          delay_setup_reg <= delay_setup;

          m_axis_tdata_reg <= s_axis_tdata;
          m_axis_tvalid_reg <= s_axis_tvalid;
          m_axis_tlast_reg <= s_axis_tlast;

          s_axis_tready_reg <= '0';

        end if;
      elsif ((unsigned(cnt) < unsigned(delay_setup_reg))) then
        if(clk_en = '1')then
          cnt <= unsigned(cnt) + 1;

        else
          cnt <= cnt;

        end if;

        delay_setup_reg <= delay_setup_reg;

        m_axis_tdata_reg <= m_axis_tdata_reg;
        m_axis_tvalid_reg <= m_axis_tvalid_reg;
        m_axis_tlast_reg <= m_axis_tlast_reg;

        s_axis_tready_reg <= '0';

      elsif ((unsigned(cnt) >= unsigned(delay_setup_reg))) then
        cnt <= (others => '0');
        delay_setup_reg <= (others => '0');

        m_axis_tdata_reg <= (others => '0');
        m_axis_tvalid_reg <= '0';
        m_axis_tlast_reg <= '0';

        s_axis_tready_reg <= '1';

      else
        cnt <= cnt;
        delay_setup_reg <= delay_setup_reg;

        m_axis_tdata_reg <= m_axis_tdata_reg;
        m_axis_tvalid_reg <= m_axis_tvalid_reg;
        m_axis_tlast_reg <= m_axis_tlast_reg;

        s_axis_tready_reg <= s_axis_tready_reg;

      end if;
    end if;
  end process main_proc;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
end rtl;
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------