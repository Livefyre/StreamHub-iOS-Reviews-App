//
//  LFRDetailTableViewCell.m
//  LiveFyreReviewsIOS2
//
//  Created by kvana inc on 28/06/14.
//  Copyright (c) 2014 kvana inc. All rights reserved.
//

#import "LFRDetailTableViewCell.h"


@implementation LFRDetailTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //profile image
        self.profileImage=[[UIImageView alloc]initWithFrame:CGRectMake(15, 10, 48, 48)];
        CALayer *btnLayer = [self.profileImage layer];
        [btnLayer setMasksToBounds:YES];
        [btnLayer setCornerRadius:3.0f];
        [self addSubview:self.profileImage];
        
        
        //moderator or not
        self.moderator=[[UILabel alloc]initWithFrame:CGRectMake(73,10, 80, 18)];
        self.moderator.font=[UIFont fontWithName:@"helveticaNeue" size:14];
        self.moderator.textColor=UIColorFromRGB(0x0F98EC);
        [self addSubview:self.moderator];
        
        //featured
        self.featuredImage=[[UIImageView alloc]init];
        [self addSubview:self.featuredImage];
        
        
        //rating Stars
        CGRect frame = CGRectMake(73,45,100,20);
        self.rateView = [[DYRateView alloc] initWithFrame:frame fullStar:[UIImage imageNamed:@"icon_star_small"] emptyStar:[UIImage imageNamed:@"icon_star_empty_small"]];
        self.rateView.padding = 3;
        self.rateView.alignment = RateViewAlignmentLeft;
        self.rateView.userInteractionEnabled = NO;
        self.rateView.delegate = self;
        [self addSubview:self.rateView];

        //User name
        self.userName= [[UILabel alloc]initWithFrame:CGRectMake(73, 26, 200, 18)];
        self.userName.font=[UIFont fontWithName:@"helveticaNeue-Bold" size:16];
        self.userName.textColor=UIColorFromRGB(0x2F3440);
        [self addSubview:self.userName];
        
        //date and time
        self.date= [[UILabel alloc]init];
        self.date.textColor=UIColorFromRGB(0xb2b2b2);
        self.date.font=[UIFont fontWithName:@"helveticaNeue" size:12];
        [self.date setNeedsLayout];
        [self addSubview:self.date];
        
        // title
        self.title=[[LFSBasicHTMLLabel alloc]init];
        [self addSubview:self.title];
         
        //body
        self.body=[[LFSBasicHTMLLabel alloc]init];
        [self addSubview:self.body];
        
        //footer left
        self.footerLeftView = [[UILabel alloc] init];
        [self.footerLeftView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [self.footerLeftView setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.f]];
        [self.footerLeftView setTextColor:UIColorFromRGB(0xb2b2b2)];
        [self addSubview:self.footerLeftView];
        
        //toolbar
        
        
        
    }
    return self;
}
-(void)layoutsets{
    CGRect toolbarFrame = self.toolbar.frame;
    toolbarFrame.origin = CGPointMake(0.f,self.title.frame.size.height+self.body.frame.size.height+83);
    [self.toolbar setFrame:toolbarFrame];
    
}
-(void)layoutsetsForSubcell{
    CGRect toolbarFrame = self.toolbar.frame;
    toolbarFrame.origin = CGPointMake(0.f,self.body.frame.size.height+63);
    [self.toolbar setFrame:toolbarFrame];
}
-(NSMutableAttributedString*)getAttributedTextWithFormat:(NSString*)text :(float) fontSize :(NSString*)fontName :(float)lineSpace{
    NSMutableAttributedString *attributedText=[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:text];
    UIFont *textFont;
    textFont = [UIFont fontWithName:fontName size:fontSize];
    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    [attributedText setFont:textFont];
    [attributedText addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:NSMakeRange(0u, [attributedText length])];
    
    return attributedText;
}
@synthesize button1=_button1;
-(UIButton*)button1{
    if (_button1 == nil) {
         // initialize
        _button1 = [[UIButton alloc] init];
        [_button1.titleLabel setFont:[UIFont boldSystemFontOfSize:14.f]];
        [_button1 setTitleColor:[UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f]
                       forState:UIControlStateNormal];
        [_button1 setTitleColor:[UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f]
                       forState:UIControlStateHighlighted];
         // Set the amount of space to appear between image and title
        _button1.imageEdgeInsets = UIEdgeInsetsMake(0, 8.0f, 0, 0);
        _button1.titleEdgeInsets = UIEdgeInsetsMake(0, 2 * 8.0f, 0, 0);
        [_button1 setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
   }
return _button1;
}

@synthesize button2=_button2;
-(UIButton*)button2{
    if (_button2 == nil) {
        
        CGRect frame = CGRectMake(0.f, 0.f,
                                  0.f,
                                  0.f);
        // initialize
        _button2 = [[UIButton alloc] initWithFrame:frame];
        [_button2.titleLabel setFont:[UIFont boldSystemFontOfSize:14.f]];
        [_button2 setTitleColor:[UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f]
                       forState:UIControlStateNormal];
        [_button2 setTitleColor:[UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f]
                       forState:UIControlStateHighlighted];

        // Set the amount of space to appear between image and title
        _button2.imageEdgeInsets = UIEdgeInsetsMake(0, 8.0f, 0, 0);
        _button2.titleEdgeInsets = UIEdgeInsetsMake(0, 2 * 8.0f, 0, 0);
        [_button2 setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
     }
    return _button2;
    
}
@synthesize button3=_button3;
-(UIButton*)button3{
    if (_button3 == nil) {
        
        CGRect frame = CGRectMake(0.f, 0.f,
                                  0.f,
                                  0.f);
        // initialize
        _button3 = [[UIButton alloc] initWithFrame:frame];
        [_button3.titleLabel setFont:[UIFont boldSystemFontOfSize:14.f]];
        [_button3 setTitleColor:[UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f]
                       forState:UIControlStateNormal];
        [_button3 setTitleColor:[UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f]
                       forState:UIControlStateHighlighted];

        // Set the amount of space to appear between image and title
        _button3.imageEdgeInsets = UIEdgeInsetsMake(0, 8.0f, 0, 0);
        _button3.titleEdgeInsets = UIEdgeInsetsMake(0, 2 * 8.0f, 0, 0);
        [_button3 setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
     }
    return _button3;
    
}
@synthesize toolbar = _toolbar;
-(LFSContentToolbar*)toolbar
{
    if (_toolbar == nil) {
        
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(self.bounds.size.width, 54);
        
        // initialize
        _toolbar = [[LFSContentToolbar alloc] initWithFrame:frame];
        
        // configure
        [_toolbar setItems:
         @[
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:self action:nil],
           
           [[UIBarButtonItem alloc]
            initWithCustomView:self.button1],
           
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:self action:nil],
           
           [[UIBarButtonItem alloc]
            initWithCustomView:self.button2],
           
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:self action:nil],
           
           [[UIBarButtonItem alloc]
            initWithCustomView:self.button3],
           
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:self action:nil]
           ]
         ];
        [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // add to superview
        [self addSubview:_toolbar];
    }
    return _toolbar;
}


- (void)rateView:(DYRateView *)rateView changedToNewRate:(NSNumber *)rate{
    
}
- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
