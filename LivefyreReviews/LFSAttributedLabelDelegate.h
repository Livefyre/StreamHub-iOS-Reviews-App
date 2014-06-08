//
//  LFSAttributedLabelDelegate.h
//  CommentStream
//
//  Created by Eugene Scherba on 10/21/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "LFSBasicHTMLLabel.h"

// TODO: rename LFSAttributedLabelDelegate to something more generic as we
// use it not only as a delegate of said protocol
@interface LFSAttributedLabelDelegate : NSObject <OHAttributedLabelDelegate, UIWebViewDelegate>

-(void)followURL:(NSURL*)url;

@property (nonatomic, strong) UIViewController *webViewController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end
