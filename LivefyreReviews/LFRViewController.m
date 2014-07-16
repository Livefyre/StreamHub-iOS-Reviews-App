//
//  LFRViewController.m
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import "LFRViewController.h"
#import "LFRConfig.h"
#import <StreamHub-iOS-SDK/LFSClient.h>
#import "LFSTextField.h"
#import "LFSContent.h"
#import "LFSAttributedTextCell.h"
#import "LFSAttributedLabelDelegate.h"
#import "LFSUser.h"
#import "LFSViewResources.h"
#import <objc/runtime.h>
#import "UIImage+LFSColor.h"
#import "LFSContentCollection.h"
#import "LFRAppDelegate.h"
#import "LFSDeletedCell.h"
#import "DLStarRatingControl.h"




@interface LFRViewController ()
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) LFSContentCollection *content;
@property (nonatomic, strong) LFSAttributedLabelDelegate *attributedLabelDelegate;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) UIImage *placeholderImage;

@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;

@property (nonatomic, readonly) LFSBootstrapClient *bootstrapClient;
@property (nonatomic, readonly) LFSAdminClient *adminClient;
@property (nonatomic, readonly) LFSStreamClient *streamClient;
@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (nonatomic, readonly) LFSTextField *postCommentField;
@property (nonatomic, strong) LFSPostViewController *postViewController;
@property (nonatomic,assign)NSInteger oldCount;
@property (nonatomic, strong) LFSUser *user;
@property (nonatomic, strong) NSMutableArray *contentArray;

@end

static NSString* const kAttributedCellReuseIdentifier = @"LFSAttributedCell";
static NSString* const kFailureModifyTitle = @"Failed to modify content";
const static CGFloat kGenerationOffset = 20.f;
//const static char kAttributedTextValueKey;
//const static char kAttributedTitleValueKey;
//const static char kAtttributedTextHeightKey;
static NSString* const kCellSelectSegue = @"detailView";


@implementation LFRViewController{
#ifdef CACHE_SCALED_IMAGES
    NSCache* _imageCache;
#endif
    
    UIActivityIndicatorView *_activityIndicator;
    UIView *_container;
    CGPoint _scrollOffset;
    NSMutableArray *chaildContent;
}


#pragma mark - Properties
@synthesize content = _content;
@synthesize attributedLabelDelegate = _attributedLabelDelegate;
@synthesize collection = _collection;
@synthesize operationQueue = _operationQueue;
@synthesize user = _user;
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;
static NSString* const kDeletedCellReuseIdentifier = @"LFSDeletedCell";


@synthesize placeholderImage = _placeholderImage;
@synthesize postCommentField = _postCommentField;

@synthesize bootstrapClient = _bootstrapClient;
@synthesize streamClient = _streamClient;
@synthesize adminClient = _adminClient;
@synthesize writeClient = _writeClient;
@synthesize postViewController = _postViewController;

-(LFSAdminClient*)adminClient
{
    if (_adminClient == nil) {
        _adminClient = [LFSAdminClient
                        clientWithNetwork:[self.collection objectForKey:@"network"]
                        environment:[self.collection objectForKey:@"environment"]];
    }
    return _adminClient;
}

- (LFSWriteClient*)writeClient
{
    if (_writeClient == nil) {
        _writeClient = [LFSWriteClient
                        clientWithNetwork:[self.collection objectForKey:@"network"]
                        environment:[self.collection objectForKey:@"environment"]];
    }
    return _writeClient;
}

- (LFSBootstrapClient*)bootstrapClient
{
    if (_bootstrapClient == nil) {
        _bootstrapClient = [LFSBootstrapClient
                            clientWithNetwork:[_collection objectForKey:@"network"]
                            environment:[_collection objectForKey:@"environment"] ];
    }
    return _bootstrapClient;
}

- (LFSStreamClient*)streamClient
{
    // return StreamClient while also setting it's callback in case
    // StreamClient needs to be initialized
    if (_streamClient == nil) {
        _streamClient = [LFSStreamClient
                         clientWithNetwork:[_collection objectForKey:@"network"]
                         environment:[_collection objectForKey:@"environment"] ];
        
        __weak typeof(_content) _weakContent = _content;
        [self.streamClient setResultHandler:^(id responseObject) {
            //NSLog(@"%@", responseObject);
            [_weakContent addContent:[[responseObject objectForKey:@"states"] allValues]
                         withAuthors:[responseObject objectForKey:@"authors"]];
            
        } success:nil failure:nil];
    }
    return _streamClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _oldCount = 0;
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self setNeedsStatusBarAppearanceUpdate];
    _content = [[LFSContentCollection alloc] init];
    [_content setDelegate:self];
    _contentArray=[[NSMutableArray alloc]init];
    LFRConfig *config = [[LFRConfig alloc] initwithValues];
   // NSLog(@"%@",config.collections);
    self.collection=[[NSDictionary alloc]init];
    self.collection=[config.collections objectAtIndex:0];
	// Do any additional setup after loading the view, typically from a nib.
    [self authenticateUser];
    
    ////notification/////
    
    
    

#ifdef CACHE_SCALED_IMAGES
    _imageCache = [[NSCache alloc] init];
#endif
    
    // set system cache for URL data to 5MB
    [[NSURLCache sharedURLCache] setMemoryCapacity:1024*1024*5];
    
    _placeholderImage = [UIImage imageWithColor:
                         [UIColor colorWithRed:232.f / 255.f
                                         green:236.f / 255.f
                                          blue:239.f / 255.f
                                         alpha:1.f]];
    
    _operationQueue = [[NSOperationQueue alloc] init];
    [_operationQueue setMaxConcurrentOperationCount:8];
   // [self wheelContainerSetup];


}
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    // {{{ Navigation bar
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    //navigationBar.hidden=YES;
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2F3440) ;
        [navigationBar setTranslucent:NO];
        
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"livefyrelogo.png"]];
//        [self.navigationController.toolbar setBackgroundColor:[UIColor clearColor]];
        

    }
    [self authenticateUser];
    [self startStreamWithBoostrap];

}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    
    // add some pizzas by animating the toolbar from below (we want
    // to encourage users to post comments and this feature serves as
    // almost a call to action)
    [self.navigationController setToolbarHidden:NO animated:animated];
}
-(void)viewWillDisappear:(BOOL)animated
{
    // hide the navigation controller here
    [super viewWillDisappear:animated];
//    [self.streamClient stopStream];
//    [self.operationQueue cancelAllOperations];
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
#ifdef CACHE_SCALED_IMAGES
    [_imageCache removeAllObjects];
#endif
}

-(LFSAttributedLabelDelegate*)attributedLabelDelegate
{
    if (_attributedLabelDelegate == nil) {
        _attributedLabelDelegate = [[LFSAttributedLabelDelegate alloc] init];
        _attributedLabelDelegate.navigationController = self.navigationController;
    }
    return _attributedLabelDelegate;
}
- (void)dealloc
{
    //[self wheelContainerTeardown];
    [self.navigationController setDelegate:nil];
    [self.tableView setDelegate:nil];
    [self.tableView setDataSource:nil];
        [_postViewController setDelegate:nil];
    _postViewController = nil;
    
    _streamClient = nil;
    _bootstrapClient = nil;
    _writeClient = nil;
    _adminClient = nil;
    
//    [_postCommentField setDelegate:nil];
//    _postCommentField = nil;
    
#ifdef CACHE_SCALED_IMAGES
    [_imageCache removeAllObjects];
    _imageCache = nil;
#endif
    
    [_content setDelegate:nil];
    _content = nil;
    _container = nil;
    _activityIndicator = nil;
}

-(void)setStatusBarHidden:(BOOL)hidden
            withAnimation:(UIStatusBarAnimation)animation
{
    const static CGFloat kStatusBarHeight = 20.f;
    _prefersStatusBarHidden = hidden;
    _preferredStatusBarUpdateAnimation = animation;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        // iOS7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    else
    {
        // iOS6
        [[UIApplication sharedApplication] setStatusBarHidden:hidden
                                                withAnimation:animation];
        if (self.navigationController) {
            UINavigationBar *navigationBar = self.navigationController.navigationBar;
            if (hidden && navigationBar.frame.origin.y > 0.f)
            {
                CGRect frame = navigationBar.frame;
                frame.origin.y = 0.f;
                navigationBar.frame = frame;
            }
            else if (!hidden && navigationBar.frame.origin.y < kStatusBarHeight)
            {
                CGRect frame = navigationBar.frame;
                frame.origin.y = kStatusBarHeight;
                navigationBar.frame = frame;
            }
        }
    }
}




#pragma mark - Toolbar behavior
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y == 0){
        
        
        [_contentArray removeAllObjects];
        for (int index=0;index<[_content count] ; index++) {
            LFSContent *content=[_content objectAtIndex:index];
            if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
                [_contentArray addObject:content];
            }
        }
        [TSMessage dismissActiveNotification];
        [self sortReviews:_contentArray];

        [self.tableView reloadData];
        
    }
    
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.navigationController
     setToolbarHidden:(scrollView.contentOffset.y <= _scrollOffset.y)
     animated:YES];
//    [viewButton.titleLabel setTextColor:UIColorFromRGB(0x0F98EC)];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    _scrollOffset = scrollView.contentOffset;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self createComment:textField];
    return NO;
}
-(IBAction)createComment:(id)sender
{
    // configure destination controller
    [self.postViewController setCollection:self.collection];
    [self.postViewController setCollectionId:self.collectionId];
    [self.postViewController setAvatarImage:self.placeholderImage];
    [self.postViewController setUser:self.user];
    
    [self.navigationController presentViewController:self.postViewController
                                            animated:YES
                                          completion:nil];
}
#pragma mark - Private methods

- (void)authenticateUser
{
    if ([self.collection objectForKey:@"lftoken"] == nil) {
        return;
    }
    
    [self.adminClient authenticateUserWithToken:[self.collection objectForKey:@"lftoken"]
                                           site:[self.collection objectForKey:@"siteId"]
                                        article:[self.collection objectForKey:@"articleId"]
      onSuccess:^(NSOperation *operation, id responseObject)
     {
         self.user = [[LFSUser alloc] initWithObject:responseObject];
        [self showStatusBarWithReview];
         [self sortReviews:_contentArray];
         [self.tableView reloadData];

     
     }
      onFailure:^(NSOperation *operation, NSError *error)
     {
         NSLog(@"Could not authenticate user against collection");
     }];
}



- (void)startStreamWithBoostrap
{
    // If we have some data, do not clear it and do not run bootstrap.
    // Instead, grab the latest event ID and start streaming from there
    
    if (_content.count == 0u) {
        [_content removeAllObjects];
        
        //[self startSpinning];
        
        [self.bootstrapClient getInitForSite:[self.collection objectForKey:@"siteId"] article:[self.collection objectForKey:@"articleId"] onSuccess:^(NSOperation *operation, id responseObject)

         {
             NSDictionary *headDocument = [responseObject objectForKey:@"headDocument"];
             
             [_content addContent:[headDocument objectForKey:@"content"]
                      withAuthors:[headDocument objectForKey:@"authors"]];
             NSDictionary *collectionSettings = [responseObject objectForKey:@"collectionSettings"];
             NSString *collectionId = [collectionSettings objectForKey:@"collectionId"];
             NSNumber *eventId = [headDocument objectForKey:@"event"];
           
             //NSLog(@"%@", responseObject);
             
             // we are already on the main queue...
             [self setCollectionId:collectionId];
             [self.streamClient setCollectionId:collectionId];
             [self.streamClient startStreamWithEventId:eventId];
             //[self stopSpinning];
          }
                                   onFailure:^(NSOperation *operation, NSError *error)
         {
             NSLog(@"Error code %ld, with description %@", (long)error.code, [error localizedDescription]);
             //[self stopSpinning];
         }];
    }
    else {
        NSNumber *eventId = _content.lastEventId;
        [self.streamClient setCollectionId:self.collectionId];
        [self.streamClient startStreamWithEventId:eventId];
    }
}
-(void)didUpdateModelWithDeletes:(NSArray*)deletes updates:(NSArray*)updates inserts:(NSArray*)inserts
{
    // TODO: only perform animated insertion of cells when the top of the
    // viewport is the same as the top of the first cell
    
    UITableView *tableView = self.tableView;
    
    
//    [tableView beginUpdates];
//    [tableView deleteRowsAtIndexPaths:deletes withRowAnimation:UITableViewRowAnimationNone];
//    [tableView reloadRowsAtIndexPaths:updates withRowAnimation:UITableViewRowAnimationNone];
//    [tableView insertRowsAtIndexPaths:inserts withRowAnimation:UITableViewRowAnimationNone];
//    [tableView endUpdates];


    if(_content.count){
        //// newCount Calculating here
        //
        int newCount=0;
        for (int index=0;index<[_content count] ; index++) {
            LFSContent *content=[_content objectAtIndex:index];
            if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
                newCount++;
            }
        }
        if (_contentArray.count<newCount && _contentArray.count!=0 && tableView.contentOffset.y!=0) {
            [TSMessage dismissActiveNotification];
            [TSMessage showNotificationInViewController:self
                                                  title:[ NSString stringWithFormat:@"%lu",(unsigned long)(newCount-_contentArray.count)]
                                               subtitle:nil//NSLocalizedString(@"Please update our app. We would be very thankful", nil)
                                                  image:nil
                                                   type:TSMessageNotificationTypeMessage
                                               duration:TSMessageNotificationDurationEndless
                                               callback:nil
                                            buttonTitle:NSLocalizedString(@"New Reviews", nil)
                                         buttonCallback:^{
                                             
                                             [_contentArray removeAllObjects];
                                             
                                             for (int index=0;index<[_content count] ; index++) {
                                                 LFSContent *content=[_content objectAtIndex:index];
                                                 if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
                                                     [_contentArray addObject:content];
                                                 }
                                             }
                                             [self sortReviews:_contentArray];

                                             [tableView reloadData];
                                             [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                                   atScrollPosition:UITableViewScrollPositionTop
                                                                           animated:YES];
                                             
                                         }
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];

           // [tableView reloadData];
            
        }else{
            [_contentArray removeAllObjects];
            
            for (int index=0;index<[_content count] ; index++) {
                LFSContent *content=[_content objectAtIndex:index];
                if ([content.parentId isEqual:@""] && content.visibility == LFSContentVisibilityEveryone) {
                    [_contentArray addObject:content];
                }
            }
            [self sortReviews:_contentArray];
            [self showStatusBarWithReview ];
            [self.tableView reloadData];
        }
        //    [tableView reloadData];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ToDetail"
         object:_content];
        [self showStatusBarWithReview];
        
    }

    [tableView reloadData];

}
-(void)sortReviews:(NSMutableArray*)allReviewsBeforeSort{
    LFSContent *ownReview;
    
    if(_contentArray.count){
        for (int index=0;index<[_contentArray count] ; index++) {
            LFSContent *content=[_contentArray objectAtIndex:index];
            if ([content.parentId isEqual:@""] && [content.author.idString isEqual:self.user.idString] && content.visibility==LFSContentVisibilityEveryone) {
                ownReview=content;
                [allReviewsBeforeSort removeObjectAtIndex:index];
        }
    }
    
        
        NSArray *sortedArray;
        sortedArray = [allReviewsBeforeSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            int countA=0;
            NSArray *votesA=[[NSArray alloc]initWithArray:[[(LFSContent*)a annotations]objectForKey:@"vote" ]];
            for (NSDictionary *voteObject in votesA) {
                if ([[voteObject valueForKey:@"value"] integerValue] ==1) {
                    countA++;
                }
            }
            float percentageA;
            if ([[[(LFSContent*)a annotations]objectForKey:@"vote" ] count]!=0) {
                percentageA=countA/[[[(LFSContent*)a annotations]objectForKey:@"vote" ] count];

            }
            else{
                percentageA=0.0f;
            }
            int countB=0;
            NSArray *votesB=[[NSArray alloc]initWithArray:[[(LFSContent*)b annotations]objectForKey:@"vote" ]];
            for (NSDictionary *voteObject in votesB) {
                if ([[voteObject valueForKey:@"value"] integerValue] ==1) {
                    countB++;
                }
            }
            float percentageB;
            if ([[[(LFSContent*)b annotations]objectForKey:@"vote" ] count]!=0) {
                percentageB=countB/[[[(LFSContent*)b annotations]objectForKey:@"vote" ] count];
                
            }
            else{
                percentageB=0.0f;
            }
            
            NSString *first=[NSString stringWithFormat:@"%f",percentageA];
            NSString *second=[NSString stringWithFormat:@"%f",percentageB];
            return [second compare:first options:NSNumericSearch];
        }];
        [_contentArray removeAllObjects];
        if(ownReview)
        [_contentArray addObject:ownReview];
        [_contentArray addObjectsFromArray:sortedArray];
    }
}
-(void)showStatusBarWithReview{
    int count=0;
    float rating=0;
    for (int index=0;index<[_contentArray count] ; index++) {
        LFSContent *content=[_contentArray objectAtIndex:index];
        if ([content.parentId isEqual:@""] && [content.author.idString isEqual: self.user.idString]) {
            count++;
            rating=[[[content.annotations objectForKey:@"rating"]objectAtIndex:0] floatValue]/20;
         }
    }
    if (count == 1) {
        DYRateView *headerRatingView=[[DYRateView alloc]init];
        UILabel *reviewLabel=[[UILabel alloc]initWithFrame:CGRectMake(30, self.navigationController.navigationBar.frame.size.height/2, 95, 30)];
        reviewLabel.text=@"Your Review";
        reviewLabel.font=[UIFont fontWithName:@"helvetica neue regular" size:16];
        [reviewLabel setTextColor:UIColorFromRGB(0x777777)];
        
        headerRatingView=[[DYRateView alloc] initWithFrame:CGRectMake(135, self.navigationController.navigationBar.frame.size.height/2, 135, 15) fullStar:[UIImage imageNamed:@"icon_star_small.png"] emptyStar:[UIImage imageNamed:@"smallEmptyStar.png"]];
        headerRatingView.padding = 3;
        headerRatingView.alignment = RateViewAlignmentLeft;
        headerRatingView.userInteractionEnabled=NO;
        headerRatingView.rate=rating;
        
        UIButton *viewButton=[[UIButton alloc]initWithFrame:CGRectMake(290, self.navigationController.navigationBar.frame.size.height/2, 40, 30)];
        [viewButton setTitle:@"View" forState:UIControlStateNormal];
        [viewButton.titleLabel setFont:[UIFont fontWithName:@"helvetica neue medium" size:16]];
        [viewButton setTitleColor:UIColorFromRGB(0x0F98EC) forState:UIControlStateNormal];
        
//        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2F3440);
        [viewButton addTarget:self action:@selector(viewReviewButtonSelected) forControlEvents:UIControlEventTouchUpInside];
        
        
        UIBarButtonItem *viewButtonOnRating=[[UIBarButtonItem alloc]initWithCustomView:viewButton];
        UIBarButtonItem *starRating=[[UIBarButtonItem alloc]initWithCustomView:headerRatingView];
        UIBarButtonItem *writeCommentItem = [[UIBarButtonItem alloc]initWithCustomView:reviewLabel];
        [self setToolbarItems:[NSArray arrayWithObjects:writeCommentItem,starRating,viewButtonOnRating,nil]];
        UIToolbar *toolbar = self.navigationController.toolbar;
        [toolbar setBackgroundColor:[UIColor clearColor]];
        [toolbar setBarStyle:UIBarStyleDefault];
        headerRatingView.userInteractionEnabled=NO;
        if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70))
        {
            // iOS7
            [toolbar setBackgroundColor:[UIColor clearColor]];
            [toolbar setTranslucent:YES];
        }
        else
        {
            // iOS6
            [toolbar setBarStyle:UIBarStyleDefault];
            //[toolbar setTintColor:[UIColor lightGrayColor]];
        }
    }
    else{
        _scrollOffset = CGPointZero;
        
        CGFloat textFieldWidth =
        self.navigationController.navigationBar.frame.size.width -
        (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70) ? 32.f : 25.f);
        
        BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]
                                                            statusBarOrientation]);
        _postCommentField= [[LFSTextField alloc]
                            initWithFrame:
                            CGRectMake(0.f, 0.f, textFieldWidth, (isPortrait ? 30.f : 18.f))];
        
        [_postCommentField setDelegate:self];
        [_postCommentField setPlaceholder:@"Write a review…"];
        UIBarButtonItem *writeCommentItem = [[UIBarButtonItem alloc]
                                             initWithCustomView:_postCommentField];
        [self setToolbarItems:
         [NSArray arrayWithObjects:writeCommentItem, nil]];
        
        UIToolbar *toolbar = self.navigationController.toolbar;
        [toolbar setBackgroundColor:[UIColor clearColor]];
        [toolbar setBarStyle:UIBarStyleDefault];
        if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70))
        {
            // iOS7
            [toolbar setBackgroundColor:[UIColor clearColor]];
            [toolbar setTranslucent:YES];
        }
        else
        {
            // iOS6
            [toolbar setBarStyle:UIBarStyleDefault];
        }
    }

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFSContent *content = [_contentArray objectAtIndex:indexPath.row];
    LFSContentVisibility visibility = content.visibility;
    if (visibility == LFSContentVisibilityEveryone)
    {
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LFRDetailViewController *detailViewController = [storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
        [self.navigationController pushViewController:detailViewController animated:YES];
        detailViewController.deletedContent=self;
        detailViewController.collection=self.collection;
        detailViewController.collectionId=self.collectionId;
        detailViewController.contentItem=content;
        detailViewController.user=self.user;
         NSMutableArray *test=[[NSMutableArray alloc]init];
        [test addObject:content];
        [self recursiveChilds:content.children :test];
        detailViewController.mainContent=test;
        [self.navigationController setToolbarHidden:YES animated:YES];
 
    }
}
-(NSMutableArray*)recursiveChilds:(NSHashTable*)hashtable :(NSMutableArray*)test{
    NSEnumerator *enumerator = [hashtable objectEnumerator];
    id value;
    
    while ((value = [enumerator nextObject])) {
        /* code that acts on the hash table's values */
                if([value isKindOfClass:[LFSContent class]])
        {
            if(((LFSContent*)value).visibility==LFSContentVisibilityEveryone && ((LFSContent*)value).bodyHtml ){
                [test addObject:value];

            }
            [self recursiveChilds:((LFSContent*)value).children :test];

        }
        
            }
    return test;
}
-(void)viewReviewButtonSelected
{

    if(_contentArray.count){
        for (int index=0;index<[_contentArray count] ; index++) {
            LFSContent *content=[_contentArray objectAtIndex:index];
            if ([content.parentId isEqual:@""] && [content.author.idString isEqual:self.user.idString] && content.visibility==LFSContentVisibilityEveryone) {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                LFRDetailViewController *detailViewController = [storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
                [self.navigationController pushViewController:detailViewController animated:YES];
//                detailViewController.navigationHideen=[[NSString alloc]init];
//                detailViewController.navigationHideen=@"YES";
               // [self presentViewController:detailViewController animated:YES completion:nil];
                detailViewController.deletedContent=self;
                detailViewController.collection=self.collection;
                detailViewController.collectionId=self.collectionId;
                detailViewController.contentItem=content;
                detailViewController.user=self.user;
                NSMutableArray *test=[[NSMutableArray alloc]init];
                [test addObject:content];
                [self recursiveChilds:content.children :test];
                detailViewController.mainContent=test;
                [self.navigationController setToolbarHidden:YES animated:YES];

                
            }
        }
    }



}


#pragma mark - Table view data source

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFSContent *content = [_contentArray objectAtIndex:indexPath.row];
    LFSContentVisibility visibility = content.visibility;
    return (visibility == LFSContentVisibilityEveryone
            ? indexPath
            : nil);
}

// disable this method to get static height = better performance
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeightValue;
    LFSContent *content = [_contentArray objectAtIndex:indexPath.row];
//    CGFloat leftOffset = (CGFloat)([content.datePath count] - 1) * kGenerationOffset;
    LFSContentVisibility visibility = content.visibility;
    if (visibility == LFSContentVisibilityEveryone)
    {
        
        NSMutableAttributedString *attributedString =
        [LFSAttributedTextCell attributedStringFromHTMLString:(content.bodyHtml ?: @"")];
        
        NSMutableAttributedString *attributedTitleString=[LFSAttributedTextCell attributedStringFromTitle:(content.title ?: @"")];
        
        cellHeightValue = [LFSAttributedTextCell
                           cellHeightForAttributedString:attributedString hasAttachment:NO width:(tableView.bounds.size.width )];
        
        
        cellHeightValue=cellHeightValue+[LFSAttributedTextCell cellHeightForAttributedTitle:attributedTitleString hasAttachment:NO width:(tableView.bounds.size.width)];
        
        
          }
    else
    {
        //        cellHeightValue = [LFSDeletedCell cellHeightForBoundsWidth:tableView.bounds.size.width
        //                                                    withLeftOffset:leftOffset];
    }
    return cellHeightValue+45;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    int count=0;
    if(_contentArray.count!=0)
    for (LFSContent *content in _contentArray) {
        if(content.visibility==LFSContentVisibilityEveryone && content.parentId)
            count++;
    }
   return count;
    //return [_contentArray count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: find out which content was created by current user
    // and only return "YES" for cells displaying that content
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    LFSContent *content = [_contentArray objectAtIndex:indexPath.row];
    LFSContentVisibility visibility = content.visibility;
    return (userToken  != nil &&
            visibility == LFSContentVisibilityEveryone);
}
// Overriding this will enable "swipe to delete" gesture
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self postDestructiveMessage:LFSMessageDelete forIndexPath:indexPath];
    }
}

-(void)postDestructiveMessage:(LFSMessageAction)message forIndexPath:(NSIndexPath*)indexPath
{
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (userToken == nil) {
        // userToken is nil -- show an error message and return
        //
        // Note: Normally we never reach this block because we do not
        // allow editing for cells if our user token is nil
        [[[UIAlertView alloc]
          initWithTitle:kFailureModifyTitle
          message:@"You do not have permission to modify comments in this collection"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
        return;
    }
    
    ////////////////////////////////////////////////////////////////
    // cache current visibility state in case we need to revert
    NSUInteger row = indexPath.row;
    LFSContent *content = [_contentArray objectAtIndex:row];
    
    NSString *contentId = content.idString;
    
    [self.writeClient postMessage:message
                       forContent:content.idString
                     inCollection:self.collectionId
                        userToken:userToken
                       parameters:nil
                        onSuccess:^(NSOperation *operation, id responseObject)
     {
         NSUInteger row = [_content indexOfKey:contentId];
         if (row != NSNotFound) {
             [_content updateContentForContentId:contentId setVisibility:LFSContentVisibilityNone];
             [_contentArray removeAllObjects];
             for (int index=0;index<[_content count] ; index++) {
                 LFSContent *content=[_content objectAtIndex:index];
                 if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
                     [_contentArray addObject:content];
                 }
             }
             [self.tableView reloadData];
         }
         
     }
     onFailure:^(NSOperation *operation, NSError *error)
     {
         // show an error message
         [[[UIAlertView alloc]
           initWithTitle:kFailureModifyTitle
           message:[error localizedRecoverySuggestion]
           delegate:nil
           cancelButtonTitle:@"OK"
           otherButtonTitles:nil] show];
        NSUInteger newContentIndex = [_content indexOfKey:contentId];
        if (newContentIndex != NSNotFound)
        {
//            [[_content objectAtIndex:newContentIndex] setVisibility:visibility];
//             
//            // obtain new index path since it could have changed during the time
//            // it toook for the error response to come back
//            [self didUpdateModelWithDeletes:nil
//                                     updates:@[[NSIndexPath indexPathForRow:newContentIndex inSection:0]]
//                                     inserts:nil];
         }
     }];
    
    ////////////////////////////////////////////////////////////////
    // TODO: keep an "undo" stack from where we restore objects if delete operation is
    // a failure
    
    // the block below will result in the standard content cell being replaced by a
    // "this comment has been removed" cell.
    //[content setVisibility:LFSContentVisibilityPendingDelete];
    
//    UITableView *tableView = self.tableView;
//    [tableView beginUpdates];
//    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]
//                     withRowAnimation:UITableViewRowAnimationFade];
//    [tableView endUpdates];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     LFSContent *content = [_contentArray objectAtIndex:indexPath.row];
     LFSContentVisibility visibility = LFSContentVisibilityEveryone;

    id returnedCell;
//   if ([content.parentId isEqualToString:@""]) {
    
    if (visibility == LFSContentVisibilityEveryone)
    {
        LFSAttributedTextCell *cell = (LFSAttributedTextCell*)[tableView dequeueReusableCellWithIdentifier:kAttributedCellReuseIdentifier];
        
        if (!cell) {
            cell = [[LFSAttributedTextCell alloc]
                    initWithReuseIdentifier:kAttributedCellReuseIdentifier];
            [cell.bodyView setDelegate:self.attributedLabelDelegate];

        }
        
      [self configureAttributedCell:cell forContent:content];
        returnedCell = cell;
  }
     else
    {
        LFSDeletedCell *cell = (LFSDeletedCell *)[tableView dequeueReusableCellWithIdentifier:
                                                  kDeletedCellReuseIdentifier];
        if (!cell) {
            cell = [[LFSDeletedCell alloc]
                    initWithReuseIdentifier:kDeletedCellReuseIdentifier];
            [cell.imageView setBackgroundColor:[UIColor colorWithRed:(217.f/255.f)
                                                               green:(217.f/255.f)
                                                                blue:(217.f/255.f)
                                                               alpha:1.f]];
            [cell.imageView setImage:[UIImage imageNamed:@"Trash"]];
            [cell.imageView setContentMode:UIViewContentModeCenter];
            [cell.textLabel setFont:[UIFont italicSystemFontOfSize:12.f]];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        }
        [self configureDeletedCell:cell forContent:content];
        returnedCell = cell;
    }
    return returnedCell;

}
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:kCellSelectSegue])
    {
        // Get reference to the destination view controller
        if ([segue.destinationViewController isKindOfClass:[LFRDetailViewController class]]) {
            if ([sender isKindOfClass:[UITableViewCell class]]) {
                LFSAttributedTextCell *cell = (LFSAttributedTextCell *)sender;
                NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
                LFRDetailViewController *vc = segue.destinationViewController;
                
                // assign model object(s)
                LFSContent *contentItem = [_contentArray objectAtIndex:indexPath.row];
//#ifdef CACHE_SCALED_IMAGES
//                UIImage *avatarPreview = ([_imageCache objectForKey:contentItem.author.idString]
//                                          ?: self.placeholderImage);
//#else
//                UIImage *avatarPreview = self.placeholderImage;
//#endif
                
                
                
                vc.deletedContent=self;
                vc.collection=self.collection;
                vc.collectionId=self.collectionId;
                vc.contentItem=contentItem;
                chaildContent=[[NSMutableArray alloc]init];
                [chaildContent addObject:contentItem];
                for (int i=0; i<[_content count]; i++) {
                    LFSContent *singleContent=[_content objectAtIndex:i];
                    if ([singleContent.parentId isEqual:contentItem.idString]) {
                        [chaildContent addObject:singleContent];
                    }
                }
                vc.mainContent=chaildContent;
                

            }else if([sender isKindOfClass:[LFSContent class]]){
                LFRDetailViewController *vc = segue.destinationViewController;
//#ifdef CACHE_SCALED_IMAGES
//                UIImage *avatarPreview = ([_imageCache objectForKey:sender.author.idString]
//                                          ?: self.placeholderImage);
//#else
//                UIImage *avatarPreview = self.placeholderImage;
//#endif
                LFSContent *contentItem=(LFSContent*)sender;
                
                vc.deletedContent=self;
                vc.collection=self.collection;
                vc.collectionId=self.collectionId;
                vc.contentItem=contentItem;
                chaildContent=[[NSMutableArray alloc]init];
                [chaildContent addObject:sender];
                for (int i=0; i<[_content count]; i++) {
                    LFSContent *singleContent=[_content objectAtIndex:i];
                    if ([singleContent.parentId isEqual:contentItem.idString]) {
                        [chaildContent addObject:singleContent];
                    }
                }
                vc.mainContent=chaildContent;
                

            }
        }
    }
}
#pragma mark - Table and cell helpers

-(void)configureDeletedCell:(LFSDeletedCell*)cell forContent:(LFSContent*)content
{
    LFSContentVisibility visibility = content.visibility;
    [cell setLeftOffset:((CGFloat)([content.datePath count] - 1) * kGenerationOffset)];
    
    NSString *bodyText = (visibility == LFSContentVisibilityPendingDelete
                          ? @""
                          : @"This comment has been removed");
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%@ (%ld)", bodyText, (long)content.nodeCount]];
    [cell.textLabel setText:bodyText];
}

// called every time a cell is configured
- (void)configureAttributedCell:(LFSAttributedTextCell*)cell forContent:(LFSContent*)content
{
    // load image first
    [self loadImagesForAttributedCell:cell withContent:content];
    [cell setContentDate:content.createdAt];
    NSMutableAttributedString *attributedString =
    [LFSAttributedTextCell attributedStringFromHTMLString:(content.bodyHtml ?: @"")];
    NSMutableAttributedString *attributedTitleString=[LFSAttributedTextCell attributedStringFromTitle:(content.title ?: @"")];
    CGFloat cellHeightValue;
    cellHeightValue = [LFSAttributedTextCell
                       cellHeightForAttributedString:attributedString hasAttachment:NO width:(self.tableView.bounds.size.width )];
    cellHeightValue=cellHeightValue+[LFSAttributedTextCell cellHeightForAttributedTitle:attributedTitleString hasAttachment:NO width:(self.tableView.bounds.size.width)];
    [cell setAttributedString:attributedString];
    [cell setAttributedTitleString:attributedTitleString];
    [cell setRequiredBodyHeight: cellHeightValue];
    LFSAuthorProfile *author = content.author;
    NSNumber *rating=[[content.annotations objectForKey:@"rating"]objectAtIndex:0];
    NSString *title = author.displayName ?: @"";
    cell.content=content;
    [cell setProfileLocal:[[LFSResource alloc]initWithIdentifier:(author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : @"")attribute:AttributeObjectFromContent(content)displayString:title icon:nil rating:rating]];
}

UIImage* scaleImage(UIImage *image, CGSize size, UIViewContentMode contentMode)
{
    // scale down image with Aspect Fill
    CGRect targetRect;
    targetRect.origin = CGPointZero;
    if (contentMode == UIViewContentModeScaleAspectFill) {
        CGSize currentSize = image.size;
        if (currentSize.height * size.width > size.height * currentSize.width) {
            // pick size.width
            targetRect.size.width = size.width;
            targetRect.size.height = (size.width / currentSize.width) * currentSize.height;
        } else {
            // pick size.height
            targetRect.size.height = size.height;
            targetRect.size.width = (size.height / currentSize.height) * currentSize.width;
        }
    }
    else if (contentMode == UIViewContentModeScaleToFill) {
        targetRect.size = size;
    }
    else {
        NSException* invalidContentMode =
        [NSException exceptionWithName:@"LFSInvalidContentMode"
                                reason:@"Invalid content mode for image rescaling"
                              userInfo:nil];
        @throw invalidContentMode;
    }
    
    // don't call UIGraphicsBeginImageContext when supporting Retina,
    // instead call UIGraphicsBeginImageContextWithOptions with zero
    // for scale
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.f);
    [image drawInRect:targetRect];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return processedImage;
}

-(void)loadImageWithURL:(NSURL*)url
            scaleToSize:(CGSize)size
            contentMode:(UIViewContentMode)contentMode
                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    if (url == nil) { return; }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[AFImageResponseSerializer serializer]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIImage *image = scaleImage(responseObject, size, contentMode);
        success(operation, image);
    } failure:failure];
    
    [self.operationQueue addOperation:operation];
}

-(void)loadImageWithURL:(NSURL*)url
      forAttributedCell:(LFSAttributedTextCell*)cell
              contentId:(NSString*)contentId
               cacheKey:(NSString*)key
            scaleToSize:(CGSize)size
            contentMode:(UIViewContentMode)contentMode
              loadBlock:(void (^)(LFSAttributedTextCell *cell, UIImage *image))loadBlock
{
#ifdef CACHE_SCALED_IMAGES
    UIImage *scaledImage = [_imageCache objectForKey:key];
    if (scaledImage) {
        [_imageCache setObject:scaledImage forKey:key];
        loadBlock(cell, scaledImage);
    }
    else {
#endif
        // load avatar images in a separate queue
        loadBlock(cell, self.placeholderImage);
        
        // avatarUrl will be nil if URL string is nil or invalid
        [self loadImageWithURL:url
                   scaleToSize:size
                   contentMode:contentMode
                       success:^(AFHTTPRequestOperation *operation, UIImage* image) {
#ifdef CACHE_SCALED_IMAGES
                           [_imageCache setObject:image forKey:key];
#endif
                           // we are on the main thead here -- display the image
                           NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_content indexOfKey:contentId]
                                                                       inSection:0];
                           UITableViewCell *cell = (UITableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                           if (cell != nil && [cell isKindOfClass:[LFSAttributedTextCell class]])
                           {
                               // check for cell class (as it could have been deleted)
                               // `cell' is true here only when cell is visible
                               loadBlock((LFSAttributedTextCell*)cell, image);
                               [cell setNeedsLayout];
                           }
                       }
                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef CACHE_SCALED_IMAGES
                           // cache placeholder image instead so we don't repeatedly
                           // hit the server looking for stuff that doesn't exist
                           if (self.placeholderImage) {
                               [_imageCache setObject:self.placeholderImage forKey:key];
                           }
#endif
                       }];
#ifdef CACHE_SCALED_IMAGES
    }
#endif
}

-(void)loadImagesForAttributedCell:(LFSAttributedTextCell*)cell withContent:(LFSContent*)content
{
    LFSAuthorProfile *author = content.author;
    [self loadImageWithURL:[NSURL URLWithString:author.avatarUrlString75]
         forAttributedCell:cell
                 contentId:content.idString
                  cacheKey:author.idString
               scaleToSize:kCellImageViewSize
               contentMode:UIViewContentModeScaleToFill
                 loadBlock:^(LFSAttributedTextCell *cell, UIImage *image)
     {
         [cell.imageView setImage:image];
     }];
    
    LFSOembed *attachment = content.firstOembed;
    if (content.firstOembed.contentAttachmentThumbnailUrlString != nil) {
        [self loadImageWithURL:[NSURL URLWithString:content.firstOembed.contentAttachmentThumbnailUrlString]
             forAttributedCell:cell
                     contentId:content.idString
                      cacheKey:attachment.thumbnailUrlString
                   scaleToSize:kAttachmentImageViewSize
                   contentMode:UIViewContentModeScaleAspectFill
                     loadBlock:^(LFSAttributedTextCell *cell, UIImage *image)
         {
             [cell setAttachmentImage:image];
         }];
    } else {
        [cell setAttachmentImage:nil];
    }
}



-(void)flagContent:(LFSContent*)content withFlag:(LFSContentFlag)flag
{
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (content != nil && userToken != nil && self.collectionId != nil) {
        [self.writeClient postFlag:flag
                        forContent:content.idString
                      inCollection:self.collectionId
                         userToken:userToken
                        parameters:nil
                         onSuccess:nil
                         onFailure:^(NSOperation *operation, NSError *error)
         {
             // show an error message
             [[[UIAlertView alloc]
               initWithTitle:nil
               message:@"An error has occurred. Please try again. "
               delegate:nil
               cancelButtonTitle:@"OK"
               otherButtonTitles:nil] show];
         }];
    }
}

-(void)featureContent:(LFSContent*)content
{
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (content != nil && userToken != nil && self.collectionId != nil) {
        [self.writeClient feature:YES comment:content.idString inCollection:self.collectionId userToken:userToken onSuccess:^(NSOperation *operation, id responseObject) {
            NSLog(@"%@ ",responseObject);
        } onFailure:^(NSOperation *operation, NSError *error) {
//            <#code#>
//        }]
//        
//        
//        [self.writeClient feature:YES
//                          comment:content.idString
//                     inCollection:self.collectionId
//                        userToken:userToken
//                        onSuccess:nil
//                        onFailure:^(NSOperation *operation, NSError *error)
//         {
             // show an error message
             [[[UIAlertView alloc]
               initWithTitle:nil
               message:@"An error has occurred. Please try again."
               delegate:nil
               cancelButtonTitle:@"OK"
               otherButtonTitles:nil] show];
         }];
    }
}

-(void)banAuthorOfContent:(LFSContent*)content
{
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (content != nil && userToken != nil && self.collectionId != nil) {
        [self.writeClient flagAuthor:content.author.idString
                              action:LFSAuthorActionBan
                            forSites:[self.collection objectForKey:@"siteId"]
                         retroactive:NO
                           userToken:userToken
                           onSuccess:nil
                           onFailure:^(NSOperation *operation, NSError *error)
         {
             // show an error message
             [[[UIAlertView alloc]
               initWithTitle:nil
               message:@"An error has occurred. Please try again."
               delegate:nil
               cancelButtonTitle:@"OK"
               otherButtonTitles:nil] show];
         }];
    }
}
-(void)postDestructiveMessage:(LFSMessageAction)message forContent:(LFSContent*)content
{
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    NSString *contentId = content.idString;
    LFSContentVisibility visibility = content.visibility;
    
    [self.writeClient postMessage:message
                       forContent:content.idString
                     inCollection:self.collectionId
                        userToken:userToken
                       parameters:nil
                        onSuccess:^(NSOperation *operation, id responseObject)
     {
 
         NSUInteger row = [_content indexOfKey:contentId ];
         if (row != NSNotFound) {
             [_content updateContentForContentId:contentId setVisibility:LFSContentVisibilityNone];
//             [self.navigationController popToRootViewControllerAnimated:YES];
         }
         
     }
     
                        onFailure:^(NSOperation *operation, NSError *error)
     {
         // show an error message
         [[[UIAlertView alloc]
           initWithTitle:nil
           message:@"An error has occurred. Please try again."
           delegate:nil
           cancelButtonTitle:@"OK"
           otherButtonTitles:nil] show];
         
         // check if an object with the cached id still exists in the model
         // and if so, revert to its previous visibility state. This check is necessary
         // because it is conceivable that the streaming client has already deleted
         // the content object
         NSUInteger newContentIndex = [_content indexOfKey:contentId];
         if (newContentIndex != NSNotFound)
         {
             [[_content objectAtIndex:newContentIndex] setVisibility:visibility];
             
             // obtain new index path since it could have changed during the time
             // it toook for the error response to come back
             [self didUpdateModelWithDeletes:nil
                                     updates:@[[NSIndexPath indexPathForRow:newContentIndex inSection:0]]
                                     inserts:nil];
         }
     }];
}
-(void)editReviewOfContent:(LFSMessageAction)message forContent:(LFSContent*)content;
{
        LFREditViewViewController *EditViewController=[[LFREditViewViewController alloc]init];
        
        EditViewController.content=content;
        EditViewController.collection=self.collection;
        EditViewController.collectionId=self.collectionId;
        EditViewController.user=self.user;
        [self.navigationController presentViewController:EditViewController
                                                animated:YES
                                              completion:nil];
   
}
#pragma mark - LFSPostViewControllerDelegate
-(id<LFSPostViewControllerDelegate>)viewController
{
    // forward collection view controller here to insert messagesinto
    // the content view as soon as the server gets back to us with 200 OK
    return self;
}

-(void)didSendPostRequestWithReplyTo:(NSString *)replyTo
{
    // this is triggered before we receive 200 OK from server
    
    // decide whether to scroll to the top row or to whichever row we are
    // replying to
    NSUInteger row = (replyTo != nil) ? [_content indexOfKey:replyTo] : 0;
    [_contentArray removeAllObjects];
    for (int index=0;index<[_content count] ; index++) {
        LFSContent *content=[_content objectAtIndex:index];
        if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
            [_contentArray addObject:content];
        }
    }
    [TSMessage dismissActiveNotification];
    [self sortReviews:_contentArray];
    
    [self.tableView reloadData];

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

-(void)didPostContentWithOperation:(NSOperation*)operation response:(id)responseObject
{
    // 200 OK received, post was successful
    [_content addContent:[responseObject objectForKey:@"messages"]
             withAuthors:[responseObject objectForKey:@"authors"]];
    [_contentArray removeAllObjects];
    for (int index=0;index<[_content count] ; index++) {
        LFSContent *content=[_content objectAtIndex:index];
        if ([content.parentId isEqual:@""] && content.visibility==LFSContentVisibilityEveryone) {
            [_contentArray addObject:content];
        }
    }
    [TSMessage dismissActiveNotification];
    [self sortReviews:_contentArray];
    
    [self.tableView reloadData];
    
}
-(LFSPostViewController*)postViewController
{
    static NSString* const kLFSPostCommentViewControllerId = @"postComment";
    
    if (_postViewController == nil) {
        _postViewController =
        (LFSPostViewController*)[[AppDelegate mainStoryboard]
                                 instantiateViewControllerWithIdentifier:
                                 kLFSPostCommentViewControllerId];
        [_postViewController setDelegate:self];
    }
    return _postViewController;
}

@end

