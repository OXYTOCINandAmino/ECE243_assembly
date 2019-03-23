Attribution: Many thanks are due to Tanner Young-Schultz, who wrote this Assembler
----------------------------------------------------------------------------------

To install and use the assembler:

1) First install Python (version 2). Make sure that the installer updates your Path
environment variable so that it includes the folder where python is installed.

2) Copy the sbasm.py file and the Assembler subfolder that are provided on the course 
website to a folder on your computer.

3) Make a PYTHONPATH environment variable (Control Panel | User Accounts |
Change my environment variables). Set the PYTHONPATH environment variable to
the full path of the Assembler folder. This setting allows Python to find the
Assembler.py code.

For example, assume that the Python executable sbasm.py is stored in the folder 
C:\Users\brownste\Dropbox\UofT\Courses\ece243_19\Design_Files\Assembler_SB
This means that the Assembler itself, which is made up of the two
files Assembler.py and ErrorCodes.py, is stored in the folder called
C:\Users\brownste\Dropbox\UofT\Courses\ece243_19\Design_Files\Assembler_SB\Assembler.

Then, you would set PYTHONPATH as follows: 
PYTHONPATH = C:\Users\brownste\Dropbox\UofT\Courses\ece243_19\Design_Files\Assembler_SB

Also, you need to add the same search path,
C:\Users\brownste\Dropbox\UofT\Courses\ece243_19\Design_Files\Assembler_SB
to your Path environment variable.

This completes the installation process!

Now, in a Command prompt window you can navigate to a folder that has your 
assembly-language code, such as file.s, and then assemble it by typing

   sbasm.py file.s file.mif

By default, the Windows OS associates any file *.py with the python executable program.
Thus, Windows will automatically execute the command "python sbasm.py file.s file.mif". 
Windows uses your Path environment variable to find sbasm.py and the python program uses 
the PYTHONPATH environment variable to find Assembler.py.

*****************************************************************************************
Notes
-----

1) Assembly Language File Format

	The input file IGNORES BLANK LINES. The input file line numbers start indexing at line 
	number 1 (for error messages). 
	// is used for comments, the assembler will ignore everything afer the //
	
	Supported instructions are:

	mv rX, rY
	mvi rX, #IMMU16 or #IMMU32 (depending on data width)
	add rX, rY
	sub rX, rY
	ld rX, [rY]
	st rX, [rY]
	mvnz rX, rY
	mvnc rX, rY

	mv: moves the contents of register rY into register rX
	mvi: moves the immediate value into register rX
	add: adds regsiters rX and rY and stores the result in rX
	sub: subtracts rY from rX (rX - rY) and stores the result in rX
	ld: loads the contents of memory at address rY, into register rX
	st: stores the contents of register rX, into memory at the address of rY
	mvnz: moves contents of rY into rX, iff last add, sub, or mv did not produce 0
	mvnc: moves contents of rY into rX, iff last add or sub did not produce carry-out
	
2)	Python
	Written for Python 2.7. Currently not tested on any other versions

3)	Running the program.
	The program expects 2 arguments in particular order. 
	The input file name (the file with the assembly code written).
	The output file name (the file where the MIF is produced).
	
	Example:
		python sbasm.py <path to input file>.s <path to output file>.mif
		python sbasm.py <path to input file>.s <path to output file>
		python sbasm.py <path to input file>.s								// produces a.mif in the pwd

4)	Assumptions

	!INSTRUCTION ENCODINGS!
	mv:	3'b000
	mvi:	3'b001
	add:	3'b010
	sub:	3'b011
	ld:	3'b100
	st:	3'b101
	mvnz:	3'b110
	mvnc:	3'b111
	
5) Bitwidth

	The Assembler supports bits widths of 16 and 32. The default is 16, which
	can be changed by including in your assembly-language program the line

	WIDTH = y   (where y can be either 16 or 32)

	The Assembler supports different memory depths. The default is 256 words, but can 
	be changed by including in your assembly-language program the line

	DEPTH = x   (only integer multiples of 2 supported)

	Each word of machine code produced by the Assembler has the format:
	
	15              0
	 0000000IIIXXXYYY

	 or
	
	31              15      8       0
	 00000000000000000000000IIIXXXYYY
	
	Where III specifies the instruction, XXX is rX and YYY is rY.

6) Labels and Assembler Directives

	Any line of assembly-language code can include a label, which can use the 
	characters a-z, A-Z, 0-9, _, or $. As example of a label being used is:

	MAIN:		mvi	r0, #0				// initialize counter
				...
				...
				mvi	r7, #MAIN

	The Assembler supports two directives: .define and .word.

	The .define directive is used to associate a symbolic name with a constant.
	For example, if your assembly-language code includes the line

	.define STACK 256			// bottom of memory

	Then your program could use this symbolic name STACK in an instruction such as

	mvi	r6, #STACK			// stack pointer

	The default number base is 10, as used for Stack. Other examples are

	.define SW_ADDRESS 0x3000
	.define HEX_ADDRESS 0x2000
	.define LED_ADDRESS 0x1000
	.define PATTERN 0b00111111

	where 0x means hexadecimal and 0b means binary. 
	
	The .word directive is used to place data into memory, normally at the end
	of an assembly-language source-code file. For example, if your assembly-language 
	code includes the lines

	DATA:	.word 0b00111111			// '0'
			.word 0b00000110			// '1'

	Then these data words (extended to 16 bits) will appear in the resulting .MIF file.

	
