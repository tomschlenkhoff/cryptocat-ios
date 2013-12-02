//
//  TBBubbleView.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 07/11/13.
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

#import "TBBubbleView.h"

#define kLineWidth      2.0
#define kShadowOffsetX  1.5
#define kArrowHeight    12.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleView ()

+ (UIEdgeInsets)contentInsets;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBubbleView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor greenColor];
    _bubbleColor = [UIColor redColor];
    _insideColor = [UIColor whiteColor];
    _shouldAlignTailToLeft = YES;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)innerRect {
  return UIEdgeInsetsInsetRect(self.bounds, [[self class] contentInsets]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  // view dimensions
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = rect.size.width;
  CGFloat height = rect.size.height;
  
  // constant values
  CGFloat lineWidth = kLineWidth;
  CGFloat shadowOffsetX = kShadowOffsetX;
  CGFloat shadowOffsetY = 3.5;
  CGSize cornerRadius = CGSizeMake(4.0, 4.0);
  CGFloat arrowWidth = 16.0;
  CGFloat arrowHeight = kArrowHeight;
  CGFloat arrowCenterDistanceFromBorder = 34.5;
  
  // bubble
  CGFloat bubbleX = x + (lineWidth/2);
  CGFloat bubbleY = y + (lineWidth/2);
  CGFloat bubbleWidth = width - shadowOffsetX - lineWidth;
  CGFloat bubbleHeight = height - arrowHeight - (lineWidth/2);
  
  // shadow
  CGFloat shadowX = bubbleX + shadowOffsetX;
  CGFloat shadowY = bubbleY + shadowOffsetY;
  CGFloat shadowWidth = bubbleWidth;
  CGFloat shadowHeight = bubbleHeight - 2.0;
  
  // arrow
  CGFloat arrowBottomX = 0;
  if (self.shouldAlignTailToLeft) {
    arrowBottomX = x + arrowCenterDistanceFromBorder;
  }
  else {
    arrowBottomX = x + width - arrowCenterDistanceFromBorder;
  }
  
  CGFloat arrowBottomY = y + height;
  CGFloat arrowTopY = arrowBottomY - arrowHeight;
  CGFloat arrowTopXLeft = arrowBottomX - (arrowWidth/2);
  CGFloat arrowTopXRight = arrowBottomX + (arrowWidth/2);
  
  // -- Shadow Drawing
  CGRect shadowRect = CGRectMake(shadowX, shadowY, shadowWidth, shadowHeight);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:shadowRect
                                                   byRoundingCorners:UIRectCornerTopLeft |
                                                                      UIRectCornerBottomLeft |
                                                                      UIRectCornerBottomRight
                                                         cornerRadii:cornerRadius];
  [self.bubbleColor setFill];
  [shadowPath fill];
  [self.bubbleColor setStroke];
  shadowPath.lineWidth = lineWidth;
  [shadowPath stroke];
  
  // -- Bubble Frame Drawing
  CGRect bubbleRect = CGRectMake(bubbleX, bubbleY, bubbleWidth, bubbleHeight);
  UIBezierPath *bubbleFramePath = [UIBezierPath bezierPathWithRoundedRect:bubbleRect
                                                        byRoundingCorners:UIRectCornerTopLeft |
                                                                           UIRectCornerBottomLeft |
                                                                           UIRectCornerBottomRight
                                                              cornerRadii:cornerRadius];
  [self.insideColor setFill];
  [bubbleFramePath fill];
  [self.bubbleColor setStroke];
  bubbleFramePath.lineWidth = lineWidth;
  [bubbleFramePath stroke];
  
  // -- Arrow Drawing
  UIBezierPath* arrowPath = [UIBezierPath bezierPath];
  [arrowPath moveToPoint: CGPointMake(arrowBottomX, arrowBottomY)];
  [arrowPath addLineToPoint: CGPointMake(arrowTopXRight, arrowTopY)];
  [arrowPath addLineToPoint: CGPointMake(arrowTopXLeft, arrowTopY)];
  [arrowPath closePath];
  arrowPath.miterLimit = 4;
  
  arrowPath.usesEvenOddFillRule = YES;
  
  [self.bubbleColor setFill];
  [arrowPath fill];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForContentHeight:(CGFloat)contentHeight {
  UIEdgeInsets contentInset = [self contentInsets];
  return contentHeight+contentInset.top+contentInset.bottom;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIEdgeInsets)contentInsets {
  return UIEdgeInsetsMake(kLineWidth, kLineWidth, kArrowHeight+1, kLineWidth + kShadowOffsetX);
}

@end