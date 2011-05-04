//
//  VirtualMachineAssembler.m
//  CVM
//
//  Created by Michael Ash on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "VirtualMachineAssembler.h"
#import "VirtualMachine.h"
#import "VirtualMachineError.h"


@interface AssemblerLabelReference : NSObject {
	NSString *name;
	int programLocation;
	int line, character;
}

+ referenceWithName:(NSString *)n programLocation:(int)p line:(int)l character:(int)c;
- initWithName:(NSString *)n programLocation:(int)p line:(int)l character:(int)c;
- (NSString *)name;
- (int)programLocation;
- (int)line;
- (int)character;

@end

@implementation AssemblerLabelReference

+ referenceWithName:(NSString *)n programLocation:(int)p line:(int)l character:(int)c
{
	return [[[self alloc] initWithName:n programLocation:p line:l character:c] autorelease];
}

- initWithName:(NSString *)n programLocation:(int)p line:(int)l character:(int)c
{
	if((self = [super init]))
	{
		name = [n copy];
		programLocation = p;
		line = l;
		character = c;
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[super dealloc];
}

- (NSString *)name
{
	return name;
}

- (int)programLocation
{
	return programLocation;
}

- (int)line
{
	return line;
}

- (int)character
{
	return character;
}

- copyWithZone:(NSZone *)zone
{
	return [self retain];
}

@end





@implementation VirtualMachineAssembler


static NSString *opcodeStrings[] = {
	@"NOP",
	@"Load",
	@"Stor",
	@"Jump",
	@"JEQZ",
	@"JNEZ",
	@"JLTZ",
	@"JGTZ",
	@"LdI",
	@"Move",
	@"Add",
	@"Sub",
	@"Mul",
	@"Div",
	@"Mod",
	@"Cmp",
	@"Trap",
	@"LdPC",
	nil
};

static NSString *trapStrings[] = {
	@"Dir",
	@"Enrg",
	@"Spwn",
	@"Eat",
	@"Fwd",
	@"Look",
	@"Give",
	@"Slp",
	@"Send",
	@"Read",
	nil
};

+ (NSString *)disassemblyForInstruction:(VMInstruction)inst
{
	NSString *opString;
	if(inst.load.opcode < opFinalOp)
		opString = opcodeStrings[inst.load.opcode];
	else
		opString = opcodeStrings[0];

	switch(inst.load.opcode)
	{
		case opLoad:
		case opStore:
		{
			NSString *str;
			if(inst.load.absolute)
				str = [NSString stringWithFormat:@"%@ abs\tr%d", opString, inst.load.reg];
			else
				str = [NSString stringWithFormat:@"%@\tr%d", opString, inst.load.reg];
			if(inst.load.op_is_address)
				return [NSString stringWithFormat:@"%@\t%d", str, inst.load.addr];
			else
				return [NSString stringWithFormat:@"%@\tr%d", str, inst.load.addr & VM_REG_MASK];
			break;
		}
		case opJumpEQZ:
		case opJumpNEQZ:
		case opJumpLTZ:
		case opJumpGTZ:
		{
			NSString *str;
			if(inst.load.absolute)
				str = [NSString stringWithFormat:@"%@ abs\tr%d", opString, inst.load.reg];
			else
				str = [NSString stringWithFormat:@"%@\tr%d", opString, inst.load.reg];
			if(inst.load.op_is_address)
				return [NSString stringWithFormat:@"%@\t%d", str, inst.load.addr];
			else
				return [NSString stringWithFormat:@"%@\tr%d", str, inst.load.addr & VM_REG_MASK];
			break;
		}
		case opJump:
		{
			NSString *str;
			if(inst.load.absolute)
				str = [NSString stringWithFormat:@"%@ abs\t", opString];
			else
				str = [NSString stringWithFormat:@"%@\t", opString];
			if(inst.load.op_is_address)
				return [NSString stringWithFormat:@"%@\t%d", str, inst.load.addr];
			else
				return [NSString stringWithFormat:@"%@\tr%d", str, inst.load.addr & VM_REG_MASK];
			break;
		}
		case opLoadi:
			return [NSString stringWithFormat:@"%@\tr%d\t%d", opString, inst.loadi.reg, inst.loadi.val];
			break;
		case opMove:
		case opAdd:
		case opSub:
		case opMul:
		case opDiv:
		case opMod:
		case opCmp:
			return [NSString stringWithFormat:@"%@\tr%d\tr%d\tr%d", opString, inst.reg.source1, inst.reg.source2, inst.reg.dest];
			break;
		case opSpecial:
			if(inst.special.specialopcode < sizeof(trapStrings)/sizeof(trapStrings[0]) - 1)
				return [NSString stringWithFormat:@"%@\tr%d", trapStrings[inst.special.specialopcode], inst.special.reg];
			else
				return [NSString stringWithFormat:@"%@\t%d\tr%d", opString, inst.special.specialopcode, inst.special.reg];
			break;
		case opLoadPC:
			return [NSString stringWithFormat:@"%@\tr%d", opString, inst.special.reg];
			break;
		default:
			return [NSString stringWithFormat:@"%@\t%d", opString, inst.raw];
			break;
	}
}

+ (NSString *)disassemblyForData:(NSData *)data
{
	const VMInstruction *prog = [data bytes];
	int progLength = [data length] / sizeof(VMInstruction);
	NSMutableString *str = [NSMutableString string];
	int i;
	for(i = 0; i < progLength; i++)
	{
		[str appendString:[NSString stringWithFormat:@"L%d:\t%@\n", i, [self disassemblyForInstruction:prog[i]]]];
	}
	return str;
}

- initWithString:(NSString *)s
{
	if((self = [super init]))
	{
		inString = [s copy];
		scanner = [[NSScanner alloc] initWithString:inString];
		[scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
		opcodeDictionary = [[NSMutableDictionary alloc] init];

		int i;
		for(i = 0; opcodeStrings[i] != nil; i++)
			[opcodeDictionary setObject:[NSNumber numberWithInt:i] forKey:[opcodeStrings[i] uppercaseString]];

		trapDictionary = [[NSMutableDictionary alloc] init];

		for(i = 0; trapStrings[i] != nil; i++)
			[trapDictionary setObject:[NSNumber numberWithInt:i] forKey:[trapStrings[i] uppercaseString]];

		labelDictionary = [[NSMutableDictionary alloc] init];
		labelReferenceList = [[NSMutableArray alloc] init];
		errors = [[NSMutableArray alloc] init];

		assembledData = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[inString release];
	[scanner release];
	[opcodeDictionary release];
	[trapDictionary release];
	[labelDictionary release];
	[labelReferenceList release];
	[errors release];
	[assembledData release];
	[super dealloc];
}

- (int)convertToNumber:(NSString *)sin
{
	BOOL negative;
	NSString *s = sin;
	if([s hasPrefix:@"-"])
	{
		negative = YES;
		s = [s substringFromIndex:1];
	}
	else
		negative = NO;

	if([s hasPrefix:@"0x"])
	{
		const char *cstr = [s UTF8String];
		int i;
		long long retVal = 0;
		for(i = 2; cstr[i] != 0; i++)
		{
			retVal *= 16;
			if(cstr[i] >= '0' && cstr[i] <= '9')
				retVal += cstr[i] - '0';
			else if(cstr[i] >= 'A' && cstr[i] <= 'F')
				retVal += cstr[i] - 'A' + 10;
			else if (cstr[i] >= 'a' && cstr[i] <= 'f')
				retVal += cstr[i] - 'a' + 10;
			else
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
			if(retVal > INT_MAX)
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
		}
		if(negative)
			return -retVal;
		else
			return retVal;
	}
	else if([s hasPrefix:@"0"] && [s length] > 1)
	{
		const char *cstr = [s UTF8String];
		int i;
		long long retVal = 0;
		for(i = 1; cstr[i] != 0; i++)
		{
			retVal *= 8;
			if(cstr[i] >= '0' && cstr[i] <= '7')
				retVal += cstr[i] - '0';
			else
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
			if(retVal > INT_MAX)
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
		}
		if(negative)
			return -retVal;
		else
			return retVal;
	}
	else
	{
		const char *cstr = [s UTF8String];
		int i;
		long long retVal = 0;
		for(i = 0; cstr[i] != 0; i++)
		{
			retVal *= 10;
			if(cstr[i] >= '0' && cstr[i] <= '9')
				retVal += cstr[i] - '0';
			else
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
			if(retVal > INT_MAX)
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Badly formed number %@", @"Assembler error"), sin]];
				return 0;
			}
		}
		if(negative)
			return -retVal;
		else
			return retVal;
	}
}

- (int)curProgramPosition
{
	return [assembledData length]/sizeof(VMInstruction);// - 1;
}

- (int)curLine
{
	return curLine + 1;
}

- (int)curChar
{
	return [scanner scanLocation] - curLineStartIndex + 1;
}

- (void)recordError:(NSString *)s onLine:(int)line atChar:(int)character
{
	[errors addObject:[VirtualMachineError errorWithLine:line character:character message:s]];
}

- (void)recordError:(NSString *)s
{
	[self recordError:s onLine:[self curLine] atChar:[self curChar]];
}

- (NSString *)nextLine
{
	static NSCharacterSet *newlineCharacterSet = nil;
	if(!newlineCharacterSet)
		newlineCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] retain];
	NSString *remainingContents;
	if(![scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&remainingContents])
		remainingContents = nil;
	NSString *newlineString = nil;
	if([scanner scanCharactersFromSet:newlineCharacterSet intoString:&newlineString])
	{
		int i;
		for(i = 0; i < [newlineString length]; i++)
			if([newlineString characterAtIndex:i] == '\n')
				curLine++; // only count \n, not \r
	}
	curLineStartIndex = [scanner scanLocation];
	return remainingContents;
}

- (NSString *)nextToken
{
	if(startNewLineForNextToken)
	{
		[self nextLine];
		startNewLineForNextToken = NO;
	}
	
	NSString *token;
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
	if([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&token])
	{
		if([token hasPrefix:@"#"])
		{
			startNewLineForNextToken = YES;;
			return nil;
		}
		else
			return token;
	}
	else
	{
		startNewLineForNextToken = YES;
		return nil;
	}
}

- (void)scan
{
	NSMutableCharacterSet *letterAndUnderscoreCharacterSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
	[letterAndUnderscoreCharacterSet addCharactersInString:@"_"];
	[letterAndUnderscoreCharacterSet autorelease];
	
	while(![scanner isAtEnd])
	{
		VMInstruction curLineInstruction = {{0}};
		NSString *token = [self nextToken];
		// if we hit end of line without reading anything, just keep going
		if(token == nil)
			continue;
		
		if([token hasSuffix:@":"])
		{
			NSString *labelName = [[token substringToIndex:[token length]-1] uppercaseString];
			if([labelDictionary objectForKey:labelName] != nil)
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Label %@ already defined", @"Assembler error"), labelName]];
			else
				[labelDictionary setObject:[NSNumber numberWithInt:[self curProgramPosition]] forKey:labelName];
			token = [self nextToken];
		}

		// if we hit end of line after just reading a label, that's ok too
		if(token == nil)
			continue;

		int opcode = -1;
		id trapObj = nil;
		id opcodeObj = [opcodeDictionary objectForKey:[token uppercaseString]];
		if(opcodeObj)
			opcode = [opcodeObj intValue];
		else
		{
			trapObj = [trapDictionary objectForKey:[token uppercaseString]];
			if(trapObj)
				opcode = opSpecial;
			else
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Unknown opcode %@", @"Assembler error"), token]];
				[self nextLine];
				continue;
			}
		}

		/*
			--------------- NOPs handled here ---------------
		 */
		if(opcode == opNop)
		{
			token = [self nextToken];
			if(token == nil)
				curLineInstruction.loadi.opcode = opNop;
			else
				curLineInstruction.raw = [self convertToNumber:token];
		}


		/*
		    --------------- load-type opcodes handled here ---------------
		 */
		else if(opLoad <= opcode && opcode <= opJumpGTZ)
		{
			curLineInstruction.load.opcode = opcode;
			curLineInstruction.load.absolute = 1;
			token = [self nextToken];
			if(token == nil)
			{
				[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
				continue;
			}
			id tokenUppercase = [token uppercaseString];

			// Handle abs and rel keywords
			if([tokenUppercase isEqualToString:@"ABS"] || [tokenUppercase isEqualToString:@"REL"])
			{
				if([tokenUppercase isEqualToString:@"REL"])
					curLineInstruction.load.absolute = 0;
				token = [self nextToken];
				if(token == nil)
				{
					[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
					continue;
				}
				tokenUppercase = [token uppercaseString];
			}

			// handle the first register operand
			// opJump doesn't take the first register operand, but everybody else does
			if(opcode != opJump)
			{
				int reg = -1;
				if([tokenUppercase hasPrefix:@"R"])
				{
					reg = [self convertToNumber:[token substringFromIndex:1]];
				}
				if(reg >= VM_NUM_REGS || reg < 0 || ![tokenUppercase hasPrefix:@"R"])
				{
					[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Illegal register %@", @"Assembler error"), token]];
					[self nextLine];
					continue;
				}
				curLineInstruction.load.reg = reg;
				token = [self nextToken];
				if(token == nil)
				{
					[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
					continue;
				}
				tokenUppercase = [token uppercaseString];
			}
			
			if([tokenUppercase hasPrefix:@"R"])
				curLineInstruction.load.op_is_address = 0;
			else
				curLineInstruction.load.op_is_address = 1;

			// if it's a register operand, different parsing
			if(curLineInstruction.load.op_is_address == 0)
			{
				int reg = [self convertToNumber:[token substringFromIndex:1]];
				if(reg >= VM_NUM_REGS || reg < 0)
				{
					[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Illegal register %@", @"Assembler error"), token]];
					[self nextLine];
					continue;
				}
				curLineInstruction.load.addr = reg;
			}
			// if the first character is a letter or an underscore, treat it as a label operand
			else if([token rangeOfCharacterFromSet:letterAndUnderscoreCharacterSet].location == 0)
			{
				id labelReference = [AssemblerLabelReference
											referenceWithName:[token uppercaseString]
											  programLocation:[self curProgramPosition]
														 line:[self curLine]
													character:[self curChar]];
				[labelReferenceList addObject:labelReference];
			}
			else
			{
				curLineInstruction.load.addr = [self convertToNumber:token];
			}
		}
		/*
		 --------------- load-type opcodes end here ---------------
		 */


		/*
		 --------------- load immediate opcode ---------------
		 */
		else if(opcode == opLoadi)
		{
			curLineInstruction.loadi.opcode = opcode;
			token = [self nextToken];
			if(token == nil)
			{
				[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
				continue;
			}
			id tokenUppercase = [token uppercaseString];
			
			if([tokenUppercase isEqualToString:@"ABS"] || [tokenUppercase isEqualToString:@"REL"])
			{
				// communicate 'relative' addresses to the label resolution code by setting val here
				if([tokenUppercase isEqualToString:@"REL"])
					curLineInstruction.loadi.val = 1;
				
				token = [self nextToken];
				if(token == nil)
				{
					[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
					continue;
				}
				tokenUppercase = [token uppercaseString];				
			}

			// handle the register operand
			int reg = -1;
			if([tokenUppercase hasPrefix:@"R"])
			{
				reg = [self convertToNumber:[token substringFromIndex:1]];
			}
			if(reg >= VM_NUM_REGS || reg < 0 || ![tokenUppercase hasPrefix:@"R"])
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Illegal register %@", @"Assembler error"), token]];
				[self nextLine];
				continue;
			}
			curLineInstruction.loadi.reg = reg;

			token = [self nextToken];
			if(token == nil)
			{
				[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
				[self nextLine];
				continue;
			}
			
			tokenUppercase = [token uppercaseString];
	
			// if it begins with a letter or underscore, it's a label
			if([token rangeOfCharacterFromSet:letterAndUnderscoreCharacterSet].location == 0)
			{
				id labelReference = [AssemblerLabelReference
										   referenceWithName:[token uppercaseString]
											 programLocation:[self curProgramPosition]
														line:[self curLine]
												   character:[self curChar]];
				[labelReferenceList addObject:labelReference];
			}
			else
			{
				int val = [self convertToNumber:token];
				if(val > (2 << 16) - 1 || val < -(2 << 16))
				{
					[self recordError:[NSString stringWithFormat:NSLocalizedString(@"%d is out of range (must be between -32768 and 32767)", @"Assembler error"), val]];
					[self nextLine];
					continue;
				}
				curLineInstruction.loadi.val = val;
			}
		}
		/*
		 --------------- load immediate opcode end ---------------
		 */



		/*
		 --------------- in-register opcodes start ---------------
		 */
		else if(opMove <= opcode && opcode <= opCmp)
		{
			curLineInstruction.reg.opcode = opcode;
			// easy: just read three register opcodes
			int i;
			for(i = 0; i < 3; i++)
			{
				token = [self nextToken];
				if(token == nil)
				{
					[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
					[self nextLine];
					break;
				}
				id tokenUppercase = [token uppercaseString];
				int reg = -1;
				if([tokenUppercase hasPrefix:@"R"])
				{
					reg = [self convertToNumber:[token substringFromIndex:1]];
				}
				if(reg >= VM_NUM_REGS || reg < 0 || ![tokenUppercase hasPrefix:@"R"])
				{
					[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Illegal register %@", @"Assembler error"), token]];
					[self nextLine];
					continue;
				}
				if(i == 0)
					curLineInstruction.reg.source1 = reg;
				else if(i == 1)
					curLineInstruction.reg.source2 = reg;
				else if(i == 2)
					curLineInstruction.reg.dest = reg;
			}
		}
		/*
		 --------------- in-register opcodes end ---------------
		 */



		/*
		 --------------- special opcode start -------------
		 */
		else if(opcode == opSpecial || opcode == opLoadPC)
		{
			curLineInstruction.special.opcode = opcode;
			if(opcode == opLoadPC)
				; // nothing needs to be done here
			else if(trapObj) // the user has used a special trap operand, not "trap"
				curLineInstruction.special.specialopcode = [trapObj intValue];
			else // read the trap operand
			{
				token = [self nextToken];
				if(token == nil)
				{
					[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
					[self nextLine];
					continue;
				}
				int specialopcode = [self convertToNumber:token];
				if(specialopcode < 0 || specialopcode > 15)
				{
					[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Special opcode %d out of range", @"Assembler error"), specialopcode]];
					[self nextLine];
					continue;
				}
				curLineInstruction.special.specialopcode = specialopcode;
			}
			
			token = [self nextToken];
			if(token == nil)
			{
				[self recordError:NSLocalizedString(@"Missing operand", @"Assembler error")];
				[self nextLine];
				continue;
			}
			id tokenUppercase = [token uppercaseString];
			int reg = -1;
			if([tokenUppercase hasPrefix:@"R"])
			{
				reg = [self convertToNumber:[token substringFromIndex:1]];
			}
			if(reg >= VM_NUM_REGS || reg < 0 || ![tokenUppercase hasPrefix:@"R"])
			{
				[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Illegal register %@", @"Assembler error"), token]];
				[self nextLine];
				continue;
			}
			curLineInstruction.special.reg = reg;
		}
		/*
		 --------------- special opcode end -------------
		 */
		
		
		else
		{
			[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Internal error, opcode = %d", @"Assembler error"), opcode]];
			[self nextLine];
			continue;
		}

		/*
		 	End of opcode parsing. Finish the line and continue parsing on the next line
		 */

		[assembledData appendBytes:&curLineInstruction length:sizeof(curLineInstruction)];
		NSString *remaining = [self nextLine];
		if([remaining length] > 0 && ![remaining hasPrefix:@"#"])
		{
			[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Unexpected text after operand: %@", @"Assembler error"), remaining]];
		}
	}

	// now fill in all the label references

	NSEnumerator *enumerator = [labelReferenceList objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		id locationObj = [labelDictionary objectForKey:[obj name]];
		if(locationObj == nil)
		{
			[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Unknown label %@", @"Assembler error"), [obj name]] onLine:[obj line] atChar:[obj character]];
			continue;
		}
		VMInstruction *prog = [assembledData mutableBytes];
		int referenceIndex = [obj programLocation];
		if((prog[referenceIndex].load.opcode < opLoad || prog[referenceIndex].load.opcode > opJumpGTZ)
				&& prog[referenceIndex].load.opcode != opLoadi)
			[self recordError:[NSString stringWithFormat:NSLocalizedString(@"Internal error: bad opcode %d with label operand", @"Assembler error"), prog[referenceIndex].load.opcode]];

		if(prog[referenceIndex].load.opcode == opLoadi)
		{
			if(prog[referenceIndex].loadi.val) // this indicates relative
				prog[referenceIndex].loadi.val = [locationObj intValue] - referenceIndex;
			else
				prog[referenceIndex].loadi.val = [locationObj intValue];
		}
		else if(prog[referenceIndex].load.absolute)
			prog[referenceIndex].load.addr = [locationObj intValue];
		else
			prog[referenceIndex].load.addr = [locationObj intValue] - referenceIndex;
	}

	[self sortErrors];
	//NSLog(@"Result:\n\n%@", [VirtualMachineAssembler disassemblyForData:assembledData]);
}

- (void)sortErrors
{
	[errors sortUsingSelector:@selector(comparePosition:)];
}

- (NSArray *)errors
{
	return errors;
}

- (NSData *)assembledData
{
	return assembledData;
}

@end
