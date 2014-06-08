//
//  UIImage+LFSColor.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/6/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "UIImage+LFSColor.h"

@implementation UIImage (LFSColor)

+ (UIImage *)imageWithColor:(UIColor *)color {
    
    static const CGRect rect = {
        .origin = {0.f, 0.f},
        .size   = {1.f, 1.f}
    };
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.f);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
