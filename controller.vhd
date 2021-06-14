library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
	port (
		clk : in std_logic;
		reset : in std_logic;
		next_target : in std_logic_vector(3 downto 0);
		up : out std_logic;
		down : out std_logic;
		open_signal : out std_logic;
		at_target : out std_logic;
		floor_counter : out std_logic_vector(3 downto 0)
	);
end controller;

architecture controller_arc of controller is

	type controller_state is (IDLE, GOING_UP, GOING_DOWN, INC, DEC, DOOR_OPEN);
	signal state_reg, state_next : controller_state;

	signal t0 : unsigned(26 downto 0);
	signal t0_next : unsigned(26 downto 0);
	signal t1 : unsigned(26 downto 0);
	signal t1_next : unsigned(26 downto 0);
	constant t0Max_50Mhz : integer := 100000000;
	constant t1Max_50Mhz : integer := 100000000; 

	signal floor_counter_next : unsigned(3 downto 0);
	signal floor_counter_reg : unsigned(3 downto 0);

begin

	reg_update : process (reset, clk)
	begin
	  if (reset = '1') then
	    
	    state_reg <= IDLE;	
	    floor_counter_reg <= (others => '0');
	    t0 <= (others => '0');
	    t1 <= (others => '0');

	  elsif (rising_edge(clk)) then
	  	
	  	floor_counter_reg <= floor_counter_next;
	  	t0 <= t0_next;
	  	t1 <= t1_next;
		state_reg <= state_next;

	  end if;
	end process reg_update;

	state_control : process(state_reg, next_target, floor_counter_reg, t0, t1)
	begin
		t0_next <= t0 + 1;
		t1_next <= t1 + 1;
		floor_counter_next <= floor_counter_reg;

		case(state_reg) is
			when IDLE => 

				if (unsigned(next_target)>floor_counter_reg) then
					state_next <= GOING_UP;
					t0_next <= (others => '0'); -- reset t0

				elsif(unsigned(next_target)<floor_counter_reg) then
					state_next <= GOING_DOWN;
					t0_next <= (others => '0'); -- reset t0
				else 
					state_next <= IDLE;
				end if;

			when GOING_UP =>

				if(to_integer(t0)<t0Max_50Mhz) then
					state_next <= GOING_UP;
				else
					state_next <= INC;
				end if;

			when GOING_DOWN =>

				if(to_integer(t0)<t0Max_50Mhz) then
					state_next <= GOING_DOWN;
				else
					state_next <= DEC;
				end if;

			when INC => 

				floor_counter_next <= floor_counter_reg+1;
				if(unsigned(next_target)>floor_counter_reg+1) then
					state_next <= GOING_UP;
				else
					state_next <= DOOR_OPEN;
					t1_next <= (others => '0');
				end if;

			when DEC => 

				floor_counter_next <= floor_counter_reg-1;
				if(unsigned(next_target)<floor_counter_reg-1) then
					state_next <= GOING_DOWN;
				else
					state_next <= DOOR_OPEN;
					t1_next <= (others => '0');
				end if;

			when DOOR_OPEN =>

				if(to_integer(t1)<t1Max_50Mhz) then
					state_next <= DOOR_OPEN;
				else 
					state_next <= IDLE;
				end if;

			when others =>
				null;
		end case;
	end process ; -- state_control

	-- output

	output : process( state_reg )
	begin
		floor_counter <= std_logic_vector(floor_counter_reg);
		at_target <= '0';
		up <= '0';
		down <= '0';
		open_signal <= '0';

		case(state_reg) is
			when IDLE => 
				at_target <= '1';
			when GOING_UP =>
				up <= '1';
			when GOING_DOWN =>
				down <= '1';
			when DOOR_OPEN =>
				open_signal <= '1';
				at_target <= '1';
			when INC =>
				up <= '1';
			when DEC =>
				down <= '1';
			when others =>
				null;
		end case;
	end process ; -- output

end controller_arc;