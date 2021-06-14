library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity Resolver_tb is
end Resolver_tb;

architecture Resolver_tb_arc of Resolver_tb is

	component Resolver
	  port (
		clk, up, down, reset, at_target: in std_logic;
		floor_counter : in std_logic_vector(3 downto 0);
		up_requests : in std_logic_vector(8 downto 0);
		down_requests : in std_logic_vector(8 downto 0);
		internal_requests : in std_logic_vector(8 downto 0);
		next_floor : out std_logic_vector(3 downto 0)
	  );
	end component;

	-- independent signals

	signal clk : std_logic := '0';
	signal reset : std_logic := '1';
	signal at_target : std_logic := '0';

	-- signals extracted from test vector file

	signal external_up : std_logic_vector(8 downto 0);
	signal external_down : std_logic_vector(8 downto 0);
	signal internal : std_logic_vector(8 downto 0);
	signal floor_counter : std_logic_vector(3 downto 0);
	signal up : std_logic;
	signal down : std_logic;

	-- output

	signal expected_target : std_logic_vector(3 downto 0);
	signal actual_target : std_logic_vector(3 downto 0);

	-- constants

	constant PERIOD : time := 10 ns;

begin

	dut : Resolver
	port map(
		clk => clk,
		reset => reset,
		up => up,
		down => down,
		floor_counter => floor_counter,
		at_target => at_target,
		internal_requests => internal,
		up_requests => external_up,
		down_requests => external_down,
		next_floor => actual_target
	);

	clk <= not clk after PERIOD/2;
	
	read_test_vector_file : process
		file test_vector_file : text open read_mode is "./TestVectorFileGenerator/testVectors";
		variable test_vector : line;
		variable vexternal_up : std_logic_vector(8 downto 0);
		variable vexternal_down : std_logic_vector(8 downto 0);
		variable vinternal : std_logic_vector(8 downto 0);
		variable vfloor_counter : std_logic_vector(3 downto 0);
		variable vup : std_logic;
		variable vdown : std_logic;
		variable vspace : character;
		variable vtarget : std_logic_vector(3 downto 0);
		variable vectorValid : boolean;
		variable vectorNumber : integer := 1;
	begin

		reset <= '1';

		wait for PERIOD;

		reset <= '0';

		read_loop : while not endfile(test_vector_file) loop

			readline(test_vector_file, test_vector);
			read(test_vector, vexternal_up, good => vectorValid);
			
			if (not vectorValid) then
				readline(test_vector_file, test_vector);
				read(test_vector, vexternal_up, good => vectorValid);
			end if;		

			read(test_vector, vspace);
			read(test_vector, vexternal_down);
			read(test_vector, vspace);
			read(test_vector, vinternal);
			read(test_vector, vspace);
			read(test_vector, vfloor_counter);
			read(test_vector, vspace);
			read(test_vector, vup);
			read(test_vector, vspace);
			read(test_vector, vdown);
			read(test_vector, vspace);
			read(test_vector, vtarget);

			external_up <= vexternal_up;
			external_down <= vexternal_down;
			internal <= vinternal;
			floor_counter <= vfloor_counter;
			up <= vup;
			down <= vdown;
			expected_target <= vtarget;

			wait for 2*PERIOD;

			assert expected_target = actual_target
			report "Invalid Expected Target"
			severity note;

			wait for PERIOD;

			vectorNumber := vectorNumber + 1;

		end loop ; -- read_loop

		wait;
		
	end process ; -- read_test_vector_file

end Resolver_tb_arc;