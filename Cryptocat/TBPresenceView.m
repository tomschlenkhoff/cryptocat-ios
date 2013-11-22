//
//  TBPresenceView.m
//  ChatView
//
//  Created by Thomas Balthazar on 21/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBPresenceView.h"

#define kTimestampFont          [UIFont fontWithName:@"Monda-Regular" size:10.0]
#define kUsernameFont           [UIFont fontWithName:@"Monda-Regular" size:14.0]
#define kFontColor              [UIColor whiteColor]
#define kSignInBubbleColor      [UIColor colorWithRed:0.592 green:0.808 blue:0.925 alpha:1.000]
#define kSignInTimeStampColor   [UIColor colorWithRed:0.475 green:0.647 blue:0.741 alpha:1.000]
#define kSignOutBubbleColor     [UIColor colorWithWhite:0.855 alpha:1.000]
#define kSignOutTimeStampColor  [UIColor colorWithWhite:0.682 alpha:1.000]

static NSDictionary *_usernameFontAttributes = nil;
static NSDictionary *_timestampFontAttributes = nil;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBPresenceView ()

@property (nonatomic, readonly) NSDictionary *usernameFontAttributes;
@property (nonatomic, readonly) NSDictionary *timestampFontAttributes;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBPresenceView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  if (self=[super initWithFrame:frame]) {
    self.backgroundColor = [UIColor blackColor];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  // colors
  UIColor *bubbleColor = self.isSignIn ? kSignInBubbleColor : kSignOutBubbleColor;
  UIColor *timestampBgColor = self.isSignIn ? kSignInTimeStampColor : kSignOutTimeStampColor;
  
  // sign in/out text
  NSString *actionText = self.isSignIn ? @"+ " : @"- ";
  
  // frames
  CGRect bubbleFrame = rect;
  CGRect timestampFrame = rect;
  timestampFrame.origin.x+=5.0;
  timestampFrame.size.width = 40.0;
  
  CGFloat timeStampLineHeight = kTimestampFont.lineHeight;
  CGFloat timeStampTopInset = roundf((bubbleFrame.size.height - timeStampLineHeight) / 2) - 1;
  CGFloat usernameLineHeight = kUsernameFont.lineHeight;
  CGFloat usernameTopInset = roundf((bubbleFrame.size.height - usernameLineHeight) / 2) - 2;

  CGRect timestampTextFrame = CGRectInset(timestampFrame, 0, timeStampTopInset);
  CGRect usernameTextFrame = CGRectInset(bubbleFrame, 0, usernameTopInset);
  usernameTextFrame.origin.x+=timestampFrame.origin.x + timestampFrame.size.width + 5.0;
  usernameTextFrame.size.width-=timestampFrame.origin.x + timestampFrame.size.width + 5.0;
  
  // -- draw bubble
  UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:bubbleFrame
                                                             byRoundingCorners:UIRectCornerTopLeft |
                                                                            UIRectCornerBottomLeft |
                                                                           UIRectCornerBottomRight
                                                                   cornerRadii: CGSizeMake(4, 4)];
  [roundedRectanglePath closePath];
  [bubbleColor setFill];
  [roundedRectanglePath fill];
  [bubbleColor setStroke];
  roundedRectanglePath.lineWidth = 1;
  [roundedRectanglePath stroke];
  
  // --  draw timestamp rectangle
  UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect:timestampFrame];
  [timestampBgColor setFill];
  [rectanglePath fill];
  [timestampBgColor setStroke];
  rectanglePath.lineWidth = 1;
  [rectanglePath stroke];
  
  // -- draw the timestamp
  [self.timestamp drawInRect:timestampTextFrame
              withAttributes:self.timestampFontAttributes];
  
  // -- draw username
  [[actionText stringByAppendingString:self.username] drawInRect:usernameTextFrame
                                                  withAttributes:self.usernameFontAttributes];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Properties

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setIsSignIn:(BOOL)isSignIn {
  _isSignIn = isSignIn;
  [self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTimestamp:(NSString *)timestamp {
  _timestamp = timestamp;
  [self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setUsername:(NSString *)username {
  _username = username;
  [self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Properties

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)usernameFontAttributes {
  if (_usernameFontAttributes==nil) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];
    _usernameFontAttributes = @{NSFontAttributeName: kUsernameFont,
                                NSForegroundColorAttributeName: kFontColor,
                                NSParagraphStyleAttributeName: style};
  }
  
  return _usernameFontAttributes;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)timestampFontAttributes {
  if (_timestampFontAttributes==nil) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    _timestampFontAttributes = @{NSFontAttributeName: kTimestampFont,
                                 NSForegroundColorAttributeName: kFontColor,
                                 NSParagraphStyleAttributeName: style};
  }
  
  return _timestampFontAttributes;
}

@end
