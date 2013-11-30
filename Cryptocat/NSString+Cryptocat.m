//
//  NSString+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 26/09/13.
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

#import "NSString+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSString (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)tb_JSONObject {
  NSData *JSONData = [self dataUsingEncoding:NSUTF8StringEncoding];
  return [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tb_trim {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)tb_randomStringWithLength:(NSInteger)length {
  NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
  
  for (NSInteger i=0; i < length; i++) {
    NSUInteger index = arc4random() % [letters length];
    [randomString appendFormat: @"%C", [letters characterAtIndex:index]];
  }
  
  return randomString;
}

@end
