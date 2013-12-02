//
//  TBMessageView.m
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

#import "TBMessageView.h"

#define kFont                 [UIFont fontWithName:@"Monda-Regular" size:15.0]
#define kTextViewInsetTop     0.0
#define kTextViewInsetBottom  1.0
#define kTextViewInsetLeft    7.0
#define kTextViewInsetRight   7.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBMessageView () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *senderNameBgView;

- (void)updateTextView;
+ (NSDictionary *)textAttributes;
+ (UIFont *)font;
+ (NSString *)paddedSenderName:(NSString *)senderName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBMessageView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  if (self=[super initWithFrame:frame]) {
    _paddedSenderNameSize = CGSizeZero;

    // -- text view
    _textView = [[UITextView alloc] init];
    _textView.editable = NO;
    _textView.scrollEnabled = NO;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.font = [[self class] font];
    _textView.textContainerInset = UIEdgeInsetsMake(kTextViewInsetTop, kTextViewInsetLeft,
                                                    kTextViewInsetBottom, kTextViewInsetRight);
    _textView.textContainer.lineFragmentPadding = 0.0;
    _textView.dataDetectorTypes = UIDataDetectorTypeLink;
    _textView.delegate = self;
    [self addSubview:_textView];
    
    // -- senderNameBgView
    _senderNameBgView = [[UIView alloc] init];
    _senderNameBgView.backgroundColor = [UIColor yellowColor];
    [_textView addSubview:_senderNameBgView];
    [_textView sendSubviewToBack:_senderNameBgView];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];

  // textView
  CGRect textViewFrame = self.innerRect;
  self.textView.frame = textViewFrame;
  
  // senderBgLabel
  CGRect senderBgLabelFrame = CGRectZero;
  senderBgLabelFrame.size = self.paddedSenderNameSize;
  senderBgLabelFrame.size.height+=1.5;
  self.senderNameBgView.frame = senderBgLabelFrame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBubbleColor:(UIColor *)bubbleColor {
  [super setBubbleColor:bubbleColor];
  self.senderNameBgView.backgroundColor = bubbleColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSenderName:(NSString *)senderName {
  _senderName = senderName;
  self.paddedSenderNameSize = [[[self class] paddedSenderName:senderName]
                               sizeWithAttributes:[[self class] textAttributes]];
  
  [self updateTextView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMessage:(NSString *)message {
  _message = message;
  [self updateTextView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForSenderName:(NSString *)senderName
                       message:(NSString *)message
                      maxWidth:(CGFloat)maxWidth {
  maxWidth-=(kTextViewInsetLeft+kTextViewInsetRight);
  
	CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
  
  NSString *text = [[self paddedSenderName:senderName] stringByAppendingString:message];
  
  CGRect boundingRect = [text boundingRectWithSize:maxSize
                                           options:
                         (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        attributes:[self textAttributes]
                                           context:nil];
  CGFloat textHeight = ceilf(boundingRect.size.height);
  
  // add the inset
  textHeight+=kTextViewInsetTop+kTextViewInsetBottom;
  
  return [super heightForContentHeight:textHeight];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateTextView {
  if (self.senderName!=nil && self.message!=nil) {
    NSString *text = [[[self class] paddedSenderName:self.senderName]
                      stringByAppendingString:self.message];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text
                                                          attributes:[[self class] textAttributes]];
    NSDictionary *senderAttr = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [attrText addAttributes:senderAttr range:NSMakeRange(0, self.senderName.length)];
    self.textView.attributedText = attrText;
    
    [self setNeedsLayout];  // layout the textView
    [self setNeedsDisplay]; // display the drawn bubble
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSDictionary *)textAttributes {
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
  return @{ NSFontAttributeName: [self font],
            NSParagraphStyleAttributeName: paragraphStyle};
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIFont *)font {
  return kFont;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)paddedSenderName:(NSString *)senderName {
  return [senderName stringByAppendingString:@"    "];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange {
  if ([self.delegate respondsToSelector:@selector(messageView:shouldInteractWithURL:inRange:)]) {
    return [self.delegate messageView:self shouldInteractWithURL:URL inRange:characterRange];
  }
  
  return NO;
}

@end
