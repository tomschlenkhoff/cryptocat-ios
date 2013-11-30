//
//  TBMessageCell.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 07/11/13.
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

@protocol TBMessageCellDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBMessageCell : UITableViewCell

@property (nonatomic, weak) id <TBMessageCellDelegate> delegate;
@property (nonatomic, strong) NSString *senderName;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *warningMessage;
@property (nonatomic, assign, getter=isMeSpeaking) BOOL meSpeaking;
@property (nonatomic, assign) BOOL isErrorMessage;

+ (CGFloat)heightForCellWithSenderName:(NSString *)senderName
                                  text:(NSString *)text
                           warningText:(NSString *)warningText;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBMessageCellDelegate <NSObject>

- (BOOL)messageCell:(TBMessageCell *)cell
shouldInteractWithURL:(NSURL *)URL
            inRange:(NSRange)characterRange;

@end