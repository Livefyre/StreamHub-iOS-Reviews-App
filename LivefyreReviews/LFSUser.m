//
//  LFSUser.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/16/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSModelMacros.h"
#import "LFSUser.h"

@implementation LFSUser {
    BOOL _isModAnywhereIsSet;
}

/*
{
    "auth_token" =     {
        ttl = 13034548;
        value = "<access token>";
    };
    isModAnywhere = 1;
    permissions =     {
        authors =         (
                           {
                               id = "commenter_0@labs.fyre.co";
                               key = 81b163f3d37446b1352d3c87b8660ae579ebedbb;
                           }
                           );
    };
    profile =     {
        avatar = "http://avatars.fyre.co/a/anon/50.jpg";
        displayName = "Commenter 0";
        id = "commenter_0@labs.fyre.co";
        profileUrl = "<null>";
        settingsUrl = "<null>";
    };
    token =     {
        ttl = 2592000;
        value = "<access token>";
    };
    version = "__VERSION__";
}*/

#pragma mark - Properties

@synthesize object = _object;
-(void)setObject:(id)object
{
    if (_object != nil && _object != object) {
        typeof(self) newObject = [[self.class alloc] initWithObject:object];
        NSString *newId = newObject.idString;
        if (![self.idString isEqualToString:newId]) {
            [NSException raise:@"Object rebase conflict"
                        format:@"Cannot rebase object with id %@ on top %@", self.idString, newId];
        }
        [self resetCached];
    }
    _object = object;
}

-(NSString*)description
{
    return [_object description];
}

-(NSUInteger)hash
{
    return [self.idString hash];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [self.idString isEqualToString:[object idString]];
    } else {
        return NO;
    }
}

#pragma mark - Lazy autho-synthesized properties
@synthLazyWithNull(NSString, version, _object, @"version")

@synthLazyWithNull(NSDictionary, authToken, _object, @"auth_token")
@synthLazyWithNull(NSDictionary, permissions, _object, @"permissions")
@synthLazyWithNull(NSDictionary, token, _object, @"token")


#pragma mark -
@synthesize idString = _idString;
-(NSString*)idString
{
    if (_idString == nil) {
        // no need to check for NSNull
        _idString = self.profile.idString;
    }
    return _idString;
}

#pragma mark -
@synthesize isModAnywhere = _isModAnywhere;
-(BOOL)isModAnywhere {
    const static NSString* const key = @"isModAnywhere";
    if (_isModAnywhereIsSet == NO) {
        NSNumber *value = [_object objectForKey:key];
        _isModAnywhere  = [value boolValue];
        _isModAnywhereIsSet = YES;
    }
    return _isModAnywhere;
}

#pragma mark -
@synthesize profile = _profile;
-(LFSAuthorProfile*)profile
{
    const static NSString* const key = @"profile";
    if (_profile == nil) {
        id object = [_object objectForKey:key];
        _profile = [[LFSAuthorProfile alloc] initWithObject:object];
    }
    return _profile;
}

#pragma mark - Lifecycle
-(id)initWithObject:(id)object
{
    self = [super init];
    if (self ) {
        // initialization stuff here
        _object = object;
        [self resetCached];
    }
    return self;
}

-(id)init
{
    // simply call designated initializer
    self = [self initWithObject:nil];
    return self;
}

-(void)dealloc
{
    [self resetCached];
    _object = nil;
}

-(void)resetCached
{
    // reset all cached properties except _object
    _idString = nil;
    _profile = nil;
    
    _authToken = nil;
    _version = nil;
    _token = nil;
    _profile = nil;
    _permissions = nil;
    
    _isModAnywhereIsSet = NO;
}


@end
