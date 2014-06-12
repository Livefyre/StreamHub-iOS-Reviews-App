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

@property (nonatomic, strong) LFSUser *user;


@end

static NSString* const kAttributedCellReuseIdentifier = @"LFSAttributedCell";
static NSString* const kFailureModifyTitle = @"Failed to modify content";
const static CGFloat kGenerationOffset = 20.f;
const static char kAttributedTextValueKey;
const static char kAtttributedTextHeightKey;


@implementation LFRViewController{
#ifdef CACHE_SCALED_IMAGES
    NSCache* _imageCache;
#endif
    
    UIActivityIndicatorView *_activityIndicator;
    UIView *_container;
    CGPoint _scrollOffset;
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
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self setNeedsStatusBarAppearanceUpdate];
    _content = [[LFSContentCollection alloc] init];
    [_content setDelegate:self];
    
    LFRConfig *config = [[LFRConfig alloc] initwithValues];
   // NSLog(@"%@",config.collections);
    self.collection=[[NSDictionary alloc]init];
    self.collection=[config.collections objectAtIndex:0];
	// Do any additional setup after loading the view, typically from a nib.
    //self.headerView.backgroundColor=UIColorFromRGB(0x2F3440);
    
    // {{{ Navigation bar
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    //navigationBar.hidden=YES;
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2F3440) ;
        [navigationBar setTranslucent:NO];
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"livefyre_logo.png"]];
  
    }
    
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
        //[toolbar setTintColor:[UIColor lightGrayColor]];
    }
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
    [self.streamClient stopStream];
    [self.operationQueue cancelAllOperations];
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
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.navigationController
     setToolbarHidden:(scrollView.contentOffset.y <= _scrollOffset.y)
     animated:YES];
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
        
        [self.bootstrapClient getInitForSite:[self.collection objectForKey:@"siteId"]
                                     article:[self.collection objectForKey:@"articleId"]
                                   onSuccess:^(NSOperation *operation, id responseObject)
         {
             NSDictionary *headDocument = [responseObject objectForKey:@"headDocument"];
             [_content addContent:[headDocument objectForKey:@"content"]
                      withAuthors:[headDocument objectForKey:@"authors"]];
             NSDictionary *collectionSettings = [responseObject objectForKey:@"collectionSettings"];
             NSString *collectionId = [collectionSettings objectForKey:@"collectionId"];
             NSNumber *eventId = [collectionSettings objectForKey:@"event"];
             
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
    
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:deletes withRowAnimation:UITableViewRowAnimationNone];
    [tableView reloadRowsAtIndexPaths:updates withRowAnimation:UITableViewRowAnimationNone];
    [tableView insertRowsAtIndexPaths:inserts withRowAnimation:UITableViewRowAnimationNone];
    [tableView endUpdates];
    
    //[tableView reloadData];
}


#pragma mark - Table view data source

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFSContent *content = [_content objectAtIndex:indexPath.row];
    LFSContentVisibility visibility = content.visibility;
    return (visibility == LFSContentVisibilityEveryone
            ? indexPath
            : nil);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    LFSContent *content = [_content objectAtIndex:indexPath.row];
//    LFSContentVisibility visibility = content.visibility;
//    if (visibility == LFSContentVisibilityEveryone)
//    {
//        // TODO: no need to get cell from index and back if we are not using segues
//        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//        [self performSegueWithIdentifier:kCellSelectSegue sender:cell];
//    }
}

// disable this method to get static height = better performance
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeightValue;
    LFSContent *content = [_content objectAtIndex:indexPath.row];
    CGFloat leftOffset = (CGFloat)([content.datePath count] - 1) * kGenerationOffset;
    LFSContentVisibility visibility = content.visibility;
    if (visibility == LFSContentVisibilityEveryone || visibility == LFSContentVisibilityPendingDelete)
    {
        NSNumber *cellHeight = objc_getAssociatedObject(content, &kAtttributedTextHeightKey);
        if (cellHeight == nil)
        {
            NSMutableAttributedString *attributedString =
            [LFSAttributedTextCell attributedStringFromHTMLString:(content.bodyHtml ?: @"")];
            
            objc_setAssociatedObject(content, &kAttributedTextValueKey,
                                     attributedString,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            cellHeightValue = [LFSAttributedTextCell
                               cellHeightForAttributedString:attributedString
                               hasAttachment:(content.firstOembed.contentAttachmentThumbnailUrlString != nil)
                               width:(tableView.bounds.size.width - leftOffset)];
            
            objc_setAssociatedObject(content, &kAtttributedTextHeightKey,
                                     [NSNumber numberWithFloat:cellHeightValue],
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        else
        {
            cellHeightValue = [cellHeight floatValue];
        }
    }
    else
    {
//        cellHeightValue = [LFSDeletedCell cellHeightForBoundsWidth:tableView.bounds.size.width
//                                                    withLeftOffset:leftOffset];
    }
    return cellHeightValue+20;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_content count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: find out which content was created by current user
    // and only return "YES" for cells displaying that content
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    LFSContent *content = [_content objectAtIndex:indexPath.row];
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
    LFSContent *content = [_content objectAtIndex:row];
    
    LFSContentVisibility visibility = content.visibility;
    NSString *contentId = content.idString;
    
    [self.writeClient postMessage:message
                       forContent:content.idString
                     inCollection:self.collectionId
                        userToken:userToken
                       parameters:nil
                        onSuccess:^(NSOperation *operation, id responseObject)
     {
         /*
          NSAssert([[responseObject objectForKey:@"comment_id"] isEqualToString:contentId],
          @"Wrong content Id received");
          
          // Note: sometimes we get an object like this:
          {
          collections =     (
          10726472
          );
          messageId = "051d17a631d943f58705e4ad974f4131@livefyre.com";
          }
          */
         
         NSUInteger row = [_content indexOfKey:contentId];
         if (row != NSNotFound) {
             [_content updateContentForContentId:contentId setVisibility:LFSContentVisibilityNone];
         }
         
     }
     ////////////////////////////////////////////////////////////////
                        onFailure:^(NSOperation *operation, NSError *error)
     {
         // show an error message
         [[[UIAlertView alloc]
           initWithTitle:kFailureModifyTitle
           message:[error localizedRecoverySuggestion]
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
    
    ////////////////////////////////////////////////////////////////
    // TODO: keep an "undo" stack from where we restore objects if delete operation is
    // a failure
    
    // the block below will result in the standard content cell being replaced by a
    // "this comment has been removed" cell.
    [content setVisibility:LFSContentVisibilityPendingDelete];
    
    UITableView *tableView = self.tableView;
    [tableView beginUpdates];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]
                     withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     LFSContent *content = [_content objectAtIndex:indexPath.row];
     LFSContentVisibility visibility = LFSContentVisibilityEveryone;

    id returnedCell;
    
    
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
#pragma mark - Table and cell helpers

-(void)configureDeletedCell:(LFSDeletedCell*)cell forContent:(LFSContent*)content
{
    LFSContentVisibility visibility = content.visibility;
    [cell setLeftOffset:((CGFloat)([content.datePath count] - 1) * kGenerationOffset)];
    
    NSString *bodyText = (visibility == LFSContentVisibilityPendingDelete
                          ? @""
                          : @"This comment has been removed");
    
    //[cell.textLabel setText:[NSString stringWithFormat:@"%@ (%d)", bodyText, content.nodeCount]];
    [cell.textLabel setText:bodyText];
}

// called every time a cell is configured
- (void)configureAttributedCell:(LFSAttributedTextCell*)cell forContent:(LFSContent*)content
{
    // load image first
    [self loadImagesForAttributedCell:cell withContent:content];
    
    // configure the rest of the cell
    [cell setContentDate:content.createdAt];
    UIImage *iconSmall = SmallImageForContentSource(content.contentSource);
    [cell.headerAccessoryRightImageView setImage:iconSmall];
    
    [cell setLeftOffset:((CGFloat)([content.datePath count] - 1) * kGenerationOffset)];
    
    NSMutableAttributedString *attributedString = objc_getAssociatedObject(content, &kAttributedTextValueKey);
    [cell setAttributedString:attributedString];
    
    NSNumber *cellHeight = objc_getAssociatedObject(content, &kAtttributedTextHeightKey);
    [cell setRequiredBodyHeight:[cellHeight floatValue]];
    
    // always set an object
    LFSAuthorProfile *author = content.author;
    
    NSString *title = author.displayName ?: @"";
    
    [cell setProfileLocal:[[LFSResource alloc]
                           initWithIdentifier:(author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : @"")
                           attribute:AttributeObjectFromContent(content)
                           displayString:title
                           icon:nil]];
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


//#pragma mark - LFSContentActionsDelegate
//-(void)postDestructiveMessage:(LFSMessageAction)message forContent:(LFSContent*)content
//{
//    if (content != nil) {
//        NSUInteger row = [_content indexOfObject:content];
//        [self postDestructiveMessage:message
//                        forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
//        [self popDetailControllerForContent:content];
//    }
//}

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
               initWithTitle:kFailureModifyTitle
               message:[error localizedRecoverySuggestion]
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
        [self.writeClient feature:YES
                          comment:content.idString
                     inCollection:self.collectionId
                        userToken:userToken
                        onSuccess:nil
                        onFailure:^(NSOperation *operation, NSError *error)
         {
             // show an error message
             [[[UIAlertView alloc]
               initWithTitle:kFailureModifyTitle
               message:[error localizedRecoverySuggestion]
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
               initWithTitle:kFailureModifyTitle
               message:[error localizedRecoverySuggestion]
               delegate:nil
               cancelButtonTitle:@"OK"
               otherButtonTitles:nil] show];
         }];
    }
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
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

-(void)didPostContentWithOperation:(NSOperation*)operation response:(id)responseObject
{
    // 200 OK received, post was successful
    [_content addContent:[responseObject objectForKey:@"messages"]
             withAuthors:[responseObject objectForKey:@"authors"]];
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

/*
 (lldb) po responseObject;
 {
 collectionSettings =     {
 allowEditComments = 0;
 allowGuestComments = 0;
 archiveInfo =         {
 nPages = 4;
 pageInfo =             {
 0 =                 {
 first = 1379374452;
 last = 1381210768;
 url = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/0.json";
 };
 1 =                 {
 first = 1381210778;
 last = 1396917158;
 url = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/1.json";
 };
 2 =                 {
 first = 1396917266;
 last = 1399071838;
 url = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/2.json";
 };
 3 =                 {
 first = 1399072596;
 last = 1402553454;
 url = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/3.json";
 };
 };
 pathBase = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/";
 };
 bootstrapUrl = "/labs.fyre.co/320568/Y3VzdG9tLTEzNzkzNzIyODcwMzc=/head.json";
 checksum = "1379372387737.2224";
 collectionId = 47466506;
 commentsDisabled = 0;
 config =         {
 };
 data =         (
 );
 editCommentInterval = 0;
 event = 1402553477220916;
 followers = 1;
 nestLevel = 0;
 networkId = "labs.fyre.co";
 numVisible = 115;
 siteId = 320568;
 title = Sandbox;
 url = "http://www.google.com/sergey";
 };
 headDocument =     {
 authors =         {
 "commenter_0@labs.fyre.co" =             {
 avatar = "http://avatars.fyre.co/a/anon/50.jpg";
 displayName = "Commenter 0";
 id = "commenter_0@labs.fyre.co";
 profileUrl = "";
 tags =                 (
 );
 type = 1;
 };
 };
 content =         (
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402553454;
 id = 176488040;
 parentId = "";
 };
 event = 1402553477220916;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402491690;
 id = 176167036;
 parentId = "";
 };
 event = 1402491699113640;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402472769;
 id = 176126228;
 parentId = "";
 };
 event = 1402488584226948;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402384054;
 id = 175429260;
 parentId = "";
 };
 event = 1402384064948125;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402381028;
 id = 175424746;
 parentId = "";
 };
 event = 1402489586137615;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>kiii</p>";
 createdAt = 1402381010;
 id = 175424709;
 parentId = "";
 updatedAt = 1402381010;
 };
 event = 1402381010332691;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402380956;
 id = 175424624;
 parentId = "";
 };
 event = 1402380972114677;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402380901;
 id = 175424554;
 parentId = "";
 };
 event = 1402380918845427;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402380866;
 id = 175424505;
 parentId = "";
 };
 event = 1402380921378410;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402380842;
 id = 175424464;
 parentId = "";
 };
 event = 1402380923828377;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402324776;
 id = 175134167;
 parentId = "";
 };
 event = 1402324811112859;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402324739;
 id = 175133958;
 parentId = "";
 };
 event = 1402324804563348;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402322647;
 id = 175123413;
 parentId = "";
 };
 event = 1402322650995232;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402322476;
 id = 175122558;
 parentId = "";
 };
 event = 1402324806720141;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402246935;
 id = 174884112;
 parentId = "";
 };
 event = 1402246956596196;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402223277;
 id = 174816941;
 parentId = "";
 };
 event = 1402254977158484;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402223250;
 id = 174816909;
 parentId = "";
 };
 event = 1402223642692948;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 {
 childContent =                         (
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 174816758;
 createdAt = 1402223236;
 id = 174816890;
 parentId = 174816758;
 };
 event = 1402223650405623;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402223125;
 id = 174816758;
 parentId = "";
 };
 event = 1402223645752817;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 {
 childContent =                         (
 {
 childContent =                                 (
 {
 childContent =                                         (
 {
 childContent =                                                 (
 {
 childContent =                                                         (
 {
 childContent =                                                                 (
 {
 childContent =                                                                         (
 {
 childContent =                                                                                 (
 {
 childContent =                                                                                         (
 {
 childContent =                                                                                                 (
 {
 childContent =                                                                                                         (
 {
 childContent =                                                                                                                 (
 {
 childContent =                                                                                                                         (
 {
 childContent =                                                                                                                                 (
 {
 childContent =                                                                                                                                         (
 {
 childContent =                                                                                                                                                 (
 {
 childContent =                                                                                                                                                         (
 );
 collectionId = 47466506;
 content =                                                                                                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205427;
 id = 174794639;
 parentId = 174794626;
 };
 event = 1402205504928385;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205420;
 id = 174794626;
 parentId = 174794614;
 };
 event = 1402205502185047;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205414;
 id = 174794614;
 parentId = 174794602;
 };
 event = 1402205499284773;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205410;
 id = 174794602;
 parentId = 174794589;
 };
 event = 1402205496998403;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205404;
 id = 174794589;
 parentId = 174794526;
 };
 event = 1402205494816239;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205363;
 id = 174794526;
 parentId = 174794483;
 };
 event = 1402205491676625;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205345;
 id = 174794483;
 parentId = 174794453;
 };
 event = 1402205488625725;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205332;
 id = 174794453;
 parentId = 174794422;
 };
 event = 1402205486262709;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205319;
 id = 174794422;
 parentId = 174794385;
 };
 event = 1402205484028898;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205296;
 id = 174794385;
 parentId = 174794340;
 };
 event = 1402205479552281;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                         {
 ancestorId = 174794117;
 createdAt = 1402205271;
 id = 174794340;
 parentId = 174794332;
 };
 event = 1402205477423338;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                                 {
 ancestorId = 174794117;
 createdAt = 1402205264;
 id = 174794332;
 parentId = 174794296;
 };
 event = 1402205473211133;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                         {
 ancestorId = 174794117;
 createdAt = 1402205249;
 id = 174794296;
 parentId = 174794282;
 };
 event = 1402205470941921;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                                 {
 ancestorId = 174794117;
 createdAt = 1402205242;
 id = 174794282;
 parentId = 174794266;
 };
 event = 1402205469191557;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                         {
 ancestorId = 174794117;
 createdAt = 1402205234;
 id = 174794266;
 parentId = 174794241;
 };
 event = 1402205466749169;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                                 {
 ancestorId = 174794117;
 createdAt = 1402205222;
 id = 174794241;
 parentId = 174794182;
 };
 event = 1402205464670877;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 174794117;
 createdAt = 1402205192;
 id = 174794182;
 parentId = 174794117;
 };
 event = 1402205462494975;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402205158;
 id = 174794117;
 parentId = "";
 };
 event = 1402205455384779;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402067780;
 id = 174311325;
 parentId = "";
 };
 event = 1402114081530035;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402067750;
 id = 174311184;
 parentId = "";
 };
 event = 1402114070491692;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1402067677;
 id = 174310796;
 parentId = "";
 };
 event = 1402114066928259;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1401812458;
 id = 173217508;
 parentId = "";
 };
 event = 1402114129745323;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400701131;
 id = 168996380;
 parentId = "";
 };
 event = 1401812559583501;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1503782304</p>";
 createdAt = 1400629124;
 id = 168569609;
 parentId = "";
 updatedAt = 1400629124;
 };
 event = 1400629124753631;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400557356;
 id = 168261067;
 parentId = "";
 };
 event = 1401812561983508;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400550634;
 id = 168233964;
 parentId = "";
 };
 event = 1402322655172063;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -967501481</p>";
 createdAt = 1400533860;
 id = 168158437;
 parentId = "";
 updatedAt = 1400533860;
 };
 event = 1400533860521543;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400291834;
 id = 167454190;
 parentId = "";
 };
 event = 1400607862068861;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1855263841</p>";
 createdAt = 1400207656;
 id = 167161151;
 parentId = "";
 updatedAt = 1400207656;
 };
 event = 1400207656680134;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400005793;
 id = 165751559;
 parentId = "";
 };
 erefs =                 (
 "iR5vrvNGo/DWocUXDeZoXju0NlMIQS5t0JKGWUyiVt4J9Zoz/0HLYw2A8Qf3dGlx23Ux4sA9jpgcxFg="
 );
 event = 1400005793690361;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1400005757;
 id = 165751244;
 parentId = "";
 };
 erefs =                 (
 "iR5vrvNGo/DWocUXDeFpUzu0NlZbRyU5gJCBXEv5AIEO8885qUHLZA2BpQz4I2FyiSY7tpBvgMpOzQ8="
 );
 event = 1400005757743545;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Refgid. CCTV </p>";
 createdAt = 1400005461;
 id = 165748434;
 parentId = "";
 updatedAt = 1400005462;
 };
 event = 1400005462059964;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399579734;
 id = 164242605;
 parentId = "";
 };
 event = 1400529749730170;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -751226465</p>";
 createdAt = 1399573421;
 id = 164208772;
 parentId = "";
 updatedAt = 1399573421;
 };
 event = 1399573421993555;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -24012981</p>";
 createdAt = 1399573243;
 id = 164207750;
 parentId = "";
 updatedAt = 1399573243;
 };
 event = 1399573243844633;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -906550630</p>";
 createdAt = 1399571398;
 id = 164197899;
 parentId = "";
 updatedAt = 1399571398;
 };
 event = 1399571398578080;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399570312;
 id = 164192115;
 parentId = "";
 };
 event = 1400529678126240;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399424516;
 id = 163597155;
 parentId = "";
 };
 event = 1400529685728869;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399313459;
 id = 162877342;
 parentId = "";
 };
 event = 1400293507036488;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399079728;
 id = 162089781;
 parentId = "";
 };
 event = 1400529682006141;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399074289;
 id = 162053971;
 parentId = "";
 };
 event = 1400618574402285;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399073045;
 id = 162048561;
 parentId = "";
 };
 event = 1400529698287908;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -760955873</p>";
 createdAt = 1399072805;
 id = 162047620;
 parentId = "";
 updatedAt = 1399072806;
 };
 event = 1399072806104421;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399072596;
 id = 162046741;
 parentId = "";
 };
 event = 1400293502831044;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1399071838;
 id = 162043808;
 parentId = "";
 };
 event = 1402203663006058;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1201746809</p>";
 createdAt = 1399071718;
 id = 162043352;
 parentId = "";
 updatedAt = 1399071718;
 };
 event = 1399071718205413;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -132481941</p>";
 createdAt = 1399070273;
 id = 162038102;
 parentId = "";
 updatedAt = 1399070273;
 };
 event = 1399070273667399;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1979882304</p>";
 createdAt = 1399063893;
 id = 162001268;
 parentId = "";
 updatedAt = 1399063893;
 };
 event = 1399063893669007;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1067301381</p>";
 createdAt = 1399063097;
 id = 161995421;
 parentId = "";
 updatedAt = 1399063097;
 };
 event = 1399063098489813;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<strong>bold</strong>";
 createdAt = 1399054226;
 id = 161935434;
 parentId = "";
 updatedAt = 1399054226;
 };
 event = 1399054226503884;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 {
 childContent =                         (
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 161935176;
 createdAt = 1402246896;
 id = 174883957;
 parentId = 161935176;
 };
 event = 1402246917373849;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<ul><li>this</li>\n<li>is</li>\n<li>a</li>\n<li>list</li>\n</ul>";
 createdAt = 1399054186;
 id = 161935176;
 parentId = "";
 updatedAt = 1399054186;
 };
 event = 1399054186929087;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1038403164</p>";
 createdAt = 1398964752;
 id = 161412290;
 parentId = "";
 updatedAt = 1398964752;
 };
 event = 1398964752970895;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1398816175;
 id = 160876413;
 parentId = "";
 };
 erefs =                 (
 "iR5vrvNGo/DWpMoVCudsVDu0NlZbES09gcCCCRr6UtUM9pxk+RTNZQqLpwb6cTh12iE+s5I93Z9KzQ4="
 );
 event = 1398816175957420;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>What happens to long comments? Are they truncated as they are on the web, or shown in their full glory?\n\nLorizzle pimpin' dolizzle sizzle amizzle, yo adipiscing sheezy. Nullam sapien velizzle, uhuh ... yih! volutpizzle, crackalackin shit, gravida nizzle, arcu. Cool i saw beyonces tizzles and my pizzle went crizzle tortizzle. Sed erizzle. Stuff izzle dolizzle dapibus turpis tempizzle fizzle. Maurizzle pellentesque my shizz izzle turpizzle. Shizzlin dizzle izzle tortor. Pellentesque dawg rhoncizzle da bomb. In hac bizzle platea dictumst. Donec dapibizzle. Break yo neck, yall crazy, pretizzle daahng dawg, mattizzle izzle, eleifend hizzle, nunc. Fo suscipizzle. Integer semper velit sed purus.\n\nCurabitizzle bow wow wow shiz bizzle nisi check it out mollizzle. Dawg shut the shizzle up. Morbi you son of a bizzle. Vivamus neque. Pizzle orci. My shizz maurizzle mauris, interdizzle a, feugiat crackalackin amizzle, fizzle in, boofron. Pellentesque gravida. Vestibulizzle mi, volutpizzle dizzle, sagittis sizzle, bizzle sempizzle, phat. Cras izzle shiznit. Aliquam volutpizzle sheezy vizzle . Cras quis justo shiz purus sodales ornare. Shut the shizzle up venenatizzle justo izzle lacus. Nunc phat. Suspendisse fizzle placerat shiz. Curabitizzle eu ante. Nunc pharetra, leo gangsta hendrerizzle, ipsum felizzle break it down sizzle, fo shizzle aliquizzle magna felis luctus pede. Nam izzle nisl. Class aptent pimpin' shiznit ad we gonna chung torquent gizzle conubia nostra, per fo ghetto. Aliquam interdum, yo mamma nizzle uhuh ... yih! nonummy, hizzle orci sizzle leo, that's the shizzle shut the shizzle up risus yippiyo izzle sizzle.\n\nIn sagittizzle break yo neck, yall nizzle nisi. Pellentesque ma nizzle, arcu non stuff funky fresh, sizzle sure crackalackin sem, nizzle get down get down nulla the bizzle a the bizzle. Suspendisse fizzle scelerisque augue. Sizzle egestas lectizzle away libero. Proin consectetuer blandizzle sapizzle. Crazy aliquet, dizzle sit boom shackalack accumsizzle owned, leo sizzle ultricizzle gizzle, izzle daahng dawg erat mofo sit amizzle purus. Check it out ma nizzle tortor yo mamma enizzle. Phasellizzle ghetto. Nulla da bomb that's the shizzle, convallis nizzle, dawg fo shizzle my nizzle gangsta, pulvinizzle egestizzle, augue. Shizznit convallizzle. Break yo neck, yall ante ipsum nizzle shizzlin dizzle faucibizzle orci luctizzle et ultricizzle gangster cubilia Crunk; In own yo' elit sheezy crunk dizzle condimentizzle. Mofo est get down get down, vulputate vel, semper mammasay mammasa mamma oo sa, commodo things, check out this. Yo break yo neck, yall, tortizzle egizzle vehicula stuff, phat its fo rizzle ultrices lorizzle, pot viverra mofo urna vitae erizzle.\n\n</p>";
 createdAt = 1398469354;
 id = 159444999;
 parentId = "";
 updatedAt = 1398469354;
 };
 event = 1398469354893606;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>hihi</p>";
 createdAt = 1398469019;
 id = 159443744;
 parentId = "";
 updatedAt = 1398469020;
 };
 event = 1398469020076371;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 {
 childContent =                         (
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 156160260;
 createdAt = 1398468451;
 id = 159440596;
 parentId = 156160260;
 };
 event = 1402254963824929;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Test 456</p>";
 createdAt = 1397670980;
 id = 156160260;
 parentId = "";
 updatedAt = 1397670980;
 };
 event = 1397670980641674;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1397670966;
 id = 156160195;
 parentId = "";
 };
 erefs =                 (
 "iR5vrvNGo/DVosMUDOJkUju0NgEORClp1MeAWhr9V9UL8J0wqhWbZQ6GoQevJT8hh3Y57cM93ZpPxg8="
 );
 event = 1397670967228359;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1442620612</p>";
 createdAt = 1397517342;
 id = 155561449;
 parentId = "";
 updatedAt = 1397517342;
 };
 event = 1397517342319824;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1397517228;
 id = 155560689;
 parentId = "";
 };
 event = 1398468457401633;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -3239611</p>";
 createdAt = 1397510504;
 id = 155526764;
 parentId = "";
 updatedAt = 1397510504;
 };
 event = 1397510504669041;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 88893158</p>";
 createdAt = 1397502123;
 id = 155480874;
 parentId = "";
 updatedAt = 1397502123;
 };
 event = 1397502123918419;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -365542664</p>";
 createdAt = 1397501866;
 id = 155479309;
 parentId = "";
 updatedAt = 1397501866;
 };
 event = 1397501866622173;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1369233398</p>";
 createdAt = 1397501785;
 id = 155478834;
 parentId = "";
 updatedAt = 1397501785;
 };
 event = 1397501785975410;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 385137349</p>";
 createdAt = 1397255410;
 id = 154429267;
 parentId = "";
 updatedAt = 1397255410;
 };
 event = 1397255410388763;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 2029834917</p>";
 createdAt = 1397255296;
 id = 154428949;
 parentId = "";
 updatedAt = 1397255296;
 };
 event = 1397255297014122;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -482385642</p>";
 createdAt = 1397255224;
 id = 154428705;
 parentId = "";
 updatedAt = 1397255225;
 };
 event = 1397255225048856;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1602107983</p>";
 createdAt = 1397255140;
 id = 154428464;
 parentId = "";
 updatedAt = 1397255141;
 };
 event = 1397255141103942;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 252424444</p>";
 createdAt = 1397254198;
 id = 154425777;
 parentId = "";
 updatedAt = 1397254198;
 };
 event = 1397254198339437;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1513670539</p>";
 createdAt = 1397239038;
 id = 154367348;
 parentId = "";
 updatedAt = 1397239038;
 };
 event = 1397239038488726;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1356995126</p>";
 createdAt = 1397238966;
 id = 154367039;
 parentId = "";
 updatedAt = 1397238966;
 };
 event = 1397238966250668;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -2070401541</p>";
 createdAt = 1397238798;
 id = 154366221;
 parentId = "";
 updatedAt = 1397238798;
 };
 event = 1397238798856645;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 533174202</p>";
 createdAt = 1397237285;
 id = 154359975;
 parentId = "";
 updatedAt = 1397237286;
 };
 event = 1397237286372630;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1397156230;
 id = 154074923;
 parentId = "";
 };
 erefs =                 (
 "iR5vrvNGo/DVoMIVCOpvVDu0NlMIQH5p0cSCWE7+Vd4P9po2qRPBMluB8g35IGp22HE445E4i5tKwVo="
 );
 event = 1397156231198044;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1397154216;
 id = 154058501;
 parentId = "";
 };
 event = 1397154223275762;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 {
 childContent =                         (
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 154058297;
 createdAt = 1397156199;
 id = 154074669;
 parentId = 154058297;
 };
 erefs =                         (
 "iR5vrvNGo/DVoMIVCOVrXju0NlEGEHlrhMCACxijVtJap8o3qReabFGHoVmsIWgkiyY65ZY7gJpLwFo="
 );
 event = 1397156200371095;
 source = 5;
 type = 0;
 vis = 2;
 },
 {
 childContent =                         (
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 154058297;
 annotations =                             {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Lvl1 reply</p>";
 createdAt = 1397155902;
 id = 154072130;
 parentId = 154058297;
 updatedAt = 1397155902;
 };
 event = 1397155902331472;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                         (
 {
 childContent =                                 (
 );
 collectionId = 47466506;
 content =                                 {
 ancestorId = 154058297;
 annotations =                                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Reply to lvl 1</p>";
 createdAt = 1397154285;
 id = 154059023;
 parentId = 154058629;
 updatedAt = 1397154285;
 };
 event = 1397154285573755;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                                 (
 {
 childContent =                                         (
 );
 collectionId = 47466506;
 content =                                         {
 ancestorId = 154058297;
 annotations =                                             {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Lvl 4 reply</p>";
 createdAt = 1397154264;
 id = 154058837;
 parentId = 154058680;
 updatedAt = 1397154264;
 };
 event = 1397154264561145;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                                         (
 );
 collectionId = 47466506;
 content =                                         {
 ancestorId = 154058297;
 annotations =                                             {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Lvl 3 reply</p>";
 createdAt = 1397154256;
 id = 154058776;
 parentId = 154058680;
 updatedAt = 1397154256;
 };
 event = 1397154256633677;
 source = 5;
 type = 0;
 vis = 1;
 }
 );
 collectionId = 47466506;
 content =                                 {
 ancestorId = 154058297;
 annotations =                                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Reply to my reply</p>";
 createdAt = 1397154242;
 id = 154058680;
 parentId = 154058629;
 updatedAt = 1397154242;
 };
 event = 1397154242504434;
 source = 5;
 type = 0;
 vis = 1;
 }
 );
 collectionId = 47466506;
 content =                         {
 ancestorId = 154058297;
 createdAt = 1397154234;
 id = 154058629;
 parentId = 154058297;
 };
 event = 1397155918740123;
 source = 5;
 type = 0;
 vis = 0;
 }
 );
 collectionId = 47466506;
 content =                 {
 createdAt = 1397154184;
 id = 154058297;
 parentId = "";
 };
 event = 1402114044432092;
 source = 5;
 type = 0;
 vis = 0;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1318662855</p>";
 createdAt = 1397086776;
 id = 153721318;
 parentId = "";
 updatedAt = 1397086777;
 };
 event = 1397086777136890;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>Oh Hai</p>";
 createdAt = 1397081048;
 id = 153700635;
 parentId = "";
 updatedAt = 1397081048;
 };
 event = 1397081048480924;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1105179846</p>";
 createdAt = 1396995782;
 id = 153281441;
 parentId = "";
 updatedAt = 1396995783;
 };
 event = 1396995783145332;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 594308306</p>";
 createdAt = 1396987814;
 id = 153243907;
 parentId = "";
 updatedAt = 1396987814;
 };
 event = 1396987814810569;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -3006484</p>";
 createdAt = 1396987379;
 id = 153241584;
 parentId = "";
 updatedAt = 1396987379;
 };
 event = 1396987379336500;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1544343699</p>";
 createdAt = 1396987358;
 id = 153241471;
 parentId = "";
 updatedAt = 1396987359;
 };
 event = 1396987359079682;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -533250509</p>";
 createdAt = 1396982427;
 id = 153215269;
 parentId = "";
 updatedAt = 1396982427;
 };
 event = 1396982427681114;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1015384612</p>";
 createdAt = 1396982318;
 id = 153214742;
 parentId = "";
 updatedAt = 1396982318;
 };
 event = 1396982318551596;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1222456846</p>";
 createdAt = 1396980795;
 id = 153207755;
 parentId = "";
 updatedAt = 1396980795;
 };
 event = 1396980795442638;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -631993095</p>";
 createdAt = 1396980641;
 id = 153207097;
 parentId = "";
 updatedAt = 1396980641;
 };
 event = 1396980641850932;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API 1106460825</p>";
 createdAt = 1396980397;
 id = 153205921;
 parentId = "";
 updatedAt = 1396980397;
 };
 event = 1396980397907607;
 source = 5;
 type = 0;
 vis = 1;
 },
 {
 childContent =                 (
 );
 collectionId = 47466506;
 content =                 {
 annotations =                     {
 };
 authorId = "commenter_0@labs.fyre.co";
 bodyHtml = "<p>testing streaming API -1485481104</p>";
 createdAt = 1396919555;
 id = 153058135;
 parentId = "";
 updatedAt = 1396919555;
 };
 event = 1396919555802376;
 source = 5;
 type = 0;
 vis = 1;
 }
 );
 followers =         (
 "commenter_0@labs.fyre.co"
 );
 isComplete = 0;
 };
 networkSettings =     {
 allowEditComments = 0;
 allowGuestComments = 0;
 charLimit = 8000;
 commentsEnabled = 1;
 editCommentInterval = 5;
 editMode = 0;
 editReviewReplies = 1;
 enabled = 1;
 fbShareEnabled = 1;
 featuredReaderEnabled = 1;
 featuringEnabled = 1;
 highVelocityMode = 0;
 hovercardsEnabled = 1;
 liShareEnabled = 0;
 mediaDisplay = 1;
 mediaUploadEnabled = 0;
 nestLevel = 4;
 premoderated = 0;
 rawHtml = 0;
 repliesEnabled = 1;
 reviewRepliesEnabled = 1;
 richTextEnabled = 1;
 streamType = 1;
 taggingEnabled = 1;
 throttleStream = 0;
 topContentDisplay = 1;
 twitterShareEnabled = 1;
 xxHtmlBlob = "";
 };
 siteSettings =     {
 "__modified__" = "1357633156.357029";
 allowGuestComments = 0;
 enabled = 1;
 nestLevel = 4;
 premoderated = 0;
 };
 }
 
 */
