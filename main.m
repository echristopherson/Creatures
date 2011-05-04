#import <Cocoa/Cocoa.h>
#import <Foundation/NSDebug.h>
#import <ExceptionHandling/NSExceptionHandler.h>

#include <time.h>
#include <stdlib.h>

#import "VirtualMachine.h"
#import "VirtualMachineAssembler.h"
#import "StackTrace.h"
#import "SimpleWebController.h"


@interface MyException : NSException {

}
@end
@implementation MyException
- (void)raise
{
	NSLog(@"%@", self);
	[super raise];
}
@end

@interface MyHandler : NSObject {
}
@end

@implementation MyHandler

- (int)handleTrap:(VMSpecialOperands)instruction withRegisterPointer:(int *)rp
{
	return 1;
}

@end

int main(int argc, const char *argv[])
{
	[MyException poseAsClass:[NSException class]];
	
	if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1) {
		// on a system less than 10.2
		
		NSApplicationLoad();
		NSRunCriticalAlertPanel(NSLocalizedString(@"Creatures cannot run on this version of Mac OS.", @""), NSLocalizedString(@"Creatures requires at least Mac OS 10.2 (Jaguar). You will not be able to run it on your current system. Sorry....", @""), NSLocalizedString(@"Quit", @"button title"), nil, nil);
		exit(1);
	}

	id pool = [NSAutoreleasePool new];
	[SimpleWebController loadWebKit]; // this has to be done really early
	unsigned int oldMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:oldMask|NSLogAndHandleEveryExceptionMask];
	// make sure every exception generates a stack trace so we can report it
	
#if MAC_OS_X_VERSION_10_3 <= MAC_OS_X_VERSION_MAX_ALLOWED
	srandomdev(); // srandomdev() is only included with 10.3 and up, apparently
#else
	srandom(time(0)); // seed with time() as a backup if /dev/random fails for some reason
	
	long seed;
	FILE *randomFile;
	if((randomFile = fopen("/dev/random", "r")))
	{
		if(fread(&seed, sizeof(seed), 1, randomFile) < sizeof(seed))
			srandom(seed);
		else
			perror("fread");
	}
	else
		perror("fopen");
#endif
	
	[pool release];
	
    return NSApplicationMain(argc, argv);
}
