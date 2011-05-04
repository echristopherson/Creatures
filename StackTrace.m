//
//  StackTrace.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>
#import "StackTrace.h"

static NSMutableSet *classesSet = nil;
static NSMutableDictionary *classesDictionary = nil;
static NSMutableDictionary *tracesDictionary = nil;
static NSMutableDictionary *refcountDictionary = nil;

@interface RefcountInterception : NSObject {

}
+ (void)pose;
@end

@implementation RefcountInterception

+ (void)pose
{
	static BOOL posed = NO;
	if(!posed)
		[self poseAsClass:[NSObject class]];
}

- (void)insertTrace:(StackTrace *)trace inDictionariesWithName:(NSString *)name
{
	NSValue *value = [NSValue valueWithNonretainedObject:self];
	if([classesDictionary objectForKey:value] == nil)
	{
		[classesDictionary setObject:isa forKey:value];
	}

	id traceArray = [tracesDictionary objectForKey:value];
	if(traceArray == nil)
	{
		traceArray = [NSMutableArray array];
		[tracesDictionary setObject:traceArray forKey:value];
	}
	[traceArray addObject:trace];
	
	id refcountArray = [refcountDictionary objectForKey:value];
	if(refcountArray == nil)
	{
		refcountArray = [NSMutableArray array];
		[refcountDictionary setObject:refcountArray forKey:value];
	}
	[refcountArray addObject:[NSString stringWithFormat:@"<%@ %d>", name, [self retainCount]]];
}

+ allocWithZone:(NSZone *)zone
{
	id obj = [super allocWithZone:zone];
	if([classesSet member:self])
	{
		StackTrace *trace = [StackTrace stackTrace];
		[obj insertTrace:trace inDictionariesWithName:@"alloc"];
	}
	return obj;
}

- retain
{
	[super retain];
	if([classesSet member:isa])
	{
		StackTrace *trace = [StackTrace stackTrace];
		[self insertTrace:trace inDictionariesWithName:@"retain"];
	}
	return self;
}

- (void)release
{
	if([classesSet member:isa])
	{
		StackTrace *trace = [StackTrace stackTrace];
		[self insertTrace:trace inDictionariesWithName:@"release"];
	}
	[super release];
}

- autorelease
{
	if([classesSet member:isa])
	{
		StackTrace *trace = [StackTrace stackTrace];
		[self insertTrace:trace inDictionariesWithName:@"autorelease"];
	}
	return [super autorelease];
}

@end

@implementation StackTrace

+ (void)initialize
{
	if(classesSet == nil)
		classesSet = [[NSMutableSet alloc] init];
	if(classesDictionary == nil)
		classesDictionary = [[NSMutableDictionary alloc] init];
	if(tracesDictionary == nil)
		tracesDictionary = [[NSMutableDictionary alloc] init];
	if(refcountDictionary == nil)
		refcountDictionary = [[NSMutableDictionary alloc] init];
}

+ (void)recordRefcountForClass:(Class)class
{
	if([classesSet member:class] == nil)
		[classesSet addObject:class];
	[RefcountInterception pose];
}

+ (void)stopRecodingRefcountForClass:(Class)class
{
	if([classesSet member:class] != nil)
		[classesSet removeObject:class];
}

+ (NSArray *)instanceHistoryTrace:obj
{
	return [tracesDictionary objectForKey:[NSValue valueWithNonretainedObject:obj]];
}

+ (NSArray *)instanceHistoryCount:obj
{
	return [refcountDictionary objectForKey:[NSValue valueWithNonretainedObject:obj]];
}

+ (NSArray *)instanceHistory:obj
{
	NSMutableArray *returnArray = [NSMutableArray array];

	NSEnumerator *traceEnumerator = [[self instanceHistoryTrace:obj] objectEnumerator];
	NSEnumerator *countEnumerator = [[self instanceHistoryCount:obj] objectEnumerator];
	id trace, count;
	while((trace = [traceEnumerator nextObject]), (count = [countEnumerator nextObject]))
	{
		[returnArray addObject:count];
		[returnArray addObject:trace];
	}
	return returnArray;
}

id InstanceHistory(id obj) { return [StackTrace instanceHistory:obj]; }

+ (NSArray *)classHistoryTrace:class
{
	NSMutableArray *returnArray = [NSMutableArray array];
	NSEnumerator *enumerator = [tracesDictionary keyEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		if([classesDictionary objectForKey:obj] == class)
			[returnArray addObject:[self instanceHistoryTrace:[obj nonretainedObjectValue]]];
	}
	return returnArray;
}

+ (NSArray *)classHistoryCount:class
{
	NSMutableArray *returnArray = [NSMutableArray array];
	NSEnumerator *enumerator = [tracesDictionary keyEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		if([classesDictionary objectForKey:obj] == class)
			[returnArray addObject:[self instanceHistoryCount:[obj nonretainedObjectValue]]];
	}
	return returnArray;
}

void PrintHistoryForClass(char *className)
{
	Class class = NSClassFromString([NSString stringWithFormat:@"%s", className]);
	NSArray *traceArray = [StackTrace classHistoryTrace:class];
	NSArray *countArray = [StackTrace classHistoryCount:class];

	NSMutableString *outString = [NSMutableString string];
	NSEnumerator *traceEnumerator = [traceArray objectEnumerator];
	NSEnumerator *countEnumerator = [countArray objectEnumerator];
	id trace, count;
	while(((trace = [traceEnumerator nextObject]) && (count = [countEnumerator nextObject])))
	{
		[outString appendFormat:@"%@\n%@\n", count, trace];
	}
	NSLog(@"Traces for %s:\n\n----------\n%@\n----------\n\n", className, outString);
}

+ stackTrace
{
	NSString *stackTrace = nil;
	unsigned int oldMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:oldMask|NSLogAndHandleEveryExceptionMask];

	NS_DURING
		[[NSException exceptionWithName:@"FakeStackTraceException" reason:@"Fake exception for generating stack trace" userInfo:[NSMutableDictionary dictionary]] raise];
	NS_HANDLER
		stackTrace = [[[[localException userInfo] objectForKey:NSStackTraceKey] retain] autorelease];
	NS_ENDHANDLER
	
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:oldMask];

	return [[[self alloc] initWithRawTrace:stackTrace] autorelease];
}

+ stackTraceWithException:(NSException *)exception
{
	return [[[self alloc] initWithRawTrace:[[exception userInfo] objectForKey:NSStackTraceKey]] autorelease];
}

- initWithRawTrace:(NSString *)trace
{
	if(trace == nil)
	{
		[self release];
		return nil;
	}
	rawTrace = [trace retain];
	return self;
}

- (NSString *)fullTrace
{
	if(fullTrace == nil)
	{
		NSArray *rawTraceArray = [rawTrace componentsSeparatedByString:@" "];
		NSArray *arguments = [[NSArray arrayWithObjects:@"-p", [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]], nil] arrayByAddingObjectsFromArray:[rawTraceArray subarrayWithRange:NSMakeRange(3, [rawTraceArray count] - 3)]];
		NSTask *task = [[NSTask alloc] init];
		NSPipe *outPipe = [NSPipe pipe];
		NSFileHandle *outHandle = [outPipe fileHandleForReading];
		NS_DURING
			[task setLaunchPath:@"/usr/bin/atos"];
			[task setArguments:arguments];
			[task setStandardOutput:outPipe];
			[task launch];
			[task waitUntilExit];
			NSString *tempStackTraceString = [[NSString alloc] initWithData:[outHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
			fullTrace = [[[tempStackTraceString componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"] retain];
			[tempStackTraceString release];
		NS_HANDLER
			// assume the task failed, so the "fullTrace" is just the raw trace
			fullTrace = [[[rawTraceArray subarrayWithRange:NSMakeRange(3, [rawTraceArray count] - 3)] componentsJoinedByString:@"\n"] retain];
		NS_ENDHANDLER
	}
	return fullTrace;
}

- (NSString *)description
{
	NSString *tabbedTrace = [[[[self fullTrace] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n\t"];
	return [NSString stringWithFormat:@"StackTrace: (\n\t%@\n)\n", tabbedTrace];
}

@end
