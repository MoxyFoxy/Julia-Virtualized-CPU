# Julia-Virtualized-CPU
Julia Virtualized CPU, will possibly be used for a video game I'm making

# Infrastructure
The CPU has four registers, A (accumulator), B (open register), C (count register), and D (data register). There are also three pointers, the RP (read pointer), WP (write pointer), and SP (stack pointer). There is currently only a single interrupt, the UOI, or User Input Overflow Interrupt, which defaults to going back to the first line of code for now, may change later. The CPU also has three flags: OF, OF2, and OF3, all open flags that can be set with the TOGGLE opcode. As for memory, the CPU has 5kb of memory, and a 1kb stack. Memory addresses can be read through the RP's respective opcode, or by using %[register], which causes the register to act like a pointer, and call its numeric value from the memory array.

# OpCodes
write (for writing numerical values, but can also write one-word strings) - WRITE [numeric value, bit size (8 or 16 for all bit sizes hereon)]
strwrite (for writing strings) - STRWRITE [string]
read (for reading value to a register) - READ [register, bit size]
load (for loading values to a register/pointer/memory location) - LOAD [register/pointer/%register, value/register/%register]
push (for pushing to the stack) - PUSH [value, bit size]
pop (for popping values from the stack) - POP [location, bit size]
getin (gets user input up to 255 characters. Is loaded to the last 255 memory locations) - GETIN
wipein (wipes input) - WIPEIN
add (adds to values) - ADD [location, value]
sub (subtracts value 2 from value 1) - SUB [location, value]
iter (iterates a pointer 1 byte) - ITER [pointer (either RP or WP)]
jmp (unconditionally jumps to a line #. Use GOTO for labels) - JMP [line]
jeq (jumps if two values are equal) - JEQ [location, value, line]
jneq (jumps if two values are not equal) - JNEQ [location, value, line]
jgt (jumps if value 1 is greater than value 2) - JGT [location, value, line]
jngt (jumps if value 1 is not greater than value 2) - JNGT [location, value, line]
jlt (jumps if value 1 is less than value 2) - JLT [location, value, line]
jnlt (jumps if value 1 is not less than value 2) - JNLT [location, value, line]
jif (jumps if given open flag is true) - JIF [flag, line]
toggle (toggles the value of an open flag) - TOGGLE [flag]
print (prints to screen. Note that \n properly works) - PRINT [char amount/byte amount]
goto (goes to label) - GOTO [label]
hlt (stops the program) - HLT