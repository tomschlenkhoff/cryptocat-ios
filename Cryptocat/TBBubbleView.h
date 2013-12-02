//
//  TBBubbleView.h
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

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBubbleView : UIView

@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, strong) UIColor *insideColor;
@property (nonatomic, readonly) CGRect innerRect;
@property (nonatomic, assign) BOOL shouldAlignTailToLeft;

+ (CGFloat)heightForContentHeight:(CGFloat)contentHeight;

@end
