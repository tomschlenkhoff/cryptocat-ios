//
//  TBBuddyViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 28/10/13.
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

#import "TBBuddyViewController.h"
#import "TBBuddy.h"
#import "TBFingerprintCell.h"
#import <MobileCoreServices/UTCoreTypes.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBuddyViewController ()

@property (weak, nonatomic) IBOutlet TBFingerprintCell *groupFingerprintCell;
@property (weak, nonatomic) IBOutlet TBFingerprintCell *privateFingerprintCell;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBuddyViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [self.buddy removeObserver:self forKeyPath:@"groupChatFingerprint"];
  [self.buddy removeObserver:self forKeyPath:@"chatFingerprint"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = self.buddy.nickname;
  self.groupFingerprintCell.fingerprint = self.buddy.groupChatFingerprint;
  self.privateFingerprintCell.fingerprint = self.buddy.chatFingerprint;
  
  [self.buddy addObserver:self forKeyPath:@"groupChatFingerprint" options:0 context:NULL];
  [self.buddy addObserver:self forKeyPath:@"chatFingerprint" options:0 context:NULL];
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
  if (object==self.buddy) {
    self.groupFingerprintCell.fingerprint = self.buddy.groupChatFingerprint;
    self.privateFingerprintCell.fingerprint = self.buddy.chatFingerprint;
    [self.tableView reloadData];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
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
