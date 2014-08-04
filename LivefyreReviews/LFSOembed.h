//
//  LFSOembed.h
//  CommentStream
//
//  Created by Eugene Scherba on 10/27/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// {{{
// https://github.com/Livefyre/lfdj/blob/production/lfcore/lfcore/v2/content/models.proto#L286
#define LFS_OEMBED_TYPES_LENGTH 5u
extern const NSString *const LFSOembedTypes[LFS_OEMBED_TYPES_LENGTH];
/**
 @since Available since 0.2.1 and later
 */
typedef NS_ENUM(NSUInteger, LFSOembedType) {
    /* unknown type */
    LFSOembedTypeUnknown = 0u,      // 0
    /*! Photographic image or raster graphic art */
    LFSOembedTypePhoto,             // 1
    /*! Video */
    LFSOembedTypeVideo,             // 2
    /*! Link */
    LFSOembedTypeLink,              // 3
    /*! Rich text */
    LFSOembedTypeRich,              // 4
};
// }}}

extern LFSOembedType attachmentCodeFromString(NSString* attachmentString);
extern LFSOembedType attachmentCodeFromUTType(NSString* uttypeString);

@interface LFSOembed : NSObject

-(id)initWithObject:(id)object;

@property (nonatomic, readonly) id object;

// provider
@property (nonatomic, copy) NSString *providerName;
@property (nonatomic, copy) NSString *providerUrlString;

// general content stuff
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) NSString *linkUrlString;
@property (nonatomic, readonly) NSString *embedYouTubeId;

// image stuff
@property (nonatomic, copy) NSString *sourceUrlString;
@property (nonatomic, copy) NSString *thumbnailUrlString;
@property (nonatomic, assign) CGSize thumbnailSize; // in points (1/2 pixel)
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, assign) CGSize size; // in points (1/2 pixel)

// author stuff
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy) NSString *authorUrlString;

// meta
@property (nonatomic, assign) LFSOembedType oembedType;
@property (nonatomic, copy) NSString *version;

-(NSString*)contentAttachmentThumbnailUrlString;

@end
