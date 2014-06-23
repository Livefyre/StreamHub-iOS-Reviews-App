//
//  LFRReplyViewController.h
//  LivefyreReviews
//
//  Created by Kvana Inc 2 on 13/06/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "LFSUser.h"
#import "LFSContent.h"

@protocol LFRReplyViewControllerDelegate;
@interface LFRReplyViewController : UIViewController

@property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;
@property (nonatomic, strong) LFSContent *replyToContent;

@property (nonatomic, strong) LFSUser *user;
@property (nonatomic, strong) UIImage *avatarImage;

@property (nonatomic, weak) id<LFRReplyViewControllerDelegate> delegate;

@end


@protocol LFRReplyViewControllerDelegate <NSObject>

@optional

-(id<LFRReplyViewControllerDelegate>)ViewController;
-(void)didPostContentWithOperation:(NSOperation*)operation response:(id)responseObject;
-(void)didSendPostRequestWithReplyTo:(NSString*)replyTo;


@end
