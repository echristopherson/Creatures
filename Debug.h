/*
 *  Debug.h
 *  Creatures
 *
 *  Created by Michael Ash on Thu Aug 07 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */



#define MyAssert(condition, format...) do { \
		if(!(condition)) \
			LogAssertionFailure(#condition, __FILE__, __FUNCTION__, __LINE__, format); \
	} while(0)

#define MyErrorLog(format...) LogError(YES, __FILE__, __FUNCTION__, __LINE__, format)
#define MyNonfatalErrorLog(format...) LogError(NO, __FILE__, __FUNCTION__, __LINE__, format)

void LogAssertionFailure(char *condition, char *file, char *function, int line, NSString *format, ...);
void LogError(BOOL fatal, char *file, char *function, int line, NSString *format, ...);
void LogUncaughtException(NSException *exception);
