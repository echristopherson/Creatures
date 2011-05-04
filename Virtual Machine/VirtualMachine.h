//
//  VirtualMachine.h
//  CVM
//
//  Created by Michael Ash on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


enum {
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
	
	opLoadPC, // goes on the end so as not to disturb existing programs, is a 'special' for layout
	
	opFinalOp,
};

typedef struct {
	unsigned opcode:5;
	unsigned pack:4;
	unsigned absolute:1;
	unsigned reg:5;
	unsigned op_is_address:1;
	signed addr:16;
} VMLoadStoreOperands;

typedef struct {
	unsigned opcode:5;
	unsigned pack:6;
	unsigned reg:5;
	signed val:16;
} VMLoadImmediateOperands;

typedef struct {
	unsigned opcode:5;
	unsigned pack:12;
	unsigned source1:5;
	unsigned source2:5;
	unsigned dest:5;
} VMRegisterOnlyOperands;

typedef struct {
	unsigned opcode:5;
	unsigned pack:18;
	unsigned specialopcode:4;
	unsigned reg:5;
} VMSpecialOperands;

typedef union {
	VMLoadStoreOperands load;
	VMLoadImmediateOperands loadi;
	VMRegisterOnlyOperands reg;
	VMSpecialOperands special;
	int raw;
} VMInstruction;


#define VM_NUM_REGS 32
#define VM_REG_MASK (0x1F)
#define VM_CACHE_IMP

@interface VirtualMachine : NSObject <NSCoding, NSCopying> {
	id notifyObject;
	SEL notifySEL;
#ifdef VM_CACHE_IMP
	IMP notifyIMP;
#endif
	
	VMInstruction *memory;
	int memlength;

	int PC;
	int r[VM_NUM_REGS];
}

- initWithMemory:(const VMInstruction *)mem length:(int)len pad:(int)pad;
- initWithData:(NSData *)data pad:(int)pad;
- (void)setData:(NSData *)data;
- (NSMutableData *)data;
- (int)PC;
- (int *)registers;
- (void)setTrapHandlerObject:obj selector:(SEL)sel;
// selector should be of the form:
//
//  - (int)handleTrap:(VMSpecialOperands)instruction withRegisterPointer:(int *)rp;
//
// return 0 to continue execution, nonzero to halt
- (void)executeWithCount:(int)howMany;

- (NSString *)disassembly;

@end
