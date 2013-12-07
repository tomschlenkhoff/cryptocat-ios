//
//  TBMeViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 24/10/13.
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

#import "TBMeViewController.h"
#import "TBBuddy.h"
#import "TBFingerprintCell.h"
#import "TBButtonCell.h"
#import "UIColor+Cryptocat.h"
#import <MobileCoreServices/UTCoreTypes.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBMeViewController ()

@property (weak, nonatomic) IBOutlet TBFingerprintCell *groupFingerprintCell;
@property (weak, nonatomic) IBOutlet TBFingerprintCell *privateFingerprintCell;
@property (weak, nonatomic) IBOutlet TBButtonCell *logoutCell;

- (IBAction)done:(id)sender;
- (void)logout;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBMeViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [self.me removeObserver:self forKeyPath:@"groupChatFingerprint"];
  [self.me removeObserver:self forKeyPath:@"chatFingerprint"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = TBLocalizedString(@"Me", @"Me Screen Title");
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

  self.groupFingerprintCell.fingerprint = self.me.groupChatFingerprint;
  self.privateFingerprintCell.fingerprint = self.me.chatFingerprint;
  self.logoutCell.title = TBLocalizedString(@"Logout", @"Logout Button Title");
  self.logoutCell.titleColor = [UIColor tb_buttonTitleColor];
  
  [self.me addObserver:self forKeyPath:@"groupChatFingerprint" options:0 context:NULL];
  [self.me addObserver:self forKeyPath:@"chatFingerprint" options:0 context:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object==self.me) {
    self.groupFingerprintCell.fingerprint = self.me.groupChatFingerprint;
    self.privateFingerprintCell.fingerprint = self.me.chatFingerprint;
    [self.tableView reloadData];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)done:(id)sender {
  if ([self.delegate respondsToSelector:@selector(meViewControllerHasFinished:)]) {
    [self.delegate meViewControllerHasFinished:self];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)logout {
  if ([self.delegate respondsToSelector:@selector(meViewControllerDidAskToLogout:)]) {
    [self.delegate meViewControllerDidAskToLogout:self];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // logout
  if (indexPath.section==2) {
    return indexPath;
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // logout
  if (indexPath.section==2) {
    [self logout];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  // logout
  if (indexPath.section==2) {
    return YES;
  }
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView
shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
  // fingerprints
  if (indexPath.section==0 || indexPath.section==1) {
    TBFingerprintCell *cell = (TBFingerprintCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.fingerprint!=nil) {
      return YES;
    }
    else {
      return NO;
    }
  }
  else {
    return NO;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView
 canPerformAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender {
  if (action==@selector(copy:)) {
    return YES;
  }
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView
    performAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender {
  TBFingerprintCell *cell = (TBFingerprintCell *)[tableView cellForRowAtIndexPath:indexPath];
  
  if (cell.fingerprint!=nil) {
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    [gpBoard setValue:cell.fingerprint forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (section==0) {
    return TBLocalizedString(@"Group Fingerprint", @"Group Fingerprint Section Title");
  }
  else if (section==1) {
    return TBLocalizedString(@"Private Fingerprint", @"Private Fingerprint Section Title");
  }
  
  return nil;
}

@end
