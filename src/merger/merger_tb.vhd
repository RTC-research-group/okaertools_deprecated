-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.merger_pkg.ALL;
use work.global_pkg.ALL;

ENTITY merger_tb IS
END merger_tb;

ARCHITECTURE behavior OF merger_tb IS 

	-- Component Declaration
	COMPONENT merger
	PORT(
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
		
		STATUS 			: out STD_LOGIC
	);
	END COMPONENT;

	signal clk					: std_logic;
	signal rst					: std_logic;
	
	signal rome_a_data		: std_logic_vector(ROME_DATA_WIDTH-1 downto 0);
	signal rome_a_req			: std_logic;
	signal rome_a_ack			: std_logic;

	signal rome_b_data		: std_logic_vector(ROME_DATA_WIDTH-1 downto 0);
	signal rome_b_req			: std_logic;
	signal rome_b_ack			: std_logic;

	signal node_data			: std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
	signal node_req			: std_logic;
	signal node_ack			: std_logic;
	
	signal logger_data		: std_logic_vector(BUFFER_WIDTH-1 downto 0);
	signal logger_req			: std_logic;
	signal logger_ack			: std_logic;

	signal spinnaker_data	: std_logic_vector(SPINNAKER_DATA_WIDTH-1 downto 0);
	signal spinnaker_req		: std_logic;
	signal spinnaker_ack		: std_logic;

	signal input_select		: std_logic_vector(INPUT_NUMBER-1 downto 0);

	signal out_data			: std_logic_vector(BUFFER_WIDTH-1 downto 0);
	signal out_req				: std_logic;
	signal out_ack				: std_logic;

	signal status 				: STD_LOGIC;
	
	-- Clock period definitions
   constant CLK_period : time := 10 ns;
	
	type state is (idle, req_fall, req_rise);
	signal current_state_rome_a, next_state_rome_a 			: state;
	signal current_state_rome_b, next_state_rome_b 			: state;
	signal current_state_node, next_state_node 				: state;
	signal current_state_logger, next_state_logger			: state;
	signal current_state_spinnaker, next_state_spinnaker 	: state;
	
	type state_handshake is (idle, req_fall);
	signal current_state_out, next_state_out 	: state_handshake;
          
BEGIN

	-- Component Instantiation
	uut: merger PORT MAP(
		CLK				=> clk,
		RST				=> rst,
		
		ROME_A_DATA		=> rome_a_data,
		ROME_A_REQ		=> rome_a_req,
		ROME_A_ACK		=> rome_a_ack,
		
		ROME_B_DATA		=> rome_b_data,
		ROME_B_REQ		=> rome_b_req,
		ROME_B_ACK		=> rome_b_ack,
		
		NODE_DATA		=> node_data,
		NODE_REQ			=> node_req,
		NODE_ACK			=> node_ack,
		
		SPINNAKER_DATA	=> spinnaker_data,
		SPINNAKER_REQ	=> spinnaker_req,
		SPINNAKER_ACK	=> spinnaker_ack,
		
		LOGGER_DATA		=> logger_data,
		LOGGER_REQ		=> logger_req,
		LOGGER_ACK		=> logger_ack,
		
		INPUT_SELECT	=> input_select,
		
		OUT_DATA			=> out_data,
		OUT_REQ			=> out_req,
		OUT_ACK			=> out_ack,
		
		STATUS			=> status
	);

	-- Clock process definitions
	CLK_process :process
	begin
		clk <= '0';
		wait for CLK_period/2;
		clk <= '1';
		wait for CLK_period/2;
	end process;

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '0';
		input_select <= b"00000";
		-- hold reset state for 100 ns.
      wait for 100 ns;
		rst <= '1';
		-- insert stimulus here
      wait for CLK_period*10;
		input_select <= b"00001";
		wait for CLK_period*20;
		input_select <= b"00000";
		wait for CLK_period*10;
		input_select <= b"00011";
		wait for CLK_period*20;
		input_select <= b"00100";
		wait for CLK_period*20;
		input_select <= b"01000";
		wait for CLK_period*20;
		input_select <= b"10000";
		wait for CLK_period*20;
		input_select <= b"11111";
      wait;
   end process;
	
	signals_update : process (clk, rst)
	begin
		if rst = '0' then
			current_state_rome_a 	<= idle;
			current_state_rome_b 	<= idle;
			current_state_node 		<= idle;
			current_state_logger		<= idle;
			current_state_spinnaker <= idle;
			current_state_out			<= idle;
			
		elsif rising_edge(clk) then
			current_state_rome_a 	<= next_state_rome_a;
			current_state_rome_b 	<= next_state_rome_b;
			current_state_node 		<= next_state_node;
			current_state_logger		<= next_state_logger;
			current_state_spinnaker <= next_state_spinnaker;
			current_state_out			<= next_state_out;

		end if;
	end process;
	
	FSM_transition : process (current_state_rome_a, rome_a_ack, current_state_rome_b, rome_b_ack,
										current_state_node, node_ack, current_state_logger, logger_ack,
										current_state_spinnaker, spinnaker_ack)
	begin
		next_state_rome_a 	<= current_state_rome_a;
		next_state_rome_b 	<= current_state_rome_b;
		next_state_node	 	<= current_state_node;
		next_state_logger	 	<= current_state_logger;
		next_state_spinnaker	<= current_state_spinnaker;
		
		rome_a_req				<= '1';
		rome_b_req				<= '1';
		node_req					<= '1';
		logger_req				<= '1';
		spinnaker_req			<= '1';
		
		rome_a_data			 	<= (others=>'0');
		rome_b_data			 	<= (others=>'0');
		node_data			 	<= (others=>'0');
		logger_data			 	<= (others=>'0');
		spinnaker_data		 	<= (others=>'0');
		
		case current_state_rome_a is
			when idle =>
				if rome_a_ack = '1' then
					next_state_rome_a <= req_fall;
				end if;
				
			when req_fall =>
				rome_a_req 			<= '0';
				rome_a_data			<= std_logic_vector(to_unsigned(1, ROME_DATA_WIDTH));
				if rome_a_ack = '0' then
					next_state_rome_a 	<= req_rise;
				end if;
			
			when req_rise =>
				rome_a_req 			<= '1';
				next_state_rome_a <= idle;
					
			when others =>
				next_state_rome_a <= idle;
		end case;
		
		
		case current_state_rome_b is
			when idle =>
				if rome_b_ack = '1' then
					next_state_rome_b <= req_fall;
				end if;
				
			when req_fall =>
				rome_b_req 			<= '0';
				rome_b_data			<= std_logic_vector(to_unsigned(2, ROME_DATA_WIDTH));
				if rome_b_ack = '0' then
					next_state_rome_b 	<= req_rise;
				end if;
			
			when req_rise =>
				rome_b_req 			<= '1';
				next_state_rome_b <= idle;
					
			when others =>
				next_state_rome_b <= idle;
		end case;
		
		
		case current_state_node is
			when idle =>
				if node_ack = '1' then
					next_state_node <= req_fall;
				end if;
				
			when req_fall =>
				node_req 			<= '0';
				node_data			<= std_logic_vector(to_unsigned(3, NODE_DATA_WIDTH));
				if node_ack = '0' then
					next_state_node 	<= req_rise;
				end if;
			
			when req_rise =>
				node_req 			<= '1';
				next_state_node <= idle;
					
			when others =>
				next_state_node <= idle;
		end case;
		
		case current_state_logger is
			when idle =>
				if logger_ack = '1' then
					next_state_logger <= req_fall;
				end if;
				
			when req_fall =>
				logger_req 			<= '0';
				logger_data			<= std_logic_vector(to_unsigned(4, BUFFER_WIDTH));
				if logger_ack = '0' then
					next_state_logger 	<= req_rise;
				end if;
			
			when req_rise =>
				logger_req 			<= '1';
				next_state_logger <= idle;
					
			when others =>
				next_state_logger <= idle;
		end case;
		
		case current_state_spinnaker is
			when idle =>
				if spinnaker_ack = '1' then
					next_state_spinnaker <= req_fall;
				end if;
				
			when req_fall =>
				spinnaker_req 			<= '0';
				spinnaker_data			<= std_logic_vector(to_unsigned(5, SPINNAKER_DATA_WIDTH));
				if spinnaker_ack = '0' then
					next_state_spinnaker 	<= req_rise;
				end if;
			
			when req_rise =>
				spinnaker_req 			<= '1';
				next_state_spinnaker <= idle;
					
			when others =>
				next_state_spinnaker <= idle;
		end case;
	end process;
	
	
	OUT_FSM_transitions : process (current_state_out, out_req)
	begin
		next_state_out	<= current_state_out;
		out_ack			<= '1';
		
		case current_state_out is
			when idle =>
				if out_req = '0' then
					next_state_out <= req_fall;
				end if;
				
			when req_fall =>
				out_ack	<= '0';
				if out_req = '1' then
					next_state_out <= idle;				
				end if;
				
			when others =>
				next_state_out <= idle;
		end case;
	end process;

  END;
