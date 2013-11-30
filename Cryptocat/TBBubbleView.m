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

#define kPaddingTop     2.0
#define kPaddingBottom  14.5
#define kPaddingLeft    7.0
#define kPaddingRight   7.0

#import "TBBubbleView.h"

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
- (CGRect)contentFrame {
  CGRect frame = self.frame;
  frame.origin.x+=kPaddingLeft;
  frame.origin.y+=kPaddingTop;
  frame.size.width-=(kPaddingLeft + kPaddingRight);
  frame.size.height-=(kPaddingTop + kPaddingBottom);
  
  return frame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGPoint)originForInsideArea {
  return CGPointMake(2.0, 2.0);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)sizeForContentSize:(CGSize)contentSize {
  CGFloat width = contentSize.width + kPaddingLeft + kPaddingRight;
  CGFloat height = contentSize.height + kPaddingTop + kPaddingBottom;
  
  return CGSizeMake(width, height);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  // view dimensions
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = rect.size.width;
  CGFloat height = rect.size.height;
  
  // constant values
  CGFloat lineWidth = 2.0;
  CGFloat shadowOffsetX = 1.5;
  CGFloat shadowOffsetY = 3.5;
  CGSize cornerRadius = CGSizeMake(4.0, 4.0);
  CGFloat arrowWidth = 16.0;
  CGFloat arrowHeight = 12.0;
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

@end