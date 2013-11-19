//
//  TBComposingCellView.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 19/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
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