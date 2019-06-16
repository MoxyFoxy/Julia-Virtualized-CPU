# Julia virtual CPU created by Masterfoxify
# Called using: julia cpu.jl path/to/file.jlasm [optional debugging method, type "true" if you want debugging text turned on]

function debug(s::AbstractString)
	if size(ARGS)[1] > 1
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

	OF::Bool = false # Open Flag, for any programmer use
	OF2::Bool = false
	OF3::Bool = false

	# Memory

	memory::Array{UInt8} = Array{UInt8}(undef, 5000)

	for byte in memory
		byte = 0
	end

	stack::Array{UInt8} = Array{UInt8}(undef, 1000)

	for byte in stack
		byte = 0
	end

	function wipeinput()
		i = 0

		while i != 255
			memory[i] = 0
		end
	end

	function isUInt(s::AbstractString)::Bool
		return tryparse(UInt, s) !== nothing
	end

	# File Line

	fileline::UInt64 = 1
	file::Array{String} = readlines(open(filepath))

	labels::Dict{String, Int} = Dict{String, Int}()

	for (linecount, line) in enumerate(file)
		try
			labelcheck = split(uppercase(replace(split(line, ";")[1], "," => " ")))[1]

			if labelcheck[1] == '.'
				push!(labels, replace(labelcheck, "." => "") => linecount)
			end
		catch BoundsError
		end
	end

	debug("Labels: $labels")

	# Loads a value. Checks for register addressing, register values, characters, and numerical values. Note for characters, it will ONLY return one character
	function loadvalue(stringvalue::AbstractString)::UInt
		if isUInt(stringvalue)
			return parse(UInt16, stringvalue)

		else
			potential_char = match(r"\"(\\\\|\\\"|[^\"])*\"", stringvalue)

			if sizeof(potential_char) != 0
				return UInt(potential_char[1])
			end
		end

		if occursin("%", stringvalue)
			register = replace(stringvalue, "%" => "")
		
			if register == "A"
				return memory[A]

			elseif register == "B"
				return memory[B]

			elseif register == "C"
				return memory[C]

			elseif register == "D"
				return memory[D]

			elseif isUInt(replace(stringvalue, "%" => ""))
				return memory[parse(UInt, replace(stringvalue, "%" => ""))]

			else
				throw("Incorrect register value.")
			end

		else
			if stringvalue == "A"
				return A

			elseif stringvalue == "B"
				return B

			elseif stringvalue == "C"
				return C

			elseif stringvalue == "D"
				return D

			elseif stringvalue == "RP"
				return RP

			elseif stringvalue == "WP"
				return WP

			else
				throw("Incorrect register value.")
			end
		end
	end

	# Writes to register or location. Note, pointer addresses cannot be written to outside of their opcodes
	function writetolocation(location::AbstractString, value)
		location = string(location)

		if occursin("%", location)
			register = replace(location, "%" => "")

			if register == "A"
				memory[A] = value

			elseif register == "A"
				memory[B] = value

			elseif register == "C"
				memory[C] = value

			elseif register == "D"
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

		code::String = ""
		instruction::String = ""

		try
			code = replace(uppercase(replace(split(file[fileline], ";")[1], "," => " ")), "\t" => "")

			instruction = split(code)[1]

		catch BoundsError
		end

		debug("$fileline: $code")

		if size(split(code))[1] > 1
			arguments::Array{String} = split(code)[2:end]
		end

		if instruction == "WRITE" # write [value, bit size]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				debug("	Writing $(arguments[1]) to $WP")

				if isUInt(arguments[1]) || arguments[1] in ["A", "B", "C", "D", "%A", "%B", "%C", "%D"]
					value = loadvalue(arguments[1])
					
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

		elseif instruction == "STRWRITE" # strwrite [string]
			stringtowrite = replace(replace(split(file[fileline], ";")[1], "\t" => "")[10:end], "\\n" => "\n")

			debugmessage = replace("	Wrote \"$(stringtowrite)\" to $WP through ", "\n" => "\n\t")

			for char in stringtowrite
				memory[WP] = Int(char)
				WP += 1
			end

			debugmessage = string(debugmessage, "$WP")
			debug(debugmessage)

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

				register = arguments[1]

				if register == "A"
					A = value

				elseif register == "B"
					B = value

				elseif register == "C"
					C = value

				elseif register == "D"
					D = value

				elseif register == "RP"
					RP = value

				elseif register == "WP"
					WP = value

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
				debug("	Wrote $value to $location")
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
						address = sizeof(memory)[1] - 255 + i

						if !(address == sizeof(memory)[1])
							memory[end - 255 + i] = char

						else
							break
						end
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

		elseif instruction == "JMP" # jmp [line]
			if size(arguments)[1] > 1
				throw("Too many arguments.")

			else
				fileline = loadvalue(arguments[1])
				continue
			end

		elseif instruction == "JEQ" # Jumps if two values are equal: jeq [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 == ARG2: $(loadvalue(arguments[1]) == loadvalue(arguments[2]))")

				if loadvalue(arguments[1]) == loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNEQ" # Jumps if two values are not equal: jneq [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 != ARG2: $(loadvalue(arguments[1]) != loadvalue(arguments[2]))")

				if loadvalue(arguments[1]) != loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JGT" # Jumps if value 1 is greater than value 2: jgt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 > ARG2: $(loadvalue(arguments[1]) > loadvalue(arguments[2]))")

				if loadvalue(arguments[1]) > loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNGT" # Jumps if value 1 is not greater than value 2: jngt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 !> ARG2: $(!(loadvalue(arguments[1]) > loadvalue(arguments[2])))")

				if !(loadvalue(arguments[1]) > loadvalue(arguments[2]))
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JLT" # Jumps if value 1 is less than value 2: jlt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 < ARG2: $(loadvalue(arguments[1]) < loadvalue(arguments[2]))")

				if loadvalue(arguments[1]) < loadvalue(arguments[2])
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JNLT" # Jumps if value 1 is not less than value 2: jlt [location, value, line]
			if size(arguments)[1] > 3
				throw("Too many arguments.")

			else
				debug("	ARG1: $(loadvalue(arguments[1]))\n\tARG2: $(loadvalue(arguments[2]))")
				debug("	ARG1 !< ARG2: $((loadvalue(arguments[1]) < loadvalue(arguments[2])))")

				if !(loadvalue(arguments[1]) < loadvalue(arguments[2]))
					fileline = loadvalue(arguments[3])
					continue
				end
			end

		elseif instruction == "JIF" # Jumps if open flag is true: jif [flag, line]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				debug("$(arguments[1]): $(arguments[1] == "OF" ? OF : (arguments[1] == "OF2" ? OF2 : (arguments[1] == "OF3" ? OF3 : "Error")))")

				flag = arguments[1]
				line = parse(Int, arguments[2])

				if flag == "OF"
					if OF
						fileline = line
						continue
					end

				elseif flag == "OF2"
					if OF2
						fileline = line
						continue
					end

				elseif flag == "OF3"
					if OF3
						fileline = line
						continue
					end
				end
			end

		elseif instruction == "TOGGLE" # Toggles flag value: toggle [flag]
			if size(arguments)[1] > 1
				throw("Too many arguments.")

			else
				flag = arguments[1]

				if flag == "OF"
					OF = !OF
					debug("	OF: $OF")

				elseif flag == "OF2"
					OF2 = !OF2
					debug("	OF2: $OF2")

				elseif flag == "OF3"
					OF3 = !OF3
					debug("	OF3: $OF3")
				end
			end

		elseif instruction == "PRINT" # print [char amount]
			if size(arguments)[1] > 2
				throw("Too many arguments.")

			else
				i = RP + loadvalue(arguments[1])

				while RP < i
					print(Char(memory[RP]), "")
					RP += 1
				end

				debug("")
			end

		elseif instruction == "GOTO" # goto [label]
			fileline = labels[replace(arguments[1], "." => "")]

		elseif instruction == "HLT"
			break
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