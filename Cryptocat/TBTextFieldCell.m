//
//  TBTextFieldCell.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 25/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBTextFieldCell.h"

#define kPaddingH                   15.0
#define kTextFieldHeight            30.0
#define kTextFieldTextColor         [UIColor blackColor]
#define kTextFieldDisabledTextColor [UIColor colorWithRed:0.775 green:0.772 blue:0.779 alpha:1.000]


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBTextFieldCell

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self=[super initWithCoder:aDecoder]) {
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_textField];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect frame = self.contentView.frame;
  frame.origin.x+=kPaddingH;
  frame.origin.y = roundf((frame.size.height - kTextFieldHeight) / 2);
  frame.size.width-=(2*kPaddingH);
  frame.size.height = kTextFieldHeight;
  
  self.textField.frame = frame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEnabled:(BOOL)enabled {
  self.textField.enabled = enabled;
  self.textField.textColor = enabled ? kTextFieldTextColor : kTextFieldDisabledTextColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isEnabled {
  return self.textField.isEnabled;
}

@end
