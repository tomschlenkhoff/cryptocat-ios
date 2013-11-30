//
//  TBFingerprintCell.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 13/11/13.
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

#import "TBFingerprintCell.h"

#define kPaddingH 7.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBFingerprintCell ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBFingerprintCell

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self=[super initWithCoder:aDecoder]) {
    _label = [[UILabel alloc] init];
    _label.font = [UIFont fontWithName:@"Courier New" size:11.5];
    [self.contentView addSubview:_label];
    
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.hidesWhenStopped = YES;
    [_spinner startAnimating];
    [self.contentView addSubview:_spinner];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  // label
  CGRect labelFrame = self.contentView.frame;
  labelFrame.origin.x+=kPaddingH;
  labelFrame.size.width-=(2*kPaddingH);
  self.label.frame = labelFrame;
  
  // spinner
  CGRect spinnerFrame = self.spinner.frame;
  spinnerFrame.origin.x = kPaddingH;
  spinnerFrame.origin.y = (self.contentView.frame.size.height - spinnerFrame.size.height) / 2;
  self.spinner.frame = spinnerFrame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFingerprint:(NSString *)fingerprint {
  if (fingerprint!=nil && ![fingerprint isEqualToString:@""]) {
    [self.spinner stopAnimating];
  }
  self.label.text = fingerprint;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)fingerprint {
  return self.label.text;
}

@end
