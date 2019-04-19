--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:17:09 03/11/2019
-- Design Name:   
-- Module Name:   /home/arios/Projects/okaertools/src/monitor/monitor_tb.vhd
-- Project Name:  okaertools
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: monitor
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY monitor_tb IS
END monitor_tb;
 
ARCHITECTURE behavior OF monitor_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT monitor
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         REQ : IN  std_logic;
         AER_DATA : IN  std_logic_vector(31 downto 0);
         ACK : OUT  std_logic;
         OB_DATA : OUT  std_logic_vector(31 downto 0);
         OB_VALID : OUT  std_logic;
         STATUS : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK 				: std_logic := '0';
   signal RST 				: std_logic := '0';
   signal REQ 				: std_logic := '0';
   signal AER_DATA 		: std_logic_vector(31 downto 0) := (others => '0');
	
	signal aer_data_r 	: std_logic_vector(31 downto 0) := (others => '0');
	signal force_ovf		: std_logic;
	
 	--Outputs
   signal ACK 				: std_logic;
   signal OB_DATA 		: std_logic_vector(31 downto 0);
   signal OB_VALID 		: std_logic;
   signal STATUS 			: std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
	
	type state is (idle, req_fall, req_rise);
	signal current_state, next_state : state;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: monitor PORT MAP (
          CLK => CLK,
          RST => RST,
          REQ => REQ,
          AER_DATA => AER_DATA,
          ACK => ACK,
          OB_DATA => OB_DATA,
          OB_VALID => OB_VALID,
          STATUS => STATUS
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;
		force_ovf <= '0';
		RST <= '0';
      wait for CLK_period*10;
		RST <= '1';
      -- insert stimulus here
		
		wait for 500 us;
		force_ovf <= '1';
		wait for 2 ms;
		force_ovf <= '0';
		
      wait;
   end process;

	signals_update : process (CLK, RST)
	begin
		if RST = '0' then
			current_state <= idle;
			
		elsif rising_edge(CLK) then
			current_state 	<= next_state;
			
			if REQ = '1' and ACK = '0' then
				aer_data_r <= aer_data_r + 1;
			end if;
		end if;
	end process;
	
	FSM_transition : process (current_state, aer_data_r, ACK, force_ovf)
	begin
		next_state 	<= current_state;
		REQ			<= '1';
		AER_DATA	 	<= (others=>'0');
		
		case current_state is
			when idle =>
				if ACK = '1' and force_ovf = '0' then
					next_state <= req_fall;
				end if;
				
			when req_fall =>
				REQ 			<= '0';
				AER_DATA 	<= aer_data_r;
				if ACK = '0' then
					next_state 	<= req_rise;
				end if;
			
			when req_rise =>
				REQ 			<= '1';
				next_state 	<= idle;
					
			when others =>
				next_state <= idle;
		end case;
	end process;

END;
