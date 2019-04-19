----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:26:48 05/08/2014 
-- Design Name: 
-- Module Name:    Monitor - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.monitor_pkg.ALL;
use work.global_pkg.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity monitor is
    Port ( CLK 		: in  STD_LOGIC;
           RST 		: in  STD_LOGIC;
			  
           REQ 		: in  STD_LOGIC;
           AER_DATA 	: in  STD_LOGIC_VECTOR (AER_DATA_WIDTH-1 downto 0);
           ACK 		: out  STD_LOGIC;
			  
           OB_DATA 	: out  STD_LOGIC_VECTOR (BUFFER_WIDTH-1 downto 0);
           OB_VALID 	: out  STD_LOGIC;
			  
			  STATUS 	: out STD_LOGIC);
end monitor;

architecture Behavioral of monitor is

	type state is (idle, req_fall_0, req_fall_1, wait_req_rise, timestamp_overflow_0, timestamp_overflow_1);
	
	signal current_state, next_state : state;
	
	signal timestamp_r				: STD_LOGIC_VECTOR (TIMESTAMP_WIDTH-1 downto 0);
	signal timestamp_rst 			: STD_LOGIC;
	signal timestamp_ovf_r			: STD_LOGIC;
	signal timestamp_ovf_value		: STD_LOGIC_VECTOR (TIMESTAMP_WIDTH-1 downto 0);
	
	signal ob_data_n					: STD_LOGIC_VECTOR (BUFFER_WIDTH-1 downto 0);
	signal ob_valid_n					: STD_LOGIC;
	
	signal ack_n: STD_LOGIC;
		
begin
	
	STATUS <= not REQ;
	
	signals_update : process (CLK, RST)
	begin
		if RST = '0' then
			current_state 			<= idle;
			timestamp_ovf_r		<= '0';
			
		elsif rising_edge(CLK) then
			current_state 			<= next_state;
			
			if (timestamp_r = (timestamp_ovf_value-1)) then
				timestamp_ovf_r 	<= '1';
			else
				timestamp_ovf_r 	<= '0';
			end if;
			
		end if;
		
	end process signals_update;
	
	
	FSM_transition : process (current_state, REQ, timestamp_ovf_r, timestamp_r, AER_DATA)
	begin
		next_state 			<= current_state;
		timestamp_rst		<= '0';
		OB_DATA				<= (others=>'0');
		OB_VALID				<= '0';
		ACK					<= '1';
		
		case current_state is
			when idle =>
				if REQ = '0' then
					next_state 				<= req_fall_0;
				elsif timestamp_ovf_r = '1' then
					next_state 				<= timestamp_overflow_0;
				end if;
				
			when req_fall_0 =>
				OB_DATA(TIMESTAMP_WIDTH-1 downto 0)	<=  timestamp_r;
				OB_VALID										<= '1';
				timestamp_rst								<= '1';
				next_state 									<= req_fall_1;
				
			when req_fall_1 =>
				OB_DATA(AER_DATA_WIDTH-1 downto 0) 	<=  AER_DATA;
				OB_VALID										<= '1';
				timestamp_rst								<= '1';
				ACK											<= '0';
				next_state 									<= wait_req_rise;
				
			when wait_req_rise =>
				ACK							<= '0';
				if REQ = '1' then
					next_state 				<= idle;
				end if;
				
			when timestamp_overflow_0 =>
				OB_DATA					 	<= (others=>'1');
				OB_VALID						<= '1';
				timestamp_rst				<= '1';
				next_state 					<= timestamp_overflow_1;
				
			when timestamp_overflow_1 =>
				OB_DATA					 	<= (others=>'0');
				OB_VALID						<= '1';
				timestamp_rst				<= '1';
				next_state 					<= idle;
				
			when others => 
				next_state <= idle;
				
		end case;
	
	end process FSM_transition;
			
	timestamp_update : process (CLK, RST)
	begin
		if RST = '0' then
			timestamp_r 			<= (others=>'0');
			timestamp_ovf_value	<= (others=>'1');
			
		elsif rising_edge(CLK) then
			if timestamp_rst = '1' then
				timestamp_r <= (others => '0');
				
			else
				timestamp_r <= timestamp_r + 1;
			end if;
		end if;
		
	end process timestamp_update;
	
end Behavioral;


