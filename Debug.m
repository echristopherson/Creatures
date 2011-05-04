/*
 *  Debug.c
 *  Creatures
 *
 *  Created by Michael Ash on Thu Aug 07 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "Debug.h"
#import "ErrorPanelController.h"
#import "StackTrace.h"


void LogErrorv(BOOL fatal, char *file, char *function, int line, NSString *format, va_list args)
{
	NSString *userErrorString = [[NSString alloc] initWithFormat:format arguments:args];
	NSString *error = [NSString stringWithFormat:@"Error occured at %s:%d (%s): %@", file, line, function, userErrorString];
	NSLog(@"%@", error);
	if(NSApp)
	{
		if(fatal)
		{
			[ErrorPanelController runPanelWithError:error report:[NSString stringWithFormat:@"%@\n\nApplication version: %@\n\nThe stack trace for this error is:\n%@", error, [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey], [[StackTrace stackTrace] fullTrace]] fatal:fatal];
			exit(1);
		}
		else
			NSRunCriticalAlertPanel(userErrorString, @"", NSLocalizedString(@"OK", @"default button title"), nil, nil);
	}
	[userErrorString release];
}

void LogAssertionFailure(char *condition, char *file, char *function, int line, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	LogErrorv(YES, file, function, line, [NSString stringWithFormat:@"(assertion %s failed) %@", condition, format], args);
	va_end(args);
	abort();
}

void LogError(BOOL fatal, char *file, char *function, int line, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	LogErrorv(fatal, file, function, line, format, args);
	va_end(args);
	if(fatal)
		abort();
}

void LogUncaughtException(NSException *exception)
{
	[ErrorPanelController runPanelWithError:@"Error: uncaught exception." report:[NSString stringWithFormat:@"Error: uncaught exception: %@.\n\nApplication version: %@\n\nThe stack trace for this error is:\n%@", exception, [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey], [[StackTrace stackTraceWithException:exception] fullTrace]] fatal:YES];
	exit(1);	
}
