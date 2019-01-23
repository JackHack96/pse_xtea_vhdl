vsim work.xtea

add wave clk
add wave rst
add wave input_ready
add wave output_ready
add wave mode
add wave -radix hexadecimal text_input0
add wave -radix hexadecimal text_input1
add wave -radix hexadecimal key_input0
add wave -radix hexadecimal key_input1
add wave -radix hexadecimal data_output0
add wave -radix hexadecimal data_output1

add wave -radix hexadecimal key0
add wave -radix hexadecimal key1
add wave -radix hexadecimal key2
add wave -radix hexadecimal key3
add wave -radix hexadecimal status

# Set up 100mhz clock
force clk 0 0, 1 5ns -r 10ns

# Run encryption
force rst 0
force text_input0 16#12345678
force text_input1 16#9abcdeff
# Input keys
force key_input0 16#6a1d78c8
force key_input1 16#8c86d67f
force input_ready 1
run 5ns

force key_input0 16#2a65bfbe
force key_input1 16#b4bd6e46
force mode 0
force input_ready 1
run 500ns

# Reset the chip
force rst 1
force input_ready 0
run 50ns

# Run decryption
force rst 0
force text_input0 16#99bbb92b
force text_input1 16#3ebd1644
# Input keys
force key_input0 16#6a1d78c8
force key_input1 16#8c86d67f
force input_ready 1
run 5ns

force key_input0 16#2a65bfbe
force key_input1 16#b4bd6e46
force mode 1
force input_ready 1
run 500ns

# Reset the chip
force rst 1
force input_ready 0
run 50ns

# Run encryption
force rst 0
force text_input0 16#fd0fe0f1
force text_input1 16#ca2ea80a
# Input keys
force key_input0 16#6a1d78c8
force key_input1 16#8c86d67f
force input_ready 1
run 5ns

force key_input0 16#2a65bfbe
force key_input1 16#b4bd6e46
force mode 0
force input_ready 1
run 500ns

# Reset the chip
force rst 1
force input_ready 0
run 50ns

# Run decryption
force rst 0
force text_input0 16#1dc4dc42
force text_input1 16#11f66792
# Input keys
force key_input0 16#6a1d78c8
force key_input1 16#8c86d67f
force input_ready 1
run 5ns

force key_input0 16#2a65bfbe
force key_input1 16#b4bd6e46
force mode 1
force input_ready 1
run 500ns