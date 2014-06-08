//
//  UIWebView+ScrollViewContentSize.m
//  CommentStream
//
//  Created by Eugene Scherba on 4/16/14.
//  Copyright (c) 2014 Livefyre. All rights reserved.
//

#import "UIWebView+ScrollViewContentSize.h"

@implementation UIWebView (ScrollViewContentSize)

-(CGSize)scrollViewContentSizeWithWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    CGRect oldFrame = frame;
    frame.size.height = 1.0f;
    frame.size.width = width; // setting this to "width" gives 100% frame width
    self.frame = frame;
    CGSize result = [self sizeThatFits:CGSizeZero];
    self.frame = oldFrame; // restore old frame
    return result;
}

-(CGSize)documentSizeByEvaluatingJavaScript
{
    //NSString *height = [self stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollHeight"];
    //NSString *width = [self stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"];
    NSString *height = [self stringByEvaluatingJavaScriptFromString:@"document.height"];
    NSString *width = [self stringByEvaluatingJavaScriptFromString:@"document.width"];
    return CGSizeMake([width floatValue], [height floatValue]);
}

@end
