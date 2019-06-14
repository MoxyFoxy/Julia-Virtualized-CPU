function debug(s::AbstractString)
	if size(ARGS)[1] > 0
		if ARGS[2] == "true"
			println(s)
		end
	end
end

function cpu(filepath::String)

	# Registers. https://www.swansontec.com/sregisters.html is a good reference. Based mostly on this

	A::UInt16 = 0x00 # Accumulator
	B::UInt16 = 0x00 # Open Register
	C::UInt16 = 0xff # Count Register
	D::UInt16 = 0x00 # Data Register
	RP::UInt16 = 0x01 # Read Pointer
	WP::UInt16 = 0x01 # Write Pointer
	SP::UInt16 = 0x01 # Stack Pointer

	# Interrupts

	UOI::Bool = false # User Input Overflow Interrupt. Goes back to line 1 in code

	# Flags

	CF::Bool = false # Carry Flag, called on inexact error
	ZF::Bool = false # Zero Flag, called on inexact error
	CMF::Bool = false # 
	OF::Bool = false # Open Flag, for any programmer use

	# Memory

	memory::Array{UInt8} = Array{UInt8}(undef, 5000)
	stack::Array{UInt8} = Array{UInt8}(undef, 1000)
	userin::Array{UInt8} = Array{UInt8}(undef, 255)

	function wipeinput()
		userin = Array{UInt8}(undef, 255)
	end

	function isUInt(s::AbstractString)::Bool
		return tryparse(UInt, s) !== nothing
	end

	# File Line

	fileline::UInt64 = 1
	file::Array{String} = readlines(open(filepath))

	# Loads a value. Checks for register addressing, register values, characters, and numerical values. Note for characters, it will ONLY return one character
	function loadvalue(stringvalue::AbstractString)::UInt
		if isUInt(stringvalue)
			return parse(UInt16, stringvalue)

		else
			potential_char = match(r"\"(\\\\|\\\"|[^\"])*\"", stringvalue)

			if sizeof(potential_char) != 0
				return UInt(potential_char[1])
			end

			register = stringvalue
		end

		if occursin("%", stringvalue)
			register = Char(replace(stringvalue, "%" => "")[1])
			
			if register == 'A'
				return memory[A]

			elseif register == 'B'
				return memory[B]

			elseif register == 'C'
				return memory[C]

			elseif register == 'D'
				return memory[D]

			else
				throw("Incorrect register value.")
			end

		else
			register = Char(stringvalue[1])

			if register == 'A'
				return A

			elseif register == 'B'
				return B

			elseif register == 'C'
				return C

			elseif register == 'D'
				return D

			else
				throw("Incorrect register value.")
			end
		end
	end

	# Writes to register or location. Note, pointer addresses cannot be written to outside of their opcodes
	function writetolocation(location::AbstractString, value)
		location = string(location)

		if occursin("%", location)
			if register == 'A'
				memory[A] = value

			elseif register == 'B'
				memory[B] = value

			elseif register == 'C'
				memory[C] = value

			elseif register == 'D'
				memory[D] = value

			else # Note, pointer addresses cannot be written to outside of their opcodes
				throw("Incorrect register value. Did you try to use a pointer? Note that pointers cannot be used in a address write except through their respective opcodes.")
			end

		else
			if location == "A"
				A = value

			elseif location == "B"
				B = value

			elseif location == "C"
				C = value

			elseif location == "D"
				D = value

			elseif location == "RP"
				RP = value

			elseif location == "WP"
				WP = value

			else # Note, SP cannot be written to
				throw("Incorrect location value.")
			end
		end
	end

	while true
		if UOI
			fileline = 1
		end

		code::String = uppercase(replace(split(file[fileline], ";")[1], "," => " "))

		instruction::String = split(code)[1]

		debug("$fileline: $code")

		if size(split(code))[1] > 1
			arguments::Array{String} = split(code)[2:end]
		end

		if instruction == "WRITE" # write [value, bit size]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				if isUInt(arguments[1])
					value = parse(Int, arguments[1])
					
					if parse(Int, arguments[2]) == 16
						lower = Int(value % 0x100)
						upper = Int(value / 0x100)

						memory[WP] = lower
						WP += 1
						memory[WP] = upper

					elseif parse(Int, arguments[2]) == 8
						memory[WP] = value

					else
						throw("Incorrect bit size argument.")
					end

				else
					for char in arguments[1]
						memory[WP] = Int(char)
						WP += 1
					end
				end
			end

		elseif instruction == "READ" # read [register, bit size]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				if parse(Int, arguments[2]) == 16
					value = memory[RP]
					RP += 1
					value += memory[RP]

				elseif parse(Int, arguments[2]) == 8
					value = memory[RP]

				else
					throw("Incorrect bit size argument.")
				end

				register::Char = arguments[1]

				if register == 'A'
					A = value

				elseif register == 'B'
					B = value

				elseif register == 'C'
					C = value

				elseif register == 'D'
					D = value

				else
					throw("Incorrect register value.")
				end
			end

		elseif instruction == "LOAD" # load [register/pointer, value/register/%register]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				location::String = arguments[1]
				value = loadvalue(arguments[2])

				writetolocation(location, value)
			end

		elseif instruction == "PUSH" # push [value, bit size]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				value = loadvalue(arguments[1])

				if parse(Int, arguments[2]) == 16
					lower = Int(value % 0x100)
					upper = Int(value / 0x100)

					SP += 1
					stack[SP] = lower
					
					SP += 1
					stack[SP] = upper

				elseif parse(Int, arguments[2]) == 8
					SP += 1
					stack[SP] = value
				end
			end

		elseif instruction == "POP" # pop [location, bit size]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				if parse(Int, arguments[2]) == 16
					value = stack[SP]
					SP -= 1

					value += stack[SP]
					SP -= 1

					writetolocation(arguments[1], value)

				elseif parse(Int, arguments[2]) == 8
					value = stack[SP]
					SP -= 1

					writetolocation(arguments[1], value)

				else
					throw("Incorrect bit size argument.")
				end
			end


		elseif instruction == "GETIN"
			if size(arguments)[1] > 0
				throw("Too many arguments.")

			else
				input::String = readline(STDIN)

				if sizeof(input) > 255
					OUI = true

				else
					for (i, char) in enumerate(input)
						userin[i] = char
					end
				end
			end

		elseif instruction == "WIPEIN"
			if size(arguments)[1] > 0
				throw("Too many arguments.")

			else
				wipeinput()
			end

		elseif instruction == "ADD" # add [location, value]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				writetolocation(arguments[1], loadvalue(arguments[1]) + loadvalue(arguments[2]))
			end

		elseif instruction == "SUB" # sub [location, value]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				writetolocation(arguments[1], loadvalue(arguments[1]) - loadvalue(arguments[2]))
			end

		elseif instruction == "ITER" # iter [pointer]
			if size(arguments)[1] > 1
				throw("Too many arguments.")

			else
				if arguments[1] == "RP"
					RP += 1

				elseif arguments[1] == "WP"
					WP += 1
				end
			end

		elseif instruction == "JMP" # jmp [line/label]
			if size(arguments)[1] > 1
				throw("Too many arguments.")

			else
				fileline = loadline(arguments[1])
				continue
			end

		elseif instruction == "JEQ" # Jumps if two values are equal: jeq [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if loadvalue(arguments[1]) == loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNEQ" # Jumps if two values are not equal: jneq [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if loadvalue(arguments[1]) != loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JGT" # Jumps if value 1 is greater than value 2: jgt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if loadvalue(arguments[1]) > loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNGT" # Jumps if value 1 is not greater than value 2: jngt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if !(loadvalue(arguments[1]) > loadvalue(arguments[2]))
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JLT" # Jumps if value 1 is less than value 2: jlt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if loadvalue(arguments[1]) < loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNLT" # Jumps if value 1 is not less than value 2: jlt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				if !(loadvalue(arguments[1]) < loadvalue(arguments[2]))
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JIF" # Jumps if flag is true: jif [flag, line]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				flag::String = arguments[1]
				line = parse(Int, arguments[2])

				if flag == "CF"
				end
			end

		elseif instruction == "PRINT" # print [char amount]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				i = loadvalue(arguments[1])

				while RP <= i
					print(Char(memory[RP]), "")
					RP += 1
				end
			end
		end

		fileline += 1

		if fileline > size(file)[1]
			break
		end
	end
end

if size(ARGS)[1] > 0
	debug("Loading File: $(ARGS[1])")
	cpu(ARGS[1])
else
	debug("Error: No file loaded.\nPlease type: julia cpu.jl [path/to/file]")
end