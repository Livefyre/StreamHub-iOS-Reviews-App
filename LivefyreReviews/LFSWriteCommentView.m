//
//  LFSWriteCommentView.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/16/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <math.h>
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "LFSWriteCommentView.h"
#import "UILabel+Trim.h"
#import "DLStarRatingControl.h"
static const UIEdgeInsets kDetailPadding = {
    .top=10.0f, .left=15.0f, .bottom=115.0f, .right=15.0f
};

static const UIEdgeInsets kPostContentInset = {
    .top=255.f, .left=7.f, .bottom=80.f, .right=5.f
};

// header font settings
static const CGFloat kDetailHeaderAttributeTopFontSize = 11.f;
static const CGFloat kDetailHeaderTitleFontSize = 15.f;
static const CGFloat kDetailHeaderSubtitleFontSize = 12.f;
static const CGFloat kDetailTitleTextFieldWidth=15.f;

// content font settings
static NSString* const kPostContentFontName = @"Georgia";
static const CGFloat kPostContentFontSize = 18.0f;

// header label heights
static const CGFloat kDetailHeaderAttributeTopHeight = 10.0f;
static const CGFloat kDetailHeaderAttributeTopImageHeight = 18.0f;
static const CGFloat kDetailHeaderTitleHeight = 40.0f;

static const CGFloat kHeaderSubtitleHeight = 10.0f;

static const CGFloat kPostKeyboardMarginTop = 50.0f;


//starView
static const CGFloat kStarViewLeftBorder = 0.0f;
static const CGFloat kStarViewHeight = 60.0f;




// TODO: calculate avatar size based on pixel image size
static const CGSize  kDetailImageViewSize = { .width=38.0f, .height=38.0f };
static const CGFloat kDetailImageCornerRadius = 4.f;
static const CGFloat kDetailImageMarginRight = 8.0f;

static const CGFloat kDetailRemoteButtonWidth = 20.0f;
//static const CGFloat kDetailRemoteButtonHeight = 20.0f;

@interface LFSWriteCommentView ()

// UIView-specific
@property (readonly, nonatomic) UIImageView *headerImageView;
@property (readonly, nonatomic) UILabel *headerAttributeTopView;
@property (readonly, nonatomic) UIImageView *headerAttributeTopImageView;
@property (readonly, nonatomic) UILabel *headerTitleView;
@property (readonly, nonatomic) UILabel *headerSubtitleView;
@property (readonly, nonatomic) UILabel *headerTitleLable;
@property (readonly, nonatomic) DLStarRatingControl *starView;

@property (readonly, nonatomic) UILabel *headerProsLable;
@property (readonly, nonatomic) UILabel *consTitleLable;

@property (readonly, nonatomic) UIView *addPhotoImageView;

@end

@implementation LFSWriteCommentView {
    CGFloat _previousViewHeight;
}

#pragma mark - Properties

@synthesize profileLocal = _profileLocal;

#pragma mark -
@synthesize headerImageView = _headerImageView;
-(UIImageView*)headerImageView
{
    if (_headerImageView == nil) {
        
        CGSize avatarViewSize;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]
            && ([UIScreen mainScreen].scale == 2.f))
        {
            // Retina display, okay to use half-points
            avatarViewSize = CGSizeMake(37.5f, 37.5f);
        }
        else
        {
            // non-Retina display, do not use half-points
            avatarViewSize = CGSizeMake(37.f, 37.f);
        }
        CGRect frame;
        frame.size = avatarViewSize;
        frame.origin = CGPointMake(kDetailPadding.left, kDetailPadding.top);
        
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerImageView
         setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin)];
        
        _headerImageView.layer.cornerRadius = kDetailImageCornerRadius;
        _headerImageView.layer.masksToBounds = YES;
        
        // add to superview
        [self.textView addSubview:_headerImageView];
    }
    return _headerImageView;
}

#pragma mark -
@synthesize headerAttributeTopView = _headerAttributeTopView;
- (UILabel*)headerAttributeTopView
{
    if (_headerAttributeTopView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth,
                                      kDetailHeaderAttributeTopHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerAttributeTopView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopView setFont:[UIFont systemFontOfSize:kDetailHeaderAttributeTopFontSize]];
        [_headerAttributeTopView setTextColor:[UIColor blueColor]];
        
        // add to superview
        [self.textView addSubview:_headerAttributeTopView];
    }
    return _headerAttributeTopView;
}

#pragma mark -
@synthesize headerAttributeTopImageView = _headerAttributeTopImageView;
- (UIImageView*)headerAttributeTopImageView
{
    if (_headerAttributeTopImageView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth,
                                      kDetailHeaderAttributeTopImageHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerAttributeTopImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopImageView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopImageView setContentMode:UIViewContentModeTopLeft];
        
        // add to superview
        [self.textView addSubview:_headerAttributeTopImageView];
    }
    return _headerAttributeTopImageView;
}

#pragma mark -
@synthesize headerTitleView = _headerTitleView;
- (UILabel*)headerTitleView
{
    if (_headerTitleView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        _headerTitleView = [[UILabel alloc] initWithFrame:frame];
        _headerTitleView.backgroundColor=[UIColor whiteColor];
        // configure
        [_headerTitleView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerTitleView setFont:[UIFont boldSystemFontOfSize:kDetailHeaderTitleFontSize]];
        
        // add to superview
        [self.textView addSubview:_headerTitleView];
    }
    return _headerTitleView;
}


@synthesize headerTitleLable = _headerTitleLable;
- (UILabel*)headerTitleLable
{
    if (_headerTitleLable == nil) {
        
        CGFloat leftColumnWidth = kDetailPadding.left;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(0, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerTitleLable = [[UILabel alloc] initWithFrame:frame];
        
        // configure
//        [_headerTitleLable
//         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerTitleLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
        [_headerTitleLable setTextColor:UIColorFromRGB(0x969696)];
        
        // add to superview
        [self.textView addSubview:_headerTitleLable];
    }
    return _headerTitleLable;
}

@synthesize titleTextField = _titleTextField;
- (UITextField*)titleTextField
{
    if (_titleTextField == nil) {
        float widthIs =
        [self.headerTitleLable.text
         boundingRectWithSize:self.headerTitleLable.frame.size
         options:NSStringDrawingUsesLineFragmentOrigin
         attributes:@{ NSFontAttributeName:self.headerTitleLable.font }
         context:nil]
        .size.width;
        NSLog(@"%f",widthIs);
        CGFloat leftColumnWidth = kDetailPadding.left+widthIs+kDetailTitleTextFieldWidth;
        CGFloat rightColumnWidth = self.headerTitleLable.frame.size.width + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        
        // initialize
        _titleTextField = [[UITextField alloc] initWithFrame:frame];
        
        // configure
//        [_titleTextField
//         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_titleTextField setFont:[UIFont fontWithName:@"Georgia" size:kPostContentFontSize]];
        [_titleTextField setTextColor:UIColorFromRGB(0x474C52)];
    
        //_titleTextField.layoutManager.delegate = self;
        // add to superview
        [self.textView addSubview:_titleTextField];
        
    }
    return _titleTextField;
}
@synthesize starView =_starView;
-(DLStarRatingControl*)starView
{   _ratingPost=0;
    CGFloat leftColumnWidth =kStarViewLeftBorder;
    CGFloat rightColumnWidth = kStarViewLeftBorder;
    CGSize viewSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kStarViewHeight);
    CGRect frame;
    frame.size = viewSize;
    frame.origin = CGPointMake(leftColumnWidth,
                               self.titleTextField.frame.size.height);
    
    if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
        // iOS6
        frame.origin.y -= kPostContentInset.top;
        frame.origin.x -= kPostContentInset.left;
    }

    _starView  = [[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 70, 320, 50) andStars:5 isFractional:NO];
    _starView.rating=0;
//   self.starView.delegate=self;
    [self.textView addSubview:_starView];
    return _starView;
}


@synthesize headerProsLable = _headerProsLable;
- (UILabel*)headerProsLable
{
    if (_headerProsLable == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   95+kDetailHeaderTitleHeight); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -=  kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerProsLable = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerProsLable
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerProsLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:kPostContentFontSize]];
        [_headerProsLable setTextColor:UIColorFromRGB(0x969696)];
        
        // add to superview
        [self.textView addSubview:_headerProsLable];
    }
    return _headerProsLable;
}
@synthesize prosTextField = _prosTextField;
- (UITextField*)prosTextField
{
    if (_prosTextField == nil) {
        float widthIs =
        [self.headerProsLable.text boundingRectWithSize:self.headerProsLable.frame.size
         options:NSStringDrawingUsesLineFragmentOrigin
         attributes:@{ NSFontAttributeName:self.headerProsLable.font }
         context:nil]
        .size.width;
        NSLog(@"%f",widthIs);
        CGFloat leftColumnWidth = kDetailPadding.left+widthIs+kDetailTitleTextFieldWidth;
        CGFloat rightColumnWidth = self.headerProsLable.frame.size.width + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   95+kDetailHeaderTitleHeight); // size.y will be changed in layoutSubviews
//        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
//            // iOS6
//            frame.origin.y -= kPostContentInset.top;
//            frame.origin.x -= kPostContentInset.left;
//        }
        
        // initialize
        _prosTextField = [[UITextField alloc] initWithFrame:frame];
        
        // configure
        [_prosTextField
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_prosTextField setFont:[UIFont fontWithName:@"Georgia" size:18.0f]];
        [_prosTextField setTextColor:UIColorFromRGB(0x474C52)];
        
        //_titleTextField.layoutManager.delegate = self;
        // add to superview
        [self.textView addSubview:_prosTextField];
        
    }
    return _prosTextField;
}

@synthesize consTitleLable = _consTitleLable;
- (UILabel*)consTitleLable
{
    if (_consTitleLable == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailHeaderTitleHeight+145); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -=  kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _consTitleLable = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_consTitleLable
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_consTitleLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:kPostContentFontSize]];
        [_consTitleLable setTextColor:UIColorFromRGB(0x969696)];
        
        // add to superview
        [self.textView addSubview:_consTitleLable];
    }
    return _consTitleLable;
}
@synthesize consTextField = _consTextField;
- (UITextField*)consTextField
{
    if (_consTextField == nil) {
        float widthIs =
        [self.consTitleLable.text
         boundingRectWithSize:self.consTitleLable.frame.size
         options:NSStringDrawingUsesLineFragmentOrigin
         attributes:@{ NSFontAttributeName:self.consTitleLable.font }
         context:nil]
        .size.width;
        NSLog(@"%f",widthIs);
        CGFloat leftColumnWidth = kDetailPadding.left+widthIs+kDetailTitleTextFieldWidth;
        CGFloat rightColumnWidth = self.consTitleLable.frame.size.width + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailHeaderTitleHeight+145); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _consTextField = [[UITextField alloc] initWithFrame:frame];
        
        // configure
        [_consTextField
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_consTextField setFont:[UIFont fontWithName:@"Georgia" size:18.0f]];
        [_consTextField setTextColor:UIColorFromRGB(0x474C52)];
        
        //_titleTextField.layoutManager.delegate = self;
        // add to superview
        [self.textView addSubview:_consTextField];
        
    }
    return _consTextField;
}






#pragma mark -
@synthesize headerSubtitleView = _headerSubtitleView;
- (UILabel*)headerSubtitleView
{
    if (_headerSubtitleView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kHeaderSubtitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerSubtitleView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerSubtitleView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerSubtitleView setFont:[UIFont systemFontOfSize:kDetailHeaderSubtitleFontSize]];
        [_headerSubtitleView setTextColor:[UIColor grayColor]];
        
        // add to superview
        [self.textView addSubview:_headerSubtitleView];
    }
    return _headerSubtitleView;
}

#pragma mark -
@synthesize addPhotoImageView = _addPhotoImageView;
-(UIView*)addPhotoImageView
{
    if (_addPhotoImageView == nil) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenHeight = screenRect.size.height;
        _addPhotoImageView=[[UIView alloc]initWithFrame:CGRectMake(0, screenHeight-326, 320, 50)];
        [_addPhotoImageView setBackgroundColor:UIColorFromRGB(0xF3F3F3)];
        
        _addPhotoImageView.alpha=0.8;
        
        UIButton *addImageButton=[[UIButton alloc]initWithFrame:CGRectMake(100,11, 30, 24)];
        CAShapeLayer *lineOnImage=[self drawline:CGPointMake(0, 0) :CGPointMake(320, 0)];
        lineOnImage.strokeColor = [[UIColor colorWithRed:160/225 green:160/225 blue:161/225 alpha:1] CGColor];
        lineOnImage.lineWidth = 0.1;
        lineOnImage.fillColor = [[UIColor colorWithRed:160/225 green:160/225 blue:161/225 alpha:1] CGColor];

        [_addPhotoImageView.layer addSublayer:lineOnImage];
        
        [addImageButton setImage:[UIImage imageNamed:@"image.png"] forState:UIControlStateNormal];
        [_addPhotoImageView addSubview:addImageButton];
        UIButton *addPhoto=[[UIButton alloc]initWithFrame:CGRectMake(136,11, 100, 28)];
        [addPhoto setTitle:@"Add Photo" forState:UIControlStateNormal];
        addPhoto.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        [addPhoto setTitleColor:UIColorFromRGB(0x80848B) forState:UIControlStateNormal];
        [addPhoto addTarget:self action:@selector(addPhotoClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_addPhotoImageView addSubview:addPhoto];
        [self addSubview:_addPhotoImageView];
    }

    return _addPhotoImageView;
}
-(IBAction)addPhotoClicked:(id)sender
{
    UIImagePickerController *imagePicker =[[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType =UIImagePickerControllerSourceTypePhotoLibrary;
    //imagePicker.mediaTypes = [NSArray arrayWithObjects:(NSString *) kUTTypeImage,nil];
    imagePicker.allowsEditing = YES;
   // [self presentViewController:imagePicker animated:YES completion:nil];
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  //  [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Private overrides
-(void)layoutSubviews
{
    // layout header title label
    //
    // Note: preciese layout depends on whether we have subtitle field
    // (i.e. twitter handle)
    
    LFSResource *profileLocal = self.profileLocal;
    NSString *headerTitle = profileLocal.displayString;
    NSString *headerSubtitle = profileLocal.identifier;
    id headerAccessory = profileLocal.attributeObject;
    
    if (!headerTitle && !headerSubtitle && !headerAccessory)
    {
        // display one string
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && headerSubtitle && !headerAccessory)
    {
        // full name + twitter handle
        
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerSubtitleFrame = self.headerSubtitleView.frame;
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerSubtitleFrame.size.height) / 3.f);
        
        headerTitleFrame.origin.y = kDetailPadding.top + separator;
        headerSubtitleFrame.origin.y = (kDetailPadding.top
                                        + separator
                                        + headerTitleFrame.size.height
                                        + separator);
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
        
        [self.headerSubtitleView setFrame:headerSubtitleFrame];
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && !headerSubtitle && headerAccessory)
    {
        // attribute + full name
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerAttributeTopFrame = ([headerAccessory isKindOfClass:[UIImage class]]
                                          ? self.headerAttributeTopImageView.frame
                                          : self.headerAttributeTopView.frame);
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerAttributeTopFrame.size.height) / 3.f);
        
        
        headerAttributeTopFrame.origin.y = (kDetailPadding.top + separator);
        headerTitleFrame.origin.y = (kDetailPadding.top
                                     + separator
                                     + headerAttributeTopFrame.size.height
                                     + separator);
        
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
        }
        else {
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
        }
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && headerSubtitle && headerAccessory)
    {
        // attribute + full name + twitter handle
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerAttributeTopFrame = ([headerAccessory isKindOfClass:[UIImage class]]
                                          ? self.headerAttributeTopImageView.frame
                                          : self.headerAttributeTopView.frame);

        CGRect headerSubtitleFrame = self.headerSubtitleView.frame;
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerAttributeTopFrame.size.height
                                    - headerSubtitleFrame.size.height) / 4.f);
        
        
        headerAttributeTopFrame.origin.y = (kDetailPadding.top + separator);
        headerTitleFrame.origin.y = (kDetailPadding.top
                                     + separator
                                     + headerAttributeTopFrame.size.height
                                     + separator);
        
        headerSubtitleFrame.origin.y = (kDetailPadding.top
                                        + separator
                                        + headerAttributeTopFrame.size.height
                                        + separator
                                        + headerTitleFrame.size.height
                                        + separator);
        
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
        }
        else {
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
        }
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
        
        [self.headerSubtitleView setFrame:headerSubtitleFrame];
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && !headerSubtitle && !headerAccessory){
        [self.headerTitleLable setText:headerTitle];
        [self.headerTitleLable resizeVerticalCenterRightTrim];
        self.headerTitleLable.backgroundColor=[UIColor whiteColor];
            self.titleTextField.placeholder=@"Enter Title Here";
        self.titleTextField.backgroundColor=[UIColor whiteColor];
        
        [self.headerProsLable setText:@"Pros"];
        [self.headerProsLable resizeVerticalCenterRightTrim];
        
        
        self.prosTextField.placeholder=@"Enter Pros Here";
        [self.starView setBackgroundColor:[UIColor clearColor]];
        self.starView.delegate=self;
        
        [self.consTitleLable setText:@"Cons"];
        [self.consTitleLable resizeVerticalCenterRightTrim];
        
        self.consTextField.placeholder=@"Enter Cons Here";
        
        [self.addPhotoImageView setBackgroundColor:UIColorFromRGB(0xF3F3F3) ];

        CAShapeLayer *line1=[self drawline:CGPointMake(0, 60) :CGPointMake(320, 60)];
        [self.textView.layer addSublayer:line1];
        CAShapeLayer *line2=[self drawline:CGPointMake(0, 120) :CGPointMake(320, 120)];
        [self.textView.layer addSublayer:line2];
        CAShapeLayer *line3=[self drawline:CGPointMake(0, 180) :CGPointMake(320, 180)];
        [self.textView.layer addSublayer:line3];
        CAShapeLayer *line4=[self drawline:CGPointMake(0, 240) :CGPointMake(320, 240)];
        [self.textView.layer addSublayer:line4];
        
        CAShapeLayer *line5=[self drawline:CGPointMake(0, 0) :CGPointMake(320, 0)];
        [self.layer addSublayer:line5];
    }
    
    else {
        // no header
    }
    
    // layout avatar view
//    [self.headerImageView setImageWithURL:[NSURL URLWithString:profileLocal.iconURLString]
//                         placeholderImage:profileLocal.icon];
}
-(CAShapeLayer*)drawline:(CGPoint)from :(CGPoint)to{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:from];
    [path addLineToPoint:to];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [[UIColor colorWithRed:160/225 green:160/225 blue:161/225 alpha:1] CGColor];
    shapeLayer.lineWidth = 0.1;
    shapeLayer.fillColor = [[UIColor colorWithRed:160/225 green:160/225 blue:161/225 alpha:1] CGColor];
    return shapeLayer;
}

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    return 28; // For really wide spacing; pick your own value
}
#pragma mark - Rating Delegate
-(void)newRating:(DLStarRatingControl *)control :(float)rating {
	//self.stars.text = [NSString stringWithFormat:@"%0.1f star rating",rating];
    NSLog(@"%@",[NSString stringWithFormat:@"%0.0f star rating",rating]);
    _ratingPost=[NSString stringWithFormat:@"%0.0f",rating*20];
}

#pragma mark -
@synthesize textView = _textView;
-(UITextView*)textView
{
    if (_textView == nil) {
        CGRect frame = self.bounds;
//        frame.origin.y+=120;
//        frame.size.height-=120;
        NSLog(@"%f %f",self.bounds.origin.x, self.bounds.origin.y);
        _textView = [[UITextView alloc] initWithFrame:frame];
        
        [_textView setBackgroundColor:[UIColor whiteColor]];
        
        if ([_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS7
            [_textView setTextContainerInset:kPostContentInset];
        } else {
            // iOS6
            [_textView setContentInset:UIEdgeInsetsMake(kPostContentInset.top, 0.f, kPostContentInset.bottom, 0.f)];
        }
        [_textView setFont:[UIFont fontWithName:kPostContentFontName size:kPostContentFontSize]];
        [_textView setUserInteractionEnabled:YES];
        [_textView setScrollEnabled:YES];
        [_textView setDelegate:self];
        
        [_textView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin)];
        
        [self addSubview:_textView];
    }
    return _textView;
}


#pragma mark - UITextViewDelegate
-(void)textViewDidChange:(UITextView *)textView
{
    CGRect caret_rect = [textView caretRectForPosition:textView.selectedTextRange.end];
    UIEdgeInsets insets = textView.contentInset;
    CGRect visible_rect = textView.bounds;
    visible_rect.size.height -= (insets.top + insets.bottom);
    visible_rect.origin.y = textView.contentOffset.y;
    
    if (!CGRectContainsRect(visible_rect, caret_rect)) {
        CGFloat new_offset = MAX((caret_rect.origin.y + caret_rect.size.height) - visible_rect.size.height - textView.contentInset.top,  -textView.contentInset.top);
        [textView setContentOffset:CGPointMake(0, new_offset) animated:NO];
    }
}

#pragma mark - Lifecycle

+(CGRect)screenBounds
{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = screen.bounds;
    
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        CGRect temp;
        temp.size.width = screenRect.size.height;
        temp.size.height = screenRect.size.width;
        screenRect = temp;
    }
    return screenRect;
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up
{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect viewFrame = self.frame;
    
    // convert to window base coordinates
    CGRect keyboardFrame = [self convertRect:keyboardEndFrame toView:nil];
    
    // calculate overlap height
    CGRect screenBounds = [[self class] screenBounds];
    
    // view frame bottom minus keyboard top
    CGFloat overlapHeight = viewFrame.origin.y + viewFrame.size.height - (screenBounds.size.height - keyboardFrame.size.height);
    if (overlapHeight > 0.f && overlapHeight < viewFrame.size.height)
    {
        // need to take action (there is an overlap and it does not cover the whole view)
        if (up) {
            // shrink the view
            _previousViewHeight = viewFrame.size.height;
            viewFrame.size.height = _previousViewHeight - overlapHeight - kPostKeyboardMarginTop;
        } else {
            // restore the previous view height
            viewFrame.size.height = _previousViewHeight;
        }
        [self setFrame:viewFrame];
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:NO];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self resetFields];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self resetFields];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _previousViewHeight = frame.size.height;
    }
    return self;
}

- (void)dealloc
{
    [_textView setDelegate:nil];
    [self resetFields];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)resetFields
{
    _headerImageView = nil;
    _headerTitleView = nil;
    
    _profileLocal = nil;
}


@end
