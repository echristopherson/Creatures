//
//  VirtualMachine.m
//  CVM
//
//  Created by Michael Ash on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "VirtualMachine.h"
#import "VirtualMachineAssembler.h"


@implementation VirtualMachine

/*enum {
	opNop = 0,
	opLoad,
	opStore,
	opJump,
	opJumpEQZ,
	opJumpNEQZ,
	opJumpLTZ,
	opJumpGTZ,

	opLoadi,
	
	opMove,
	opAdd,
	opSub,
	opMul,
	opDiv,
	opMod,
	opCmp,

	opSpecial,
};*/

- initWithMemory:(const VMInstruction *)mem length:(int)len pad:(int)pad
{
	memlength = len + pad;
	memory = calloc(memlength, sizeof(VMInstruction));
	memcpy(memory, mem, len * sizeof(VMInstruction));
	return self;
}

- (void)dealloc
{
	free(memory);
	[super dealloc];
}

- initWithData:(NSData *)data pad:(int)pad
{
	return [self initWithMemory:[data bytes] length:[data length]/sizeof(VMInstruction) pad:pad];
}

- (void)setMemory:(const VMInstruction *)mem length:(int)len
{
	if(memory)
		free(memory);
	memlength = len;
	memory = calloc(memlength, sizeof(VMInstruction));
	memcpy(memory, mem, len * sizeof(VMInstruction));
}

- (void)setData:(NSData *)data
{
	[self setMemory:[data bytes] length:[data length]/sizeof(VMInstruction)];
}

- (NSData *)data
{
	return [NSMutableData dataWithBytes:memory length:memlength * sizeof(VMInstruction)];
}

- (int)PC
{
	return PC;
}

- (int *)registers
{
	return r;
}

- (void)setTrapHandlerObject:obj selector:(SEL)sel
{
	notifyObject = obj;
	notifySEL = sel;
#ifdef VM_CACHE_IMP
	notifyIMP = [notifyObject methodForSelector:notifySEL];
#endif
}

- (void)executeWithCount:(int)howMany
{
	// cache frequently-used ivars
	VMInstruction *_memory = memory;
	int _memlength = memlength;
	int _PC = PC;
	int *_r = r;
	
	int i;
	//int shouldStop = 0;
	for(i = 0; i < howMany; i++)
	{
		if(_PC < 0 || _PC >= _memlength)
		{
			_PC = 0;
			continue;
		}
		switch(_memory[_PC].load.opcode) // the .load is arbitrary
		{
			case opLoad:
			case opStore:
			case opJump:
			case opJumpEQZ:
			case opJumpNEQZ:
			case opJumpLTZ:
			case opJumpGTZ:
			{
				VMLoadStoreOperands inst = _memory[_PC].load;
				int location;
				if(inst.op_is_address)
					location = inst.addr;
				else
					location = _r[(inst.addr & VM_REG_MASK)];

				if(!inst.absolute)
					location += _PC;

				if(location < 0 || location >= _memlength)
				{
					//NSLog(@"location out of bounds");
					break;
				}

				if(inst.opcode == opLoad)
					_r[(inst.reg % VM_NUM_REGS)] = _memory[location].raw;
				else if(inst.opcode == opStore)
					_memory[location].raw = _r[(inst.reg % VM_NUM_REGS)];
				else
				{
					if(		inst.opcode == opJump
						|| (inst.opcode == opJumpEQZ && _r[(inst.reg % VM_NUM_REGS)] == 0)
						|| (inst.opcode == opJumpNEQZ && _r[(inst.reg % VM_NUM_REGS)] != 0)
						|| (inst.opcode == opJumpLTZ && _r[(inst.reg % VM_NUM_REGS)] < 0)
						|| (inst.opcode == opJumpGTZ && _r[(inst.reg % VM_NUM_REGS)] > 0))
						_PC = location - 1;
				}
				break;
			}
			case opLoadi:
				_r[(_memory[_PC].loadi.reg % VM_NUM_REGS)] = _memory[_PC].loadi.val;
				break;
			case opMove:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)];
				break;
			case opAdd:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] + _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)];
				break;
			case opSub:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] - _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)];
				break;
			case opMul:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] * _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)];
				break;
			case opDiv:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] / _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)];
				break;
			case opMod:
				_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = _r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] % _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)];
				break;
			case opCmp:
				if(_r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] < _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)])
					_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = -1;
				else if(_r[(_memory[_PC].reg.source1 % VM_NUM_REGS)] > _r[(_memory[_PC].reg.source2 % VM_NUM_REGS)])
					_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = 1;
				else
					_r[(_memory[_PC].reg.dest % VM_NUM_REGS)] = 0;
				break;
			case opSpecial:
#ifdef VM_CACHE_IMP
				if(notifyIMP(notifyObject, notifySEL, _memory[_PC], &(_r[(_memory[_PC].special.reg % VM_NUM_REGS)])))
#else
				if([notifyObject performSelector:notifySEL
									withObject:(id)(*(int *)(&_memory[_PC]))
									withObject:(id)&(_r[(_memory[_PC].special.reg % VM_NUM_REGS)])])
#endif
					i = 0x7FFFFFFD;
				break;
			case opLoadPC:
				_r[(_memory[_PC].special.reg % VM_NUM_REGS)] = _PC;
				break;
		}
		_PC++;
	}

	// reload ivars from cached locals
	memory = _memory;
	memlength = _memlength; // shouldn't need this one but what the hey
	PC = _PC;
}

- (NSString *)disassembly
{
	return [VirtualMachineAssembler disassemblyForData:[self data]];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeConditionalObject:notifyObject forKey:@"notifyObject"];
	[coder encodeObject:NSStringFromSelector(notifySEL) forKey:@"notifySELString"];
	[coder encodeBytes:(void *)memory length:memlength*sizeof(VMInstruction) forKey:@"memoryBytes"];
	[coder encodeInt:PC forKey:@"PC"];
	[coder encodeBytes:(void *)r length:sizeof(r) forKey:@"rbytes"];
}

- initWithCoder:(NSCoder *)coder
{
	notifyObject = [coder decodeObjectForKey:@"notifyObject"];
	notifySEL = NSSelectorFromString([coder decodeObjectForKey:@"notifySELString"]);
#ifdef VM_CACHE_IMP
	notifyIMP = [notifyObject methodForSelector:notifySEL];
#endif
	
	unsigned templen;
	VMInstruction *temp = (void *)[coder decodeBytesForKey:@"memoryBytes" returnedLength:&templen];
	if(memory)
		free(memory);
	memory = malloc(templen);
	memcpy(memory, temp, templen);
	memlength = templen/sizeof(VMInstruction);

	PC = [coder decodeIntForKey:@"PC"];

	int rlen;
	int *rtemp = (void *)[coder decodeBytesForKey:@"rbytes" returnedLength:&rlen];
	if(sizeof(r) < rlen)
		rlen = sizeof(r);
	memcpy(r, rtemp, rlen);

	return self;
}

- copyWithZone:(NSZone *)zone
{
	VirtualMachine *x = [[[self class] allocWithZone:zone] initWithData:[self data] pad:0];
	x->notifyObject = notifyObject;
	x->notifySEL = notifySEL;
	x->PC = PC;
	memcpy(x->r, r, sizeof(r));
	return x;
}

@end
