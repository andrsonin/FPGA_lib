--/////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
--/////////////////////////////////////////////////////////////////////
entity Serializer_v2_vhd is
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
end Serializer_v2_vhd;
--/////////////////////////////////////////////////////////////////////
architecture rtl of Serializer_v2_vhd is
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------
signal counter 					:integer range 0 to 32;
signal counter_next_keep		:std_logic_vector(15 downto 00);
signal counter_next_keep_div8	:std_logic_vector(12 downto 00);
signal counter_next_keep_div4	:std_logic_vector(13 downto 00);
  -----------------------------------------------------------------------
signal next_tkeep 				:integer range 0 to 4;
  -----------------------------------------------------------------------
signal s_axis_tdata_buf :std_logic_vector(31 downto 00);
signal s_axis_tkeep_buf :std_logic_vector(03 downto 00);
signal s_axis_tlast_buf :std_logic;
  -----------------------------------------------------------------------
signal s_axis_tready_s 	:std_logic;
  -----------------------------------------------------------------------
signal m_axis_tdata_s 	:std_logic_vector(07 downto 00);
signal m_axis_tvalid_s 	:std_logic;
signal m_axis_tlast_s 	:std_logic;
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
begin
  --/////////////////////////////////////////////////////////////////////
  -----------------------------------------------------------------------
  counter_next_keep			<= std_logic_vector(conv_unsigned(counter +1, 16)) when (counter < 31) else (others => '0');	-- counter +1 to veector
  counter_next_keep_div4	<= counter_next_keep(15 downto 02);					-- counter_next_keep / 4
  counter_next_keep_div8	<= counter_next_keep(15 downto 03);					-- counter_next_keep / 8
  next_tkeep 				<= conv_integer(unsigned(counter_next_keep_div8)); 	-- указатель на следующий tkeep
  -----------------------------------------------------------------------
  bit_pointer				<= std_logic_vector(conv_unsigned(counter, 16));
  -----------------------------------------------------------------------
  flag_new_word_next		<= '1' when ((counter = 31)or(s_axis_tkeep_buf(next_tkeep) = '0')) else '0';
  -----------------------------------------------------------------------
  m_axis_tdata_s(07 downto 01)	<= (others => '0');
  -----------------------------------------------------------------------
  s_axis_tready		<= s_axis_tready_s;
  -----------------------------------------------------------------------
  m_axis_tdata		<= m_axis_tdata_s;
  m_axis_tvalid 	<= m_axis_tvalid_s;
  m_axis_tlast 		<= m_axis_tlast_s;
  -----------------------------------------------------------------------
  MAIN_proc : process (aclk, aresetn)
  begin
    -- сброс
    if (aresetn = '0') then													-- сброс
    	counter <= 0;

    elsif (aclk'event and aclk = '1') then
    	if((m_axis_tvalid_s = '0')or(m_axis_tready = '1'))then
				if(counter = 0)then 											-- первый бит
					if((s_axis_tvalid = '1')and(s_axis_tkeep(0) = '1')and(first_bit_en = '1'))then		-- если валидные данные
						counter <= counter +1;
					
					else
						counter <= counter;
						
					end if;					
				elsif((counter = 31)or(s_axis_tkeep_buf(next_tkeep) = '0'))then	-- если последний бит слова
					if(unsigned(counter_next_keep(01 downto 00)) = 0)then
						counter <= 0;
						
					else
						counter <= counter +1;
						
					end if;
					
				else 															-- если в середине слова
					counter <= counter +1;
					
				end if; 
    	else																-- храним данные
    		counter <= counter;
    		
    	end if;   
    end if;
  end process MAIN_proc;
  -----------------------------------------------------------------------
  OUTPUTS_proc : process (aclk, aresetn)
  begin
    -- сброс
    if (aresetn = '0') then													-- сброс
	  m_axis_tdata_s(0)	<= '0';
	  m_axis_tvalid_s 	<= '0';
	  m_axis_tlast_s 	<= '0';
	  
	  s_axis_tready_s	<= '0';

    elsif (aclk'event and aclk = '1') then
    	if((m_axis_tvalid_s = '0')or(m_axis_tready = '1'))then
				if(counter = 0)then 											-- первый бит
					if((s_axis_tvalid = '1')and(s_axis_tkeep(0) = '1')and(first_bit_en = '1'))then		-- если валидные данные
						m_axis_tdata_s(0)	<= s_axis_tdata(counter);
						m_axis_tvalid_s 	<= s_axis_tvalid;
						m_axis_tlast_s 		<= '0';
						
						s_axis_tready_s	<= '1';
					
					else
						m_axis_tdata_s(0)	<= '0';
						m_axis_tvalid_s 	<= '0';
						m_axis_tlast_s 		<= '0';
						
						s_axis_tready_s	<= '0';
						
					end if;					
				elsif((counter = 31)or(s_axis_tkeep_buf(next_tkeep) = '0'))then	-- если последний бит слова
					m_axis_tdata_s(0)	<= s_axis_tdata_buf(counter);
					m_axis_tvalid_s 	<= m_axis_tvalid_s;
					m_axis_tlast_s 		<= s_axis_tlast_buf;
					
					s_axis_tready_s	<= '0';
					
				else 															-- если в середине слова
					m_axis_tdata_s(0)	<= s_axis_tdata_buf(counter);
					m_axis_tvalid_s 	<= m_axis_tvalid_s;
					m_axis_tlast_s 		<= m_axis_tlast_s;
					
					s_axis_tready_s	<= '0';
					
				end if; 
    	else																-- храним данные
			m_axis_tdata_s(0)	<= m_axis_tdata_s(0);
			m_axis_tvalid_s 	<= m_axis_tvalid_s;
			m_axis_tlast_s 		<= m_axis_tlast_s;
    		
    		s_axis_tready_s	<= '0';
    	end if;   
    end if;
  end process OUTPUTS_proc;
  -----------------------------------------------------------------------
  BUF_proc : process (aclk, aresetn)
  begin
    -- сброс
    if (aresetn = '0') then													-- сброс
		s_axis_tdata_buf	<= (others => '0');
		s_axis_tkeep_buf	<= "0000";
		s_axis_tlast_buf 	<= '0';

    elsif (aclk'event and aclk = '1') then
    	if((m_axis_tvalid_s = '0')or(m_axis_tready = '1'))then
				if(counter = 0)then 											-- первый бит
					if((s_axis_tvalid = '1')and(s_axis_tkeep(0) = '1')and(first_bit_en = '1'))then		-- если валидные данные
						s_axis_tdata_buf	<= s_axis_tdata;
						s_axis_tkeep_buf	<= s_axis_tkeep;
						s_axis_tlast_buf 	<= s_axis_tlast;
					else
						s_axis_tdata_buf	<= s_axis_tdata_buf;
						s_axis_tkeep_buf	<= s_axis_tkeep_buf;
						s_axis_tlast_buf 	<= s_axis_tlast_buf;
					end if;
				elsif((counter = 31)or(s_axis_tkeep_buf(next_tkeep) = '0'))then	-- если последний бит слова
					s_axis_tdata_buf	<= (others => '0');
					s_axis_tkeep_buf	<= "0000";
					s_axis_tlast_buf 	<= '0';
				else 															-- если в середине слова
					s_axis_tdata_buf	<= s_axis_tdata_buf;
					s_axis_tkeep_buf	<= s_axis_tkeep_buf;
					s_axis_tlast_buf 	<= s_axis_tlast_buf;
				end if; 
    	else																-- храним данные
    		s_axis_tdata_buf	<= s_axis_tdata_buf;
			s_axis_tkeep_buf	<= s_axis_tkeep_buf;
			s_axis_tlast_buf 	<= s_axis_tlast_buf;
    	end if;   
    end if;
  end process BUF_proc;
  -----------------------------------------------------------------------
  --/////////////////////////////////////////////////////////////////////
end rtl;
--/////////////////////////////////////////////////////////////////////