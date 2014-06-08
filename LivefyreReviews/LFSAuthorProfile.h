//
//  LFSAuthorProfile.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/23/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LFSAuthorProfile : NSObject

-(id)initWithObject:(id)object;

@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSString *idString;

// Note: use lazy instantiation here
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *profileUrlString;
@property (nonatomic, copy) NSString *settingsUrlString;
@property (nonatomic, copy) NSString *avatarUrlString;
@property (nonatomic, copy) NSString *avatarUrlString75;

@property (nonatomic, copy) NSString *twitterHandle;
@property (nonatomic, copy) NSString *profileUrlStringNoHashBang;

@property (nonatomic, readonly) NSString *authorHandle;

@property (nonatomic, copy) NSArray *userTags;

@property (nonatomic, strong) NSNumber *userType;

@end
