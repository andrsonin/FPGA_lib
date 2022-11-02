--! @title      Deserializer
--! @file       Deserializer.vhd
--! @author     Sonin Andrey
--! @version    0.1
--! @date       2020-03
--!
--! @copyright  Copyright (c) 2021
--! 
--! @brief Переводит данные из AXI4_STREAM шины
--! разрядностью 8бит из которых валидный нулевой разряд
--! данные заполняются последовательно начиная от младшего разряда
--! в шину AXI4_STREAM разрядностью BUS_WIDTH
--! ---
--!
--! @details ***Details***
--! Их пока что нет
--! ---
--!

--/////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
--/////////////////////////////////////////////////////////////////////
entity DeSerializer_vhd is
  port (
    --! @virtualbus s_sl_axis @dir in slave AXI4 STREAM шина пакетных последовательных  данных
    --! tready
    s_axis_tready : out std_logic;
    --! tdata
    s_axis_tdata : in std_logic_vector(07 downto 00);
    --! tvalid
    s_axis_tvalid : in std_logic;
    --! tlast
    s_axis_tlast : in std_logic;
    --! @end
    --! @virtualbus s_data_axis @dir out slave AXI4 STREAM шина пакетных паралельных данных
    --!tready
    m_axis_tready : in std_logic;
    --! tdata
    m_axis_tdata : out std_logic_vector(31 downto 00);
    --! tkeep
    m_axis_tkeep : out std_logic_vector(03 downto 00);
    --! tvalid
    m_axis_tvalid : out std_logic;
    --! tlast
    m_axis_tlast : out std_logic;
    --! @end
    --! системные такты
    clk : in std_logic;
    --! системный ассинхронный сброс активный уровень низкий 
    resetn : in std_logic
  );
end DeSerializer_vhd;
--/////////////////////////////////////////////////////////////////////
architecture rtl of DeSerializer_vhd is
  --/////////////////////////////////////////////////////////////////////
  --! not arst_n_i
  signal arst : std_logic := '1';
  --! rename arst_n_i
  signal arst_n : std_logic := '0';
  --! выводной регистр s_data_axis_tready 
  signal s_axis_tready_s : std_logic := '0';
  --! выводной регистр s_data_axis_tdata
  signal m_axis_tdata_s : std_logic_vector(31 downto 00);
  --! выводной регистр s_data_axis_tkeep
  signal m_axis_tkeep_s : std_logic_vector(03 downto 00);
  --! выводной регистр s_data_axis_tvalid
  signal m_axis_tvalid_s : std_logic := '0';
  --! выводной регистр s_data_axis_tlast
  signal m_axis_tlast_s : std_logic := '0';
  
  
  signal m_axis_tready_buf: std_logic := '0';
  --! счетчик входных bit
  signal counter : std_logic_vector(15 downto 00) := (others => '0');
  --! указатель на следующий бит
  signal counter_next : std_logic_vector(15 downto 00) := (others => '0');
  --! указатель на текущий bit шины tkeep
  signal tkeep : std_logic_vector(15 downto 00) := (others => '0');
  --! указатель на следующий bit шины tkeep
  signal next_tkeep : std_logic_vector(15 downto 00) := (others => '0');
  --/////////////////////////////////////////////////////////////////////
begin
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------
  arst_n <= resetn;
  arst   <= not arst_n;

  counter_next(15 downto 00) <= unsigned(counter(15 downto 00)) + 1 when arst = '0' else (others => '0');

  next_tkeep(15 downto 13) <= (others                                                 => '0');
  next_tkeep(12 downto 00) <= counter_next(15 downto 03) when arst = '0' else (others => '0');

  tkeep(12 downto 00) <= counter(15 downto 03) when arst = '0' else (others => '0');

  s_axis_tready <= s_axis_tready_s;
  s_axis_tready_s <= m_axis_tready when (m_axis_tvalid_s = '1') else '1' ;

  m_axis_tdata  <= m_axis_tdata_s when (m_axis_tvalid_s = '1') else (others => '0');
  m_axis_tkeep  <= m_axis_tkeep_s;
  m_axis_tvalid <= m_axis_tvalid_s;
  m_axis_tlast  <= m_axis_tlast_s;
  -----------------------------------------------------------------------
  --! основной процесс
  MAIN_proc : process (clk, arst)
  begin
    -- сброс
    if (arst = '1') then
      m_axis_tdata_s(31 downto 00) <= (others => '0');
      m_axis_tkeep_s(03 downto 00) <= (others => '0');
      m_axis_tvalid_s              <= '0';
      m_axis_tlast_s               <= '0';

      counter(15 downto 00) <= (others => '0');
      
      -- run
    elsif (clk'event and clk = '1') then 
      -- если доступен выходной интерфейс
      if (s_axis_tready_s = '1')then
        -- проверяем валидно ли входящее слово
        if (s_axis_tvalid = '1') then
          -- если пришел конец пакета или конец слова 
          if ((s_axis_tlast = '1') or (unsigned(counter(15 downto 00)) = 31)) then
            -- если пришло нечетное кол-во бит
            if (tkeep(15 downto 00) = next_tkeep(15 downto 00)) then

              --
              if (unsigned(counter(15 downto 00)) < 31) then
                if (unsigned(counter(15 downto 00)) > 0) then
                  m_axis_tdata_s(31 downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                  m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= s_axis_tdata(0);
                  m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00) <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
                  
                  m_axis_tvalid_s <= '1';
                
                  else
                  m_axis_tdata_s(31 downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                  m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= s_axis_tdata(0);

                  m_axis_tvalid_s <= '0';

                end if;
              else
                m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= s_axis_tdata(0);
                m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00) <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
              
                m_axis_tvalid_s <= '1';
                
              end if;

              --                          
              if (conv_integer(unsigned(tkeep(15 downto 00))) < (32/8 - 1)) then
                m_axis_tkeep_s((32/8 - 1) downto conv_integer(unsigned(tkeep(15 downto 00)) + 1)) <= (others => '0');

                if (conv_integer(unsigned(tkeep(15 downto 00))) = 0) then
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)))) <= '0';
                else
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '0';
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
                end if;
              else
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '0';
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
              end if;

              
              m_axis_tlast_s  <= s_axis_tlast;

              counter(15 downto 00) <= (others => '0');
              -- если пришло четное кол-во бит
            else

              --
              if (unsigned(counter(15 downto 00)) < (32 - 1)) then
                if (unsigned(counter(15 downto 00)) > 0) then
                  m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                  m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                       <= s_axis_tdata(0);
                  m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00)       <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
                else
                  m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                  m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                       <= s_axis_tdata(0);
                end if;
              else
                m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= s_axis_tdata(0);
                m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00) <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
              end if;

              --                          
              if (conv_integer(unsigned(tkeep(15 downto 00))) < (32/8 - 1)) then
                m_axis_tkeep_s((32/8 - 1) downto conv_integer(unsigned(tkeep(15 downto 00)) + 1)) <= (others => '0');

                if (conv_integer(unsigned(tkeep(15 downto 00))) = 0) then
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)))) <= '1';
                else
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '1';
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
                end if;
              else
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '1';
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
              end if;
              m_axis_tvalid_s <= '1';
              m_axis_tlast_s  <= s_axis_tlast;

              counter(15 downto 00) <= (others => '0');
            end if;
            -- если не было флага конца пакета или счетчик не досчитал до конца слова
          else
            --
            if (unsigned(counter(15 downto 00)) < (32 - 1)) then
              if (unsigned(counter(15 downto 00)) > 0) then
                m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                       <= s_axis_tdata(0);
                m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00)       <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
              else
                m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
                m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                       <= s_axis_tdata(0);
              end if;
            else
              m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= s_axis_tdata(0);
              m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00) <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
            end if;

            if (tkeep(15 downto 00) < next_tkeep(15 downto 00)) then
              --                          
              if (conv_integer(unsigned(tkeep(15 downto 00))) < (32/8 - 1)) then
                m_axis_tkeep_s((32/8 - 1) downto conv_integer(unsigned(tkeep(15 downto 00)) + 1)) <= (others => '0');

                if (conv_integer(unsigned(tkeep(15 downto 00))) = 0) then
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)))) <= '1';
                else
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '1';
                  m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
                end if;
              else
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '1';
                m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
              end if;
            else
              m_axis_tkeep_s((32/8 - 1) downto 00) <= m_axis_tkeep_s((32/8 - 1) downto 00);
            end if;

            m_axis_tvalid_s <= '0';
            m_axis_tlast_s  <= '0';

            if (unsigned(counter(15 downto 00)) < (32 - 1)) then
              counter(15 downto 00) <= unsigned(counter(15 downto 00)) + 1;
            else
              counter(15 downto 00) <= (others => '0');
            end if;
          end if;
          -- если нет валидных данных
        else

          --
          if (unsigned(counter(15 downto 00)) < (32 - 1)) then
            if (unsigned(counter(15 downto 00)) > 0) then
              m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
              m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                              <= '0';
              m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00)              <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
            else
              m_axis_tdata_s((32 - 1) downto (conv_integer(unsigned(counter(15 downto 00))) + 1)) <= (others => '0');
              m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                              <= '0';
            end if;
          else
            m_axis_tdata_s(conv_integer(unsigned(counter(15 downto 00))))                 <= '0';
            m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00) <= m_axis_tdata_s((conv_integer(unsigned(counter(15 downto 00))) - 1) downto 00);
          end if;
          --                          
          if (conv_integer(unsigned(tkeep(15 downto 00))) < (32/8 - 1)) then
            m_axis_tkeep_s((32/8 - 1) downto conv_integer(unsigned(tkeep(15 downto 00)) + 1)) <= (others => '0');

            if (conv_integer(unsigned(tkeep(15 downto 00))) = 0) then
              m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)))) <= '0';
            else
              m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '0';
              m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
            end if;
          else
            m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00))))               <= '0';
            m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00) <= m_axis_tkeep_s(conv_integer(unsigned(tkeep(15 downto 00)) - 1) downto 00);
          end if;

          m_axis_tvalid_s <= '0';
          m_axis_tlast_s  <= '0';

          counter(15 downto 00) <= counter(15 downto 00);
        end if;
        -- если выходной интерфейс недоступен, то храним последнее значения
      else

        m_axis_tdata_s((32 - 1) downto 00)   <= m_axis_tdata_s((32 - 1) downto 00);
        m_axis_tkeep_s((32/8 - 1) downto 00) <= m_axis_tkeep_s((32/8 - 1) downto 00);
        m_axis_tvalid_s                             <= m_axis_tvalid_s;
        m_axis_tlast_s                              <= m_axis_tlast_s;

        counter(15 downto 00) <= counter(15 downto 00);
      end if;
    end if;
  end process MAIN_proc;
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------

  --/////////////////////////////////////////////////////////////////////
end rtl;
--/////////////////////////////////////////////////////////////////////