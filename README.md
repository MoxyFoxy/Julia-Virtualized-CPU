# Julia-Virtualized-CPU
Julia Virtualized CPU, will possibly be used for a video game I'm making. This was made as a fun little side project to learn Julia, and is not meant to be a faithful recreation of Assembly or how a CPU truly works. While it is faithful to some portions, it's not meant to be a 100% perfect virtualization. There are many limitations that I may decide to change, depending on if I feel the want to come back to this project.

# Infrastructure
The CPU has four 16-bit registers, A (accumulator), B (open register), C (count register), and D (data register). There are also three 16-bit pointers, the RP (read pointer), WP (write pointer), and SP (stack pointer). There is currently only a single interrupt, the UOI, or User Input Overflow Interrupt, which defaults to going back to the first line of code for now, may change later. The CPU also has three flags: OF, OF2, and OF3, all open flags that can be set with the TOGGLE opcode. As for memory, the CPU has 5kb of memory, and a 1kb stack. Memory addresses can be read through the RP's respective opcode, or by using %[register], which causes the register to act like a pointer, and call its numeric value from the memory array.

# How to run it
Make sure to install the Julia binary from julialang.org or compile it yourself from source. In the console, cd to the folder where cpu.jl is and type "julia cpu.jl path/to/file.jlasm" then optionally add in " true" at the end to enter debug mode.

# OpCodes
write (for writing numerical values, but can also write one-word strings) - WRITE [numeric value, bit size (8 or 16 for all bit sizes hereon)]

strwrite (for writing strings. NOTE: only does uppercase. To get lowercase characters, use write with their integer values) - STRWRITE [string]

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

print (prints set amount of bytes from memory at RP to screen. Note that \n properly works) - PRINT [char amount/byte amount]

goto (goes to label) - GOTO [label]

hlt (stops the program) - HLT

# Example
### Code (asm-test/stringchecktest.jlasm)
```
.start
	push 20 8						; Where to jump to after the string test

	strwrite This is equivalent.\n
	write 0 16						; For some odd reason, double null buffer is needed or rogue 0x54 enters the fray
	print 20
	iter WP
	iter RP
	iter RP

	push 1 8						; Pointer to first string. 1-based indexing
	push RP 8						; Pointer to second string

	strwrite This is equivalent.\n
	write 0 8
	print 20

	goto .stringtest

	jif OF 25						; Check to see if first OF is set to true
	strwrite The strings are not equal.
	print 26
	hlt

	strwrite The strings are equal.
	print 22
	hlt

	.stringtest
		pop B 8
		pop D 8

		.stringtestloop
			jeq %B 0 45				; Check to see if first string has terminated
			jeq %D 0 38				; Check to see if second string has terminated (if first string hasn't terminated)

			jeq %B %D 41				; Check to see if the two characters are equal
			pop B 8
			jmp B

			add B 1					; End of main loop
			add D 1
			goto .stringtestloop

			jeq %D 0 49				; Check to see if second string has terminated (if the first string HAS terminated)
			pop B 8
			jmp B

			toggle OF				; If both are terminated without previously jumping out, set OF to true
			pop B 8
			jmp B
```
### Debug Output
```
Loading File: asm-test/stringchecktest.jlasm
Labels: Dict("STRINGTESTLOOP"=>33,"STRINGTEST"=>29,"START"=>1)
1: .START
2: PUSH 20 8
3:
4: STRWRITE THIS IS EQUIVALENT.\N
        Wrote "This is equivalent.
" to 1 through 21
5: WRITE 0 16
        Writing 0 to 21
6: PRINT 20
This is equivalent.

7: ITER WP
8: ITER RP
9: ITER RP
10:
11: PUSH 1 8
12: PUSH RP 8
13:
14: STRWRITE THIS IS EQUIVALENT.\N
        Wrote "This is equivalent.
" to 23 through 43
15: WRITE 0 8
        Writing 0 to 43
16: PRINT 20
This is equivalent.

17:
18: GOTO .STRINGTEST
30: POP B 8
31: POP D 8
32:
33: .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 84
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 84
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 84
        ARG2: 84
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 104
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 104
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 104
        ARG2: 104
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 115
        ARG2: 115
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 32
        ARG2: 32
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 115
        ARG2: 115
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 32
        ARG2: 32
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 101
        ARG2: 101
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 113
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 113
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 113
        ARG2: 113
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 117
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 117
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 117
        ARG2: 117
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 118
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 118
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 118
        ARG2: 118
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 97
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 97
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 97
        ARG2: 97
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 108
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 108
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 108
        ARG2: 108
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 101
        ARG2: 101
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 110
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 110
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 110
        ARG2: 110
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 116
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 116
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 116
        ARG2: 116
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 46
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 46
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 46
        ARG2: 46
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 10
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 10
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 10
        ARG2: 10
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 0
        ARG2: 0
        ARG1 == ARG2: true
45: JEQ %D 0 49
        ARG1: 0
        ARG2: 0
        ARG1 == ARG2: true
49: TOGGLE OF
        OF: true
50: POP B 8
51: JMP B
20: JIF OF 25
OF: true
25: STRWRITE THE STRINGS ARE EQUAL.
        Wrote "The strings are equal." to 43 through 65
26: PRINT 22
The strings are equal.
27: HLT

F:\Git Projects\julia-virtualized-cpu\Julia-Virtualized-CPU>julia cpu.jl asm-test/stringchecktest.jlasm true
Loading File: asm-test/stringchecktest.jlasm
Labels: Dict("STRINGTESTLOOP"=>33,"STRINGTEST"=>29,"START"=>1)
1: .START
2: PUSH 20 8
3:
4: STRWRITE THIS IS EQUIVALENT.\N
        Wrote "This is equivalent.
        " to 1 through 21
5: WRITE 0 16
        Writing 0 to 21
6: PRINT 20
This is equivalent.

7: ITER WP
8: ITER RP
9: ITER RP
10:
11: PUSH 1 8
12: PUSH RP 8
13:
14: STRWRITE THIS IS EQUIVALENT.\N
        Wrote "This is equivalent.
        " to 23 through 43
15: WRITE 0 8
        Writing 0 to 43
16: PRINT 20
This is equivalent.

17:
18: GOTO .STRINGTEST
30: POP B 8
31: POP D 8
32:
33: .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 84
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 84
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 84
        ARG2: 84
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 104
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 104
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 104
        ARG2: 104
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 115
        ARG2: 115
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 32
        ARG2: 32
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 115
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 115
        ARG2: 115
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 32
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 32
        ARG2: 32
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 101
        ARG2: 101
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 113
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 113
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 113
        ARG2: 113
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 117
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 117
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 117
        ARG2: 117
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 105
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 105
        ARG2: 105
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 118
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 118
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 118
        ARG2: 118
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 97
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 97
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 97
        ARG2: 97
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 108
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 108
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 108
        ARG2: 108
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 101
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 101
        ARG2: 101
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 110
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 110
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 110
        ARG2: 110
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 116
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 116
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 116
        ARG2: 116
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 46
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 46
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 46
        ARG2: 46
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 10
        ARG2: 0
        ARG1 == ARG2: false
35: JEQ %D 0 38
        ARG1: 10
        ARG2: 0
        ARG1 == ARG2: false
36:
37: JEQ %B %D 41
        ARG1: 10
        ARG2: 10
        ARG1 == ARG2: true
41: ADD B 1
42: ADD D 1
43: GOTO .STRINGTESTLOOP
34: JEQ %B 0 45
        ARG1: 0
        ARG2: 0
        ARG1 == ARG2: true
45: JEQ %D 0 49
        ARG1: 0
        ARG2: 0
        ARG1 == ARG2: true
49: TOGGLE OF
        OF: true
50: POP B 8
51: JMP B
20: JIF OF 25
OF: true
25: STRWRITE THE STRINGS ARE EQUAL.
        Wrote "The strings are equal." to 43 through 65
26: PRINT 22
The strings are equal.
27: HLT
```