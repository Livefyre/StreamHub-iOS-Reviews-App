//
//  LFRConfig.m
//  LivefyreReviews
//
//  Created by kvana inc on 08/06/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import "LFRConfig.h"

@implementation LFRConfig
@synthesize collections = _collections;

-(id)initwithValues{
    
    [self collections];
    return self;
}

#pragma mark - public methods
-(NSArray*)collections
{
    if (_collections) {
        return _collections;
    }
    NSArray *objects=[[NSArray alloc]initWithObjects:@"~Writable",@"livefyre.com",@"labs.fyre.co",@"320568",@"custom-1379372287037",@"eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJkb21haW4iOiAibGFicy5meXJlLmNvIiwgImV4cGlyZXMiOiAxNDI3ODczNDMwLjIwNDI1NiwgInVzZXJfaWQiOiAiY29tbWVudGVyXzAifQ.xOYm5bj_M65vYSU2eLMYYt8GteaaHgNUTq55KwJnixg",nil];
    NSArray *keys=[[NSArray alloc]initWithObjects:@"_name",@"environment",@"network",@"siteId",@"articleId",@"lftoken", nil];
    NSDictionary *defaults =[[NSDictionary alloc]initWithObjects:objects forKeys:keys];
   
    NSMutableArray *result=[[NSMutableArray alloc]init];
    [result addObject:defaults];
    
    
    return result;
}
@end
