//
//  TBMessageCellView.m
//  ChatView
//
//  Created by Thomas Balthazar on 07/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBMessageCellView.h"

//#define kFont                     [UIFont fontWithName:@"Monda-Regular" size:15.0]
#define kMaxWidthPortrait       	296.0
#define kMaxWidthLandscape      	437.0
//#define kSenderLabelPaddingTop    0.0
//#define kSenderLabelPaddingBottom 1.0
//#define kSenderLabelPaddingLeft   7.0
//#define kSenderLabelPaddingRight  7.0
//
//#define kMeSpeakingColor    [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1]
//#define kOtherSpeakingColor [UIColor colorWithRed:0.592 green:0.808 blue:0.925 alpha:1.000]

#define kSenderLabelPaddingLeft   7.0
#define kSenderLabelPaddingRight  7.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBMessageCellView ()

//@property (nonatomic, strong) TBBubbleView *bubbleView;
//@property (nonatomic, strong) UIView *senderLabelBackground;
//@property (nonatomic, strong) UILabel *senderLabel;
@property (nonatomic, strong) UITextView *textView;

+ (CGSize)textViewSizeForText:(NSString *)text;
+ (NSDictionary *)textAttributes;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBMessageCellView

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
//    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    
//    // -- bubble view
//    _bubbleView = [[TBBubbleView alloc] init];
//    //_bubbleView.bubbleColor = [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1];
//    [self addSubview:_bubbleView];
//    
//    // -- sender label background
//    _senderLabelBackground = [[UIView alloc] init];
//    //_senderLabelBackground.backgroundColor = [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1];
//    [self addSubview:_senderLabelBackground];
//    
//    // -- sender label
//    _senderLabel = [[UILabel alloc] init];
//    _senderLabel.font = kFont;
//    //_senderLabel.backgroundColor = [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1];
//    _senderLabel.textColor = [UIColor whiteColor];
//    [self addSubview:_senderLabel];
    
    // -- text view
    _textView = [[UITextView alloc] init];
    _textView.editable = NO;
    _textView.scrollEnabled = NO;
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.font = [[self class] font];
    _textView.textContainerInset = UIEdgeInsetsMake(-0.5, 0.0, 0.0, 0.0);
    _textView.textContainer.lineFragmentPadding = 0.0;
    _textView.dataDetectorTypes = UIDataDetectorTypeLink;
    [self addSubview:_textView];
    
//    [self bringSubviewToFront:_senderLabelBackground];
//    [self bringSubviewToFront:_senderLabel];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)setSenderName:(NSString *)senderName {
//  self.senderLabel.text = senderName;
//  [self.senderLabel sizeToFit];
//  [self setNeedsLayout];
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (NSString *)senderName {
//  return self.senderLabel.text;
//}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMessage:(NSString *)message {
  self.textView.attributedText = [[NSAttributedString alloc] initWithString:message
                                                          attributes:[[self class] textAttributes]];
  [self setNeedsLayout];
  [self.bubbleView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)message {
  return self.textView.text;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)setMeSpeaking:(BOOL)meSpeaking {
//  self.bubbleView.shouldAlignTailToLeft = meSpeaking;
//  self.bubbleView.bubbleColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
//  self.senderLabelBackground.backgroundColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
//  self.senderLabel.backgroundColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
//  
//  [self.bubbleView setNeedsDisplay];
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (BOOL)isMeSpeaking {
//  return self.bubbleView.shouldAlignTailToLeft;
//}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)sizeForText:(NSString *)text {
  CGSize textViewSize = [self textViewSizeForText:text];
  CGSize bubbleSize = [TBBubbleView sizeForContentSize:textViewSize];
  
  return bubbleSize;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)setBackgroundColor:(UIColor *)backgroundColor {
//  [super setBackgroundColor:backgroundColor];
//  self.bubbleView.backgroundColor = backgroundColor;
//}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)textViewSizeForText:(NSString *)text {
  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat maxWidth = isPortrait ? kMaxWidthPortrait : kMaxWidthLandscape;
  
	CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
  
  CGRect boundingRect = [text boundingRectWithSize:maxSize
                                           options:
                         (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        attributes:[self textAttributes]
                                           context:nil];
  CGFloat width = ceilf(boundingRect.size.width);
  CGFloat height = ceilf(boundingRect.size.height);

  return CGSizeMake(width, height);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSDictionary *)textAttributes {
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
  return @{ NSFontAttributeName: [self font],
            NSParagraphStyleAttributeName: paragraphStyle};
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect textViewFrame = self.bubbleView.contentFrame;

  // sender label background
  CGRect senderLabelBackgroundFrame = self.senderLabelBackground.frame;
  BOOL textIsOnOneLine = textViewFrame.size.height < senderLabelBackgroundFrame.size.height;
  if (textIsOnOneLine) {
    senderLabelBackgroundFrame.size.height+=1.0;
    self.senderLabelBackground.frame = senderLabelBackgroundFrame;
  }
  
  // textView
  CGRect exclustionFrame = self.senderLabel.frame;
  exclustionFrame.origin = CGPointZero;
  exclustionFrame.size.width+=kSenderLabelPaddingLeft+kSenderLabelPaddingRight;
  exclustionFrame.size.height-=4.0;
  UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:exclustionFrame];
  self.textView.textContainer.exclusionPaths = @[exclusionPath];
  self.textView.frame = textViewFrame;

//  [self bringSubviewToFront:self.senderLabelBackground];
//  [self bringSubviewToFront:self.senderLabel];
}

@end
