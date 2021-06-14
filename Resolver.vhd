library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Resolver is
  port (
	clk, up, down, reset, at_target: in std_logic;
	floor_counter : in std_logic_vector(3 downto 0);
	up_requests : in std_logic_vector(8 downto 0);
	down_requests : in std_logic_vector(8 downto 0);
	internal_requests : in std_logic_vector(8 downto 0);
	next_floor : out std_logic_vector(3 downto 0)
  ) ;
end entity ; -- Resolver

architecture arch of Resolver is

	signal sample_up_reg : std_logic;
	signal sample_down_reg : std_logic;

	signal nearest_up_request_above_current_floor : unsigned(3 downto 0);
	signal nearest_down_request_below_current_floor : unsigned(3 downto 0);

	signal up_requests_reg : std_logic_vector(8 downto 0);
	signal down_requests_reg : std_logic_vector(8 downto 0);

	signal valid_up_request_flag : std_logic;
	signal valid_down_request_flag : std_logic;

	signal floor_counter_reg : std_logic_vector(3 downto 0);

	signal next_floor_reg : std_logic_vector(3 downto 0);

	signal internal_requests_reg : std_logic_vector(8 downto 0);

	signal distance_between_current_and_nearest_up : std_logic_vector(3 downto 0);
	signal distance_between_current_and_nearest_down : std_logic_vector(3 downto 0);

	type resolver_state is (SAMPLE, RESOLVE, CLEAR);
	signal state_reg, state_next: resolver_state;

	type direction is (GOING_UP, GOING_DOWN, STOPPED);
	signal inferred_direction : direction;

begin

	reg_update : process( clk,reset )
	begin
		if(reset = '1') then
			
			state_reg <= SAMPLE;
			sample_up_reg <= '0';
			sample_down_reg <= '0';
			up_requests_reg <= (others => '0');
			down_requests_reg <= (others => '0');

		elsif (clk'event and clk='1') then
			
			state_reg <= state_next;

			if(state_reg = SAMPLE) then -- sample all inputs  

				up_requests_reg <= up_requests;
				down_requests_reg <= down_requests;
				internal_requests_reg <= internal_requests;
				floor_counter_reg <= floor_counter;

				if(not at_target = '1') then -- sample direction only if not at a target
					sample_up_reg <= up;
					sample_down_reg <= down;
				end if;
			
			-- log resolved floor
			elsif(state_reg = RESOLVE) then 

				if inferred_direction = GOING_UP and valid_up_request_flag = '1' then
					next_floor_reg <= std_logic_vector(nearest_up_request_above_current_floor);

				elsif inferred_direction = GOING_DOWN and valid_down_request_flag = '1' then
					next_floor_reg <= std_logic_vector(nearest_down_request_below_current_floor);

				else 

				--  either (1) stopped 
				--		or (2) valid request was not in the same direction inferred
				--		or (3) no requests

					if valid_down_request_flag = '1' and valid_up_request_flag = '1' then
						if(distance_between_current_and_nearest_up < distance_between_current_and_nearest_down) then
							next_floor_reg <= std_logic_vector(nearest_up_request_above_current_floor);
						else
							next_floor_reg <= std_logic_vector(nearest_down_request_below_current_floor);
						end if;			
					elsif valid_up_request_flag = '1' then
						next_floor_reg <= std_logic_vector(nearest_up_request_above_current_floor);
					elsif valid_down_request_flag = '1' then
						next_floor_reg <= std_logic_vector(nearest_down_request_below_current_floor);
					else
						next_floor_reg <= floor_counter_reg;
					end if;
				end if;

			elsif(state_reg = CLEAR) then
				if(at_target = '1') then
					internal_requests_reg(to_integer(unsigned(floor_counter_reg))) <= '0';
					if (inferred_direction = GOING_UP) then
						up_requests_reg(to_integer(unsigned(floor_counter_reg))) <= '0';
					elsif(inferred_direction = GOING_DOWN) then 
						down_requests_reg(to_integer(unsigned(floor_counter_reg))) <= '0';
					end if;
				end if;
								
			end if;

		end if;
	end process reg_update; -- state_reg_update

	state_control : process( state_reg, up, down )
	begin
		case( state_reg ) is
		
			when SAMPLE =>
				state_next <= RESOLVE;
		
			when RESOLVE =>
				state_next <= CLEAR;

			when CLEAR => 
				state_next <= SAMPLE;

			when others => 
				state_next <= SAMPLE;
		
		end case ;
	end process ; -- state_control

	
	resolve_direction : process( sample_up_reg, sample_down_reg )
	begin
		if(sample_up_reg = '1' and sample_down_reg = '0') then
			inferred_direction <= GOING_UP;
		elsif (sample_up_reg = '0' and sample_down_reg = '1') then
			inferred_direction <= GOING_DOWN;
		else
			inferred_direction <= STOPPED;
		end if;
	end process ; -- resolve_direction


	get_nearest_up_request_above_current_floor : process( internal_requests_reg, up_requests, floor_counter_reg )

		variable combined_requests : std_logic_vector(8 downto 0);
		variable floor_mask : std_logic_vector(8 downto 0);
		variable combined_requests_thermometer : std_logic_vector(8 downto 0);
	begin

		floor_mask := not (std_logic_vector(to_unsigned((2**(to_integer(unsigned(floor_counter_reg))+1))-1, 9)));
		combined_requests := ((internal_requests_reg or up_requests_reg) and floor_mask);

		combined_requests_thermometer(0) := combined_requests(0);
		thermometer_left : for i in 1 to 8 loop
			combined_requests_thermometer(i) := combined_requests_thermometer(i-1) or combined_requests(i);
		end loop ; -- thermometer_left


		nearest_up_request_above_current_floor <= unsigned(floor_counter_reg);
		valid_up_request_flag <= '0';

		get_nearest_request : for i in 1 to 8 loop
			if(unsigned(combined_requests_thermometer) = shift_left(to_unsigned(2**9-1,9), i)) then
				nearest_up_request_above_current_floor <= to_unsigned(i,4);
				valid_up_request_flag <= '1';
			end if;
		end loop ; -- get_nearest_request
		
		--end case ;
	end process ; -- get_nearest_up_request_above_current_floor

	get_nearest_down_request_below_current_floor : process( internal_requests_reg, down_requests_reg, floor_counter_reg )
		variable combined_requests : std_logic_vector(8 downto 0);
		variable floor_mask : std_logic_vector(8 downto 0);
		variable combined_requests_thermometer : std_logic_vector(8 downto 0);
	begin

		floor_mask := std_logic_vector(to_unsigned((2**(to_integer(unsigned(floor_counter_reg)))-1), 9));
		combined_requests := ((internal_requests_reg or down_requests_reg) and floor_mask);

		combined_requests_thermometer(8) := combined_requests(8);
		thermometer_right : for i in 7 downto 0 loop
			combined_requests_thermometer(i) := combined_requests_thermometer(i+1) or combined_requests(i);
		end loop ; -- thermometer_right

		nearest_down_request_below_current_floor <= unsigned(floor_counter_reg);
		valid_down_request_flag <= '0';

		get_nearest_request : for i in 1 to 8 loop
			if(unsigned(combined_requests_thermometer) = shift_right(to_unsigned(2**9-1,9), i)) then
				nearest_down_request_below_current_floor <= to_unsigned(8-i,4);
				valid_down_request_flag <= '1';
			end if;
		end loop ; -- get_nearest_request

	end process ; -- get_nearest_down_request_below_current_floor

	get_absolute_distances : process( 
			nearest_up_request_above_current_floor, 
			nearest_down_request_below_current_floor,
			floor_counter_reg
		)
	begin

		distance_between_current_and_nearest_up 
			<= std_logic_vector(abs(signed(nearest_up_request_above_current_floor)-signed(floor_counter_reg)));
		distance_between_current_and_nearest_down 
			<= std_logic_vector(abs(signed(nearest_down_request_below_current_floor)-signed(floor_counter_reg)));
		
	end process ; -- get_absolute_distances

	-- output 
	next_floor <= next_floor_reg;


end architecture ; -- arch