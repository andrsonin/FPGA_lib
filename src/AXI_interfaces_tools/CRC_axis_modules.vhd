----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
entity crc8 is port (
  s_axis_tready : out std_logic;
  s_axis_tdata : in std_logic_vector (07 downto 00);
  s_axis_tvalid : in std_logic;
  s_axis_tlast : in std_logic;

  crc_en : in std_logic;
  aresetn : in std_logic;
  aclk : in std_logic;

  m_axis_tready : in std_logic;
  m_axis_tdata : out std_logic_vector(07 downto 00);
  m_axis_tvalid : out std_logic;
  m_axis_tlast : out std_logic

);end crc8;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
architecture rtl of crc8 is -- crc8_wcdma_sync
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal lfsr_q : std_logic_vector (7 downto 0);
  signal lfsr_c : std_logic_vector (7 downto 0);
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  signal s_axis_tready_sig : std_logic;
  ----------------------------------------------------------------------------------
  signal m_axis_tdata_sig : std_logic_vector (07 downto 00);
  signal m_axis_tvalid_sig : std_logic;
  signal m_axis_tlast_sig : std_logic;
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
begin
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  s_axis_tready_sig <= m_axis_tready;
  ----------------------------------------------------------------------------------
  s_axis_tready <= s_axis_tready_sig;
  ----------------------------------------------------------------------------------
  m_axis_tdata <= m_axis_tdata_sig;
  m_axis_tvalid <= m_axis_tvalid_sig;
  m_axis_tlast <= m_axis_tlast_sig;
  ----------------------------------------------------------------------------------
  lfsr_c(0) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(2) xor lfsr_q(3) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(2) xor s_axis_tdata(3) xor s_axis_tdata(7);
  lfsr_c(1) <= lfsr_q(0) xor lfsr_q(4) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(4) xor s_axis_tdata(7);
  lfsr_c(2) <= lfsr_q(1) xor lfsr_q(5) xor s_axis_tdata(1) xor s_axis_tdata(5);
  lfsr_c(3) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(3) xor lfsr_q(6) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(3) xor s_axis_tdata(6) xor s_axis_tdata(7);
  lfsr_c(4) <= lfsr_q(0) xor lfsr_q(3) xor lfsr_q(4) xor s_axis_tdata(0) xor s_axis_tdata(3) xor s_axis_tdata(4);
  lfsr_c(5) <= lfsr_q(1) xor lfsr_q(4) xor lfsr_q(5) xor s_axis_tdata(1) xor s_axis_tdata(4) xor s_axis_tdata(5);
  lfsr_c(6) <= lfsr_q(2) xor lfsr_q(5) xor lfsr_q(6) xor s_axis_tdata(2) xor s_axis_tdata(5) xor s_axis_tdata(6);
  lfsr_c(7) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(2) xor lfsr_q(6) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(2) xor s_axis_tdata(6);
  ----------------------------------------------------------------------------------
  output_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      m_axis_tdata_sig <= (others => '0');
      m_axis_tvalid_sig <= '0';
      m_axis_tlast_sig <= '0';

    elsif (aclk'EVENT and aclk = '1') then
      if (crc_en = '1') then
        if ((s_axis_tvalid = '1') and (s_axis_tready_sig = '1')) then
          if (s_axis_tlast = '1') then
            m_axis_tdata_sig <= lfsr_c;

            m_axis_tvalid_sig <= '1';
            m_axis_tlast_sig <= '1';

          elsif (m_axis_tready = '1') then
            m_axis_tdata_sig <= (others => '0');
            m_axis_tvalid_sig <= '0';
            m_axis_tlast_sig <= '0';

          else
            m_axis_tdata_sig <= m_axis_tdata_sig;
            m_axis_tvalid_sig <= m_axis_tvalid_sig;
            m_axis_tlast_sig <= m_axis_tlast_sig;

          end if;
        elsif (m_axis_tready = '1') then
          m_axis_tdata_sig <= (others => '0');
          m_axis_tvalid_sig <= '0';
          m_axis_tlast_sig <= '0';

        else
          m_axis_tdata_sig <= m_axis_tdata_sig;
          m_axis_tvalid_sig <= m_axis_tvalid_sig;
          m_axis_tlast_sig <= m_axis_tlast_sig;

        end if;
      elsif (m_axis_tready = '1') then
        m_axis_tdata_sig <= (others => '0');
        m_axis_tvalid_sig <= '0';
        m_axis_tlast_sig <= '0';

      else
        m_axis_tdata_sig <= m_axis_tdata_sig;
        m_axis_tvalid_sig <= m_axis_tvalid_sig;
        m_axis_tlast_sig <= m_axis_tlast_sig;

      end if;
    end if;
  end process output_proc;
  ----------------------------------------------------------------------------------
  main_proc : process (aclk, aresetn) begin
    if (aresetn = '0') then
      lfsr_q <= b"00000000";

    elsif (aclk'EVENT and aclk = '1') then
      if (crc_en = '1') then
        if ((s_axis_tvalid = '1') and (s_axis_tready_sig = '1')) then
          if (s_axis_tlast = '1') then
            lfsr_q <= b"00000000";

          else
            lfsr_q <= lfsr_c;

          end if;
        else
          lfsr_q <= lfsr_q;

        end if;
      else
        lfsr_q <= lfsr_q;

      end if;
    end if;
  end process main_proc;
  ----------------------------------------------------------------------------------
end architecture rtl;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--architecture crc8_wcdma_async of crc8 is
--  ----------------------------------------------------------------------------------
--  ----------------------------------------------------------------------------------
--  signal lfsr_q : std_logic_vector (7 downto 0);
--  signal lfsr_c : std_logic_vector (7 downto 0);
--  ----------------------------------------------------------------------------------
--  ----------------------------------------------------------------------------------
--  signal s_axis_tready_sig : std_logic;
--  ----------------------------------------------------------------------------------
--  ----------------------------------------------------------------------------------
--begin
--  ----------------------------------------------------------------------------------
--  ----------------------------------------------------------------------------------
--  s_axis_tready_sig 	<= m_axis_tready;
--  ----------------------------------------------------------------------------------
--  s_axis_tready 		<= s_axis_tready_sig;
--  ----------------------------------------------------------------------------------
--  m_axis_tdata 			<= lfsr_c 			when (s_axis_tlast = '1') else (others => '0');
--  m_axis_tvalid 		<= s_axis_tvalid 	when (s_axis_tlast = '1') else '0';
--  m_axis_tlast 			<= s_axis_tlast 	when (s_axis_tlast = '1') else '0';
--  ----------------------------------------------------------------------------------
--  lfsr_c(0) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(2) xor lfsr_q(3) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(2) xor s_axis_tdata(3) xor s_axis_tdata(7);
--  lfsr_c(1) <= lfsr_q(0) xor lfsr_q(4) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(4) xor s_axis_tdata(7);
--  lfsr_c(2) <= lfsr_q(1) xor lfsr_q(5) xor s_axis_tdata(1) xor s_axis_tdata(5);
--  lfsr_c(3) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(3) xor lfsr_q(6) xor lfsr_q(7) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(3) xor s_axis_tdata(6) xor s_axis_tdata(7);
--  lfsr_c(4) <= lfsr_q(0) xor lfsr_q(3) xor lfsr_q(4) xor s_axis_tdata(0) xor s_axis_tdata(3) xor s_axis_tdata(4);
--  lfsr_c(5) <= lfsr_q(1) xor lfsr_q(4) xor lfsr_q(5) xor s_axis_tdata(1) xor s_axis_tdata(4) xor s_axis_tdata(5);
--  lfsr_c(6) <= lfsr_q(2) xor lfsr_q(5) xor lfsr_q(6) xor s_axis_tdata(2) xor s_axis_tdata(5) xor s_axis_tdata(6);
--  lfsr_c(7) <= lfsr_q(0) xor lfsr_q(1) xor lfsr_q(2) xor lfsr_q(6) xor s_axis_tdata(0) xor s_axis_tdata(1) xor s_axis_tdata(2) xor s_axis_tdata(6);
--  ----------------------------------------------------------------------------------
--  main_proc : process (aclk, aresetn) begin
--    if (aresetn = '0') then
--      lfsr_q <= b"00000000";

--    elsif (aclk'EVENT and aclk = '1') then
--      if (crc_en = '1') then
--        if ((s_axis_tvalid = '1') and (s_axis_tready_sig = '1')) then
--          if (s_axis_tlast = '1') then
--            lfsr_q <= b"00000000";

--          else
--            lfsr_q <= lfsr_c;

--          end if;
--        else
--          lfsr_q <= lfsr_q;

--        end if;
--      else
--        lfsr_q <= lfsr_q;

--      end if;
--    end if;
--  end process main_proc;
--  ----------------------------------------------------------------------------------
--end architecture crc8_wcdma_async;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------