//
//  LFSDetailViewController.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/13/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import <StreamHub-iOS-SDK/NSDateFormatter+RelativeTo.h>

#import "LFSViewResources.h"
#import "UIImage+LFSColor.h"
#import "LFSDetailViewController.h"
#import "LFSContentToolbar.h"

#import "LFRAppDelegate.h"

#import "LFSOembed.h"
#import "LFSAttributedLabelDelegate.h"

typedef NS_ENUM(NSUInteger, LFSActionType) {
    kLFSActionTypeFlag = 0u,
    kLFSActionTypeDelete
};

@interface LFSDetailViewController ()

@property (nonatomic, readonly) LFSWriteClient *writeClient;

@property (strong, nonatomic) LFSPostViewController *postViewController;
@property (strong, nonatomic) LFRReplyViewController *replyViewController;


// render iOS7 status bar methods as writable properties
@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet LFSDetailView *detailView;

@end

// hardcode author id for now
static NSString* const kCurrentUserId = @"_up19433660@livefyre.com";

@implementation LFSDetailViewController

#pragma mark - Properties

@synthesize delegate = _delegate;

// render iOS7 status bar methods as writable properties
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;

@synthesize attributedLabelDelegate = _attributedLabelDelegate;
//@synthesize postViewController = _postViewController;
@synthesize replyViewController=_replyViewController;
@synthesize user = _user;

@synthesize hideStatusBar = _hideStatusBar;
@synthesize scrollView = _scrollView;
@synthesize detailView = _detailView;

@synthesize collection = _collection;
@synthesize collectionId = _collectionId;
@synthesize contentItem = _contentItem;
@synthesize avatarImage = _avatarImage;

@synthesize writeClient = _writeClient;
- (LFSWriteClient*)writeClient
{
    if (_writeClient == nil) {
        NSString *network = [self.collection objectForKey:@"network"];
        NSString *environment = [self.collection objectForKey:@"environment"];
        _writeClient = [LFSWriteClient
                        clientWithNetwork:network
                        environment:environment];
    }
    return _writeClient;
}

//-(LFSPostViewController*)postViewController
//{
//    // lazy-instantiate LFSPostViewController
//    static NSString* const kLFSPostCommentViewControllerId = @"postComment";
//    
//    if (_postViewController == nil) {
//        _postViewController =
//        (LFSPostViewController*)[[AppDelegate mainStoryboard]
//                                 instantiateViewControllerWithIdentifier:kLFSPostCommentViewControllerId];
//        [_postViewController setDelegate:self];
//    }
//    return _postViewController;
//}
-(LFRReplyViewController*)replyViewController
{
    // lazy-instantiate LFRReplyViewController
    static NSString* const kLFSPostReplyViewControllerId = @"postReply";
    
    if (_replyViewController == nil) {
        _replyViewController =
        (LFRReplyViewController*)[[AppDelegate mainStoryboard]
                                 instantiateViewControllerWithIdentifier:kLFSPostReplyViewControllerId];
        [_replyViewController setDelegate:self];
    }
    return _replyViewController;
}

#pragma mark - Private methods
-(void)updateLikeButton
{
    UIButton *likeButton = self.detailView.button1;
    NSUInteger numberOfLikes = [self.contentItem.likes count];
    if (numberOfLikes > 0u) {
        if ([self.contentItem.likes containsObject:kCurrentUserId]) {
            [likeButton setImage:[UIImage imageNamed:@"StateLiked"]
                        forState:UIControlStateNormal];
            [likeButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)numberOfLikes]
                        forState:UIControlStateNormal];
            [likeButton setTitleColor:[UIColor colorWithRed:241.f/255.f green:92.f/255.f blue:56.f/255.f alpha:1.f]
                             forState:UIControlStateNormal];
            [likeButton setTitleColor:[UIColor colorWithRed:128.f/255.f green:49.f/255.f blue:29.f/255.f alpha:1.f]
                             forState:UIControlStateHighlighted];
        }
        else {
            [likeButton setImage:[UIImage imageNamed:@"StateNotLiked"]
                        forState:UIControlStateNormal];
            [likeButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)numberOfLikes]
                        forState:UIControlStateNormal];
            [likeButton setTitleColor:[UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f]
                             forState:UIControlStateNormal];
            [likeButton setTitleColor:[UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f]
                             forState:UIControlStateHighlighted];
        }
    }
    else {
        [likeButton setImage:[UIImage imageNamed:@"heartsmall"]
                    forState:UIControlStateNormal];
        [likeButton setTitle:@"Helpful"
                    forState:UIControlStateNormal];
        [likeButton setTitleColor:[UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f]
                         forState:UIControlStateNormal];
        [likeButton setTitleColor:[UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f]
                         forState:UIControlStateHighlighted];
    }
}

- (void)updateScrollViewContentSize
{
    UIScrollView *scrollView = self.scrollView;
    LFSDetailView *detailView = self.detailView;
    
    CGSize scrollViewSize = scrollView.bounds.size;
    CGSize detailViewSize = [detailView sizeThatFits:CGSizeMake(scrollViewSize.width, CGFLOAT_MAX)];
    detailViewSize.width = scrollViewSize.width;
    [scrollView setContentSize:detailViewSize];
    
    // set height of detailView to calculated height
    // (otherwise the toolbar stops responding to tap events...)
    CGRect detailViewFrame = detailView.frame;
    detailViewFrame.size = detailViewSize;
    [detailView setFrame:detailViewFrame];
}

#pragma mark - Lifecycle

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _hideStatusBar = NO;
        _writeClient = nil;
//        _postViewController = nil;
        _replyViewController=nil;
    }
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hideStatusBar = NO;
        _writeClient = nil;
//        _postViewController = nil;
        _replyViewController=nil;

    }
    return self;
}

- (void)dealloc
{
    [_detailView setDelegate:nil];
//    [_postViewController setDelegate:nil];
    [_replyViewController setDelegate:nil];
    _replyViewController=nil;
//    _postViewController = nil;
}

#pragma mark - Public methods

- (void)detailView:(LFSDetailView*)detailView setOembed:(LFSOembed*)oembed
{
    // currently supporting image and video oembeds
    if (oembed != nil) {
        if (oembed.oembedType == LFSOembedTypePhoto) {
            // set attachment view frame size
            UIImageView *attachmentView = [[UIImageView alloc] init];
            [self.detailView setAttachmentView:attachmentView];
            CGRect attachmentFrame = attachmentView.frame;
            attachmentFrame.size = oembed.size;
            [attachmentView setFrame:attachmentFrame];
            
            __weak UIImageView* weakAttachmentView = attachmentView;
            
            // TODO: ask JS about desired behavior on image download failure
            [attachmentView setImageWithURL:[NSURL URLWithString:oembed.urlString]
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType)
            {
                // find out image size here and re-layout view
                [weakAttachmentView setImage:image];
            }];
            
            // toggle attachment view visibility
            [attachmentView setHidden:NO];
        }
        else if (oembed.oembedType == LFSOembedTypeVideo || oembed.oembedType == LFSOembedTypeRich) {
            // set attachment view frame size
            UIWebView *attachmentView = [[UIWebView alloc] init];
            [attachmentView setBackgroundColor:[UIColor clearColor]];
            [attachmentView setOpaque:NO];
            [attachmentView setScalesPageToFit:YES];
            [attachmentView setSuppressesIncrementalRendering:YES];
            [attachmentView setAllowsInlineMediaPlayback:YES];
            [attachmentView.scrollView setScrollEnabled:NO];
            [attachmentView.scrollView setBounces:NO];
            
            [self.detailView setAttachmentView:attachmentView];
            if (oembed.oembedType == LFSOembedTypeVideo && oembed.embedYouTubeId != nil) {
                NSString *urlString = [@"http://www.youtube.com/embed/"
                                       stringByAppendingString:oembed.embedYouTubeId];
                NSURL *url = [NSURL URLWithString:urlString];
                [attachmentView loadRequest:[NSURLRequest requestWithURL:url]];
            } else {
                NSString *urlString = oembed.urlString ?: oembed.linkUrlString ?: oembed.providerUrlString;
                [attachmentView loadHTMLString:oembed.html baseURL:[NSURL URLWithString:urlString]];
            }
            
            CGRect attachmentFrame = attachmentView.frame;
            attachmentFrame.size = oembed.size;
            [attachmentView setFrame:attachmentFrame];
            
            // toggle attachment view visibility
            [attachmentView setHidden:NO];
        }
        else {
            [detailView.attachmentView setHidden:YES];
        }
    }
    else {
        [detailView.attachmentView setHidden:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    _postViewController = nil;
    _replyViewController=nil;
    LFSDetailView *detailView = self.detailView;
    LFSContent *contentItem = self.contentItem;
    
    [self.scrollView setAlwaysBounceVertical:YES];
    
    [detailView setDelegate:self];
    [detailView setContentBodyHtml:contentItem.bodyHtml];
    [detailView setContentDate:contentItem.createdAt];
    [detailView.bodyView setDelegate:self.attributedLabelDelegate];
    [self detailView:detailView setOembed:self.contentItem.firstOembed];

    [self updateLikeButton];
    
    [detailView.button2 setTitle:@"Reply" forState:UIControlStateNormal];
    [detailView.button2 setImage:[UIImage imageNamed:@"ActionReply"] forState:UIControlStateNormal];
    
    [detailView.button3 setTitle:@"More" forState:UIControlStateNormal];
    [detailView.button3 setImage:[UIImage imageNamed:@"More"] forState:UIControlStateNormal];
    
    // only set an object if we have a remote (Twitter) url
    NSString *twitterUrlString = contentItem.twitterUrlString;
    if (twitterUrlString != nil) {
        [detailView setContentRemote:[[LFSResource alloc]
                                      initWithIdentifier:twitterUrlString
                                      displayString:@"View on Twitter"
                                      icon:nil]];
    }
    
    UIImage *iconLarge = ImageForContentSource(contentItem.contentSource);
    LFSAuthorProfile *author = contentItem.author;
    [detailView setProfileRemote:[[LFSResource alloc]
                                  initWithIdentifier:author.profileUrlStringNoHashBang
                                  displayString:nil
                                  icon:iconLarge]];
    
    LFSResource *headerInfo = [[LFSResource alloc]
                               initWithIdentifier:(author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : nil)
                               attribute:AttributeObjectFromContent(contentItem)
                               displayString:author.displayName
                               icon:self.avatarImage];
    [headerInfo setIconURLString:author.avatarUrlString75];
    [detailView setProfileLocal:headerInfo];
 
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setStatusBarHidden:self.hideStatusBar withAnimation:UIStatusBarAnimationNone];
    //[self.navigationController setToolbarHidden:YES animated:animated];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    
    // calculate content size for scrolling
    [self updateScrollViewContentSize];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self updateScrollViewContentSize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Status bar

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

#pragma mark - LFSDetailViewDelegate

- (void)didChangeContentSize
{
    [self updateScrollViewContentSize];
}

- (CGSize)requestedContentSize
{
    CGSize requestedSize = self.contentItem.firstOembed.size;
    return requestedSize;
}

- (void)didSelectButton1:(id)sender
{
    [self.contentActions.actionSheet3 showInView:self.view];

    // Like button selected
//    static NSString* const kFailureModifyTitle = @"Action Failed";
//    NSString *userToken = [self.collection objectForKey:@"lftoken"];
//    if (userToken != nil) {
//        LFSMessageAction action;
//        if ([self.contentItem.likes containsObject:kCurrentUserId]) {
//            [self.contentItem.likes removeObject:kCurrentUserId];
//            action = LFSMessageUnlike;
//        } else {
//            [self.contentItem.likes addObject:kCurrentUserId];
//            action = LFSMessageLike;
//        }
//        [self updateLikeButton];
//        
//        
//        [self.writeClient postMessage:action
//                           forContent:self.contentItem.idString
//                         inCollection:self.collectionId
//                            userToken:userToken
//                           parameters:nil
//                            onSuccess:^(NSOperation *operation, id responseObject)
//         {
//             //NSLog(@"success posting opine %d", action);
//         }
//                            onFailure:^(NSOperation *operation, NSError *error)
//         {
//             //NSLog(@"failed posting opine %d", action);
//         }];
//    } else {
//        // userToken is nil -- show an error message
//        [[[UIAlertView alloc]
//          initWithTitle:kFailureModifyTitle
//          message:@"You do not have permission to like comments in this collection"
//          delegate:nil
//          cancelButtonTitle:@"OK"
//          otherButtonTitles:nil] show];
//    }
}

- (void)didSelectButton2:(id)sender
{
    // Reply selected
    [self.replyViewController setCollection:self.collection];
    [self.replyViewController setCollectionId:self.collectionId];
    [self.replyViewController setReplyToContent:self.contentItem];
    
    [self.replyViewController setUser:self.user];
    [self.replyViewController setAvatarImage:[UIImage imageWithColor:
                                             [UIColor colorWithRed:232.f / 255.f
                                                             green:236.f / 255.f
                                                              blue:239.f / 255.f
                                                             alpha:1.f]]];
    
    [self.navigationController presentViewController:self.replyViewController
                                            animated:YES
                                          completion:nil];
}

- (void)didSelectButton3:(id)sender
{
    [self.contentActions.actionSheet showInView:self.view];
}

- (void)didSelectProfile:(id)sender withURL:(NSURL*)url
{
    [self.attributedLabelDelegate followURL:url];
}

- (void)didSelectContentRemote:(id)sender withURL:(NSURL*)url
{
    [self.attributedLabelDelegate followURL:url];
}

//#pragma mark - LFSPostViewControllerDelegate
//-(id<LFSPostViewControllerDelegate>)collectionViewController
//{
//    // forward collection view controller here to insert messagesinto
//    // the content view as soon as the server gets back to us with 200 OK
//    id<LFSPostViewControllerDelegate> collectionViewController = (id<LFSPostViewControllerDelegate>)self.delegate;
//    return collectionViewController;
//}
-(id<LFRReplyViewControllerDelegate>)ViewController
{
    // forward collection view controller here to insert messagesinto
    // the content view as soon as the server gets back to us with 200 OK
    id<LFRReplyViewControllerDelegate> ViewController = (id<LFRReplyViewControllerDelegate>)self.delegate;
    return ViewController;
}

-(void)didSendPostRequestWithReplyTo:(NSString*)replyTo
{
    // simply forward to the collection view controller
    id<LFRReplyViewControllerDelegate> ViewController = (id<LFRReplyViewControllerDelegate>)self.delegate;
    [self.navigationController popViewControllerAnimated:NO];
    [ViewController didSendPostRequestWithReplyTo:replyTo];
}

@end
