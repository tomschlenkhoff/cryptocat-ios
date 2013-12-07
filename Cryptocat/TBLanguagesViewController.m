//
//  TBLanguagesViewController.m
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

#import "TBLanguagesViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBLanguagesViewController ()

@property (nonatomic, strong) NSArray *languagesKeys;
@property (nonatomic, strong) NSString *currentLanguageKey;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBLanguagesViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark LifeCycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

  self.currentLanguageKey = [TBUserLanguageHelper sharedUserLanguageHelper].currentLanguage;
  self.languagesKeys = [[NSBundle mainBundle] localizations];
  
  self.title = TBLocalizedString(@"Languages", @"Languages Selector Screen Title");
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.languagesKeys count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"LanguageCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                          forIndexPath:indexPath];
  
  NSString *language = [self.languagesKeys objectAtIndex:indexPath.row];
  cell.textLabel.text = [TBUserLanguageHelper languageNameForKey:language];
  if ([language isEqualToString:self.currentLanguageKey]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }
  else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *lg = [self.languagesKeys objectAtIndex:indexPath.row];
  [TBUserLanguageHelper sharedUserLanguageHelper].currentLanguage = lg;

  if ([self.delegate respondsToSelector:@selector(languagesController:didSelectLanguage:)]) {
    [self.delegate languagesController:self didSelectLanguage:lg];
  }
}

@end
