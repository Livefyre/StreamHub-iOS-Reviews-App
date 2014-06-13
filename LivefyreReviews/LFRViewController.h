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
#import "LFSDetailViewController.h"

@interface LFRViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,LFSContentCollectionDelegate,LFSPostViewControllerDelegate,LFSContentActionsDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;

@end
