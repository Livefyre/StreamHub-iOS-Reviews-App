//
//  LFSModelMacros.h
//  CommentStream
//
//  Created by Eugene Scherba on 11/4/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#ifndef CommentStream_LFSModelMacros_h
#define CommentStream_LFSModelMacros_h


#define synthLazyWithNull(Type, Property, Parent, Key) \
synthesize Property = _##Property; \
- (Type *) Property { \
    const static NSString* const key = Key; \
    if (_##Property == nil) { \
        _##Property = [Parent objectForKey:key]; \
    } \
    if (_##Property == (Type *)[NSNull null]) { \
        return nil; \
    } \
    return _##Property; \
}

#endif
