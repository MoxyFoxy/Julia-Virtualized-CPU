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

	CF::Bool = false # Carry Flag
	ZF::Bool = false # Zero Flag
	OF::Bool = false # Open Flag, for any use

	# Memory

	memory::Array{UInt8}(0x00, 5000)
	stack::Array{UInt8}(0x00, 1000)

	# File Line

	fileline::UInt64 = 1
	file::Array{String} = readlines(open(filepath))
end

if size(ARGS) > 0
	cpu(ARGS[1])
end