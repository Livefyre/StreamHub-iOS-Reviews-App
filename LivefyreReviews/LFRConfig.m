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
    
    NSArray *objects=[[NSArray alloc]initWithObjects:@"~Writable",@"livefyre.com",@"client-solutions.fyre.co",@"360354",@"custom-1402701825509",@"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJkb21haW4iOiJjbGllbnQtc29sdXRpb25zLmZ5cmUuY28iLCJ1c2VyX2lkIjoicmV2aWV3VGVzdDYyNzQ3NDgxMDc0NTY1MTIiLCJkaXNwbGF5X25hbWUiOiJyZXZpZXdUZXN0NjI3NDc0ODEwNzQ1NjUxMiIsImV4cGlyZXMiOjE0MDE0NjQ4MjQ4MTcuMDA0fQ.B7Z7VFJuqsvOmou4SUqXI4bD8yW_GEr5-QEhrSs6rHk",@"84194121",nil];
    NSArray *keys=[[NSArray alloc]initWithObjects:@"_name",@"environment",@"network",@"siteId",@"articleId",@"lftoken",@"CollectionId",nil];
    NSDictionary *defaults =[[NSDictionary alloc]initWithObjects:objects forKeys:keys];
    
    NSMutableArray *result=[[NSMutableArray alloc]init];


    [result addObject:defaults];
    
    
    return result;
}
@end
