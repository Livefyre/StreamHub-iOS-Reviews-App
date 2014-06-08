//
//  LFSContent.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/24/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StreamHub-iOS-SDK/LFSConstants.h>

#import "LFSAuthorCollection.h"
#import "LFSContentCollection.h"
#import "LFSOembed.h"

@class LFSContent;

typedef void (^LFSContentChildVisitor) (LFSContent *obj);

@interface LFSContent : NSObject

-(id)initWithObject:(id)object;

@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSString *idString;

@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, readonly) BOOL authorIsModerator;
@property (nonatomic, readonly) BOOL isFeatured;

@property (nonatomic, readonly) NSString *twitterId;
@property (nonatomic, readonly) NSString *twitterUrlString;

@property (nonatomic, strong) LFSAuthorProfile *author;
@property (nonatomic, strong) LFSContent *parent;
@property (nonatomic, strong) NSHashTable *children;

@property (nonatomic, copy) NSDictionary *content;

@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, copy) NSString *authorId;
@property (nonatomic, copy) NSString *parentId;
@property (nonatomic, copy) NSString *bodyHtml;
@property (nonatomic, copy) NSDictionary *annotations;

@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSNumber *eventId;

@property (nonatomic, assign) LFSContentVisibility lastVis;
@property (nonatomic, assign) LFSContentVisibility visibility;
@property (nonatomic, assign) LFSContentType contentType;
@property (nonatomic, assign) NSUInteger contentSource;

@property (nonatomic, strong) NSMutableSet *likes;
@property (nonatomic, copy) NSMutableArray *datePath;

@property (nonatomic, strong) NSArray *childContent;
@property (nonatomic, assign) NSInteger nodeCount;

@property (nonatomic, copy) LFSOembed *firstOembed;

-(NSUInteger)nodeCountSumOfChildren;
-(void)enumerateVisiblePathsUsingBlock:(LFSContentChildVisitor)block;

-(void)setAuthorWithCollection:(LFSAuthorCollection*)authorCollection;
-(NSComparisonResult)compare:(LFSContent*)content;

-(NSMutableDictionary*)authorHandles;
-(NSOrderedSet*)conversationParticipants;

-(void)addOembed:(id)oembed;

@end
