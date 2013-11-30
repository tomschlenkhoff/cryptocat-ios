//
//  TBPresenceCell.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 21/11/13.
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

#import "TBPresenceCell.h"
#import "TBPresenceView.h"

#define kPaddingTop     0.0
#define kPaddingBottom  25.0
#define kPaddingLeft    11.0
#define kPaddingRight   120.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBPresenceCell ()

@property (nonatomic, strong) TBPresenceView *presenceView;
@property (nonatomic, readonly) NSDateFormatter *dateFormatter;

@end

static NSDateFormatter *_dateFormatter = nil;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBPresenceCell

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    _presenceView = [[TBPresenceView alloc] init];
    [self.contentView addSubview:_presenceView];
    
    _isSignIn = YES;
    _timestamp = nil;
    _username = nil;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect frame = self.contentView.frame;
  frame.origin.x+=kPaddingLeft;
  frame.origin.y+=kPaddingTop;
  frame.size.width-=(kPaddingLeft+kPaddingRight);
  frame.size.height-=(kPaddingTop+kPaddingBottom);
  
  self.presenceView.frame = frame;
  [self.presenceView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  self.presenceView.backgroundColor = backgroundColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)height {
  return 49.0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setIsSignIn:(BOOL)isSignIn {
  _isSignIn = isSignIn;
  self.presenceView.isSignIn = isSignIn;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTimestamp:(NSDate *)timestamp {
  _timestamp = timestamp;
  self.presenceView.timestamp = [self.dateFormatter stringFromDate:timestamp];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setUsername:(NSString *)username {
  _username = username;
  self.presenceView.username = username;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDateFormatter *)dateFormatter {
  if (_dateFormatter==nil) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"HH:mm"];
  }
  
  return _dateFormatter;
}

@end
