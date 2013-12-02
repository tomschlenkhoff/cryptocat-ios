//
//  TBBubbleCell.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/12/13.
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

#import "TBBubbleCell.h"
#import "TBWarningView.h"
#import "TBMessageView.h"

#define kPaddingTop     0.0
#define kPaddingBottom  10.0
#define kPaddingLeft    11.0
#define kPaddingRight   12.5
#define kMeSpeakingColor    [UIColor colorWithRed:0.592 green:0.808 blue:0.925 alpha:1.000]
#define kOtherSpeakingColor [UIColor colorWithRed: 0.396 green: 0.685 blue: 0.872 alpha: 1]
#define kWarningColor       [UIColor redColor]

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleCell () <TBMessageViewDelegate>

@property (nonatomic, strong) TBWarningView *warningView;
@property (nonatomic, strong) TBMessageView *messageView;

- (void)updateColors;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBubbleCell

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    _warningView = nil;
    _messageView = [[TBMessageView alloc] init];
    _messageView.delegate = self;
    [self.contentView addSubview:_messageView];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  [self updateColors];

  CGRect messageViewFrame = self.contentView.frame;
  messageViewFrame.size.width-=(kPaddingLeft+kPaddingRight);
  messageViewFrame.origin.x+=kPaddingLeft;
  messageViewFrame.size.height-=(kPaddingTop+kPaddingBottom);
  messageViewFrame.origin.y+=kPaddingTop;
  
  // warning view
  if (self.warningMessage!=nil) {
    CGRect warningViewFrame = messageViewFrame;
    CGSize size = [TBWarningView sizeForText:self.warningMessage];
    warningViewFrame.size.height = size.height;
    self.warningView.frame = warningViewFrame;

    messageViewFrame.size.height-=size.height;
    messageViewFrame.origin.y+=size.height;
    [self.warningView setNeedsDisplay];
  }

  self.messageView.frame = messageViewFrame;
  [self.messageView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Properties

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  
  self.messageView.backgroundColor = backgroundColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSenderName:(NSString *)senderName {
  self.messageView.senderName = senderName;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)senderName {
  return self.messageView.senderName;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMessage:(NSString *)message {
  self.messageView.message = message;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)message {
  return self.messageView.message;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setWarningMessage:(NSString *)warningMessage {
  if (warningMessage==nil) {
    [self.warningView removeFromSuperview];
    self.warningView = nil;
  }
  else if (self.warningView==nil) {
    self.warningView = [[TBWarningView alloc] init];
    [self.contentView addSubview:self.warningView];
    self.warningView.message = warningMessage;
    self.warningView.backgroundColor = self.backgroundColor;
    [self setNeedsLayout];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)warningMessage {
  return self.warningView==nil ? nil : self.warningView.message;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMeSpeaking:(BOOL)meSpeaking {
  if (self.isMeSpeaking!=meSpeaking) {
    self.messageView.shouldAlignTailToLeft = !meSpeaking;
  }
  
  [self updateColors];
  [self.messageView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isMeSpeaking {
  return !self.messageView.shouldAlignTailToLeft;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)paddedSenderNameSize {
  return self.messageView.paddedSenderNameSize;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForSenderName:(NSString *)senderName
                       message:(NSString *)message
                warningMessage:(NSString *)warningMessage
                      maxWidth:(CGFloat)maxWidth {
  maxWidth-=(kPaddingLeft+kPaddingRight);
  CGFloat messageViewHeight = [TBMessageView heightForSenderName:senderName
                                                         message:message
                                                        maxWidth:maxWidth];
  if (warningMessage!=nil) {
    messageViewHeight+=[TBWarningView sizeForText:warningMessage].height;
  }
  
  return messageViewHeight+kPaddingTop+kPaddingBottom;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateColors {
  if (self.isErrorMessage) {
    self.messageView.bubbleColor = kWarningColor;
  }
  else {
    self.messageView.bubbleColor = self.isMeSpeaking ? kMeSpeakingColor : kOtherSpeakingColor;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBMessageViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)messageView:(TBMessageView *)messageView
shouldInteractWithURL:(NSURL *)URL
            inRange:(NSRange)characterRange {
  if ([self.delegate respondsToSelector:@selector(bubbleCell:shouldInteractWithURL:inRange:)]) {
    return [self.delegate bubbleCell:self shouldInteractWithURL:URL inRange:characterRange];
  }
  
  return NO;
}

@end
