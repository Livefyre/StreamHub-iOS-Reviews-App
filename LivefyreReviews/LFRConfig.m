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
    
    NSArray *objects=[[NSArray alloc]initWithObjects:@"~Writable",@"livefyre.com",@"client-solutions.fyre.co",@"360354",@"custom-1402701825509",@"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJkb21haW4iOiJjbGllbnQtc29sdXRpb25zLmZ5cmUuY28iLCJ1c2VyX2lkIjoicmV2aWV3VGVzdDE3NDg2MjIyNTk1MTk0ODgiLCJkaXNwbGF5X25hbWUiOiJyZXZpZXdUZXN0MTc0ODYyMjI1OTUxOTQ4OCIsImV4cGlyZXMiOjE0MDE0NjQ4MjQzMTUuNzA5fQ.Cso_nHLYx_1lFqhaK_dR2wo4SPhd7EJXh1L-Liw6d38",@"84194121",nil];
    NSArray *keys=[[NSArray alloc]initWithObjects:@"_name",@"environment",@"network",@"siteId",@"articleId",@"lftoken",@"CollectionId",nil];
    NSDictionary *defaults =[[NSDictionary alloc]initWithObjects:objects forKeys:keys];
    
    NSMutableArray *result=[[NSMutableArray alloc]init];


    [result addObject:defaults];
    
    
    return result;
}
@end
