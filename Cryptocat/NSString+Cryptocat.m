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
  uint8_t *randomBytes = malloc(length * sizeof(uint8_t));
  memset((void *)randomBytes, 0x0, length);
  
  int result = SecRandomCopyBytes(kSecRandomDefault, length, randomBytes);

  NSMutableString *hexValue = nil;
  
  // no error
  if (result==0) {
    // convert to hex string
    hexValue = [NSMutableString string];
    for (int i=0; i < length; i++) {
      [hexValue appendString:[NSString stringWithFormat:@"%02X", randomBytes[i]]];
    }
  }
  
  if (randomBytes) free(randomBytes);
  
  return hexValue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_containsString:(NSString *)string {
  NSRange range = [self rangeOfString:string];
  
  return range.location!=NSNotFound;
}

@end
