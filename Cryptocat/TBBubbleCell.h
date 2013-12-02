//
//  TBBubbleCell.h
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

#import <UIKit/UIKit.h>

@protocol TBBubbleCellDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleCell : UITableViewCell

@property (nonatomic, weak) id <TBBubbleCellDelegate> delegate;
@property (nonatomic, strong) NSString *senderName;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *warningMessage;
@property (nonatomic, assign, getter=isMeSpeaking) BOOL meSpeaking;
@property (nonatomic, assign) BOOL isErrorMessage;
@property (nonatomic, readonly) CGSize paddedSenderNameSize;

+ (CGFloat)heightForSenderName:(NSString *)senderName
                       message:(NSString *)message
                warningMessage:(NSString *)warningMessage
                      maxWidth:(CGFloat)maxWidth;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBBubbleCellDelegate <NSObject>

- (BOOL)bubbleCell:(TBBubbleCell *)bubbleCell
shouldInteractWithURL:(NSURL *)URL
            inRange:(NSRange)characterRange;

@end