//
//  LFSOembed.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/27/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "LFSModelMacros.h"
#import "LFSOembed.h"

// http://embed.ly/docs/embed/api/endpoints/1/oembed
const NSString* const LFSOembedTypes[LFS_OEMBED_TYPES_LENGTH] =
{
    @"error",
    @"photo",
    @"video",
    @"link",
    @"rich"
};

LFSOembedType attachmentCodeFromString(NSString *attachmentString) {
    static NSDictionary *_attachmentCodeFromString = nil;
    if (_attachmentCodeFromString == nil) {
        _attachmentCodeFromString = @{
                                      @"error" : [NSNumber numberWithUnsignedInteger:LFSOembedTypeUnknown],
                                      @"photo" : [NSNumber numberWithUnsignedInteger:LFSOembedTypePhoto],
                                      @"video" : [NSNumber numberWithUnsignedInteger:LFSOembedTypeVideo],
                                      @"link"  : [NSNumber numberWithUnsignedInteger:LFSOembedTypeLink],
                                      @"rich"  : [NSNumber numberWithUnsignedInteger:LFSOembedTypeRich]
                                      };
    }
    NSNumber *value = [_attachmentCodeFromString objectForKey:attachmentString];
    return  (value == nil
             ? LFSOembedTypeUnknown
             : (LFSOembedType)[value unsignedIntegerValue]);
}

LFSOembedType attachmentCodeFromUTType(NSString* uttypeString)
{
    // this function converts from UTType (e.g. "public.movie")
    // to type used in Livefyre API.
    if ([uttypeString isEqualToString:(NSString*)kUTTypeImage]
        || [uttypeString isEqualToString:(NSString*)kUTTypeJPEG]
        || [uttypeString isEqualToString:(NSString*)kUTTypeGIF]
        || [uttypeString isEqualToString:(NSString*)kUTTypePNG]
        || [uttypeString isEqualToString:(NSString*)kUTTypeJPEG2000]
        || [uttypeString isEqualToString:(NSString*)kUTTypeTIFF]
        || [uttypeString isEqualToString:(NSString*)kUTTypeBMP]
        || [uttypeString isEqualToString:(NSString*)kUTTypeICO]
        )
    {
        return LFSOembedTypePhoto;
    }
    else if ([uttypeString isEqualToString:(NSString*)kUTTypeMovie]) {
        return LFSOembedTypeVideo;
    }
    else if ([uttypeString isEqualToString:(NSString*)kUTTypeHTML]) {
        return LFSOembedTypeRich;
    }
    else if ([uttypeString isEqualToString:(NSString*)kUTTypeURL]) {
        return LFSOembedTypeLink;
    }
    else {
        return LFSOembedTypeUnknown;
    }
}

@implementation LFSOembed {
    BOOL _sizeIsSet;
    BOOL _thumbnailSizeIsSet;
    BOOL _attachmentTypeIsSet;
}

#pragma mark - Lifecycle
-(id)initWithObject:(id)object
{
    // check if object is of appropriate type
    if ([object isKindOfClass:[self class]])
    {
        self = object; // let ARC release self
    }
    else
    {
        self = [super init];
        if (self)
        {
            // initialization stuff here
            [self resetCached];
            _object = object;
        }
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
    _sizeIsSet = NO;
    _thumbnailSizeIsSet = NO;
    _attachmentTypeIsSet = NO;
    
    _providerName = nil;
    _providerUrlString = nil;
    _embedYouTubeId = nil;
    
    _title = nil;
    _linkUrlString = nil;
    
    _thumbnailUrlString = nil;
    _urlString = nil;
    
    _authorName = nil;
    _authorUrlString = nil;
    
    _version = nil;
}

-(NSString*)description
{
    return [_object description];
}

@synthesize object = _object;

#pragma mark - Lazy autho-synthesized properties
@synthLazyWithNull(NSString, authorName, _object, @"author_name")
@synthLazyWithNull(NSString, authorUrlString, _object, @"author_url")

@synthLazyWithNull(NSString, html, _object, @"html")
@synthLazyWithNull(NSString, linkUrlString, _object, @"link")
@synthLazyWithNull(NSString, providerName, _object, @"provider_name")
@synthLazyWithNull(NSString, providerUrlString, _object, @"provider_url")
@synthLazyWithNull(NSString, sourceUrlString, _object, @"source_url")
@synthLazyWithNull(NSString, thumbnailUrlString, _object, @"thumbnail_url")

@synthLazyWithNull(NSString, title, _object, @"title")

@synthLazyWithNull(NSString, urlString, _object, @"url")
@synthLazyWithNull(NSString, version, _object, @"version")


#pragma mark -
-(NSString*)contentAttachmentThumbnailUrlString
{
    if (self.oembedType == LFSOembedTypePhoto) {
        // when dealing with a photo attachment, a URL will point
        // to an image that we can use when lacking a thumbnail.
        return self.thumbnailUrlString ?: self.urlString;
    } else {
        return self.thumbnailUrlString;
    }
}

#pragma mark -
@synthesize embedYouTubeId = _embedYouTubeId;
-(NSString*)embedYouTubeId
{
    // try to extract twitter id from contentId --
    // if we fail, return nil
    static NSRegularExpression *regex = nil;
    if (_embedYouTubeId == nil) {
        NSString *urlString = self.urlString;
        if (urlString != nil) {
            if (regex == nil) {
                NSError *regexError = nil;
                regex = [NSRegularExpression
                         regularExpressionWithPattern:@"^(http|https)://www.youtube.com/watch\\?v=([a-zA-Z0-9]+)$"
                         options:0 error:&regexError];
                NSAssert(regexError == nil,
                         @"Error creating regex: %@",
                         regexError.localizedDescription);
            }
            NSTextCheckingResult *match =
            [regex firstMatchInString:urlString
                              options:0
                                range:NSMakeRange(0, [urlString length])];
            if (match != nil) {
                _embedYouTubeId = [urlString substringWithRange:[match rangeAtIndex:2u]];
            }
        }
    }
    return _embedYouTubeId;
}

#pragma mark -
@synthesize thumbnailSize = _thumbnailSize;
-(CGSize)thumbnailSize
{
    const static NSString* const kWidthKey = @"thumbnail_width";
    const static NSString* const kHeightKey = @"thumbnail_height";
    if (_thumbnailSizeIsSet == NO) {
        NSNumber *width = [_object objectForKey:kWidthKey] ?: @0;
        NSNumber *height = [_object objectForKey:kHeightKey] ?: @0;
        _thumbnailSize = CGSizeMake([width floatValue] / 2.f,
                                    [height floatValue] / 2.f);
        _thumbnailSizeIsSet = YES;
    }
    return _thumbnailSize;
}

#pragma mark -
@synthesize size = _size;
-(CGSize)size
{
    const static NSString* const kWidthKey = @"width";
    const static NSString* const kHeightKey = @"height";
    if (_sizeIsSet == NO) {
        NSNumber *width = [_object objectForKey:kWidthKey] ?: @0;
        NSNumber *height = [_object objectForKey:kHeightKey] ?: @0;
        _size = CGSizeMake([width floatValue] / 2.f,
                           [height floatValue] / 2.f);
        _sizeIsSet = YES;
    }
    return _size;
}

#pragma mark -
@synthesize oembedType = _attachmentType;
-(LFSOembedType)oembedType
{
    const static NSString* const key = @"type";
    if (_attachmentTypeIsSet == NO) {
        NSString *typeString = [_object objectForKey:key];
        _attachmentType = attachmentCodeFromString(typeString);
        _attachmentTypeIsSet = YES;
    }
    return _attachmentType;
}

@end
