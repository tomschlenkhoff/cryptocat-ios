//
//  TBUserLanguageHelper.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 07/12/13.
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

#import "TBUserLanguageHelper.h"

#define TBUserLanguageKey @"TBUserLanguageKey"

static TBUserLanguageHelper *_languageHelper = nil;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBUserLanguageHelper ()

@property (nonatomic, strong) NSBundle *currentLanguageBundle;

+ (NSString *)defaultLanguage;
+ (NSBundle *)bundleForLanguage:(NSString *)language;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBUserLanguageHelper

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark LifeCycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
  if (self=[super init]) {
    _currentLanguage = [[self class] defaultLanguage];
    _currentLanguageBundle = [[self class] bundleForLanguage:_currentLanguage];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (TBUserLanguageHelper *)sharedUserLanguageHelper {
  if (_languageHelper==nil) {
    _languageHelper = [[TBUserLanguageHelper alloc] init];
  }
  
  return _languageHelper;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCurrentLanguage:(NSString *)currentLanguage {
  // -- save the current language to the user defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:currentLanguage forKey:TBUserLanguageKey];
  [defaults synchronize];

  _currentLanguage = [[self class] defaultLanguage];
  _currentLanguageBundle = [[self class] bundleForLanguage:currentLanguage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value {
	return [self.currentLanguageBundle localizedStringForKey:key value:value table:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)languageNameForKey:(NSString *)lgKey {
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:lgKey];
  NSString *localeStr = [locale displayNameForKey:NSLocaleIdentifier value:lgKey];
  NSString *uppercaseFirstLetter = [[localeStr substringToIndex:1] uppercaseString];
  return [localeStr stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                            withString:uppercaseFirstLetter];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSBundle *)bundleForLanguage:(NSString *)language {
  if (language==nil) {
    return [NSBundle mainBundle];
  }
  else {
    NSString *path = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
    
    return path==nil ? [NSBundle mainBundle] : [NSBundle bundleWithPath:path];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)defaultLanguage {
  // try to get the default language from user defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultLanguage = [defaults objectForKey:TBUserLanguageKey];
  
  // if not set by the user, get system default
  if (defaultLanguage==nil) {
    defaultLanguage = [[defaults objectForKey:@"AppleLanguages"] objectAtIndex:0];
    
    // check if the default system language is in the main bundle
    if (![[[NSBundle mainBundle] localizations] containsObject:defaultLanguage]) {
      defaultLanguage = [[[NSBundle mainBundle] localizations] objectAtIndex:0];
    }
  }

  return defaultLanguage;
}

@end