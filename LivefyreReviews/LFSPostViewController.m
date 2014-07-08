//
//  LFSNewCommentViewController.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/13/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import "LFSPostViewController.h"


#import "LFSAuthorProfile.h"
#import "LFSResource.h"
#import "LFRConfig.h"
#import "DYRateView.h"
#import "LFSWriteCommentView.h"
#import "LFSBasicHTMLParser.h"
@interface LFSPostViewController ()

// render iOS7 status bar methods as writable properties
@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;

@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (weak, nonatomic) IBOutlet LFSWriteCommentView *writeCommentView;

@property (weak, nonatomic) IBOutlet UINavigationBar *postNavbar;


- (IBAction)cancelClicked:(UIBarButtonItem *)sender;
- (IBAction)postClicked:(UIBarButtonItem *)sender;

@end

@implementation LFSPostViewController {
    NSDictionary *_authorHandles;
}

#pragma mark - Properties

@synthesize writeCommentView;
@synthesize delegate = _delegate;

// render iOS7 status bar methods as writable properties
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;
@synthesize collection = _collection;

@synthesize postNavbar = _postNavbar;
@synthesize user = _user;

@synthesize writeClient = _writeClient;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    LFRConfig *config = [[LFRConfig alloc] initwithValues];
    // NSLog(@"%@",config.collections);
    self.collection=[[NSDictionary alloc]init];
    self.collection=[config.collections objectAtIndex:0];
    LFSAuthorProfile *author = self.user.profile;
    NSString *detailString = (author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : nil);
    LFSResource *headerInfo = [[LFSResource alloc]
                               initWithIdentifier:detailString
                               attribute:nil
                               displayString:@"Title"
                               icon:self.avatarImage];
    [headerInfo setIconURLString:author.avatarUrlString75];
    [self.writeCommentView setProfileLocal:headerInfo];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationController.navigationBar.barTintColor=UIColorFromRGB(0xF6F6F6);

    // show keyboard (doing this in viewDidAppear causes unnecessary lag)
    [self.writeCommentView.textView becomeFirstResponder];
    
    if (self.replyToContent != nil) {
        [self.postNavbar.topItem setTitle:@"NewReview"];
        
        _authorHandles = nil;
        NSString *replyPrefix = [self replyPrefixFromContent:self.replyToContent];
        if (replyPrefix != nil) {
            [self.writeCommentView.textView setText:replyPrefix];
        }
    }
    if(_isEdit){
        ;

        [self.writeCommentView.textView setAttributedText:[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:_content.bodyHtml]];
        [self.writeCommentView.titleTextField setText:_content.title];
        self.writeCommentView.starView.rating=[[[_content.annotations valueForKey:@"rating"] objectAtIndex:0] floatValue]/20;
        self.writeCommentView.starView.userInteractionEnabled=NO;

        
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
- (void)rateView:(DYRateView *)rateView changedToNewRate:(NSNumber *)rate {
    //self.headerRatingView.text = [NSString stringWithFormat:@"Rate: %d", rate.intValue];
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
        UITextView *textView = self.writeCommentView.textView;
        NSString *text = (self.replyToContent
                          ? [self processReplyText:textView.text]
                          : textView.text);
        
        
        UITextField *titleText=self.writeCommentView.titleTextField;
        NSString *title=titleText.text;
        UITextField *prosText=self.writeCommentView.prosTextField;
        NSString *pros=prosText.text;
        UITextField *consText=self.writeCommentView.consTextField;
        NSString *cons=consText.text;
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber * value = [f numberFromString:self.writeCommentView.ratingPost];
        

        if (title.length == 0 ) {
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"alert" message:@"Your review must include a title" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        else if (((int) value<1  && (int) value > 100) || self.writeCommentView.ratingPost==nil){
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"alert" message:@"Your review must include a star rating" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
            
        }
        
        else{
            
            if (pros.length == 0){
                pros=@"";
            }
            else{
                pros=[NSString stringWithFormat:@"<p><strong>Pros:</strong>%@</p>",pros];

            }
            if (cons.length == 0){
                cons=@"";
            }
            else{
                cons=[NSString stringWithFormat:@"<p><strong>Cons:</strong>%@</p>",cons];
                
            }
            if (pros.length == 0 && cons.length == 0){
                
            }
            else{
                text=[NSString stringWithFormat:@"<p><strong>Description:</strong>%@</p>",text];
                
            }
        NSDictionary *rating = @{@"default":value};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rating options:0 error:NULL];
        NSString *ratingjsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSLog(@"%@", ratingjsonString);
            NSString *bodyofReview=[NSString stringWithFormat:@"%@%@%@",pros,cons,text];

        [textView setText:@""];
        
        
        
        
        id<LFSPostViewControllerDelegate> collectionViewController = nil;
        if ([self.delegate respondsToSelector:@selector(collectionViewController)]) {
            collectionViewController = [self.delegate collectionViewController];
        }
        
        NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:ratingjsonString, LFSCollectionPostRatingKey,bodyofReview,LFSCollectionPostBodyKey,userToken,LFSCollectionPostUserTokenKey,title,LFSCollectionPostTitleKey, nil ];
        
        
            if(self.isEdit){
                [self.writeClient postMessage:LFSMessageEdit
                                   forContent:self.content.idString
                                 inCollection:self.collectionId
                                    userToken:userToken
                                   parameters:dict
                                    onSuccess:^(NSOperation *operation, id responseObject) {
                                        if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
                                        {
                                            [collectionViewController didPostContentWithOperation:operation response:responseObject];
                                        }
                                    } onFailure:^(NSOperation *operation, NSError *error) {
                                        [[[UIAlertView alloc]
                                          initWithTitle:kFailurePostTitle
                                          message:[error localizedRecoverySuggestion]
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                                    }];

//                [self.writeClient postContentType:13 forCollection:self.collectionId parameters:dict
//                                        onSuccess:^(NSOperation *operation, id responseObject) {
//                                            if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
//                                            {
//                                                [collectionViewController didPostContentWithOperation:operation response:responseObject];
//                                            }
//                                        } onFailure:^(NSOperation *operation, NSError *error) {
//                                            [[[UIAlertView alloc]
//                                              initWithTitle:kFailurePostTitle
//                                              message:[error localizedRecoverySuggestion]
//                                              delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil] show];
//                                        }];

            }else{
        
        [self.writeClient postContentType:2 forCollection:self.collectionId parameters:dict
                           onSuccess:^(NSOperation *operation, id responseObject) {
                               if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
                               {
                               [collectionViewController didPostContentWithOperation:operation response:responseObject];
                                }
                           } onFailure:^(NSOperation *operation, NSError *error) {
                               [[[UIAlertView alloc]
                               initWithTitle:kFailurePostTitle
                               message:[error localizedRecoverySuggestion]
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
                           }];
            }
        if ([self.delegate respondsToSelector:@selector(didSendPostRequestWithReplyTo:)]) {
            [self.delegate didSendPostRequestWithReplyTo:self.replyToContent.idString];
        }
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        // userToken is nil -- show an error message
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"You do not have permission to write to this collection"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
        
    
    ;
}

@end
