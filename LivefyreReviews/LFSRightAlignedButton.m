//
//  LFSRightAlignedButton.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/21/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSRightAlignedButton.h"

@implementation LFSRightAlignedButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super imageRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(frame) -  self.imageEdgeInsets.right + self.imageEdgeInsets.left;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super titleRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMinX(frame) - CGRectGetWidth([self imageRectForContentRect:contentRect]);
    return frame;
}

@end
