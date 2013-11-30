//
//  TBMacros.h
//
//  Created by Thomas Balthazar on 30/07/13.
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

#ifdef DEBUG
  #define TBLOGMARK NSLog(@"== %s:%d(%p)", __PRETTY_FUNCTION__, __LINE__, self)
  #define TBLOG(...) NSLog(@"%s:%d(%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__])
  #define TBALOG(...) {NSLog(@"%s:%d(%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__]);[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__];}
#else
  #define TBLOGMARK do { } while (0)
  #define TBLOG(...) do { } while (0)
  #define TBALOG(...) NSLog(@"== %s:%d(%p)", __PRETTY_FUNCTION__, __LINE__, self)
#endif

#define TBASSERT(condition, ...) do { if (!(condition)) { TBALOG(__VA_ARGS__); }} while(0)