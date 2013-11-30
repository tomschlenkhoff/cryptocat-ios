//
//  UIColor+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 05/11/13.
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

#import "UIColor+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UIColor (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIColor *)tb_backgroundColor {
  return [UIColor colorWithRed:0.761 green:0.894 blue:0.957 alpha:1.000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIColor *)tb_tableViewSectionTitleColor {
  return [UIColor colorWithRed:0.435 green:0.624 blue:0.784 alpha:1.000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIColor *)tb_tableViewCellTextColor {
  return [UIColor colorWithWhite:0.443 alpha:1.000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIColor *)tb_buttonTitleColor {
  return [UIColor colorWithRed:0.435 green:0.624 blue:0.784 alpha:1.000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIColor *)tb_navigationBarColor {
  return [UIColor colorWithRed:0.082 green:0.075 blue:0.145 alpha:1.000];
}

@end
