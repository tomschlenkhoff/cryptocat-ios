//
//  TBBubbleCellView.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 19/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TBBubbleView.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleCellView : UIView

@property (nonatomic, strong) TBBubbleView *bubbleView;
@property (nonatomic, strong) UIView *senderLabelBackground;
@property (nonatomic, strong) UILabel *senderLabel;

@property (nonatomic, strong) NSString *senderName;
@property (nonatomic, assign, getter=isMeSpeaking) BOOL meSpeaking;
@property (nonatomic, assign) BOOL isWarningMessage;

+ (UIFont *)font;

@end
