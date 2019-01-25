# Simulation script for XTEA
# by Matteo Iervasi
vsim work.xtea

add wave clk
add wave rst
add wave input_ready
add wave output_ready
add wave mode
add wave -radix hexadecimal -color yellow data_input
add wave -radix hexadecimal -color yellow data_output

add wave -radix hexadecimal -color red key0
add wave -radix hexadecimal -color red key1
add wave -radix hexadecimal -color red key2
add wave -radix hexadecimal -color red key3
add wave -radix hexadecimal -color red text0
add wave -radix hexadecimal -color red text1
add wave -radix unsigned -color blue status

# Set up 100mhz clock
force clk 0 0, 1 5ns -r 10ns

## START ENCRYPTION
force rst 0
force mode 0
# Input keys
force data_input 16#8c86d67f6a1d78c8
force input_ready 1
run 5ns
force data_input 16#b4bd6e462a65bfbe
run 5ns
# Input text
force data_input 16#9abcdeff12345678
force input_ready 1
run 500ns
## END ENCRYPTION

## RESET THE CHIP
force rst 1
force input_ready 0
run 50ns

## START DECRYPTION
force rst 0
force mode 1
# Input keys
force data_input 16#8c86d67f6a1d78c8
force input_ready 1
run 5ns
force data_input 16#b4bd6e462a65bfbe
run 5ns
# Input text
force data_input 16#3ebd164499bbb92b
force input_ready 1
run 500ns
## END DECRYPTION

## RESET THE CHIP
force rst 1
force input_ready 0
run 50ns

## RUN ENCRYPTION
force rst 0
force mode 0
# Input keys
force data_input 16#8c86d67f6a1d78c8
force input_ready 1
run 5ns
force data_input 16#b4bd6e462a65bfbe
run 5ns
# Input text
force data_input 16#ca2ea80afd0fe0f1
force input_ready 1
run 500ns
## END ENCRYPTION

## RESET THE CHIP
force rst 1
force input_ready 0
run 50ns

# RUN DECRYPTION
force rst 0
force mode 1
# Input keys
force data_input 16#8c86d67f6a1d78c8
force input_ready 1
run 5ns
force data_input 16#b4bd6e462a65bfbe
run 5ns
# Input text
force data_input 16#11f667921dc4dc42
force input_ready 1
run 500ns
## END DECRYPTION