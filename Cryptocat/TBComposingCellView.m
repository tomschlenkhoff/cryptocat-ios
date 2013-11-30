//
//  TBComposingCellView.m
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

#import "TBComposingCellView.h"

#define kSenderLabelPaddingRight  7.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBComposingCellView ()

@property (nonatomic, strong) UIImageView *imageView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBComposingCellView

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  if (self=[super initWithFrame:frame]) {
    _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"typing-1"]];
    _imageView.animationImages = @[[UIImage imageNamed:@"typing-1"],
                                   [UIImage imageNamed:@"typing-2"],
                                   [UIImage imageNamed:@"typing-3"],
                                   [UIImage imageNamed:@"typing-4"],
                                   [UIImage imageNamed:@"typing-5"],
                                   [UIImage imageNamed:@"typing-6"],
                                   [UIImage imageNamed:@"typing-7"],
                                   [UIImage imageNamed:@"typing-1"],  // 8 same as 1
                                   [UIImage imageNamed:@"typing-9"],
                                   [UIImage imageNamed:@"typing-6"],  // 10 same as 6
                                   [UIImage imageNamed:@"typing-11"],
                                   [UIImage imageNamed:@"typing-12"],
                                   [UIImage imageNamed:@"typing-13"],
                                   [UIImage imageNamed:@"typing-3"],  // 14 same as 3
                                   [UIImage imageNamed:@"typing-15"],
                                   [UIImage imageNamed:@"typing-16"]];
    _imageView.animationDuration = 1.6;
    [self addSubview:_imageView];
    
    self.meSpeaking = NO;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect senderLabelBackgroundFrame = self.senderLabelBackground.frame;
  senderLabelBackgroundFrame.size.height+=1.0;
  self.senderLabelBackground.frame = senderLabelBackgroundFrame;

  CGRect imageViewFrame = self.imageView.frame;
  imageViewFrame.origin.x = senderLabelBackgroundFrame.origin.x +
                            senderLabelBackgroundFrame.size.width + kSenderLabelPaddingRight;
  imageViewFrame.origin.y = 6.0;  self.imageView.frame = imageViewFrame;

  [self.imageView startAnimating];
}

@end