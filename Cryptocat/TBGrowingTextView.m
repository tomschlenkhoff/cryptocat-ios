//
//  TBGrowingTextView.m
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

#import "TBGrowingTextView.h"

#define kDefaultFont       [UIFont systemFontOfSize:14.0f]
#define kAnimationDuration 0.15

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBGrowingTextView ()

@property (nonatomic, assign) CGFloat currentHeight;
@property (nonatomic, readonly) CGRect boundingRectForText;
@property (nonatomic, strong) NSCharacterSet *aNewLineCharSet;
@property (nonatomic, assign) CGFloat oneLineHeight;

- (CGRect)boundingRectForText:(NSString *)text;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBGrowingTextView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextViewTextDidChangeNotification
                                                object:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  if (self=[super initWithFrame:frame]) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _oneLineHeight = [self boundingRectForText:@"f"].size.height;
    _currentHeight = self.boundingRectForText.size.height;
    _maxNbLines = 0;
    _aNewLineCharSet = [NSCharacterSet newlineCharacterSet];
    
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [[UIColor colorWithRed:0.839
                                              green:0.839
                                               blue:0.843
                                              alpha:1.000] CGColor];
    self.layer.cornerRadius = 6.0;
    
    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textDidChange:(NSNotification *)notification {
  CGFloat newHeight = self.boundingRectForText.size.height;

  // hack : if last char is a newLine, add a line to the new height
  NSUInteger textLength = [self.text length];
  unichar lastChar = [self.text characterAtIndex:textLength - 1];
  BOOL lastCharIsNewLine = [self.aNewLineCharSet characterIsMember:lastChar];
  if (lastCharIsNewLine) {
    newHeight+=self.oneLineHeight;
  }
  
  if (self.currentHeight==newHeight) return;
  
  CGFloat currentHeight = self.currentHeight;
  
  // limit the number of lines if needed
  if (self.maxNbLines > 0) {
    CGFloat oneLineHeight = [self boundingRectForText:@"f"].size.height;
    CGFloat maxHeight = oneLineHeight * self.maxNbLines;
    newHeight = (newHeight > maxHeight) ? maxHeight : newHeight;
  }
  
  // adapt the frame
  CGFloat heightOffset = newHeight - self.currentHeight;
  CGRect frame = self.frame;
  frame.size.height+=heightOffset;
  
  if ([self.growingDelegate
       respondsToSelector:@selector(growingTextView:willChangeFromHeight:toHeight:)]) {
    [self.growingDelegate growingTextView:self
                     willChangeFromHeight:self.currentHeight
                                 toHeight:newHeight];
  }
  
  [UIView animateWithDuration:kAnimationDuration
                   animations:^
  {
    self.frame = frame;
  }
                   completion:^(BOOL finished)
  {
    if ([self.growingDelegate
         respondsToSelector:@selector(growingTextView:didChangeFromHeight:toHeight:)]) {
      [self.growingDelegate growingTextView:self
                        didChangeFromHeight:currentHeight
                                   toHeight:newHeight];
    }
  }];
  
  self.currentHeight = newHeight;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Properties

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFont:(UIFont *)font {
  [super setFont:font];
  self.currentHeight = self.boundingRectForText.size.height;
  self.oneLineHeight = [self boundingRectForText:@"f"].size.height;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTypingAttributes:(NSDictionary *)typingAttributes {
  [super setTypingAttributes:typingAttributes];
  self.currentHeight = self.boundingRectForText.size.height;
  self.oneLineHeight = [self boundingRectForText:@"f"].size.height;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setText:(NSString *)text {
  [super setText:text];
  [self textDidChange:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)boundingRectForText {
  return [self boundingRectForText:self.text];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)boundingRectForText:(NSString *)text {
  CGFloat maxWidth = self.frame.size.width - (2 * self.textContainer.lineFragmentPadding);
  CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
  return [text boundingRectWithSize:maxSize
                            options:
          (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                         attributes:self.typingAttributes
                            context:nil];
}

@end
