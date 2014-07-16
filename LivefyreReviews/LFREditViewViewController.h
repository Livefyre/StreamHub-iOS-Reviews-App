//
//  LFREditViewViewController.h
//  LivefyreReviews
//
//  Created by kvana inc on 09/07/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DYRateView.h"
#import "LFSContent.h"
#import "LFSUser.h"
@protocol LFSEditViewControllerDelegate;


@interface LFREditViewViewController : UIViewController<DYRateViewDelegate>
@property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;
@property (nonatomic, weak) LFSContent *content;
@property (nonatomic, weak) LFSUser *user;
- (IBAction)cancelClicked:(id)sender;
- (IBAction)actionClicked:(id)sender;

@property (nonatomic, weak) id<LFSEditViewControllerDelegate> delegate;
@end
@protocol LFSEditViewControllerDelegate <NSObject>

-(id<LFSEditViewControllerDelegate>)collectionViewController;
-(void)didPostContentWithOperation:(NSOperation*)operation response:(id)responseObject;
-(void)didSendPostRequestWithReplyTo:(NSString*)replyTo;
@end
