//
//  LFSContentCollection.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/24/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSContent.h"
#import "LFSContentCollection.h"
#import "LFSAuthorCollection.h"


#pragma mark - convenience methods for maintaining sorted order
@interface NSMutableArray (SortedArray)

-(NSUInteger)indexOfObject:(id)anObject options:(NSBinarySearchingOptions)options usingReverseOrder:(BOOL)reverse;
-(void)insertObject:(id)anObject usingReverseOrder:(BOOL)reverse;

@end

@implementation NSMutableArray (SortedArray)

-(NSUInteger)indexOfObject:(id)anObject options:(NSBinarySearchingOptions)options usingReverseOrder:(BOOL)reverse
{
    return [self indexOfObject:anObject
                 inSortedRange:NSMakeRange(0u, [self count])
                       options:options
               usingComparator:(reverse
                                ? ^NSComparisonResult(id obj1, id obj2)
                                { return [obj2 compare:obj1]; }
                                : ^NSComparisonResult(id obj1, id obj2)
                                { return [obj1 compare:obj2]; })];
}

-(void)insertObject:(id)anObject usingReverseOrder:(BOOL)reverse
{
    NSUInteger index = [self indexOfObject:anObject options:NSBinarySearchingInsertionIndex usingReverseOrder:reverse];
    [self insertObject:anObject atIndex:index];
}

@end


NSString *descriptionForObject(id object, id locale, NSUInteger indent)
{
    if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
    {
        return [object descriptionWithLocale:locale indent:indent];
    }
    else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
    {
        return [object descriptionWithLocale:locale];
    }
    else
    {
        return [object description];
    }
}

#pragma mark LFSOrderedKeyEnumerator
@interface LFSContentKeyEnumerator : NSEnumerator

@property (nonatomic, copy) NSArray *array;
@property (nonatomic, assign) NSUInteger index;

- (id)initWithObjects:(NSArray *)array;

@end

@implementation LFSContentKeyEnumerator

@synthesize array = _array;
@synthesize index = _index;

- (id)initWithObjects:(NSArray *)array
{
    self = [super init];
    if (self)
    {
        _array = [array copy];
        _index = [_array count];
    }
    return self;
}

- (id)nextObject
{
    if (_index > 0) {
        LFSContent *content = [_array objectAtIndex:--_index];
        return content.idString;
    } else {
        return nil;
    }
}

@end

#pragma mark - LFSContentCollection
@interface LFSContentCollection ()

@property (nonatomic, strong) NSMutableDictionary *mapping;
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) NSMutableDictionary *likes;

@property (nonatomic, strong) NSMutableArray *deleteStack;
@property (nonatomic, strong) NSMutableSet *updateSet;
@property (nonatomic, strong) NSMutableArray *insertStack;

@end


@implementation LFSContentCollection

@synthesize delegate = _delegate;
@synthesize lastEventId = _lastEventId;
@synthesize mapping = _mapping;
@synthesize array = _array;

@synthesize likes = _likes;

@synthesize authors = _authors;

#pragma mark - some lazy-instantiated properties
@synthesize deleteStack = _deleteStack;
-(NSMutableArray*)deleteStack
{
    if (_deleteStack == nil) {
        _deleteStack = [[NSMutableArray alloc] init];
    }
    return _deleteStack;
}
-(void)setDeleteStack:(NSMutableArray *)deleteStack
{
    if (_deleteStack != nil) {
        for (LFSContent *obj in _deleteStack) {
            obj.index = NSNotFound;
        }
    }
    _deleteStack = deleteStack;
}

#pragma mark - 
@synthesize updateSet = _updateSet;
-(NSMutableSet*)updateSet
{
    if (_updateSet == nil) {
        _updateSet = [[NSMutableSet alloc] init];
    }
    return _updateSet;
}
-(void)setUpdateSet:(NSMutableSet *)updateSet
{
    if (_updateSet != nil) {
        for (LFSContent *obj in _updateSet) {
            obj.index = NSNotFound;
        }
    }
    _updateSet = updateSet;
}

#pragma mark -
@synthesize insertStack = _insertStack;
-(NSMutableArray*)insertStack
{
    if (_insertStack == nil) {
        _insertStack = [[NSMutableArray alloc] init];
    }
    return _insertStack;
}
-(void)setInsertStack:(NSMutableArray *)insertStack
{
    if (_insertStack != nil) {
        for (LFSContent *obj in _insertStack) {
            obj.index = NSNotFound;
        }
    }
    _insertStack = insertStack;
}

#pragma mark -
- (id)copyWithZone:(NSZone *)zone
{
    return [[[LFSContentCollection class] allocWithZone:zone]
            initWithDictionary:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[LFSContentCollection class] allocWithZone:zone]
            initWithDictionary:self];
}

#pragma mark - insertion stuff

- (NSUInteger)indexOfObject:(id)anObject
{
    return [_array indexOfObject:anObject options:NSBinarySearchingFirstEqual usingReverseOrder:YES];
}

- (NSUInteger)indexOfKey:(id<NSCopying>)key
{
    LFSContent *content = [self objectForKey:key];
    if (content == nil) {
        return NSNotFound;
    } else {
        return [self indexOfObject:content];
    }
}

-(void)insertObject:(LFSContent*)object
{
    [self insertObject:object forKey:[(LFSContent*)object idString]];
}


- (void)addObject:(id)anObject
{
    // check if object is of appropriate type
    LFSContent *content = [[LFSContent alloc] initWithObject:anObject];
    [self setObject:content forKey:content.idString];
}

-(void)insertObject:(LFSContent*)object forKey:(id<NSCopying>)key
{
    // this is our insert primitive -- all other methods with similar functionality
    // ultimately redirect here
    //
    // first insert into the dictionary
    NSAssert([_mapping objectForKey:key] == nil, @"Pre-existing object found");
    [_mapping setObject:object forKey:key];
    
    // prepare our nested enumeration data
    LFSContent *parent;
    if (object.parentId != nil
        && (parent = [self objectForKey:object.parentId]) != nil)
    {
        // found parent
        NSAssert(parent.datePath != nil, @"evenPath cannot be nil");
        NSMutableArray *array = [parent.datePath mutableCopy];
        [array addObject:object.createdAt];
        [object setDatePath:array];
        [object setParent:parent];
        [parent.children addObject:object];
    }
    else
    {
        // either no nesting or parent does not exist in memory
        object.datePath = [[NSMutableArray alloc] initWithObjects:object.createdAt, nil];
    }
    
    // at this point, we actually want to know the insertion index
    // (index to maintain a sorted array)
    NSUInteger index = [_array indexOfObject:object options:NSBinarySearchingInsertionIndex usingReverseOrder:YES];
    [self.insertStack insertObject:object usingReverseOrder:YES];
    [object setIndex:index];
}

-(void)removeObject:(id)object
{
    [self removeObject:object forKey:[(LFSContent*)object idString]];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    id object = [_array objectAtIndex:index];
    [self removeObject:object];
}

-(void)removeObject:(id)object forKey:(id)key
{
    // this is our remove primitive -- all other methods with similar functionality
    // ultimately redirect here
    //
    [[[object parent] children] removeObject:object];
    [object setParent:nil];
    [_mapping removeObjectForKey:key];
    NSUInteger index = [self indexOfObject:object];
    [_array removeObjectAtIndex:index];
}

-(void)updateLastEventWithContent:(LFSContent*)content
{
    // store last event id
    if (_lastEventId == nil ||
        (content.eventId != nil && [content.eventId compare:_lastEventId] == NSOrderedDescending))
    {
        _lastEventId = content.eventId;
    }
}

- (void)registerOembedWithContent:(LFSContent*)content
{
    NSString *targetId = content.targetId;
    id obj = [_mapping objectForKey:targetId];
    [obj addOembed:content];
}

- (void)registerOpineWithContent:(LFSContent*)content
{
    NSString *targetId = content.targetId;
    NSMutableSet *authors = [_likes objectForKey:targetId];
    if (authors == nil) {
        authors = [[NSMutableSet alloc] init];
        [_likes setObject:authors forKey:targetId];
    }
    if (content.visibility == LFSContentVisibilityNone) {
        // unlike -- remove author id
        [authors removeObject:content.authorId];
    }
    else if (content.visibility == LFSContentVisibilityEveryone) {
        // like -- add author id
        [authors addObject:content.authorId];
    }
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key
{
    // check if object is of appropriate type
    LFSContent *content = ([object isKindOfClass:[LFSContent class]]
                           ? object
                           : [[LFSContent alloc] initWithObject:object]);
    [self updateLastEventWithContent:content];
    
    NSAssert([content.idString isEqualToString:(NSString*)key], @"Key not equal to content id");
    
    LFSContent *oldContent = [_mapping objectForKey:key];
    if (oldContent != nil)
    {
        // pre-existing object found (should never happen with bootstrap data)
        [oldContent setObject:content.object];
        
        if (oldContent.index == NSNotFound) {
            // not in the set of updated, deleted, or removed objects
            // (reasoning is that it makes no sense to reload rows that will
            // be deleted or inserted)
            [self.updateSet addObject:oldContent];
            [oldContent setIndex:[self indexOfObject:oldContent]];
        }
        else {
            NSAssert(oldContent.index == NSNotFound ||
                     (self.deleteStack.count > 0 ||
                     self.insertStack.count > 0 ||
                     self.updateSet.count > 0), @"have index but not in any of the stacks");
            
            NSUInteger oldContentIndex = [self indexOfObject:oldContent];
            NSAssert(oldContent.index == oldContentIndex, @"indexes must match");
            
            NSUInteger deletedIndex = [self.deleteStack indexOfObject:oldContent options:NSBinarySearchingFirstEqual usingReverseOrder:YES];
            NSAssert(deletedIndex == NSNotFound, @"object cannot be present in deleted set since it is present in mapping");
            
            NSUInteger index = [self.insertStack indexOfObject:oldContent options:NSBinarySearchingFirstEqual usingReverseOrder:YES];
            NSAssert(index == NSNotFound, @"object cannot be present in insert set since it is present in mapping");
        }
        
        [self handleVisibilityChangeForContent:oldContent];
    }
    else
    {
        // no pre-existing object found
        // (this means that the insert/update/delete stacks also do not contain
        // said object)
        if (content.contentType == LFSContentTypeMessage) {
            [content enumerateVisiblePathsUsingBlock:^(LFSContent *obj) {
                // insert all objects listed here in that order
                [self insertObject:obj];
            }];
            
            if (content.nodeCount > 0 && content.parentId != nil) {
                LFSContent *parent = [self objectForKey:content.parentId];
                
                // update parents
                if (parent != nil) {
                    [self changeNodeCountOf:parent withDelta:content.nodeCount];
                }
            }
        }
        else if (content.contentType == LFSContentTypeOpine) {
            // dealing with an opine
            [self registerOpineWithContent:content];
        }
        else if (content.contentType == LFSContentTypeOEmbed) {
            [self registerOembedWithContent:content];
        }
    }
}

-(void)handleVisibilityChangeForContent:(LFSContent*)content
{
    NSInteger expectedNodeCount = ((content.visibility == LFSContentVisibilityEveryone ? 1 : 0) + content.nodeCountSumOfChildren);
    NSInteger delta = (NSInteger)expectedNodeCount - content.nodeCount;
    if (delta < 0) {
        // checking if delta is negative here because it is possible that we receive content
        // after delete event
        NSAssert(delta == -1, @"No support for deleting more than one comment at once");
        [self changeNodeCountOf:content withDelta:delta];
    }
}

-(void)transactionalDeleteObject:(LFSContent*)content
{
    // remove object from mapping
    [content.parent.children removeObject:content];
    [content setParent:nil];
    [_mapping removeObjectForKey:content.idString];
    
    NSUInteger contentIndex = [self indexOfObject:content];
    if (contentIndex == NSNotFound) {
        // try to remove object from the insert stack if it exists there
        NSUInteger index = [self.insertStack indexOfObject:content options:NSBinarySearchingFirstEqual usingReverseOrder:YES];
        if (index != NSNotFound) {
            [self.insertStack removeObjectAtIndex:index];
        }
    } else {
        if (content.index != NSNotFound) {
            // remove object from update sets if it exists there
            [self.updateSet removeObject:content];
        }
        
        // add found object to deleted set
        [self.deleteStack insertObject:content usingReverseOrder:YES];
        [content setIndex:contentIndex];

        // TODO: consider deleting this optional check
        NSUInteger index = [self.insertStack indexOfObject:content options:NSBinarySearchingFirstEqual usingReverseOrder:YES];
        NSAssert(index == NSNotFound, @"object cannot be present in both existing and insert stacks");
    }
}

-(void)changeNodeCountOf:(LFSContent*)content withDelta:(NSInteger)delta
{
    // recursively change (with optional removal) the node count of this node
    // and of all parent nodes above it
    
    NSParameterAssert(content != nil);
    if (delta == 0) {
        return;
    }

    content.nodeCount += delta;
    LFSContent *parent = content.parent;
    if (content.nodeCount < 1) {
        [self transactionalDeleteObject:content];
    }

    while (parent != nil) {
        parent.nodeCount += delta;
        LFSContent *prev = parent;
        parent = parent.parent;
        if (prev.nodeCount < 1) {
            [self transactionalDeleteObject:prev];
        }
    }
}
 
#pragma mark - Description

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)indent
{
    NSMutableString *padding = [NSMutableString string];
    for (NSUInteger i = 0; i < indent; i++)
    {
        [padding appendString:@"    "];
    }
    
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"%@{\n", padding];
    for (LFSContent *object in _array)
    {
        [description appendFormat:@"%@    %@ = %@;\n", padding,
         descriptionForObject(object.idString, locale, indent),
         descriptionForObject([object description], locale, indent)];
    }
    [description appendFormat:@"%@}\n", padding];
    return description;
}


#pragma mark - NSDictionary primitives

- (NSUInteger)count
{
    return [_array count];
}

// designated initializer
-(id)initWithObjects:(const __unsafe_unretained id [])objects
             forKeys:(const __unsafe_unretained id<NSCopying> [])keys
               count:(NSUInteger)cnt
{
    self = [super init];
    if (self != nil) {
        // initialize stuff here
        _mapping = [[NSMutableDictionary alloc] initWithCapacity:cnt];
        _array = [[NSMutableArray alloc] initWithCapacity:cnt];
        _likes = [[NSMutableDictionary alloc] init];
        _lastEventId = nil;
        _delegate = nil;
        
        _deleteStack = nil;
        _updateSet = nil;
        _insertStack = nil;
        
        for (NSUInteger i = cnt; i > 0u;)
        {
            i--;
            [self setObject:objects[i] forKey:keys[i]];
        }
    }
    return self;
}

- (id)objectForKey:(id)key
{
    return [_mapping objectForKey:key];
}

- (id)objectAtIndex:(NSUInteger)index
{
    LFSContent *content = [_array objectAtIndex:index];
    if (content.author == nil && _authors != nil) {
        // TODO: move setAuthorWithCollection out of LFSContent?
        [content setAuthorWithCollection:_authors];
    }
    NSMutableSet *authors = [_likes objectForKey:content.idString];
    if (authors == nil) {
        authors = [[NSMutableSet alloc] init];
        [_likes setObject:authors forKey:content.idString];
    }
    [content setLikes:authors];
    
    return content;
}

- (NSEnumerator *)keyEnumerator
{
    return [[LFSContentKeyEnumerator alloc] initWithObjects:_array];
}

#pragma mark - NSDictionary (not primitives)

-(NSEnumerator*)objectEnumerator
{
    return [_array objectEnumerator];
}

#pragma mark - NSArray (public)
- (NSEnumerator *)reverseObjectEnumerator
{
    return [_array reverseObjectEnumerator];
}

-(instancetype)initWithArray:(NSArray*)array
{
    self = [super init];
    if (self != nil) {
        // initialize stuff here
        _mapping = [[NSMutableDictionary alloc] init];
        _array = [[NSMutableArray alloc] init];
        _likes = [[NSMutableDictionary alloc] init];
        _lastEventId = nil;
        _delegate = nil;
        
        _deleteStack = nil;
        _updateSet = nil;
        _insertStack = nil;
        
        [self addObjectsFromArray:array];
    }
    return self;
}

#pragma mark - NSMutableArray
-(void)addObjectsFromArray:(NSArray*)array
{
    [array enumerateObjectsWithOptions:NSEnumerationReverse
                            usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [self addObject:obj];
    }];
}

#pragma mark - Other

-(LFSAuthorCollection*)authors
{
    if (_authors == nil) {
        _authors = [[LFSAuthorCollection alloc] init];
    }
    return _authors;
}

-(void)addContent:(NSArray*)content withAuthors:(NSDictionary*)authors
{
    [self beginUpdating];
    [self.authors addEntriesFromDictionary:authors];
    [self addObjectsFromArray:content];
    [self endUpdating];
}

-(void)updateContentForContentId:(id<NSCopying>)contentId setVisibility:(LFSContentVisibility)visibility
{
    [self beginUpdating];
    LFSContent *content = [self objectForKey:contentId];
    [content setVisibility:visibility];
    [self handleVisibilityChangeForContent:content];
    [self endUpdating];
}

-(void)beginUpdating
{
    self.deleteStack = nil;
    self.updateSet = nil;
    self.insertStack = nil;
}

-(void)endUpdating
{
    NSMutableArray *deletedIndexPaths = [[NSMutableArray alloc] init];
    NSMutableArray *updatedIndexPaths = [[NSMutableArray alloc] init];
    NSMutableArray *insertedIndexPaths = [[NSMutableArray alloc] init];
    
    for (LFSContent *obj in self.updateSet) {
        [updatedIndexPaths
         addObject:[NSIndexPath indexPathForRow:obj.index inSection:0]];
    }
    
    if (self.deleteStack.count && !self.insertStack.count) {
        for (LFSContent *obj in self.deleteStack) {
            [deletedIndexPaths addObject:[NSIndexPath indexPathForRow:obj.index inSection:0]];
        }
        // backward enumeration to preserve indexes
        [self.deleteStack
         enumerateObjectsWithOptions:NSEnumerationReverse
         usingBlock:^(LFSContent *obj, NSUInteger idx, BOOL *stop) {
            [_array removeObjectAtIndex:obj.index];
        }];
    }
    else if (!self.deleteStack.count && self.insertStack.count) {
        NSUInteger insertOffset = 0u;
        for (LFSContent *obj in self.insertStack) {
            [insertedIndexPaths addObject:[NSIndexPath indexPathForRow:(obj.index + insertOffset) inSection:0]];
            insertOffset++;
        }
        // backward enumeration to preserve indexes
        [self.insertStack
         enumerateObjectsWithOptions:NSEnumerationReverse
         usingBlock:^(LFSContent *obj, NSUInteger idx, BOOL *stop) {
            [_array insertObject:obj atIndex:obj.index];
            [obj setIndex:NSNotFound];
        }];
    }
    else {
        
        //////////////////////////////////////////////
        // correct for deletions
        NSUInteger i = 0u, imax = [self.deleteStack count];
        for (LFSContent *ins in self.insertStack) {
            // count how many deletions are before a given index of inserted object
            for (LFSContent *rem = [self.deleteStack objectAtIndex:i];
                 i < imax && rem.index < ins.index;
                 rem = [self.deleteStack objectAtIndex:i], i++)
            { }
            ins.index -= i;
        }
        
        //////////////////////////////////////////////
        // perform and record deletions
        for (LFSContent *obj in self.deleteStack) {
            [deletedIndexPaths addObject:[NSIndexPath indexPathForRow:obj.index inSection:0]];
        }
        // backward enumeration to preserve indexes
        [self.deleteStack
         enumerateObjectsWithOptions:NSEnumerationReverse
         usingBlock:^(LFSContent *obj, NSUInteger idx, BOOL *stop) {
            [_array removeObjectAtIndex:obj.index];
        }];
        
        //////////////////////////////////////////////
        // perform and record insertions
        NSUInteger insertOffset = 0u;
        for (LFSContent *obj in self.insertStack) {
            [insertedIndexPaths addObject:[NSIndexPath indexPathForRow:(obj.index + insertOffset) inSection:0]];
            insertOffset++;
        }
        // backward enumeration to preserve indexes
        [self.insertStack
         enumerateObjectsWithOptions:NSEnumerationReverse
         usingBlock:^(LFSContent *obj, NSUInteger idx, BOOL *stop) {
            [_array insertObject:obj atIndex:obj.index];
            [obj setIndex:NSNotFound];
        }];

    }

    // TODO: switch from delegate to observer pattern here
    [self.delegate didUpdateModelWithDeletes:deletedIndexPaths
                                     updates:updatedIndexPaths
                                     inserts:insertedIndexPaths];
}

#pragma mark - NSMutableDictionary methods
+ (id)dictionaryWithCapacity:(NSUInteger)count
{
    return [[self alloc] initWithCapacity:count];
}

// designated initializer
- (id)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self)
    {
        _authors = nil;

        // values and keys are private to LFSOrderedDictionary that we
        // inherit from
        _mapping = [[NSMutableDictionary alloc] initWithCapacity:capacity];
        _array = [[NSMutableArray alloc] initWithCapacity:capacity];
        
        // TODO: move likes outside of this class?
        _likes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)init
{
    return [self initWithCapacity:0u];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    [otherDictionary
     enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> key, id value, BOOL *stop)
     {
         [self setObject:value forKey:key];
     }];
}

- (void)removeObjectForKey:(id<NSCopying>)key
{
    [self removeObject:[_mapping objectForKey:key] forKey:key];
}

- (void)removeAllObjects
{
    [_mapping removeAllObjects];
    [_array removeAllObjects];
    [_likes removeAllObjects];
}
 
- (void)removeObjectsForKeys:(NSArray *)keyArray
{    
    for (id<NSCopying> key in [keyArray copy])
    {
        [self removeObjectForKey:key];
    }
}

- (void)setDictionary:(NSDictionary *)otherDictionary
{    
    [self removeAllObjects];
    [self addEntriesFromDictionary:otherDictionary];
}


@end
