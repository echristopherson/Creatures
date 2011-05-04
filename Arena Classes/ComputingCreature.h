//
//  ComputingCreature.h
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Creature.h"


@class Genome;
@class VirtualMachine;

@interface ComputingCreature : Creature <NSCoding> {
	VirtualMachine *vm;
	Genome *genome;
	
	int mutations;
	
	int message;
}

- (void)setVMData:(NSData *)data;
- (void)setVM:(VirtualMachine *)v;
- (NSData *)programData;
- (VirtualMachine *)vm;
//- (void)setData:(VMInstruction *)d size:(int)size;
//- (void)setDataFromGenome:(Genome *)g;
- (void)setMutations:(int)m;
- (int)mutations;
- (void)setMessage:(int)m;
- (int)message;
- (Genome *)genome;
- (void)setGenome:g;
- (void)mutate;
- (void)sendMessage:(int)m;
- (int)spawn;
- (NSString *)disassembly;

@end
