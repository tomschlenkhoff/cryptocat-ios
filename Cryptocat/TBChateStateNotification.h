//
//  TBChateStateNotification.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 15/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBBuddy.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChateStateNotification : NSObject

@property (nonatomic, strong) TBBuddy *sender;
@property (nonatomic, readonly) BOOL isComposingNotification;
@property (nonatomic, readonly) BOOL isPausedNotification;
@property (nonatomic, readonly) BOOL isActiveNotification;

+ (TBChateStateNotification *)composingNotification;
+ (TBChateStateNotification *)pausedNotification;
+ (TBChateStateNotification *)activeNotification;

@end
