//
//  TBBubbleView.h
//  ChatView
//
//  Created by Thomas Balthazar on 07/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleView : UIView

@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, strong) UIColor *insideColor;
@property (nonatomic, readonly) CGRect contentFrame;
@property (nonatomic, assign) BOOL shouldAlignTailToLeft;

+ (CGPoint)originForInsideArea;
+ (CGSize)sizeForContentSize:(CGSize)contentSize;

@end
