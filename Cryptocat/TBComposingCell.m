//
//  TBComposingCell.m
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

#import "TBComposingCell.h"

#define kSenderLabelPaddingRight  20.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBComposingCell ()

@property (nonatomic, strong) UIImageView *composingView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBComposingCell

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.meSpeaking = NO;
    self.isErrorMessage = NO;
    self.message = @" ";
    
    _composingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"typing-1"]];
    _composingView.animationImages = @[[UIImage imageNamed:@"typing-1"],
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
    _composingView.animationDuration = 1.6;
    [self.contentView addSubview:_composingView];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect composingViewFrame = self.composingView.frame;
  composingViewFrame.origin.x = self.paddedSenderNameSize.width + kSenderLabelPaddingRight;
  composingViewFrame.origin.y = 6.0;
  self.composingView.frame = composingViewFrame;
  
  [self.composingView startAnimating];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForMaxWidth:(CGFloat)maxWidth {
  return [super heightForSenderName:@"" message:@"" warningMessage:nil maxWidth:maxWidth];
}

@end
