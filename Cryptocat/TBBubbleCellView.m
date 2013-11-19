//
//  TBBubbleCellView.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 19/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBBubbleCellView.h"

#define kFont                     [UIFont fontWithName:@"Monda-Regular" size:15.0]
#define kSenderLabelPaddingTop    0.0
#define kSenderLabelPaddingBottom 1.0
#define kSenderLabelPaddingLeft   7.0
#define kSenderLabelPaddingRight  7.0

#define kMeSpeakingColor    [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1]
#define kOtherSpeakingColor [UIColor colorWithRed:0.592 green:0.808 blue:0.925 alpha:1.000]

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBubbleCellView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // -- bubble view
    _bubbleView = [[TBBubbleView alloc] init];
    [self addSubview:_bubbleView];
    
    // -- sender label background
    _senderLabelBackground = [[UIView alloc] init];
    [self addSubview:_senderLabelBackground];
    
    // -- sender label
    _senderLabel = [[UILabel alloc] init];
    _senderLabel.font = kFont;
    _senderLabel.textColor = [UIColor whiteColor];
    [self addSubview:_senderLabel];
    
//    [self bringSubviewToFront:_senderLabelBackground];
//    [self bringSubviewToFront:_senderLabel];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSenderName:(NSString *)senderName {
  self.senderLabel.text = senderName;
  [self.senderLabel sizeToFit];
  [self setNeedsLayout];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)senderName {
  return self.senderLabel.text;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMeSpeaking:(BOOL)meSpeaking {
  self.bubbleView.shouldAlignTailToLeft = meSpeaking;
  self.bubbleView.bubbleColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
  self.senderLabelBackground.backgroundColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
  self.senderLabel.backgroundColor = meSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
  
  [self.bubbleView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isMeSpeaking {
  return self.bubbleView.shouldAlignTailToLeft;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  self.bubbleView.backgroundColor = backgroundColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIFont *)font {
  return kFont;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.bubbleView.frame = self.bounds;
  //CGRect textViewFrame = self.bubbleView.contentFrame;
  
  // sender label background
  CGRect senderLabelBackgroundFrame = self.senderLabelBackground.frame;
  senderLabelBackgroundFrame.origin = [TBBubbleView originForInsideArea];
  senderLabelBackgroundFrame.size = self.senderLabel.frame.size;
  senderLabelBackgroundFrame.size.width+=kSenderLabelPaddingLeft+kSenderLabelPaddingRight;
  senderLabelBackgroundFrame.size.height+=kSenderLabelPaddingTop+kSenderLabelPaddingBottom;
  self.senderLabelBackground.frame = senderLabelBackgroundFrame;

  //BOOL textIsOnOneLine = textViewFrame.size.height < senderLabelBackgroundFrame.size.height;
  
//  if (textIsOnOneLine) {
//    senderLabelBackgroundFrame.size.height+=1.0;
//  }
  
  // sender label
  CGRect senderLabelFrame = self.senderLabel.frame;
  senderLabelFrame.origin = senderLabelBackgroundFrame.origin;
  senderLabelFrame.origin.x+=kSenderLabelPaddingLeft;
  senderLabelFrame.origin.y+=kSenderLabelPaddingTop;
  self.senderLabel.frame = senderLabelFrame;
  
  [self bringSubviewToFront:self.senderLabelBackground];
  [self bringSubviewToFront:self.senderLabel];
  // textView
//  CGRect exclustionFrame = senderLabelFrame;
//  exclustionFrame.origin = CGPointZero;
//  exclustionFrame.size.width+=kSenderLabelPaddingLeft+kSenderLabelPaddingRight;
//  exclustionFrame.size.height-=4.0;
//  UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:exclustionFrame];
//  self.textView.textContainer.exclusionPaths = @[exclusionPath];
//  self.textView.frame = textViewFrame;
}

@end
