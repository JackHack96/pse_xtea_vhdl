library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_BIT.all;

package XTEA_PACK is
	constant SIZE : integer := 32;
	-- States definition
	constant IDLE : integer := 0;
	constant BUSY_KEY : integer := 1;
	constant BUSY_ENC_INPUT : integer := 2;
	constant BUSY_ENC1 : integer := 3;
	constant BUSY_ENC2 : integer := 4;
	constant BUSY_ENC_OUTPUT : integer := 5;
	constant BUSY_DEC_INPUT : integer := 6;
	constant BUSY_DEC1 : integer := 7;
	constant BUSY_DEC2 : integer := 8;
	constant BUSY_DEC_OUTPUT : integer := 9;
end XTEA_PACK;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_BIT.all;
use WORK.XTEA_PACK.all;

entity XTEA is
	port (
		clk : in bit;
		rst : in bit;

		text_input0 : in UNSIGNED (SIZE - 1 downto 0);
		text_input1 : in UNSIGNED (SIZE - 1 downto 0);

		key_input0 : in UNSIGNED (SIZE - 1 downto 0);
		key_input1 : in UNSIGNED (SIZE - 1 downto 0);
		key_input2 : in UNSIGNED (SIZE - 1 downto 0);
		key_input3 : in UNSIGNED (SIZE - 1 downto 0);

		data_output0 : out UNSIGNED (SIZE - 1 downto 0);
		data_output1 : out UNSIGNED (SIZE - 1 downto 0);

		input_ready : in bit;
		mode : in bit;
		output_ready : out bit
	);
end XTEA;

architecture BEHAVIORAL of XTEA is
	subtype STATUS_T is integer range 0 to 9;
	subtype INTERNAL32_T is UNSIGNED (SIZE - 1 downto 0);
	subtype INTERNAL64_T is UNSIGNED (63 downto 0);

	signal STATUS : STATUS_T;
	signal NEXT_STATUS : STATUS_T;
	signal KEY0 : INTERNAL32_T;
	signal KEY1 : INTERNAL32_T;
	signal KEY2 : INTERNAL32_T;
	signal KEY3 : INTERNAL32_T;
	signal TEXT0 : INTERNAL32_T;
	signal TEXT1 : INTERNAL32_T;
	signal RESULT0 : INTERNAL32_T;
	signal RESULT1 : INTERNAL32_T;

	signal COUNTER : UNSIGNED(6 downto 0);
	signal SUM : INTERNAL64_T;

	constant DELTA : INTERNAL32_T := "10011110001101110111100110111001";
	constant ZERO32 : INTERNAL32_T := "00000000000000000000000000000000";
	constant ZERO64 : INTERNAL64_T := "0000000000000000000000000000000000000000000000000000000000000000";
	constant ONE : INTERNAL64_T := "0000000000000000000000000000000000000000000000000000000000000001";
	constant TWO : INTERNAL64_T := "0000000000000000000000000000000000000000000000000000000000000010";
	constant THREE : INTERNAL64_T := "0000000000000000000000000000000000000000000000000000000000000011";
begin
	-- FSM
	process (STATUS, input_ready)
	begin
		case STATUS is
			when IDLE => 
				if input_ready = '1' then
					NEXT_STATUS <= BUSY_KEY;
				else
					NEXT_STATUS <= IDLE;
				end if;
			when BUSY_KEY => 
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
					NEXT_STATUS <= BUSY_ENC_OUTPUT;
				else
					NEXT_STATUS <= BUSY_ENC1;
				end if;
			when BUSY_ENC_OUTPUT => 
				NEXT_STATUS <= BUSY_ENC_OUTPUT;
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
					NEXT_STATUS <= BUSY_DEC_OUTPUT;
				else
					NEXT_STATUS <= BUSY_DEC1;
				end if;
			when BUSY_DEC_OUTPUT =>
				NEXT_STATUS <= BUSY_DEC_OUTPUT;
			when others => 
				NEXT_STATUS <= STATUS;
		end case;
	end process;

	-- DATAPATH
	process (clk, rst)
		begin
			if rst = '1' then
				STATUS <= IDLE;
				data_output0 <= ZERO32;
				data_output1 <= ZERO32;
				output_ready <= '0';
				key0 <= ZERO32;
				key1 <= ZERO32;
				key2 <= ZERO32;
				key3 <= ZERO32;
				text0 <= ZERO32;
				text1 <= ZERO32;
				counter <= "0000000";
				sum <= ZERO64;
			else
				STATUS <= NEXT_STATUS;
				case NEXT_STATUS is
					when IDLE => 
						data_output0 <= ZERO32;
						data_output1 <= ZERO32;
						output_ready <= '0';
					when BUSY_KEY => 
						KEY0 <= key_input0;
						KEY1 <= key_input1;
						KEY2 <= key_input2;
						KEY3 <= key_input3;
					when BUSY_ENC_INPUT => 
						TEXT0 <= text_input0;
						TEXT1 <= text_input1;
					when BUSY_ENC1 => 
						case (sum and THREE) is
							when ZERO64 => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY0));
							when ONE => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY1));
							when TWO => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY2));
							when THREE => 
							TEXT0 <= TEXT0 + ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY3));
							when others =>
							report "Error during encryption";
						end case;
						SUM <= SUM + delta; 
					when BUSY_ENC2 => 
						case ((sum srl 11) and THREE) is
							when ZERO64 => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY0));
							when ONE => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY1));
							when TWO => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY2));
							when THREE => 
							TEXT1 <= TEXT1 + ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY3));
							when others =>
							report "Error during encryption";
						end case;
						counter <= counter + 1;
					when BUSY_ENC_OUTPUT =>
						data_output0 <= TEXT0;
						data_output1 <= TEXT1;
						output_ready <= '1';
					when BUSY_DEC_INPUT => 
						TEXT0 <= text_input0;
						TEXT1 <= text_input1;
						sum <= delta * SIZE;
					when BUSY_DEC1 => 
						case ((sum srl 11) and THREE) is
							when ZERO64 => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY0));
							when ONE => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY1));
							when TWO => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY2));
							when THREE => 
							TEXT1 <= TEXT1 - ((((TEXT0 sll 4) xor (TEXT0 srl 5)) + TEXT0) xor (sum(31 downto 0) + KEY3));
							when others =>
							report "Error during encryption";
						end case;
						sum <= sum - delta;
					when BUSY_DEC2 =>
						case (sum and THREE) is
							when ZERO64 => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY0));
							when ONE => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY1));
							when TWO => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY2));
							when THREE => 
							TEXT0 <= TEXT0 - ((((TEXT1 sll 4) xor (TEXT1 srl 5)) + TEXT1) xor (sum(31 downto 0) + KEY3));
							when others =>
							report "Error during encryption";
						end case;
						counter <= counter + 1;
					when BUSY_DEC_OUTPUT => 
						data_output0 <= TEXT0;
						data_output1 <= TEXT1;
						output_ready <= '1';
					when others => 
						data_output0 <= ZERO32;
						data_output1 <= ZERO32;
				end case;
			end if;
		end process;
end architecture;