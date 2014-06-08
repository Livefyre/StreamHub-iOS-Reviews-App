//
//  LFSUser.h
//  CommentStream
//
//  Created by Eugene Scherba on 10/16/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LFSAuthorProfile.h"

@interface LFSUser : NSObject

-(id)initWithObject:(id)object;

@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSString *idString;

@property (nonatomic, strong) NSDictionary *authToken;
@property (nonatomic, assign) BOOL isModAnywhere;
@property (nonatomic, strong) NSDictionary *permissions;
@property (nonatomic, strong) LFSAuthorProfile *profile;
@property (nonatomic, strong) NSDictionary *token;
@property (nonatomic, strong) NSString *version;

@end
