//
//  ComputingCreature.m
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <math.h>
#import "ComputingCreature.h"
#import "Genome.h"
#import "VirtualMachine.h"
#import "VirtualMachineAssembler.h"


@implementation ComputingCreature

static int arenaXSize;
static int arenaYSize;

+ (void)initialize
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arenaChanged:) name:@"ArenaChanged" object:[Arena class]];
}

+ (void)arenaChanged:(NSNotification *)notification
{
	id a = [notification userInfo];
	arenaXSize = [a xSize];
	arenaYSize = [a ySize];
}

- initWithArena:(Arena *)a location:(int)x :(int)y
{
	arena = a;
	self = [super initWithArena:a location:x :y];
	if(self)
		[a addComputingCreature:self];
	return self;
}

- (void)setVMData:(NSData *)data
{
	[vm release];
	vm = [[VirtualMachine alloc] initWithData:data pad:0];
	[vm setTrapHandlerObject:self selector:@selector(handleTrap:withRegisterPointer:)];
}

- (void)setVM:(VirtualMachine *)v
{
	vm = [v copy];
	[vm setTrapHandlerObject:self selector:@selector(handleTrap:withRegisterPointer:)];	
}

- (NSData *)programData
{
	return [vm data];
}

- (VirtualMachine *)vm
{
	return vm;
}

/*- (void)setData:(VMInstruction *)d size:(int)s
{
	if(d == nil || s == 0)
	{
		d = (VMInstruction *)program1;
		s = sizeof(program1) / sizeof(VMInstruction);
	}
	data = malloc(s * sizeof(VMInstruction));
	if(data == nil)
		printf("eek!!!!");
	memcpy(data, d, s * sizeof(VMInstruction));
	dataSize = s;
}

- (void)setDataFromGenome:(Genome *)g
{
	[self setData:[g programData] size:[g programDataSize]];
}*/

- (void)dealloc
{
	[vm release];
	[super dealloc];
}

- (void)setMutations:(int)m
{
	mutations = m;
}

- (int)mutations
{
	return mutations;
}

- (void)setMessage:(int)m
{
	message = m;
}

- (int)message
{
	return message;
}

- (Genome *)genome
{
	return genome;
}

- (void)setGenome:g
{
	genome = g;
}

static const float randMax = 2147483648.0 - 1.0;
//static const float invRandMax = 1.0 / (2147483648.0 - 1.0);

/*static float frand(void)
{
	float val = random();
	return val * invRandMax;
}*/

- (void)newGenome
{
	Genome *new = [[Genome alloc] initWithComputingCreature:self];
	[genome removeCreature:self];
	[new addCreature:self];
	genome = new;
	[new release];
}

- (void)lengthMutate:(NSMutableData *)data
{
	int where = random() % ([data length] / sizeof(VMInstruction));
	VMInstruction replacementInstruction = {{0}};
	if(random() % 2) // lengthen
		[data replaceBytesInRange:NSMakeRange(where * sizeof(VMInstruction), 0) withBytes:&replacementInstruction length:sizeof(VMInstruction)];
	else if([data length] > sizeof(VMInstruction)) // shorten
		[data replaceBytesInRange:NSMakeRange(where * sizeof(VMInstruction), sizeof(VMInstruction)) withBytes:&replacementInstruction length:0];
}

- (void)addSubMutate:(NSMutableData *)data
{
	int where = random() % ([data length] / sizeof(VMInstruction));
	VMInstruction *memory = [data mutableBytes];

	int r = random();
	int add = (r & 1) ? 1 : -1;
	
	if(r & 2)
		memory[where].load.opcode += add;
	else
		memory[where].raw += add;
}

- (void)operandMutate:(NSMutableData *)data
{
	int where = random() % ([data length] / sizeof(VMInstruction));
	VMInstruction *memory = [data mutableBytes];
	VMInstruction inst = memory[where];
	switch(inst.load.opcode)
	{
		case opLoad:
		case opStore:
		case opJump:
		case opJumpEQZ:
		case opJumpNEQZ:
		case opJumpLTZ:
		case opJumpGTZ:
			switch(random() % 4)
			{
				case 0:
					inst.load.absolute = !inst.load.absolute;
					break;
				case 1:
					inst.load.reg = random() % VM_NUM_REGS;
					break;
				case 2:
					inst.load.op_is_address = !inst.load.op_is_address;
					break;
				case 3:
					inst.load.addr = random() & 0xFFFF;
					break;
			}
			break;
		case opLoadi:
			switch(random() % 2)
			{
				case 0:
					inst.loadi.reg = random() % VM_NUM_REGS;
					break;
				case 1:
					inst.loadi.val = random() & 0xFFFF;
					break;
			}
			break;
		case opMove:
		case opAdd:
		case opSub:
		case opMul:
		case opDiv:
		case opMod:
		case opCmp:
			switch(random() % 3)
			{
				case 0:
					inst.reg.source1 = random() % VM_NUM_REGS;
					break;
				case 1:
					inst.reg.source2 = random() % VM_NUM_REGS;
					break;
				case 2:
					inst.reg.dest = random() % VM_NUM_REGS;
					break;
			}
			break;
		case opSpecial:
			switch(random() % 2)
			{
				case 0:
					inst.special.reg = random() % VM_NUM_REGS;
					break;
				case 1:
					inst.special.specialopcode = random() & 0xF;
					break;
			}
			break;
	}
	memory[where] = inst;
}

- (void)changeToRandomOpcodeMutate:(NSMutableData *)data
{
	int index = random() % ([data length] / sizeof(VMInstruction));
	VMInstruction *memory = [data mutableBytes];
	memory[index].load.opcode = random() % opFinalOp;
}

- (void)copyMutate:(NSMutableData *)data
{
	int dataSize = ([data length] / sizeof(VMInstruction));
	int from = random() % dataSize;
	int length = (random() % dataSize) + 1;
	int to = random() % dataSize;

	const VMInstruction *dataCopy = [[NSData dataWithData:data] bytes]; // temporary autoreleased copy
	VMInstruction *memory = [data mutableBytes];
	while(length--)
	{
		memory[to++] = dataCopy[from++];
		if(to >= dataSize)
			to = 0;
		if(from >= dataSize)
			from = 0;
	}
}

- (void)mutate
{
	SEL sels[] = {@selector(lengthMutate:), @selector(addSubMutate:), @selector(operandMutate:), @selector(changeToRandomOpcodeMutate:), @selector(copyMutate:)};
	id data = [vm data];
	[self performSelector:sels[random() % 4] withObject:data];
	[vm setData:data];
	mutations++;
	[self newGenome];
	//[self setColor:[NSColor yellowColor]];
	{ // color fun
		float h,s,v;
		float r,g,b;
		r = color.r / 255.0;
		g = color.g / 255.0;
		b = color.b / 255.0;
		RGBtoHSV(r,g,b, &h,&s,&v);
		float deltah = ((random() % 2) == 1 ? 4 : -4);
		h += deltah;
		if(h < 0)
			h += 360;
		else if(h >= 360)
			h -= 360;
		HSVtoRGB(&r,&g,&b, h,s,v);
		Pixel24 newColor = {r*255.0,g*255.0,b*255.0};
		[self setColor:newColor];
	}
	[genome setColor:color];
}

- (void)sendMessage:(int)m
{
	NSArray *others = [arena creaturesNear:xLoc :yLoc];
	//NSEnumerator *enumerator = [others objectEnumerator];
	ComputingCreature *obj;
	int i = 0;
	//while((obj = [enumerator nextObject]))
	while(i < [others count])
	{
		obj = [others objectAtIndex:i];
		if(obj != self)
			[obj setMessage:m];
		i++;
	}
}

static float directionXArray[] =
{
	1, 0, -1, 0
};

static float directionYArray[] = 
{
	0, 1, 0, -1
};

- (NSData *)crossDataWith:(NSData *)other
{
	NSMutableData *newData;
	NSData *insertingData;
	NSData *myData = [vm data];
	if([myData length] > [other length])
	{
		newData = [NSMutableData dataWithData:myData];
		insertingData = other;
	}
	else
	{
		newData = [NSMutableData dataWithData:other];
		insertingData = myData;
	}
	int i;
	int which = random() % 2;
	int insertingLength = [insertingData length]/sizeof(VMInstruction);
	const VMInstruction *insertingBytes = [insertingData bytes];
	for(i = 0; i < insertingLength; i++)
	{
		if(which)
			[newData replaceBytesInRange:NSMakeRange(i * sizeof(VMInstruction), sizeof(VMInstruction)) withBytes:&insertingBytes[i] length:sizeof(VMInstruction)];
		if(random() % 8 == 0)
			which = !which;
	}
	return newData;
}

- (int)spawn
{
	int x = xLoc;
	int y = yLoc;
	id newCreature;
	
	x += directionXArray[moveDirection];
	y += directionYArray[moveDirection];
	
	if(newCreature)
	{
		int spawnMask = [arena spawnMask];
		if(spawnMask & kSpawnMating)
		{
			id nearbyCreatures = [arena creaturesNear:xLoc :yLoc];
			if([nearbyCreatures count] > 2)
			{
				newCreature = [self attemptSpawnAt:x :y withClass:[self class]];
				if(newCreature)
				{
					nearbyCreatures = [nearbyCreatures mutableCopy];
					[nearbyCreatures removeObjectIdenticalTo:self];
					[nearbyCreatures removeObjectIdenticalTo:newCreature];
					int which = random() % [nearbyCreatures count];
					ComputingCreature *otherCreature = [nearbyCreatures objectAtIndex:which];
					
					[newCreature setVMData:[self crossDataWith:[otherCreature programData]]];
					[newCreature setMutations:mutations];
					[newCreature setGenome:genome];
					[genome addCreature:newCreature];
					
					if(random() / randMax < [arena birthMutationRate])
						[newCreature mutate];
					
					[nearbyCreatures release];
					return 1;
				}
			}
		}
		
		if(spawnMask & kSpawnAsexual)
		{
			newCreature = [self attemptSpawnAt:x :y withClass:[self class]];
			if(newCreature)
			{
				[newCreature setVMData:[vm data]];
				[newCreature setMutations:mutations];
				[newCreature setGenome:genome];
				[genome addCreature:newCreature];
				
				if(random() / randMax < [arena birthMutationRate])
					[newCreature mutate];
				return 1;
			}
		}
	}
	return 0;
}

- (void)execute
{
	[vm executeWithCount:energy * 10];
}

- (int)handleTrap:(VMSpecialOperands)instruction withRegisterPointer:(int *)rp
{
	//NSLog(@"trap %d %d", instruction.specialopcode, *rp);
	/*

	 Trap code summary:

	  0 -- set move direction
	  1 -- store energy in register
	  2 -- spawn
	  3 -- eat
	  4 -- move
	  5 -- look
	  6 -- give energy
	  7 -- sleep
	  8 -- send message
	  9 -- read message
	 
	 */
	switch(instruction.specialopcode)
	{
		case 0: // set move direction
			moveDirection = (moveDirection + *rp) % 4;
			if(moveDirection < 0)
			{
				moveDirection += 4;
				MyAssert(moveDirection >= 0, @"");
			}
			return 0;
		case 1: // store current energy
			*rp = energy;
			return 0;
		case 2: // attempt to spawn a copy (costs energy, stores 1 into register on success)
		{
			*rp = [self spawn];
			return 1;
		}
		case 3: // eat
		{
			int x = xLoc;
			int y = yLoc;
			x += directionXArray[moveDirection];
			y += directionYArray[moveDirection];

			*rp = [self attemptEatAt:x :y];
			/*if(*rp)
				[self setColor:[NSColor redColor]];
			else
				[self setColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
			*/
			return 1;
		}
		case 4: // execute move (costs energy, same thing for confirmation)
			*rp = [self moveToPointX:xLoc + directionXArray[moveDirection]
												   Y:yLoc + directionYArray[moveDirection]];
			return 1;
		case 5: // look
			if([self canMoveToPoint:xLoc + directionXArray[moveDirection] :yLoc + directionYArray[moveDirection]])
				*rp = 1;
			else
				*rp = 0;
			return 0;
		case 6: // give energy
		{
			int x = xLoc;
			int y = yLoc;
			x += directionXArray[moveDirection];
			y += directionYArray[moveDirection];

			[self attemptGiveEnergy:*rp At:x :y];
			return 1;
		}
		case 7: // sleep
			return 1;
		case 8: // send message
			[self sendMessage:*rp];
			return 0;
		case 9: // retrieve message
			*rp = message;
			message = 0;
			return 0;
		default:
			return 1;
	}
	return 0;
}

- (void)step
{
	//if(isnan(location.x) || isnan(location.y))
	//	NSLog(@"nan!");

	if(isDead)
	{
		//NSLog(@"Dead creature 0x%x stepping!", self);
		return;
	}

	if(age < 0)
		return;
	[self execute];
	[super step];
}

- (void)die
{
	[genome removeCreature:self];
	[super die];
}


- (NSString *)disassembly
{
	return [vm disassembly];
}

- (NSString *)description
{
	NSMutableString *s = [NSMutableString stringWithFormat:@"PC: %d\tmessage: %d\n\n", [vm PC], message];
	[s appendFormat:@"Program:\n"];
	[s appendString:[self disassembly]];
	[s appendFormat:@"\nAge = %d  Energy = %f  Mutations = %d", age, energy, mutations];
	return s;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	[coder encodeObject:vm forKey:@"vmObject"];
	[coder encodeObject:genome forKey:@"genome"];
	[coder encodeInt:mutations forKey:@"mutations"];
	[coder encodeInt:message forKey:@"message"];
}

- initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	vm = [[coder decodeObjectForKey:@"vmObject"] retain];
	genome = [coder decodeObjectForKey:@"genome"];
	mutations = [coder decodeIntForKey:@"mutations"];
	message = [coder decodeIntForKey:@"message"];
	
	return self;
}


@end
