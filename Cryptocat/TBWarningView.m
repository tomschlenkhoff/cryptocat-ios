//
//  TBWarningView.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 28/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBWarningView.h"

#define kFont       [UIFont fontWithName:@"Monda-Regular" size:10.0]
#define kTextColor  [UIColor whiteColor]

#define kPaddingTop     0.0
#define kPaddingBottom  3.0
#define kPaddingLeft    0.0
#define kPaddingRight   0.0

#define kTextPaddingLeft    5.0
#define kTextPaddingRight   5.0
#define kTextPaddingTop     3.0
#define kTextPaddingBottom  3.0

#define kMaxWidthPortrait       	296.0
#define kMaxWidthLandscape      	437.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBWarningView ()

+ (CGSize)textSizeForText:(NSString *)text;
+ (NSDictionary *)textAttributes;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBWarningView

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor greenColor];    
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  TBLOG(@"-- drawRect : %@", NSStringFromCGRect(rect));
  
  // colors
  UIColor *bubbleColor = [UIColor redColor];
  
  // frames
  CGRect bubbleFrame = rect;
  bubbleFrame.size.width-=(kPaddingLeft+kPaddingRight);
  bubbleFrame.size.height-=(kPaddingTop+kPaddingBottom);
  bubbleFrame.origin.x+=kPaddingLeft;
  bubbleFrame.origin.y+=kPaddingTop;
  
  CGRect textFrame = bubbleFrame;
  textFrame.origin.x+=kTextPaddingLeft;
  textFrame.size.width-=(kTextPaddingLeft+kTextPaddingRight);
  textFrame.origin.y+=kTextPaddingTop;
  textFrame.size.height-=(kTextPaddingTop+kTextPaddingBottom);
  
  // -- draw bubble
  UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:bubbleFrame
                                                             byRoundingCorners:
                                        UIRectCornerTopLeft | UIRectCornerTopRight
                                                                   cornerRadii: CGSizeMake(4, 4)];
  [roundedRectanglePath closePath];
  [bubbleColor setFill];
  [roundedRectanglePath fill];
  [bubbleColor setStroke];
  roundedRectanglePath.lineWidth = 1;
  [roundedRectanglePath stroke];
  
  // -- draw text
  [self.message drawInRect:textFrame withAttributes:[[self class] textAttributes]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)sizeForText:(NSString *)text {
  CGSize textSize = [self textSizeForText:text];
  textSize.height+=kTextPaddingTop+kTextPaddingBottom+kPaddingTop+kPaddingBottom;
  
  return textSize;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)textSizeForText:(NSString *)text {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat maxWidth = isPortrait ? kMaxWidthPortrait : kMaxWidthLandscape;
  
  maxWidth-=(kPaddingLeft+kPaddingRight+kTextPaddingLeft+kTextPaddingRight);
  
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
  return @{ NSFontAttributeName: kFont,
            NSForegroundColorAttributeName: kTextColor,
            NSParagraphStyleAttributeName: paragraphStyle};
}

@end
