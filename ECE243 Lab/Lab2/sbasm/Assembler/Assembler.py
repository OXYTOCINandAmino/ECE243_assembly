import os
import sys
import re

from ErrorCodes import *

class Assembler(object):
	'''
	Assemlber class.
	'''
	
	# REGEX string to match trailing space and a comment.
	TRAIL_SPACE_COMMENT = '\s*(//.*)?$'
	
	# REGEX to match a single line comment.
	COMMENT_REGEX = re.compile('//.*$')
	
	# REGEX to match the WIDTH and DEPTH definition.
	WIDTH_DEF_REGEX = re.compile('WIDTH\s+(\d+)' + TRAIL_SPACE_COMMENT)
	DEPTH_DEF_REGEX = re.compile('DEPTH\s+(\d+)' + TRAIL_SPACE_COMMENT)
	
	# REGEX to match a define (.define) statement.
	DEFINE_REGEX = re.compile('\.define\s+([a-zA-Z_$][a-zA-Z_$0-9]*)\s+((0|0b|0x)?\w+)' + TRAIL_SPACE_COMMENT)
	
	# REGEX string to match a label only).
	LABEL_REGEX_STR = '([a-zA-Z_$][a-zA-Z_$0-9]*):'
	
	# REGEX to match a label only (no trailing instruction).
	LABEL_REGEX = re.compile(LABEL_REGEX_STR + TRAIL_SPACE_COMMENT)
	
	# REGEX to match instructions. Includes an optional preceeding label and a trailing comment.
	INSTR_TYPE1_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' + '(mv|add|sub|ld|st|mvnz|mvnc)\s+(r\d+),\s*\[*(r\d+)\]*' + TRAIL_SPACE_COMMENT)
	INSTR_TYPE2_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' + '(mvi)\s+(r\d+),\s*#*(((0|0b|0x)?\w+)|[a-zA-Z_$][a-zA-Z_$0-9]*)+' + TRAIL_SPACE_COMMENT)
	# REGEX to match .word directive. Includes an optional preceeding label and a trailing comment.
	WORD_DIR_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' + '(.word)\s+((0|0b|0x)?\w+)' + TRAIL_SPACE_COMMENT)
	
	# Max integers for the two bit width options.
	MAX_INT_16U = 65535
	MAX_INT_32U = 0xFFFFFFFF
	
	# Maps instruction strings to integer values.
	INSTR_STR_TO_VAL = {'mv': 0, 'mvi': 1, 'add': 2, 'sub': 3, 'ld': 4, 'st': 5, 'mvnz': 6, 'mvnc': 7}
	
	# Maps register strings to integer values.
	REG_STR_TO_VAL = {'r0': 0, 'r1': 1, 'r2': 2, 'r3': 3, 'r4': 4, 'r5': 5, 'r6': 6, 'r7': 7}
	
	# Maps integers (indices) to instruction strings.
	INSTR_VAL_TO_STR = ['mv  ', 'mvi ', 'add ', 'sub ', 'ld  ', 'st  ', 'mvnz', 'mvnc']
	
	# Maps integers (indices) to register strings.
	REG_VAL_TO_STR = ['r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7']
	
	def __init__(self, in_filename, out_filename):
		'''
		Initializes the assembler.
		Args:
			in_filename: The input filename.
			out_filename: The output filname.
		'''
		# Store the input filename.
		self.in_filename = in_filename
		
		# Store the outputfilename, default to a.mif
		if out_filename is None:
			out_filename = 'a.mif'
		self.out_filename = out_filename
		
		# The lines of the input file will be stored here.
		self.lines = []
		
		# Stores the assembled machine instructions.
		self.machine_instructions = []
		
		# Indicates whether a word of machine code is an instruction or data. A 0 indicates data
		self.is_inst = []
		
		# Maps labels and defines to numbers.
		self.label_def_to_num = {}
		
		# Width bits (16 or 32 only).
		self.width_bits = 16
		
		# Depth bytes - should correspond to the memory bytes.
		self.depth_bytes = 256
		
		# Tracks current line number of the input file.
		self.line = 0
		
		# Tracks the current instruction number.
		self.curr_instr_num = -1
		
		# Flag for preprocess.
		self.in_preprocess = True
		
		# Validate input and output filenames.
		if not in_filename.strip() or not os.path.isfile(in_filename):
			print 'Input file: ' + in_filename + ' is invalid'
			sys.exit()
		elif not out_filename.strip():
			print 'Output file: ' + out_filename + ' is invalid'
			sys.exit()
		else:
			in_file = open(in_filename, 'r')
			self.lines = in_file.read().splitlines()


	def assemble(self):
		'''
		Assembles the input file into the output file.
		'''
		# validate and parse the in and out filenames.
		self.__validate_out_filename()
		error = self.__validate_in_filename()
		width = 0
		depth = 0
		line = 0
		
		if error == ErrorCodes.NO_ERROR:
			# Start preprocess.
			self.in_preprocess = True
			
			# Preprocess by finding the labels.
			error = self.__find_labels()
			
			if error is not ErrorCodes.NO_ERROR:
				# Error in preprocess.
				print ErrorCodes.get_error_message(error, self.line, self.depth_bytes, self.curr_instr_num)
			else:
				# Start processing.
				self.in_preprocess = False
				
				# Parse the lines of the input file.
				error = self.__parse_lines()

				if error is not ErrorCodes.NO_ERROR:
					# Error in processing.
					print ErrorCodes.get_error_message(error, self.line, self.depth_bytes, self.curr_instr_num)
				else:
					# Output the MIF file.
					self.__output_file()
		else:
			# Filenames had an error.
			ErrorCodes.print_error_message(error, 0, -1, -1)
	
	
	def __find_labels(self):
		'''
		Preprocessing - finds all labels and defines.
		Returns:
			int: ErrorCodes.BAD_INFILE on error, ErrorCodes.NO_ERROR otherwise.
		'''
		# Reset the current line and instruction number.
		self.line = 1
		self.curr_instr_num = -1
		
		for line in self.lines:
			line = line.strip()
			match = None
			
			# Skip empty lines and comments.
			if line != "" and line != "\n" and not self.__is_comment(line):
				# Check matches of REGEXs.
				if self.WIDTH_DEF_REGEX.match(line):
					# Line matches WIDTH line, get the number.
					match = self.WIDTH_DEF_REGEX.match(line)
					width = int(match.group(1), 0)
					
					# Only support 16 and 32 bit widths.
					if width != 32 and width != 16:
						return ErrorCodes.WIDTH_ERROR
					else:
						self.width_bits = width
				elif self.DEPTH_DEF_REGEX.match(line):
					# Line matches DEPTH line, get the number.
					match = self.DEPTH_DEF_REGEX.match(line)
					depth = int(match.group(1), 0)
					
					# Depth must be a power of 2.
					if depth % 2 != 0:
						return ErrorCodes.DEPTH_ERROR
					else:
						self.depth_bytes = depth
				elif self.DEFINE_REGEX.match(line):
					# Line is a define statement.
					match = self.DEFINE_REGEX.match(line)
					
					# Get the label and the number.
					label = match.group(1)
					num = int(match.group(2), 0)
					
					if label == 'WIDTH' or label == 'DEPTH':
						return ErrorCodes.WIDTH_DEPTH_DEFINE
					elif label in self.label_def_to_num:
						return ErrorCodes.DEFINE_REDEF
					elif self.__is_number_too_large(num):
						return ErrorCodes.DEFINE_BAD
					else:
						# Add the mapping to the label -> value mapping.
						self.label_def_to_num[label] = num
				elif self.INSTR_TYPE1_REGEX.match(line):
					# Line is an instruction of type 1 (mv, add, sub, etc...).
					(error, sub_mif) = self.__parse_type1_instruction(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number, assembled instruction not needed yet.
						self.curr_instr_num += len(sub_mif)
					else:
						return error
				elif self.INSTR_TYPE2_REGEX.match(line):
					# Line is an instruction of type 2 (mvi).
					(error, sub_mif) = self.__parse_type2_instruction(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number, assembled instruction not needed yet.
						self.curr_instr_num += len(sub_mif)
					else:
						return error
				elif self.WORD_DIR_REGEX.match(line):
					# Line is a .word directive
					(error, sub_mif) = self.__parse_word_dir(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number, assembled instruction not needed yet.
						self.curr_instr_num += len(sub_mif)
					else:
						return error
				elif self.LABEL_REGEX.match(line):
					# Line is only a label.
					match = self.LABEL_REGEX.match(line)
					label = match.group(1)
					
					if label == 'WIDTH' or label == 'DEPTH':
						return ErrorCodes.WIDTH_DEPTH_DEFINE
					elif label in self.label_def_to_num:
						return ErrorCodes.DEFINE_REDEF
					else:
						# Add the mapping to the label -> value mapping.
						self.label_def_to_num[label] = self.curr_instr_num + 1
				else:
					# Line matches nothing, which is bad
					print "Error: can't parse assembly code on line " + str(self.line)
					
			# Move to the next line.
			self.line += 1
		#ENDFOR
			
		return ErrorCodes.NO_ERROR
		
		
	def __parse_lines(self):
		'''
		Processing. Parses the lines of the input file.
		Returns:
			int: ErrorCodes.BAD_INFILE on error, ErrorCodes.NO_ERROR otherwise.
		'''
		self.line = 1
		self.curr_instr_num = -1
		
		for line in self.lines:
			line = line.strip()
			match = None
			
			# Skip empty lines and comments.
			if line != "" and line != "\n" and not self.__is_comment(line):
				# Only look for instructions, preprocessing has already dealt with labels and defines.
				if self.INSTR_TYPE1_REGEX.match(line):
					# Type 1 instruction.
					(error, sub_mif) = self.__parse_type1_instruction(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number.
						self.curr_instr_num += len(sub_mif)
						# Add assembled machine code to the machine instructions
						self.machine_instructions.extend(sub_mif)
						self.is_inst.extend([True])
					else:
						return error
				elif self.INSTR_TYPE2_REGEX.match(line):
					(error, sub_mif) = self.__parse_type2_instruction(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number.
						self.curr_instr_num += len(sub_mif)
						# Add assembled machine code to the machine instructions
						self.machine_instructions.extend(sub_mif)
						self.is_inst.extend([True, True])
					else:
						return error
				elif self.WORD_DIR_REGEX.match(line):
					# .word directive
					(error, sub_mif) = self.__parse_word_dir(line)
					
					if error == ErrorCodes.NO_ERROR:
						# Increment instruction number.
						self.curr_instr_num += len(sub_mif)
						# Add assembled machine code to the machine instructions
						self.machine_instructions.extend(sub_mif)
						# put False into is_inst array to indicate data item
						self.is_inst.extend([False])
					else:
						return error
			
			# Move to the next line.
			self.line += 1
		#ENDFOR
		
		return ErrorCodes.NO_ERROR
		
		
	def __output_file(self):
		'''
		Outputs the machine instructions to the output mif file.
		'''
		# Open file for writing, should already be verified.
		out_file = open(self.out_filename, 'w')
		
		####################################################
		## Preamble information (all comments).
		# out_file.write('% Format\n')
		# if self.width_bits == 16:
			# out_file.write('% 15      8       0 %\n')
			# out_file.write('%  DDDDDDDIIIXXXYYY %\n')
		# else:
			# out_file.write('% 31              15      8       0 %\n')
			# out_file.write('%  DDDDDDDDDDDDDDDDDDDDDDDIIIXXXYYY %\n')
			
		# out_file.write('\n')
		####################################################
		
		####################################################
		## MIF Data.
		out_file.write('WIDTH = ' + str(self.width_bits) + ';\n')
		out_file.write('DEPTH = ' + str(self.depth_bytes) + ';\n')
		out_file.write('ADDRESS_RADIX = HEX;\n')
		out_file.write('DATA_RADIX = HEX;\n\n')
		out_file.write('CONTENT\nBEGIN\n')
		
		########################
		## Instructions.
		last_instr_mvi = False
		instruction_num = 0
		instruction_format_str = '%0' + str(self.width_bits/4) + 'x'
		i = 0
		
		while i < len(self.machine_instructions):
			# Get the current instruction.
			instruction = self.machine_instructions[i]
			write_comment = self.is_inst[i]
			
			# Get next instruction if possible.
			next_instruction = 0
			if i < len(self.machine_instructions) - 1:
				next_instruction = self.machine_instructions[i+1]
				
			# Format the instruction number and the instruction itself (HEX).
			instruction_num_str = '%x' % i
			instruction_str = instruction_format_str % (instruction)
			
			# Move to the next instruction.
			i += 1
			
			# Write to the output file, format - <inst #>	: <inst>;	% inst comment.
			if write_comment:
				# Convert the current instruction into a comment.
				comment_str = self.__instruction_to_comment(instruction, next_instruction)
				out_file.write(instruction_num_str + '\t\t: ' + instruction_str + ';\t\t% ' + comment_str + '\n')
				# If the instruction (eg mvi) requires a second machine instruction.
				if self.__is_instruction_mvi(instruction):
					# Immediate value is the current instruction (move to the next instruction above with i += 1).
					immed = self.machine_instructions[i]
				
					# Format the instruction number and immediate value.
					instruction_num_str = '%x' % i
					immed_str = instruction_format_str % (immed)
				
					# Write the immediate value to the output file, format - <instruction number>	: <immediate>;
					out_file.write(instruction_num_str + '\t\t: ' + immed_str + ';\n')
				
					# Move to next instruction.
					i += 1
			else:
				out_file.write(instruction_num_str + '\t\t: ' + instruction_str + ';\t\t% ' + 'data %\n')
			
		#ENDWHILE
		########################
		
		out_file.write('END;\n')
		####################################################

	
	def __validate_in_filename(self):
		'''
		Validates the input filename.
		Returns:
			int: ErrorCodes.BAD_INFILE on error, ErrorCodes.NO_ERROR otherwise.
		'''
		if not self.in_filename.endswith('.s'):
			return ErrorCodes.BAD_INFILE
		else:
			return ErrorCodes.NO_ERROR
			
	
	def __validate_out_filename(self):
		'''
		Validates the output filename. Appends a '.mif' extension if it is missing.
		'''
		if not self.out_filename.endswith('.mif'):
			self.out_filename += '.mif'
			
			
	def __is_comment(self, line):
		'''
		Determines if a line is a comment.
		Returns:
			Boolean: True if the line is a comment, False otherwise.
		'''
		return self.COMMENT_REGEX.match(line)
		
	
	def __parse_type1_instruction(self, line):
		'''
		Parses a type 1 instruction (eg: mv, sub, etc...)
		Args:
			line: The line from the input file which matched the INSTR_TYPE1_REGEX.
		Returns:
			int: ErrorCodes.NO_ERROR on success, some error code on failure.
			[int]: An array of MIF instructions which is the assembled machine code.
		'''
		match = self.INSTR_TYPE1_REGEX.match(line)
		
		# If we are preprocess mode check the potential preceeding label.
		if self.in_preprocess:
			# Grab the possible label.
			label = match.group(2)
			
			if label == 'WIDTH' or label == 'DEPTH':
				return ErrorCodes.WIDTH_DEPTH_DEFINE, []
			elif label in self.label_def_to_num:
				return ErrorCodes.DEFINE_REDEF, []
			elif label is not None:
				# Label was defined, add it to the mapping.
				self.label_def_to_num[label] = self.curr_instr_num + 1
		
		# Grab the instruction and registers from the REGEX.
		instr = self.INSTR_STR_TO_VAL[match.group(3)]
		ra = self.REG_STR_TO_VAL[match.group(4)]
		rb = self.REG_STR_TO_VAL[match.group(5)]
		
		if instr is None:
			return ErrorCodes.BAD_INSTR, []
		elif ra is None:
			return ErrorCodes.BAD_REG, []
		elif rb is None:
			return ErrorCodes.BAD_REG, []
		else:
			# Create the instruction and return it.
			mif_instr = self.__make_mif_instruction(instr, ra, rb)
			return ErrorCodes.NO_ERROR, [mif_instr]


	def __parse_type2_instruction(self, line):
		'''
		Parses a type 2 instruction (eg: mvi).
		Args:
			line: The line from the input file which matched the INSTR_TYPE1_REGEX.
		Returns:
			int: ErrorCodes.NO_ERROR on success, some error code on failure.
			[int]: An array of MIF instructions which is the assembled machine code.
		'''
		match = self.INSTR_TYPE2_REGEX.match(line)
		
		# If we are preprocess mode check the potential preceeding label.
		if self.in_preprocess:
			# Grab the possible label.
			label = match.group(2)
			
			if label == 'WIDTH' or label == 'DEPTH':
				return ErrorCodes.WIDTH_DEPTH_DEFINE, []
			elif label in self.label_def_to_num:
				return ErrorCodes.DEFINE_REDEF, []
			elif label is not None:
				# Label was defined, add it to the mapping.
				self.label_def_to_num[label] = self.curr_instr_num + 1
		
		# Grab the instruction, register and immediate value from the REGEX.
		instr = self.INSTR_STR_TO_VAL[match.group(3)]
		ra = self.REG_STR_TO_VAL[match.group(4)]
		imm_str = match.group(5)
		imm = None
		try:
			imm = int(imm_str, 0)
		except ValueError:
			if not self.in_preprocess:
				imm = self.label_def_to_num[imm_str]
				if imm is None:
					return ErrorCodes.IMMED_LABEL_NF, []
				elif imm < 0:
					return ErrorCodes.NEG_IMMED
				elif self.__is_number_too_large(imm):
					return ErrorCodes.BIG_IMMED
		
		if instr is None:
			return ErrorCodes.BAD_INSTR, []
		elif ra is None:
			return ErrorCodes.BAD_REG, []
		else:
			# Create the instruction and return it with the immediate value.
			mif_instr = self.__make_mif_instruction(instr, ra, 0)
			return ErrorCodes.NO_ERROR, [mif_instr, imm]
	
	
	def __make_mif_instruction(self, instr, ra, rb):
		'''
		Converts an instruction to machine code.
		Args:
			instr: the instruction int.
			ra: The first regsiter int.
			rb: The second register int.
		Returns:
			int: The machine code for the instruction.
		'''
		return rb | (ra << 3) | (instr << 6)
		
	
	
	def __parse_word_dir(self, line):
		'''
		Parses a .word directive 
		Args:
			line: The line from the input file which matched the WORD_DIR_REGEX.
		Returns:
			int: ErrorCodes.NO_ERROR on success, some error code on failure.
			[int]: An array of MIF instructions which is the assembled machine code.
		'''
		match = self.WORD_DIR_REGEX.match(line)
		
		# If we are in preprocess mode check the potential preceeding label.
		if self.in_preprocess:
			# Grab the possible label.
			label = match.group(2)
			
			if label == 'WIDTH' or label == 'DEPTH':
				return ErrorCodes.WIDTH_DEPTH_DEFINE, []
			elif label in self.label_def_to_num:
				return ErrorCodes.DEFINE_REDEF, []
			elif label is not None:
				# Label was defined, add it to the mapping.
				self.label_def_to_num[label] = self.curr_instr_num + 1
		
		# Grab the instruction and registers from the REGEX.
		data = int(match.group(4), 0)
		
		return ErrorCodes.NO_ERROR, [data]
		
	
	
	def __is_number_too_large(self, num):
		'''
		Determines is a number is too large for the architecture.
		Args:
			num: The number to check.
		Returns:
			Boolean: True if the number is too large.
		'''
		if self.width_bits == 16:
			return num > self.MAX_INT_16U
		else:
			return num > self.MAX_INT_32U


	def __is_instruction_mvi(self, instr):
		'''
		Determines if an instruction is a MVI instruction.
		Args:
			instr: The instruction to check.
		Returns:
			Boolean: True if the instruction is a MVI.
		'''
		return ((instr >> 6) & 0x0007 == self.INSTR_STR_TO_VAL['mvi'])
		

	def __instruction_to_comment(self, instr, next_instr):
		'''
		Converts an instruction to a comment.
		Args:
			instr: The current instruction.
			next_instr: The next instruction (used for MVI).
		Returns:
			str: The string form of the instruction.
		'''
		# Parse out the instruction and first and second registers.
		rb = instr & 0x0007
		ra = (instr >> 3) & 0x0007
		i = (instr >> 6) & 0x0007
		
		# Create the comment.
		comment = self.INSTR_VAL_TO_STR[i] + ' ' + self.REG_VAL_TO_STR[ra] + ', '
		
		# Append the immediate value if the instruction is a MVI insruction.
		if i == self.INSTR_STR_TO_VAL['mvi']:
			instruction_format_str = '0x%0' + str(self.width_bits/4) + 'x'
			comment += instruction_format_str % (next_instr)
			# comment += '0x%04x' % (next_instr)
			# comment += str(next_instr)
		else:
			comment += self.REG_VAL_TO_STR[rb]
			
		comment += ' %'
		return comment
		
		
