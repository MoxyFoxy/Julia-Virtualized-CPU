function cpu(filepath::String)

	# Registers. https://www.swansontec.com/sregisters.html is a good reference. Based mostly on this

	A::UInt16 = 0x00 # Accumulator
	B::UInt16 = 0x00 # Open Register
	C::UInt16 = 0xff # Count Register
	D::UInt16 = 0x00 # Data Register
	RP::UInt16 = 0x00 # Read Pointer
	WP::UInt16 = 0x00 # Write Pointer
	SP::UInt16 = 0x00 # Stack Pointer

	# Flags

	CF::Bool = false # Carry Flag, called on inexact error
	ZF::Bool = false # Zero Flag, called on inexact error
	OF::Bool = false # Open Flag, for any programmer use

	# Memory

	memory::Array{UInt8}(0x00, 5000)
	stack::Array{UInt8}(0x00, 1000)

	# File Line

	fileline::UInt64 = 1
	file::Array{String} = readlines(open(filepath))

	while true
		code::String = uppercase(replace(split(file[fileline], ";")[1], "," => " "))

		instruction::String = split(code)[1]
		arguments::Array{String}

		if size(split(code)) > 1
			arguments = split(code)[2:end]
		end

		if instruction == "WRITE" # write [value, bit size]
			if size(arguments) > 2
				throw ArgumentError("Too many arguments.")

			else
				if isnumeric(arguments[1])
					value = parse(Int, arguments[1])
					
					if parse(Int, arguments[2]) == 16
						lower::UInt8 = value % 0x100
						upper::UInt8 = value // 0x100

						memory[WP] = lower
						WP += 1
						memory[WP] = upper

					elseif parse(Int, arguments[2]) == 8
						memory[WP] = value

					else
						throw ArgumentError("Incorrect bit size argument.")
					end

				else
					for char in arguments[1]
						memory[WP] = Int(char)
						WP += 1
					end
				end
			end

		elseif instruction == "READ" # read [register, bit size]
			if size(arguments) > 2
				throw ArgumentError("Too many arguments.")

			else
				if parse(Int, arguments[2]) == 16
					value::UInt16 = memory[RP]
					RP += 1
					value += memory[RP]

				elseif parse(Int, arguments[2]) == 8
					value::UInt8 = memory[RP]

				else
					throw ArgumentError("Incorrect bit size argument.")
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
					throw ArgumentError("Incorrect register value.")
				end
			end

		elseif instruction == "LOAD" # load [register/pointer, value]
			if size (arguments) > 2
				throw ArgumentError("Too many arguments.")

			else
				location::String = arguments[1]
				value = arguments[2]

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
					throw ArgumentError("Incorrect location value.")
				end
			end
		end

		fileline += 1
	end
end

if size(ARGS) > 0
	cpu(ARGS[1])
end