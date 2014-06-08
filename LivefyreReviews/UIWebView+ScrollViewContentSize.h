//
//  UIWebView+ScrollViewContentSize.h
//  CommentStream
//
//  Created by Eugene Scherba on 4/16/14.
//  Copyright (c) 2014 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIWebView (ScrollViewContentSize)

-(CGSize)scrollViewContentSizeWithWidth:(CGFloat)width;
-(CGSize)documentSizeByEvaluatingJavaScript;

@end
