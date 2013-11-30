//
//  TBBubbleCellView.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 19/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//
//  This file is part of Cryptocat for iOS.
//
//  Cryptocat for iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Cryptocat for iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Cryptocat for iOS.  If not, see <http://www.gnu.org/licenses/>.
//

#import "TBBubbleCellView.h"

#define kFont                     [UIFont fontWithName:@"Monda-Regular" size:15.0]
#define kSenderLabelPaddingTop    0.0
#define kSenderLabelPaddingBottom 1.0
#define kSenderLabelPaddingLeft   7.0
#define kSenderLabelPaddingRight  7.0

#define kMeSpeakingColor    [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1]
#define kOtherSpeakingColor [UIColor colorWithRed:0.592 green:0.808 blue:0.925 alpha:1.000]
#define kWarningColor       [UIColor redColor]

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleCellView ()

- (void)updateColors;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBubbleCellView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _isErrorMessage = NO;
    
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
  if (self.isMeSpeaking!=meSpeaking) {
    self.bubbleView.shouldAlignTailToLeft = !meSpeaking;
  }

  [self updateColors];
  [self.bubbleView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isMeSpeaking {
  return !self.bubbleView.shouldAlignTailToLeft;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setIsErrorMessage:(BOOL)isErrorMessage {
  if (_isErrorMessage!=isErrorMessage) {
    _isErrorMessage = isErrorMessage;
  }

  [self updateColors];
  [self.bubbleView setNeedsDisplay];
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
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateColors {
  if (self.isErrorMessage) {
    self.bubbleView.bubbleColor = kWarningColor;
    self.senderLabelBackground.backgroundColor = kWarningColor;
    self.senderLabel.backgroundColor = kWarningColor;
  }
  else {
    self.bubbleView.bubbleColor = self.isMeSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
    self.senderLabelBackground.backgroundColor = self.isMeSpeaking ?
                                                      kMeSpeakingColor : kOtherSpeakingColor;
    self.senderLabel.backgroundColor = self.isMeSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.bubbleView.frame = self.bounds;
  
  // sender label background
  CGRect senderLabelBackgroundFrame = self.senderLabelBackground.frame;
  senderLabelBackgroundFrame.origin = [TBBubbleView originForInsideArea];
  senderLabelBackgroundFrame.size = self.senderLabel.frame.size;
  senderLabelBackgroundFrame.size.width+=kSenderLabelPaddingLeft+kSenderLabelPaddingRight;
  senderLabelBackgroundFrame.size.height+=kSenderLabelPaddingTop+kSenderLabelPaddingBottom;
  self.senderLabelBackground.frame = senderLabelBackgroundFrame;
  
  // sender label
  CGRect senderLabelFrame = self.senderLabel.frame;
  senderLabelFrame.origin = senderLabelBackgroundFrame.origin;
  senderLabelFrame.origin.x+=kSenderLabelPaddingLeft;
  senderLabelFrame.origin.y+=kSenderLabelPaddingTop;
  self.senderLabel.frame = senderLabelFrame;
  
  [self bringSubviewToFront:self.senderLabelBackground];
  [self bringSubviewToFront:self.senderLabel];
}

@end
