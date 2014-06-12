//
//  LFSDetailView.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/26/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "LFSResource.h"
#import "LFSBasicHTMLLabel.h"

@protocol LFSDetailViewDelegate;

@interface LFSDetailView : UIView <UIWebViewDelegate>

@property (nonatomic, weak) id<LFSDetailViewDelegate>delegate;

@property (nonatomic, strong) LFSResource* profileLocal;
@property (nonatomic, strong) LFSResource* profileRemote;
@property (nonatomic, strong) LFSResource* contentRemote;

@property (nonatomic, copy) NSString* contentBodyHtml;

@property (nonatomic, strong) NSDate* contentDate;

@property (readonly, nonatomic) UIButton *button1;
@property (readonly, nonatomic) UIButton *button2;
@property (readonly, nonatomic) UIButton *button3;

@property (readonly, nonatomic) LFSBasicHTMLLabel *bodyView;

@property (nonatomic, strong) UIView *attachmentView;

@end

// thanks to this protocol, LFSDetailView does not need
// to know anything about the structure of the model object
@protocol LFSDetailViewDelegate <NSObject>

// actions
- (void)didSelectButton1:(id)sender;
- (void)didSelectButton2:(id)sender;
- (void)didSelectButton3:(id)sender;

- (void)didChangeContentSize;
- (CGSize)requestedContentSize;

@optional
- (void)didSelectProfile:(id)sender withURL:(NSURL*)url;
- (void)didSelectContentRemote:(id)sender withURL:(NSURL*)url;

@end
