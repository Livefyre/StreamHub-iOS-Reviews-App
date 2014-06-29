//
//  LFRReplyViewController.m
//  LivefyreReviews
//
//  Created by Kvana Inc 2 on 13/06/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//
#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import "LFRReplyViewController.h"

#import "LFSReplyWriteCommentView.h"
#import "LFSAuthorProfile.h"
#import "LFSResource.h"
#define REPLY_FONT_SIZE 28

@interface LFRReplyViewController ()
// render iOS7 status bar methods as writable properties
@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;

@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (nonatomic, strong)IBOutlet LFSReplyWriteCommentView *WriteCommentView;
@property (weak, nonatomic) IBOutlet UINavigationBar *postNavbar;


- (IBAction)cancelClicked:(UIBarButtonItem *)sender;
- (IBAction)postClicked:(UIBarButtonItem *)sender;

@end

@implementation LFRReplyViewController {
    NSDictionary *_authorHandles;
}

#pragma mark - Properties

@synthesize WriteCommentView=_WriteCommentView;
@synthesize delegate = _delegate;

// render iOS7 status bar methods as writable properties
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;

@synthesize postNavbar = _postNavbar;
@synthesize user = _user;

@synthesize writeClient = _writeClient;
@synthesize collection = _collection;
@synthesize collectionId = _collectionId;
@synthesize replyToContent = _replyToContent;

- (LFSWriteClient*)writeClient
{
    if (_writeClient == nil) {
        _writeClient = [LFSWriteClient
                        clientWithNetwork:[self.collection objectForKey:@"network"]
                        environment:[self.collection objectForKey:@"environment"]];
    }
    return _writeClient;
}


#pragma mark - UIViewController

// Hide/show status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Lifecycle

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self resetEverything];
    }
    return self;
}

-(void)resetEverything {
    _writeClient = nil;
    _collection = nil;
    _collectionId = nil;
    _replyToContent = nil;
    _delegate = nil;

}
-(LFSReplyWriteCommentView *)WriteCommentView{
    
    if (_WriteCommentView==nil) {
        _WriteCommentView=[[LFSReplyWriteCommentView alloc]init];
    }
    return _WriteCommentView;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
//    _WriteCommentView=nil;

	// Do any additional setup after loading the view.
    LFSAuthorProfile *author = self.user.profile;
    NSString *detailString = (author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : nil);
    LFSResource *headerInfo = [[LFSResource alloc]
                               initWithIdentifier:detailString
                               attribute:nil
                               displayString:author.displayName
                               icon:self.avatarImage];
    [headerInfo setIconURLString:author.avatarUrlString75];
    [self.WriteCommentView setProfileLocal:headerInfo];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    LFSAuthorProfile *author = self.user.profile;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    // show keyboard (doing this in viewDidAppear causes unnecessary lag)
    [self.WriteCommentView.textView becomeFirstResponder];
    
    if (self.replyToContent != nil) {
        [self.postNavbar.topItem setTitle:@"Reply"];
        
        _authorHandles = nil;
        NSString *replyPrefix = [self replyPrefixFromContent:self.replyToContent];
        if (replyPrefix != nil) {
            
          
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            paragraphStyle.lineSpacing = REPLY_FONT_SIZE/2;
            UIFont * labelFont = [UIFont fontWithName:@"Georgia" size:18.0];
            NSRange range=NSMakeRange(0, replyPrefix.length);
            NSMutableAttributedString *replyPrefixAttribute = [[NSMutableAttributedString alloc]initWithString : replyPrefix ] ;
            [replyPrefixAttribute addAttribute:NSFontAttributeName value:labelFont range:range];
            [replyPrefixAttribute addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x007aff) range:NSRangeFromString(author.displayName)];
            
            [self.WriteCommentView.textView setAttributedText:replyPrefixAttribute];
            
        }
    }
}

- (NSString*)replyPrefixFromContent:(LFSContent*)content
{
    // remove self (own user handle) from list
    NSMutableDictionary *dictionary = [content authorHandles];
    NSString *currentHandle = self.user.profile.authorHandle;
    if (currentHandle != nil) {
        [dictionary removeObjectForKey:[currentHandle lowercaseString]];
    }
    
    _authorHandles = dictionary;
    NSArray *handles = [_authorHandles allKeys];
    NSString *prefix = nil;
    if (handles.count  > 0) {
        NSString *joinedParticipants = [handles componentsJoinedByString:@" @"];
        prefix = [NSString stringWithFormat:@"@%@ ", joinedParticipants];
    }
    return prefix;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self resetEverything];
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

#pragma mark - Utility methods

-(NSString*)processReplyText:(NSString*)replyText
{
    if (_authorHandles == nil) {
        return replyText;
    }
    
    // process replyText such that all cases of handles get replaced with anchors
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@(\\w+)\\b"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    NSArray *matches = [regex matchesInString:replyText
                                      options:0
                                        range:NSMakeRange(0, replyText.length)];
    
    // enumerate in reverse order because that way we can preserve location
    // in our mutable string
    NSMutableString *mutableReply = [replyText mutableCopy];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:
     ^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop)
     {
         NSRange handleRange = [match rangeAtIndex:1];
         NSString *candidate = [replyText substringWithRange:match.range];
         
         NSString *urlString = [_authorHandles objectForKey:[[replyText substringWithRange:handleRange] lowercaseString]];
         if (urlString != nil) {
             // candidate found in dictionary
             NSString *replacement = [NSString
                                      stringWithFormat:@"<a href=\"%@\">%@</a>",
                                      urlString, candidate];
             [mutableReply replaceCharactersInRange:match.range withString:replacement];
         }
     }];
    
    return [mutableReply copy];
}

#pragma mark - Actions
- (IBAction)cancelClicked:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postClicked:(UIBarButtonItem *)sender
{
    static NSString* const kFailurePostTitle = @"Failed to post content";
    
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (userToken != nil) {
        UITextView *textView = self.WriteCommentView.textView;
        NSString *text = (self.replyToContent
                          ? [self processReplyText:textView.text]
                          : textView.text);
        
        [textView setText:@""];
        
        id<LFRReplyViewControllerDelegate> ViewController = nil;
        if ([self.delegate respondsToSelector:@selector(ViewController)]) {
            ViewController = [self.delegate ViewController];
        }
        [self.writeClient postContent:text
                         inCollection:self.collectionId
                            userToken:userToken
                            inReplyTo:self.replyToContent.idString
                            onSuccess:^(NSOperation *operation, id responseObject)
         {
             if ([ViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
             {
                 [ViewController didPostContentWithOperation:operation response:responseObject];
             }
         }
                            onFailure:^(NSOperation *operation, NSError *error)
         {
             // show an error message
             [[[UIAlertView alloc]
               initWithTitle:kFailurePostTitle
               message:[error localizedRecoverySuggestion]
               delegate:nil
               cancelButtonTitle:@"OK"
               otherButtonTitles:nil] show];
         }];
        if ([self.delegate respondsToSelector:@selector(didSendPostRequestWithReplyTo:)]) {
            [self.delegate didSendPostRequestWithReplyTo:self.replyToContent.idString];
        }
    } else {
        // userToken is nil -- show an error message
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"You do not have permission to write to this collection"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
