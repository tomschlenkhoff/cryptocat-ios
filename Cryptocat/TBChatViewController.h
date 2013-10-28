//
//  TBChatViewController.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TBChatViewControllerDelegate;
@class TBBuddy;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController : UIViewController

@property (nonatomic, weak) id <TBChatViewControllerDelegate> delegate;

@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSMutableSet *buddies;
@property (nonatomic, strong) TBBuddy *me;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBChatViewControllerDelegate <NSObject>

- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message;
- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message
                    toUser:(TBBuddy *)recipient;
- (void)chatViewControllerDidStartComposing:(TBChatViewController *)controller
                               forRecipient:(TBBuddy *)recipient;
- (void)chatViewControllerDidPauseComposing:(TBChatViewController *)controller
                               forRecipient:(TBBuddy *)recipient;
- (void)chatViewControllerDidEndComposing:(TBChatViewController *)controller
                             forRecipient:(TBBuddy *)recipient;
- (void)chatViewControllerDidAskToLogout:(TBChatViewController *)controller;
- (void)chatViewController:(TBChatViewController *)controller
didAskFingerprintsForBuddy:(TBBuddy *)buddy;

@end