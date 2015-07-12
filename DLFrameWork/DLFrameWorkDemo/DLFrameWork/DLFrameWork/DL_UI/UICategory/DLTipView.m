//
//  DLTipView.m
//  DLKit
//
//  Created by XueYulun on 15/3/25.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import "DLTipView.h"

@interface DLTipView ()

@property (nonatomic, assign) DLTipArrowOrientation arrowOrientation;
@property (nonatomic, assign) CGFloat margin;
@property (nonatomic, copy) NSString *contentText;
@property (nonatomic, retain) UIFont *textFont;

@property (nonatomic, retain) UIImageView *arrowImageView;
@property (nonatomic, retain) UIImageView *tipImageView;
@property (nonatomic, retain) UILabel *tipLabel;
@property (nonatomic, assign) CGPoint labelOrigin;

@property (nonatomic, retain) UIView *tipLabelView;
@property (nonatomic, retain) NSArray *tipTextArray;
@property (nonatomic, retain) NSString *rightIconName;

@end

@implementation DLTipView


- (void)dealloc {
    for (UIGestureRecognizer *recognizer in self.gestureRecognizers)
    {
        recognizer.enabled = YES;
        [recognizer removeTarget:nil action:NULL];
        [self removeGestureRecognizer:recognizer];
    }
    
    self.arrowImageView = nil;
    self.tipImageView = nil;
    self.tipLabel = nil;
    self.contentText = nil;
    self.tipLabelView = nil;
    self.tipTextArray = nil;
    self.rightIconName = nil;
}

- (id)initWithRect:(CGRect)rect
              text:(NSString *)text
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation {
    self = [super initWithFrame:rect];
    if (self) {
        self.arrowOrientation = orientation;
        self.margin = margin;
        self.contentText = text;
        self.textFont = textFont;
        [self layoutUI];
    }
    return self;
}

- (id)initWithRect:(CGRect)rect
         textArray:(NSArray *)textArray
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation
         rightIcon:(NSString *)rightIcon {
    self = [super initWithFrame:rect];
    if(self){
        self.tipTextArray = textArray;
        self.arrowOrientation = orientation;
        self.margin = margin;
        self.textFont = textFont;
        self.rightIconName = rightIcon;
        [self layoutUI];
    }
    return self;
}

- (id)initWithRect:(CGRect)rect
         textArray:(NSArray *)textArray
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation
         rightIcon:(NSString *)rightIcon
   textLabelOrigin:(CGPoint)textOrigin {
    self = [super initWithFrame:rect];
    if(self){
        self.tipTextArray = textArray;
        self.arrowOrientation = orientation;
        self.margin = margin;
        self.textFont = textFont;
        self.rightIconName = rightIcon;
        self.labelOrigin = textOrigin;
        [self layoutUI];
    }
    return self;
}

- (void)layoutUI {
    
    // you can set your arrow image here....
    self.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"btn_pop_float_top"]];
    CGAffineTransform rotate;
    switch (self.arrowOrientation) {
        case DL_ARROW_ORI_UP:{
            rotate = CGAffineTransformMakeRotation(0);
            break;
        }
        case DL_ARROW_ORI_DOWN:{
            rotate = CGAffineTransformMakeRotation(M_PI);
            break;
        }
        case DL_ARROW_ORI_LEFT:{
            rotate = CGAffineTransformMakeRotation(-M_PI/2);
            break;
        }
        case DL_ARROW_ORI_RIGHT:{
            rotate = CGAffineTransformMakeRotation(M_PI/2);
            break;
        }
        default:{
            rotate = CGAffineTransformMakeRotation(0);
            break;
        }
    }
    [self.arrowImageView setTransform:rotate];
    [self addSubview:self.arrowImageView];
    
    self.tipImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_pop_float_above"] safeResizableImageWithCapInsets:UIEdgeInsetsMake(17, 7, 17, 7)]];
    switch (self.arrowOrientation) {
        case DL_ARROW_ORI_UP:
        {
            self.tipImageView.frame = CGRectMake(0, self.arrowImageView.height - 0.5, self.width, self.height - self.arrowImageView.height);
            self.arrowImageView.origin = CGPointMake(self.margin, 0);
            break;
        }
        case DL_ARROW_ORI_DOWN:
        {
            self.tipImageView.frame = CGRectMake(0, self.bounds.origin.y, self.width, self.height - self.arrowImageView.height);
            self.arrowImageView.origin = CGPointMake(self.margin, self.tipImageView.bottom);
            break;
        }
        case DL_ARROW_ORI_LEFT:
        {
            self.tipImageView.frame = CGRectMake(self.arrowImageView.width, self.bounds.origin.y, self.width - self.arrowImageView.width, self.height);
            self.arrowImageView.origin = CGPointMake(0, self.margin);
            break;
        }
        case DL_ARROW_ORI_RIGHT:
        {
            self.tipImageView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.width - self.arrowImageView.width, self.height);
            self.arrowImageView.origin = CGPointMake(self.tipImageView.right, self.margin);
            break;
        }
        default:
            break;
    }
    [self addSubview:self.tipImageView];
    
    if(self.contentText){
        self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.tipImageView.frame.origin.x + 8, self.tipImageView.frame.origin.y,self.tipImageView.frame.size.width,self.tipImageView.frame.size.height)];
        self.tipLabel.backgroundColor = [UIColor clearColor];
        self.tipLabel.font = self.textFont;
        self.tipLabel.text = self.contentText;
        self.tipLabel.textColor = [UIColor whiteColor];
        self.tipLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.tipLabel.numberOfLines = 0;
        [self addSubview:self.tipLabel];
        
        [self addTapGesture];
    }else if(self.tipTextArray){
        [self addTipView];
    }
    
}


-(void)addTipView{
    self.tipLabelView = [[UIView alloc] initWithFrame:self.tipImageView.frame];
    self.tipLabelView.backgroundColor = [UIColor clearColor];
    
    if(!self.tipTextArray){
        return;
    }
    
    int count = 0;
    float xPos = 10;
    float yPos = self.tipLabelView.height/2 - 8;
    for(NSString *text in self.tipTextArray){
        count ++;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(xPos, yPos, 20, 16)];
        if (!CGPointEqualToPoint(self.labelOrigin, CGPointZero)) {
            label.left = self.labelOrigin.x;
        }
        label.font = [UIFont systemFontOfSize:14];
        label.text = text;
        [label sizeToFit];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [self.tipLabelView addSubview:label];
        xPos += label.width;
        if (count == 2) {
            label.textColor = [UIColor colorWithHexString:@"0xf25824"];
        }
    }
    
    if(self.rightIconName && ![self.rightIconName isEqualToString:@""]){
        UIImage* image = [UIImage imageNamed:(self.rightIconName)];
        if(image){
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(xPos, yPos+2, 12, 14)];
            imageView.image = image;
            [self.tipLabelView addSubview:imageView];
            xPos += imageView.width;
        }
    }
    
    xPos += 10;
    
    [self addSubview:self.tipLabelView];
}


- (void)addTapGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandle:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)tapGestureHandle:(id)sender
{
    [self dismissTip];
}

- (void)dismissTip
{
    [self removeFromSuperview];
}


@end
