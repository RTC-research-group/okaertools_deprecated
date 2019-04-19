----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:24:06 03/16/2019 
-- Design Name: 
-- Module Name:    merger - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.merger_pkg.ALL;
use work.global_pkg.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity merger is
	Port (
		CLK				: in std_logic;
		RST				: in std_logic;
		
		ROME_A_DATA		: in std_logic_vector(ROME_DATA_WIDTH-1 downto 0);
		ROME_A_REQ		: in std_logic;
		ROME_A_ACK		: out std_logic;
		
		ROME_B_DATA		: in std_logic_vector(ROME_DATA_WIDTH-1 downto 0);
		ROME_B_REQ		: in std_logic;
		ROME_B_ACK		: out std_logic;
		
		NODE_DATA		: in std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
		NODE_REQ			: in std_logic;
		NODE_ACK			: out std_logic;
		
		SPINNAKER_DATA	: in std_logic_vector(SPINNAKER_DATA_WIDTH-1 downto 0);
		SPINNAKER_REQ	: in std_logic;
		SPINNAKER_ACK	: out std_logic;
		
		LOGGER_DATA		: in std_logic_vector(BUFFER_WIDTH-1 downto 0);
		LOGGER_REQ		: in std_logic;
		LOGGER_ACK		: out std_logic;
		
		INPUT_SELECT	: in std_logic_vector(INPUT_NUMBER-1 downto 0);
		
		OUT_DATA			: out std_logic_vector(BUFFER_WIDTH-1 downto 0);
		OUT_REQ			: out std_logic;
		OUT_ACK			: in std_logic;
		
		STATUS 			: out STD_LOGIC);
end merger;

architecture Behavioral of merger is

	type state is (idle, rome_a, rome_b, node, logger, spinnaker);
	
	signal current_state, next_state : state;
	
begin

	signals_update : process (CLK, RST)
	begin
		if RST = '0' then
			current_state 			<= idle;
						
		elsif rising_edge(CLK) then
			current_state 			<= next_state;
						
		end if;
		
	end process signals_update;
	
	FSM_transition : process (current_state, ROME_A_REQ, ROME_B_REQ, NODE_REQ, SPINNAKER_REQ, LOGGER_REQ, INPUT_SELECT,
										ROME_A_DATA, ROME_B_DATA, NODE_DATA, LOGGER_DATA, SPINNAKER_DATA, OUT_ACK)
	begin
		ROME_A_ACK		<= '1';
		ROME_B_ACK		<= '1';
		NODE_ACK			<= '1';
		SPINNAKER_ACK	<= '1';
		LOGGER_ACK		<= '1';
		
		OUT_DATA			<= (others=>'0');
		OUT_REQ			<= '1';

		next_state	<= current_state;
		
		case current_state is
			when idle =>
				if INPUT_SELECT(0) = '1' and ROME_A_REQ = '0' then
					next_state <= rome_a;
				
				elsif INPUT_SELECT(1) = '1' and ROME_B_REQ = '0' then
					next_state <= rome_b;
					
				elsif INPUT_SELECT(2) = '1' and NODE_REQ = '0' then
					next_state <= node;
					
				elsif INPUT_SELECT(3) = '1' and LOGGER_REQ = '0' then
					next_state <= logger;
					
				elsif INPUT_SELECT(4) = '1' and SPINNAKER_REQ = '0' then
					next_state <= spinnaker;				
				end if;
			
			when rome_a =>
				OUT_DATA(BUFFER_WIDTH-1 downto BUFFER_WIDTH-3) 	<= b"000"; 
				OUT_DATA(ROME_DATA_WIDTH-1 downto 0)				<= ROME_A_DATA;
				OUT_REQ 														<= ROME_A_REQ;
				ROME_A_ACK													<= OUT_ACK;
				if INPUT_SELECT = b"00000" then
						next_state <= idle;
						
				elsif (ROME_A_REQ = '1' and OUT_ACK = '1') then
					if INPUT_SELECT(1) = '1' and ROME_B_REQ = '0' then
						next_state <= rome_b;
						
					elsif INPUT_SELECT(2) = '1' and NODE_REQ = '0' then
						next_state <= node;
						
					elsif INPUT_SELECT(3) = '1' and LOGGER_REQ = '0' then
						next_state <= logger;
					
					elsif INPUT_SELECT(4) = '1' and SPINNAKER_REQ = '0' then
						next_state <= spinnaker;

					end if;
				end if;
			
			when rome_b =>
				OUT_DATA(BUFFER_WIDTH-1 downto BUFFER_WIDTH-3)	<= b"001"; 
				OUT_DATA(ROME_DATA_WIDTH-1 downto 0)				<= ROME_B_DATA;
				OUT_REQ 														<= ROME_B_REQ;
				ROME_B_ACK													<= OUT_ACK;
				if INPUT_SELECT = b"00000" then
						next_state <= idle;
						
				elsif (ROME_B_REQ = '1' and OUT_ACK = '1') then
					if INPUT_SELECT(2) = '1' and NODE_REQ = '0' then
						next_state <= node;
						
					elsif INPUT_SELECT(3) = '1' and LOGGER_REQ = '0' then
						next_state <= logger;
						
					elsif INPUT_SELECT(4) = '1' and SPINNAKER_REQ = '0' then
						next_state <= spinnaker;
					
					elsif INPUT_SELECT(0) = '1' and ROME_A_REQ = '0' then
						next_state <= rome_a;
						
					end if;
				end if;
			
			when node =>
				OUT_DATA(BUFFER_WIDTH-1 downto BUFFER_WIDTH-3)	<= b"010"; 
				OUT_DATA(NODE_DATA_WIDTH-1 downto 0)				<= NODE_DATA;
				OUT_REQ 														<= NODE_REQ;
				NODE_ACK														<= OUT_ACK;
				if INPUT_SELECT = b"00000" then
						next_state <= idle;
						
				elsif (NODE_REQ = '1' and OUT_ACK = '1') then
					if INPUT_SELECT(3) = '1' and LOGGER_REQ = '0' then
						next_state <= logger;
						
					elsif INPUT_SELECT(4) = '1' and SPINNAKER_REQ = '0' then
						next_state <= spinnaker;
					
					elsif INPUT_SELECT(0) = '1' and ROME_A_REQ = '0' then
						next_state <= rome_a;
					
					elsif INPUT_SELECT(1) = '1' and ROME_B_REQ = '0' then
						next_state <= rome_b;
					
					end if;
				end if;
				
			when logger =>
				OUT_DATA(BUFFER_WIDTH-1 downto BUFFER_WIDTH-3)	<= b"011"; 
				OUT_DATA(BUFFER_WIDTH-4 downto 0)					<= LOGGER_DATA(BUFFER_WIDTH-4 downto 0);
				OUT_REQ 														<= LOGGER_REQ;
				LOGGER_ACK													<= OUT_ACK;
				if INPUT_SELECT = b"00000" then
						next_state <= idle;
						
				elsif (LOGGER_REQ = '1' and OUT_ACK = '1') then
					if INPUT_SELECT(4) = '1' and SPINNAKER_REQ = '0' then
						next_state <= spinnaker;
					
					elsif INPUT_SELECT(0) = '1' and ROME_A_REQ = '0' then
						next_state <= rome_a;
					
					elsif INPUT_SELECT(1) = '1' and ROME_B_REQ = '0' then
						next_state <= rome_b;
					
					elsif INPUT_SELECT(2) = '1' and NODE_REQ = '0' then
						next_state <= node;
				
					end if;
				end if;
			
			when spinnaker => 
				OUT_DATA(BUFFER_WIDTH-1 downto BUFFER_WIDTH-3)	<= b"100"; 
				OUT_DATA(SPINNAKER_DATA_WIDTH-1 downto 0)			<= SPINNAKER_DATA;
				OUT_REQ 														<= SPINNAKER_REQ;
				SPINNAKER_ACK												<= OUT_ACK;
				if INPUT_SELECT = b"00000" then
						next_state <= idle;
						
				elsif (SPINNAKER_REQ = '1' and OUT_ACK = '1') then
					if INPUT_SELECT(0) = '1' and ROME_A_REQ = '0' then
						next_state <= rome_a;
					
					elsif INPUT_SELECT(1) = '1' and ROME_B_REQ = '0' then
						next_state <= rome_b;
					
					elsif INPUT_SELECT(2) = '1' and NODE_REQ = '0' then
						next_state <= node;
						
					elsif INPUT_SELECT(3) = '1' and LOGGER_REQ = '0' then
						next_state <= logger;
					
					end if;
				end if;
			
			when others =>
				next_state <= idle;
				
		end case;
	end process;
	
end Behavioral;

