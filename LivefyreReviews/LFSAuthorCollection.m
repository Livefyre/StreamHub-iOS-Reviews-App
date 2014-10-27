//
//  LFSAuthorCollection.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/23/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSAuthorCollection.h"

@implementation LFSAuthorCollection {
    NSMutableDictionary *_dictionary;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _dictionary = [[NSMutableDictionary alloc]
                       initWithCapacity:0u];
    }
    return self;
}

- (id)copy
{
    // this is a bit sneaky since some code out there assumes
    // that regular copy always returns an immutable version
    // of the object
	return [self mutableCopy];
}

-(void)dealloc
{
    _dictionary = nil;
}

+(instancetype)dictionary
{
    return [[self alloc] init];
}

#pragma mark - NSMutableDictionary primitives

-(id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
	if (self != nil)
	{
        _dictionary = [[NSMutableDictionary alloc]
                       initWithCapacity:numItems];
	}
	return self;
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    // only update object data if the two
    // objects turn out to have the same key
    if ([anObject isKindOfClass:[LFSAuthorProfile class]]) {
        LFSAuthorProfile *author = [_dictionary objectForKey:aKey];
        if (author == nil) {
            [_dictionary setObject:anObject forKey:aKey];
        } else {
            [author setObject:[anObject object]];
        }
        [_dictionary setObject:anObject forKey:aKey];
    } else {
        LFSAuthorProfile *author = [_dictionary objectForKey:aKey];
        if (author == nil) {
            [_dictionary setObject:[[LFSAuthorProfile alloc]
                                    initWithObject:anObject]
                            forKey:aKey];
        } else {
            [author setObject:anObject];
        }
    }
}

-(void)removeObjectForKey:(id)aKey
{
    [_dictionary removeObjectForKey:aKey];
}

#pragma mark - NSDictionary primitives

-(NSUInteger)count
{
    return [_dictionary count];
}

// designated initializer
-(id)initWithObjects:(const __unsafe_unretained id [])objects
             forKeys:(const __unsafe_unretained id<NSCopying> [])keys
               count:(NSUInteger)cnt
{
    self = [super init];
    if (self != nil) {
        // initialize stuff here
        
        // create an NSDictionary from a C array of object pointers
        // and a C array of key pointers
        Class classOfLFSAuthor = [LFSAuthorProfile class];
        LFSAuthorProfile *__strong *array =
        (LFSAuthorProfile *__strong *)malloc(sizeof(LFSAuthorProfile*) * cnt);
        for (NSUInteger i = 0; i < cnt; i++) {
            id object = objects[i];
            LFSAuthorProfile *author = ([object isKindOfClass:classOfLFSAuthor]
                                 ? (LFSAuthorProfile*)object
                                 : [[LFSAuthorProfile alloc]
                                    initWithObject:object]);
            array[i] = author;
        }
        _dictionary = [[NSMutableDictionary alloc]
                       initWithObjects:array forKeys:keys count:cnt];
        free(array);
    }
    
    return self;
}

-(id)objectForKey:(id)aKey
{
    return [_dictionary objectForKey:aKey];
}

-(NSEnumerator*)keyEnumerator
{
    return [_dictionary keyEnumerator];
}

@end
