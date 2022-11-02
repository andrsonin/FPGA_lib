--! @title      Serializer
--! @file       Serializer.vhd
--! @author     Sonin Andrey
--! @version    0.1
--! @date       2020-03
--!
--! @copyright  Copyright (c) 2021
--! 
--! @brief Переводит данные из AXI4_STREAM шины
--! разрядностью BUS_WIDTH
--! в шину AXI4_STREAM разрядностью 8бит
--! из которых валидный нулевой разряд
--! Данные выходят последовательно
--! начиная от младшего разряда входной шины
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
entity Serializer_vhd is
  port (
    s_axis_tready : out std_logic;
    s_axis_tdata : in std_logic_vector(31 downto 00);
    s_axis_tkeep : in std_logic_vector(03 downto 00);
    s_axis_tvalid : in std_logic;
    s_axis_tlast : in std_logic;

    s_axis_size_tready : out std_logic;
    s_axis_size_tdata : in std_logic_vector(15 downto 00);
    s_axis_size_tvalid : in std_logic;
    s_axis_size_tlast : in std_logic;

    m_axis_tready : in std_logic;
    m_axis_tdata : out std_logic_vector(07 downto 00);
    m_axis_tvalid : out std_logic;
    m_axis_tlast : out std_logic;

    m_axis_size_tdata : out std_logic_vector(31 downto 00);
    m_axis_size_tvalid : out std_logic;
    m_axis_size_tlast : out std_logic;

    --! системные такты
    clk : in std_logic;
    --! системный ассинхронный сброс активный уровень низкий 
    resetn : in std_logic
  );
end Serializer_vhd;
--/////////////////////////////////////////////////////////////////////
architecture rtl of Serializer_vhd is
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------
  constant AXIS_KEEP_WIDTH : integer range 1 to 32 := 03; --! параметр разрядности tkeep
  constant AXIS_BUS_WIDTH  : integer range 1 to 32 := 31; --! параметр разрядности tkeep
  -----------------------------------------------------------------------
  --! not arst_n_i
  signal arst : std_logic;
  -----------------------------------------------------------------------
  --! выводной регистр s_data_axis_tready и s_data_ps_axis_tready 
  signal axis_tready : std_logic;
  --! регистр задержки s_axis_tready на один такт
  signal s_axis_tready_buf : std_logic;
  --! буфер входного s_data_axis_tdata
  signal axis_tdata_buf : std_logic_vector(AXIS_BUS_WIDTH downto 00);
  --! буфер входного s_data_axis_tkeep
  signal axis_tkeep_buf : std_logic_vector(AXIS_KEEP_WIDTH downto 00);
  --! буфер входного s_data_axis_tvalid
  signal axis_tvalid_buf : std_logic;
  --! буфер входного s_data_axis_tlast
  signal axis_tlast_buf : std_logic;
  --! выводной регистр m_sl_axis_tdata
  signal axis_tdata : std_logic;
  --! выводной регистр m_sl_axis_tvalid
  signal axis_tvalid : std_logic;
  --! выводной регистр m_sl_axis_tlast
  signal axis_tlast : std_logic;
  --! выводной регистр s_data_ps_axis_tready
  signal axis_size_tready : std_logic;
  --! выводной регистр m_sl_ps_axis_tdata
  signal axis_size_tdata : std_logic_vector(31 downto 00);
  --! выводной регистр m_sl_ps_axis_tvalid
  signal axis_size_tvalid : std_logic;
  --! выводной регистр m_sl_ps_axis_tlast
  signal axis_size_tlast : std_logic;
  -----------------------------------------------------------------------
  --! счетчик (указатель) bit входного слова
  signal counter : integer range 0 to 256;
  -----------------------------------------------------------------------
  --! буфер входного tkeep
  signal axis_tkeep_i_buf : std_logic_vector((AXIS_KEEP_WIDTH - 1) downto 00);
  --! указатель на следующий bit tkeep
  signal next_tkeep : integer range 0 to (256/8);
  --! новый размер пакета в битах
  signal new_size : std_logic_vector(31 downto 00);
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
begin
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------
  arst <= not resetn;

  axis_size_tlast <= s_axis_size_tlast;

  new_size(02 downto 00) <= (others => '0');
  new_size(18 downto 03) <= s_axis_size_tdata(15 downto 00);
  new_size(31 downto 19) <= (others => '0');
  -----------------------------------------------------------------------
  s_axis_tready      <= axis_tready;
  s_axis_size_tready <= axis_size_tready;

  m_axis_tdata(07 downto 01)  <= (others => '0');
  m_axis_tdata(0)  <= axis_tdata;
  m_axis_tvalid <= axis_tvalid;
  m_axis_tlast  <= axis_tlast;

  m_axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
  m_axis_size_tvalid              <= axis_size_tvalid;
  m_axis_size_tlast               <= axis_size_tlast;
  -----------------------------------------------------------------------
  next_tkeep <= (counter + 1) / 8; -- указатель на следующий tkeep
  -----------------------------------------------------------------------
  --! оснавной процесс
  --! ---
  MAIN_proc : process (clk, arst)
  begin
    -- сброс
    if (arst = '1') then
      counter                                  <= 0;
      axis_tlast_buf                           <= '1';
      axis_tkeep_buf                           <= (others => '0');
      axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= (others => '0');
      axis_tvalid_buf                          <= '0';

      axis_tready      <= '0';
      axis_size_tready <= '0';

      axis_tdata  <= '0';
      axis_tvalid <= '0';
      axis_tlast  <= '1';

      axis_size_tdata(31 downto 00) <= (others => '0');
      axis_size_tvalid              <= '0';

    elsif (clk'event and clk = '1') then
      if (counter = 0) then -- если первый bit
        if (axis_tlast_buf = '1') then -- если первый bit и до этого был последний бит пакета
          if ((s_axis_tvalid = '1') and (s_axis_size_tvalid = '1')) then -- если первый bit и до этого был последний бит пакета и есть данные из 2х буферов для передачи
            if (m_axis_tready = '1') then -- если первый bit и до этого был последний бит пакета и есть данные из 2х буферов для передачи и интерфейс свободен
              counter                                  <= counter + 1;
              axis_tlast_buf                           <= s_axis_tlast;
              axis_tkeep_buf                           <= s_axis_tkeep;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= s_axis_tdata(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= s_axis_tvalid;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= s_axis_size_tvalid;

              axis_tready      <= '1';
              axis_size_tready <= '1';

              axis_tdata  <= s_axis_tdata(counter);
              axis_tvalid <= s_axis_tvalid;
              axis_tlast  <= '0';

            elsif (axis_tvalid = '0') then -- если первый bit и до этого был последний бит пакета и есть данные из 2х буферов для передачи и интерфейс занят и до этого НЕ было что-то переданно. обновляем значения
              counter                                  <= counter + 1;
              axis_tlast_buf                           <= s_axis_tlast;
              axis_tkeep_buf                           <= s_axis_tkeep;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= s_axis_tdata(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= s_axis_tvalid;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= s_axis_size_tvalid;

              axis_tready      <= '1';
              axis_size_tready <= '1';

              axis_tdata  <= s_axis_tdata(counter);
              axis_tvalid <= s_axis_tvalid;
              axis_tlast  <= '0';

            else -- если первый bit и до этого был последний бит пакета и есть данные из 2х буферов для передачи и интерфейс занят и до этого было что-то переданно, то храним предыдущие значения
              counter                                  <= counter;
              axis_tlast_buf                           <= axis_tlast_buf;
              axis_tkeep_buf                           <= axis_tkeep_buf;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= axis_tvalid_buf;

              axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
              axis_size_tvalid              <= axis_size_tvalid;

              axis_tready      <= '0';
              axis_size_tready <= '0';

              axis_tdata  <= axis_tdata;
              axis_tvalid <= axis_tvalid;
              axis_tlast  <= axis_tlast;

            end if;
          else -- если первый bit и до этого был последний бит пакета и нет данных из 2х буферов для передачи то ждем синхронизыции буферов
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= '0';

            axis_tready      <= '0';
            axis_size_tready <= '0';

            if (m_axis_tready = '1') then -- если интерфейс свободен
              axis_tdata  <= '0';
              axis_tvalid <= '0';
              axis_tlast  <= '0';

            else
              axis_tdata  <= axis_tdata;
              axis_tvalid <= axis_tvalid;
              axis_tlast  <= axis_tlast;

            end if;
          end if;
        elsif (m_axis_tready = '1') then -- если первый bit и до этого был не последний бит пакета и интерфейс свободен
          if (s_axis_tvalid = '1') then
            counter                                  <= counter + 1;
            axis_tlast_buf                           <= s_axis_tlast;
            axis_tkeep_buf                           <= s_axis_tkeep;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= s_axis_tdata(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= s_axis_tvalid;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= s_axis_size_tvalid;

            axis_tready      <= '1';
            axis_size_tready <= '0';

            axis_tdata  <= s_axis_tdata(counter);
            axis_tvalid <= s_axis_tvalid;
            axis_tlast  <= '0';

          else
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= '0';

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= '0';
            axis_tvalid <= '0';
            axis_tlast  <= '0';

          end if;
        elsif (axis_tvalid = '0') then -- если первый bit и интерфейс занят и до этого НЕ было что-то переданно. обновляем значения
          if (s_axis_tvalid = '1') then
            counter                                  <= counter + 1;
            axis_tlast_buf                           <= s_axis_tlast;
            axis_tkeep_buf                           <= s_axis_tkeep;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= s_axis_tdata(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= s_axis_tvalid;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= s_axis_size_tvalid;

            axis_tready      <= '1';
            axis_size_tready <= '0';

            axis_tdata  <= s_axis_tdata(counter);
            axis_tvalid <= s_axis_tvalid;
            axis_tlast  <= '0';

          else
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= '0';

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= '0';
            axis_tvalid <= '0';
            axis_tlast  <= '0';

          end if;
        else -- если первый bit и интерфейс занят и до этого было что-то переданно, то храним предыдущие значения
          counter                                  <= counter;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
          axis_size_tvalid              <= axis_size_tvalid;

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= axis_tdata;
          axis_tvalid <= axis_tvalid;
          axis_tlast  <= axis_tlast;

        end if;
      elsif ((counter = AXIS_BUS_WIDTH) or (axis_tkeep_buf(next_tkeep) = '0')) then -- если последний bit по счетчику или если next keep = 0
        if (axis_tlast_buf = '1') then -- если последний бит пакета
          if (m_axis_tready = '1') then -- если интерфейс свободен
            if (axis_tvalid_buf = '1') then
              counter                                  <= 0;
              axis_tlast_buf                           <= axis_tlast_buf;
              axis_tkeep_buf                           <= axis_tkeep_buf;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= axis_tvalid_buf;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= s_axis_size_tvalid;

              axis_tready      <= '0';
              axis_size_tready <= '0';

              axis_tdata  <= axis_tdata_buf(counter);
              axis_tvalid <= axis_tvalid_buf;
              axis_tlast  <= '1';

            else
              counter                                  <= counter;
              axis_tlast_buf                           <= axis_tlast_buf;
              axis_tkeep_buf                           <= axis_tkeep_buf;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= axis_tvalid_buf;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= '0';

              axis_tready      <= '0';
              axis_size_tready <= '0';

              axis_tdata  <= '0';
              axis_tvalid <= '0';
              axis_tlast  <= '0';

            end if;
          elsif (axis_tvalid = '0') then -- если последний бит пакета и интерфейс занят и до этого НЕ было что-то переданно. обновляем значения
            if (axis_tvalid_buf = '1') then
              counter                                  <= 0;
              axis_tlast_buf                           <= axis_tlast_buf;
              axis_tkeep_buf                           <= axis_tkeep_buf;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= axis_tvalid_buf;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= s_axis_size_tvalid;

              axis_tready      <= '0';
              axis_size_tready <= '0';

              axis_tdata  <= axis_tdata_buf(counter);
              axis_tvalid <= axis_tvalid_buf;
              axis_tlast  <= '1';

            else
              counter                                  <= counter;
              axis_tlast_buf                           <= axis_tlast_buf;
              axis_tkeep_buf                           <= axis_tkeep_buf;
              axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
              axis_tvalid_buf                          <= axis_tvalid_buf;

              axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
              axis_size_tvalid              <= '0';

              axis_tready      <= '0';
              axis_size_tready <= '0';

              axis_tdata  <= '0';
              axis_tvalid <= '0';
              axis_tlast  <= '0';

            end if;
          else -- если последний бит пакета и интерфейс занят и до этого было что-то переданно, то храним предыдущие значения
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
            axis_size_tvalid              <= axis_size_tvalid;

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= axis_tdata;
            axis_tvalid <= axis_tvalid;
            axis_tlast  <= axis_tlast;

          end if;
        elsif (m_axis_tready = '1') then -- если не последний бит пакета но последний бит слова и интерфейс свободен
          if (axis_tvalid_buf = '1') then
            counter                                  <= 0;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= s_axis_size_tvalid;

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= axis_tdata_buf(counter);
            axis_tvalid <= axis_tvalid_buf;
            axis_tlast  <= '0';

          else
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= '0';

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= '0';
            axis_tvalid <= '0';
            axis_tlast  <= '0';

          end if;
        elsif (axis_tvalid = '0') then -- если не последний бит пакета но последний бит слова и интерфейс занят и до этого НЕ было что-то переданно. обновляем значения
          if (axis_tvalid_buf = '1') then
            counter                                  <= 0;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= s_axis_size_tvalid;

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= axis_tdata_buf(counter);
            axis_tvalid <= axis_tvalid_buf;
            axis_tlast  <= '0';

          else
            counter                                  <= counter;
            axis_tlast_buf                           <= axis_tlast_buf;
            axis_tkeep_buf                           <= axis_tkeep_buf;
            axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
            axis_tvalid_buf                          <= axis_tvalid_buf;

            axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
            axis_size_tvalid              <= '0';

            axis_tready      <= '0';
            axis_size_tready <= '0';

            axis_tdata  <= '0';
            axis_tvalid <= '0';
            axis_tlast  <= '0';

          end if;
        else -- если не последний бит пакета но последний бит слова и интерфейс занят и до этого было что-то переданно, то храним предыдущие значения
          counter                                  <= counter;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
          axis_size_tvalid              <= axis_size_tvalid;

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= axis_tdata;
          axis_tvalid <= axis_tvalid;
          axis_tlast  <= axis_tlast;

        end if;
      elsif (m_axis_tready = '1') then -- если не поледний bit и интерфейс свободен -- 
        if (axis_tvalid_buf = '1') then
          counter                                  <= counter + 1;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
          axis_size_tvalid              <= s_axis_size_tvalid;

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= axis_tdata_buf(counter);
          axis_tvalid <= axis_tvalid_buf;
          axis_tlast  <= '0';

        else
          counter                                  <= counter;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
          axis_size_tvalid              <= '0';

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= '0';
          axis_tvalid <= '0';
          axis_tlast  <= '0';

        end if;
      elsif (axis_tvalid = '0') then -- если не поледний bit и интерфейс занят и до этого НЕ было что-то переданно. обновляем значения
        if (axis_tvalid_buf = '1') then
          counter                                  <= counter + 1;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
          axis_size_tvalid              <= s_axis_size_tvalid;

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= axis_tdata_buf(counter);
          axis_tvalid <= axis_tvalid_buf;
          axis_tlast  <= '0';

        else
          counter                                  <= counter;
          axis_tlast_buf                           <= axis_tlast_buf;
          axis_tkeep_buf                           <= axis_tkeep_buf;
          axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
          axis_tvalid_buf                          <= axis_tvalid_buf;

          axis_size_tdata(31 downto 00) <= new_size(31 downto 00);
          axis_size_tvalid              <= '0';

          axis_tready      <= '0';
          axis_size_tready <= '0';

          axis_tdata  <= '0';
          axis_tvalid <= '0';
          axis_tlast  <= '0';

        end if;
      else -- если интерфейс занят и до этого было что-то переданно, то храним предыдущие значения
        counter                                  <= counter;
        axis_tlast_buf                           <= axis_tlast_buf;
        axis_tkeep_buf                           <= axis_tkeep_buf;
        axis_tdata_buf(AXIS_BUS_WIDTH downto 00) <= axis_tdata_buf(AXIS_BUS_WIDTH downto 00);
        axis_tvalid_buf                          <= axis_tvalid_buf;

        axis_size_tdata(31 downto 00) <= axis_size_tdata(31 downto 00);
        axis_size_tvalid              <= axis_size_tvalid;

        axis_tready      <= '0';
        axis_size_tready <= '0';

        axis_tdata  <= axis_tdata;
        axis_tvalid <= axis_tvalid;
        axis_tlast  <= axis_tlast;

      end if;
    end if;
  end process MAIN_proc;
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
end rtl;
--/////////////////////////////////////////////////////////////////////