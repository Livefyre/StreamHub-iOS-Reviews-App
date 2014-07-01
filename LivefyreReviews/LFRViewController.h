//
//  LFRViewController.h
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFSContentCollection.h"
#import "LFSPostViewController.h"
#import "LFRReplyViewController.h"
#import "LFRDetailViewController.h"
#import "DYRateView.h"
#import "TSMessage.h"
#import "TSMessageView.h"

@interface LFRViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,LFSContentCollectionDelegate,LFSPostViewControllerDelegate,LFSContentCollectionDelegate,Delete>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;

-(void)viewReviewSelected;

@end
