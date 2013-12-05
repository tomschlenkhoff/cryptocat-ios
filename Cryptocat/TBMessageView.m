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
/*
 * This property is only used to determine the metrics of the senderName background frame.
 * This property is not used to actually display the senderName. It will be displayed as
 * part of the attributedText.
 */
- (void)setSenderName:(NSString *)senderName {
  _senderName = senderName;
  self.paddedSenderNameSize = [[[self class] paddedSenderName:senderName]
                               sizeWithAttributes:[[self class] textAttributes]];
  
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setAttributedText:(NSAttributedString *)attributedText {
  self.textView.attributedText = attributedText;
  
  [self setNeedsLayout];  // layout the textView
  [self setNeedsDisplay]; // display the drawn bubble
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSAttributedString *)attributedText {
  return self.textView.attributedText;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForAttributedText:(NSAttributedString *)attributedText maxWidth:(CGFloat)maxWidth {
  maxWidth-=(kTextViewInsetLeft+kTextViewInsetRight);
	CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);

  CGRect boundingRect = [attributedText boundingRectWithSize:maxSize
                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                     context:nil];
  CGFloat textHeight = ceilf(boundingRect.size.height);
  
  // add the inset
  textHeight+=kTextViewInsetTop+kTextViewInsetBottom;
  
  return [super heightForContentHeight:textHeight];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * This method concat the senderName and the message, apply the styling attributes, and replace
 * the smileys with images. The resulting attributedString is what's going to be displayed and used
 * for chat cell metrics.
 */
+ (NSAttributedString *)attributedStringForSenderName:(NSString *)senderName
                                              message:(NSString *)message {
  // concat the senderName + padding + message
  NSString *text = [[[self class] paddedSenderName:senderName]
                    stringByAppendingString:message];
  
  // create an attrString and add senderName specific attributes
  NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text
                                                         attributes:[[self class] textAttributes]];
  NSDictionary *senderAttr = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
  [attrText addAttributes:senderAttr range:NSMakeRange(0, senderName.length)];
  
  // detect smileys
  NSRange range = [text rangeOfString:@" :) "];
  if (range.location!=NSNotFound) {
    range.location+=1;
    range.length-=2;
    UIImage *image = [UIImage imageNamed:@"cat"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0.0, -2.0, 13.0, 13.0);
    NSAttributedString *attrStrImg = [NSAttributedString
                                      attributedStringWithAttachment:attachment];
    [attrText replaceCharactersInRange:range withAttributedString:attrStrImg];
  }

  return attrText;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

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
