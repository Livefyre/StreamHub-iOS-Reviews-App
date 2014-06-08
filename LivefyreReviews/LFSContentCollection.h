//
//  LFSContentCollection.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/24/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <StreamHub-iOS-SDK/LFSConstants.h>
#import "LFSAuthorCollection.h"

@protocol LFSContentCollectionDelegate;

@interface LFSContentCollection : NSMutableDictionary

- (id)objectAtIndex:(NSUInteger)index;
- (NSEnumerator *)reverseObjectEnumerator;
- (instancetype)initWithArray:(NSArray*)array;

- (NSUInteger)indexOfObject:(id)anObject; // implemented using sorted range
- (NSUInteger)indexOfKey:(id<NSCopying>)key;

@property (nonatomic, readonly) NSNumber *lastEventId;
@property (nonatomic, weak) id<LFSContentCollectionDelegate> delegate;


+ (id)dictionaryWithCapacity:(NSUInteger)count;
- (id)initWithCapacity:(NSUInteger)count;

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;
- (void)setDictionary:(NSDictionary *)otherDictionary;
- (void)setObject:(id)object forKey:(id<NSCopying>)key;

- (void)removeObject:(id)object;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectForKey:(id<NSCopying>)key;
- (void)removeObjectsForKeys:(NSArray *)keyArray;
- (void)removeAllObjects;

- (void)addObject:(id)anObject;
- (void)addObjectsFromArray:(NSArray*)array;

// other
@property (nonatomic, readonly) LFSAuthorCollection *authors;

-(void)addContent:(NSArray*)content withAuthors:(NSDictionary*)authors;

-(void)updateContentForContentId:(id<NSCopying>)contentId setVisibility:(LFSContentVisibility)visibility;

@end

@protocol LFSContentCollectionDelegate <NSObject>

-(void)didUpdateModelWithDeletes:(NSArray*)deleteSet updates:(NSArray*)updateSet inserts:(NSArray*)insertStack;

@end