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
+ (NSAttributedString *)replaceEmoticonsInAttributedText:
(NSMutableAttributedString *)attributedText;

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
  // make some arbitrary adjustment to prevent height that are not big enough
  maxWidth = floorf(maxWidth) - 2.0;
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
  
  return [self replaceEmoticonsInAttributedText:attrText];
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
+ (NSAttributedString *)replaceEmoticonsInAttributedText:
(NSMutableAttributedString *)attributedText {
  NSError *error;
  /*
   *  (\\s|^) : whitespace OR beginning of string
   *  (:|=)   : eyes, either : OR =
   *  (-?)    : nose, 1 OR 0
   *  (3)     : mouth, 3
   *  (\\s|$) : whitespace OR end of string
   */
  NSString *catPattern = @"(\\s|^)(:|=)(-?)(3)(\\s|$)?";
  NSString *cryPattern = @"(\\s|^)(:|=)(’|‘|')(-?)(\\)|3)(\\s|$)?";
  NSString *gaspPattern = @"(\\s|^)(:|=)(-?)(o)(\\s|$)?";
  NSString *grinPattern = @"(\\s|^)(:|=)(-?)(D)(\\s|$)?";
  NSString *sadPattern = @"(\\s|^)(:|=)(-?)(\\()(\\s|$)?";
  NSString *smilePattern = @"(\\s|^)(:|=)(-?)(\\))(\\s|$)?";
  NSString *squintPattern = @"(\\s|^)-_-(\\s|$)?";
  NSString *tonguePattern = @"(\\s|^)(:|=)(-?)(p)(\\s|$)?";
  NSString *unsurePattern = @"(\\s|^)(:|=)(-?)(\\/|s)(\\s|$)?";
  NSString *winkPattern = @"(\\s|^)(;)(-?)(\\))(\\s|$)?";
  NSString *winkTonguePattern = @"(\\s|^)(;)(-?)(p)(\\s|$)?";
  NSString *happyPattern = @"(\\s|^)(\\^)(_|\\.)(\\^)(\\s|$)?";
  NSString *shutPattern = @"(\\s|^)(:|=)(-?)(x)(\\s|$)?";
  
  NSDictionary *patternsForImages = @{  catPattern:         [UIImage imageNamed:@"cat"],
                                        cryPattern:         [UIImage imageNamed:@"cry"],
                                        gaspPattern:        [UIImage imageNamed:@"gasp"],
                                        grinPattern:        [UIImage imageNamed:@"grin"],
                                        sadPattern:         [UIImage imageNamed:@"sad"],
                                        smilePattern:       [UIImage imageNamed:@"smile"],
                                        squintPattern:      [UIImage imageNamed:@"squint"],
                                        tonguePattern:      [UIImage imageNamed:@"tongue"],
                                        unsurePattern:      [UIImage imageNamed:@"unsure"],
                                        winkPattern:        [UIImage imageNamed:@"wink"],
                                        winkTonguePattern:  [UIImage imageNamed:@"winkTongue"],
                                        happyPattern:       [UIImage imageNamed:@"happy"],
                                        shutPattern:        [UIImage imageNamed:@"shut"]
                                        };
  
  for (NSString *pattern  in patternsForImages) {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:&error];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [patternsForImages objectForKey:pattern];
    attachment.bounds = CGRectMake(0.0, -2.0, 13.0, 13.0);
    NSAttributedString *attrStrImg = [NSAttributedString
                                      attributedStringWithAttachment:attachment];
    
    [regex enumerateMatchesInString:attributedText.string
                            options:0
                              range:NSMakeRange(0, [attributedText.string length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags,
                                      BOOL *stop)
     {
       NSRange range = match.range;
       NSString *matchingString = [attributedText.string substringWithRange:range];
       
       // if the matchingString is " :) ", just replace ":)" by the image (leave the spaces)
       NSString *firstChar = [matchingString substringWithRange:NSMakeRange(0, 1)];
       NSString *lastChar = [matchingString
                             substringWithRange:NSMakeRange([matchingString length] -1, 1)];
       if ([firstChar isEqualToString:@" "]) {
         range.location+=1;
         range.length-=1;
       }
       if ([lastChar isEqualToString:@" "]) {
         range.length-=1;
       }
       
       [attributedText replaceCharactersInRange:range withAttributedString:attrStrImg];
     }];
  }
  
  
  return attributedText;
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
