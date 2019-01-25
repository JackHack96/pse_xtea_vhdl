library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_BIT.all;

package XTEA_PACK is
	-- States definition
	constant IDLE 				: UNSIGNED(3 downto 0) := "0000";
	constant BUSY_KEY1 			: UNSIGNED(3 downto 0) := "0001";
	constant BUSY_KEY2 			: UNSIGNED(3 downto 0) := "0010";
	constant BUSY_ENC_INPUT 	: UNSIGNED(3 downto 0) := "0011";
	constant BUSY_ENC1 			: UNSIGNED(3 downto 0) := "0100";
	constant BUSY_ENC2 			: UNSIGNED(3 downto 0) := "0101";
	constant BUSY_ENC_OUTPUT1	: UNSIGNED(3 downto 0) := "0110";
	constant BUSY_ENC_OUTPUT2	: UNSIGNED(3 downto 0) := "0111";
	constant BUSY_DEC_INPUT 	: UNSIGNED(3 downto 0) := "1000";
	constant BUSY_DEC1 			: UNSIGNED(3 downto 0) := "1001";
	constant BUSY_DEC2 			: UNSIGNED(3 downto 0) := "1010";
	constant BUSY_DEC_OUTPUT1 	: UNSIGNED(3 downto 0) := "1011";
	constant BUSY_DEC_OUTPUT2 	: UNSIGNED(3 downto 0) := "1100";
end XTEA_PACK;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_BIT.all;
use WORK.XTEA_PACK.all;

entity XTEA is
	port (
		clk 			: in 	BIT;
		rst 			: in 	BIT;
		data_input 		: in 	UNSIGNED (63 downto 0);
		data_output 	: out 	UNSIGNED (31 downto 0);
		input_ready 	: in 	BIT;
		mode 			: in 	BIT;
		output_ready 	: out 	BIT
	);
end XTEA;

architecture BEHAVIORAL of XTEA is
	subtype STATUS_T 		is UNSIGNED (3 downto 0);
	subtype INTERNAL32_T 	is UNSIGNED (31 downto 0);

	signal STATUS 		: STATUS_T;
	signal NEXT_STATUS 	: STATUS_T;
	signal KEY0 		: INTERNAL32_T;
	signal KEY1 		: INTERNAL32_T;
	signal KEY2 		: INTERNAL32_T;
	signal KEY3 		: INTERNAL32_T;
	signal TEXT0 		: INTERNAL32_T;
	signal TEXT1 		: INTERNAL32_T;
	signal COUNTER 		: UNSIGNED(5 downto 0);
	signal SUM 			: INTERNAL32_T;

	constant DELTA 		: INTERNAL32_T := "10011110001101110111100110111001";
	constant ZERO 		: INTERNAL32_T := "00000000000000000000000000000000";
	constant ONE 		: INTERNAL32_T := "00000000000000000000000000000001";
	constant TWO 		: INTERNAL32_T := "00000000000000000000000000000010";
	constant THREE 		: INTERNAL32_T := "00000000000000000000000000000011";
begin
	-- FSM
	process (STATUS, input_ready)
	begin
		case STATUS is
			when IDLE => 
				if input_ready = '1' then
					NEXT_STATUS <= BUSY_KEY1;
				else
					NEXT_STATUS <= IDLE;
				end if;
			when BUSY_KEY1 =>
				if input_ready = '1' then
					NEXT_STATUS <= BUSY_KEY2;
				else
					NEXT_STATUS <= BUSY_KEY1;
				end if;
			when BUSY_KEY2 => 
				if mode = '0' then
					NEXT_STATUS <= BUSY_ENC_INPUT;
				else
					NEXT_STATUS <= BUSY_DEC_INPUT;
				end if;
			when BUSY_ENC_INPUT => 
				if input_ready = '1' then
					NEXT_STATUS <= BUSY_ENC1;
				else
					NEXT_STATUS <= BUSY_ENC_INPUT;
				end if;
			when BUSY_ENC1 => 
				NEXT_STATUS <= BUSY_ENC2;
			when BUSY_ENC2 => 
				if COUNTER = "100000" then
					NEXT_STATUS <= BUSY_ENC_OUTPUT1;
				else
					NEXT_STATUS <= BUSY_ENC1;
				end if;
			when BUSY_ENC_OUTPUT1 => 
				NEXT_STATUS <= BUSY_ENC_OUTPUT2;
			when BUSY_ENC_OUTPUT2 => 
				NEXT_STATUS <= BUSY_ENC_OUTPUT1;
			when BUSY_DEC_INPUT => 
				if input_ready = '1' then
					NEXT_STATUS <= BUSY_DEC1;
				else
					NEXT_STATUS <= BUSY_DEC_INPUT;
				end if;
			when BUSY_DEC1 => 
				NEXT_STATUS <= BUSY_DEC2;
			when BUSY_DEC2 => 
				if COUNTER = "100000" then
					NEXT_STATUS <= BUSY_DEC_OUTPUT1;
				else
					NEXT_STATUS <= BUSY_DEC1;
				end if;
			when BUSY_DEC_OUTPUT1 =>
				NEXT_STATUS <= BUSY_DEC_OUTPUT2;
			when BUSY_DEC_OUTPUT2 =>
				NEXT_STATUS <= BUSY_DEC_OUTPUT1;
			when others => 
				NEXT_STATUS <= STATUS;
		end case;
	end process;

	-- DATAPATH
	process (clk, rst)
		begin
			if rst = '1' then
				STATUS <= IDLE;
				data_output <= ZERO;
				output_ready <= '0';
				KEY0 <= ZERO;
				KEY1 <= ZERO;
				KEY2 <= ZERO;
				KEY3 <= ZERO;
				TEXT0 <= ZERO;
				TEXT1 <= ZERO;
				COUNTER <= "000000";
				SUM <= ZERO;
			else
				STATUS <= NEXT_STATUS;
				case NEXT_STATUS is
					when IDLE => 
						data_output <= ZERO;
						output_ready <= '0';
					when BUSY_KEY1 => 
						KEY0 <= data_input(31 downto 0);
						KEY1 <= data_input(63 downto 32);
					when BUSY_KEY2 => 
						KEY2 <= data_input(31 downto 0);
						KEY3 <= data_input(63 downto 32);
					when BUSY_ENC_INPUT => 
						TEXT0 <= data_input(31 downto 0);
						TEXT1 <= data_input(63 downto 32);
					when BUSY_ENC1 => 
						case (SUM and THREE) is
							when ZERO => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY0));
							when ONE => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY1));
							when TWO => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY2));
							when others => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY3));
						end case;
						SUM <= SUM + delta; 
					when BUSY_ENC2 => 
						case ((SUM srl 11) and THREE) is
							when ZERO => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY0));
							when ONE => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY1));
							when TWO => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY2));
							when others => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY3));
						end case;
						COUNTER <= COUNTER + 1;
					when BUSY_ENC_OUTPUT1 =>
						data_output <= TEXT0;
						output_ready <= '1';
					when BUSY_ENC_OUTPUT2 =>
						data_output <= TEXT1;
					when BUSY_DEC_INPUT => 
						TEXT0 <= data_input(31 downto 0);
						TEXT1 <= data_input(63 downto 32);
						SUM <= "11000110111011110011011100100000";
					when BUSY_DEC1 => 
						case ((SUM srl 11) and THREE) is
							when ZERO => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY0));
							when ONE => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY1));
							when TWO => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY2));
							when others => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (SUM + KEY3));
						end case;
						SUM <= SUM - delta;
					when BUSY_DEC2 =>
						case (SUM and THREE) is
							when ZERO => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY0));
							when ONE => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY1));
							when TWO => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY2));
							when others => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (SUM + KEY3));
						end case;
						COUNTER <= COUNTER + 1;
					when BUSY_DEC_OUTPUT1 => 
						data_output <= TEXT0;
						output_ready <= '1';
					when BUSY_DEC_OUTPUT2=>
						data_output <= TEXT1;
					when others => 
						data_output <= ZERO;
				end case;
			end if;
		end process;
end architecture;