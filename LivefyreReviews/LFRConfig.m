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
    //http://quill.client-solutions.fyre.co/api/v3.0/collection/84194121/post/review/?lftoken=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJkb21haW4iOiJjbGllbnQtc29sdXRpb25zLmZ5cmUuY28iLCJ1c2VyX2lkIjoicmV2aWV3VGVzdDcyMTc1NjMxMjE0ODM3NzYiLCJkaXNwbGF5X25hbWUiOiJyZXZpZXdUZXN0NzIxNzU2MzEyMTQ4Mzc3NiIsImV4cGlyZXMiOjE0MTQ2NDExNzMzNS40NDJ9.uUImJFY0EgzWOEJa3GPuMOo3JEREeFW1c5CpJyyWwbU&body=bodyText&title=titleText&rating=%7B%22default%22%3A70%7D
    NSArray *objects=[[NSArray alloc]initWithObjects:@"~Writable",@"livefyre.com",@"client-solutions.fyre.co",@"360354",@"custom-1402701825509",@"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJkb21haW4iOiJjbGllbnQtc29sdXRpb25zLmZ5cmUuY28iLCJ1c2VyX2lkIjoicmV2aWV3VGVzdDcyMTc1NjMxMjE0ODM3NzYiLCJkaXNwbGF5X25hbWUiOiJyZXZpZXdUZXN0NzIxNzU2MzEyMTQ4Mzc3NiIsImV4cGlyZXMiOjE0MTQ2NDExNzMzNS40NDJ9.uUImJFY0EgzWOEJa3GPuMOo3JEREeFW1c5CpJyyWwbU",@"84194121",nil];
    NSArray *keys=[[NSArray alloc]initWithObjects:@"_name",@"environment",@"network",@"siteId",@"articleId",@"lftoken",@"CollectionId",nil];
    NSDictionary *defaults =[[NSDictionary alloc]initWithObjects:objects forKeys:keys];
    
    NSMutableArray *result=[[NSMutableArray alloc]init];
    [result addObject:defaults];
    
    
    return result;
}
@end
