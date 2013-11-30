//
//  TBBuddiesViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 17/10/13.
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

#import "TBBuddiesViewController.h"
#import "TBBuddyViewController.h"
#import "TBBuddy.h"
#import "UIColor+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBuddiesViewController ()

- (IBAction)done:(id)sender;

- (TBBuddy *)buddyForIndexPath:(NSIndexPath *)indexPath;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBBuddiesViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter removeObserver:self
                           name:TBBuddyDidSignInNotification
                         object:nil];
  [defaultCenter removeObserver:self
                           name:TBBuddyDidSignOutNotification
                         object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.title = NSLocalizedString(@"Buddies", @"Buddies Screen Title");

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(buddiesListDidChange:)
                        name:TBBuddyDidSignInNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(buddiesListDidChange:)
                        name:TBBuddyDidSignOutNotification
                      object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // buddy info
  if ([segue.identifier isEqualToString:@"BuddySegueID"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    TBBuddyViewController *bvc = segue.destinationViewController;
    bvc.buddy = [self buddyForIndexPath:indexPath];
    if ([self.delegate
         respondsToSelector:@selector(buddiesViewController:didAskFingerprintsForBuddy:)]) {
      [self.delegate buddiesViewController:self didAskFingerprintsForBuddy:bvc.buddy];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Table view data source

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.buddies count] + 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"BuddyCellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                          forIndexPath:indexPath];
  
  if (indexPath.row==0) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([self.roomName isEqualToString:self.currentRoomName]) {
      cell.textLabel.textColor = [UIColor tb_buttonTitleColor];
    }
    else {
      cell.textLabel.textColor = [UIColor blackColor];
    }
    NSString *conversationRoomTitle = NSLocalizedString(@"Conversation",
                                                        @"Conversation Room Label");
    if (self.nbUnreadMessagesInRoom == 0) {
      cell.textLabel.text = conversationRoomTitle;
    }
    else {
      cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",
                             conversationRoomTitle, self.nbUnreadMessagesInRoom];
    }
  }
  else {
    TBBuddy *buddy = [self buddyForIndexPath:indexPath];
    if ([buddy.fullname isEqualToString:self.currentRoomName]) {
      cell.textLabel.textColor = [UIColor tb_buttonTitleColor];
    }
    else {
      cell.textLabel.textColor = [UIColor blackColor];
    }

    NSInteger nbUnreadMessages = [[self.nbUnreadMessagesForBuddy objectForKey:buddy.fullname]
                                  integerValue];
    if (nbUnreadMessages==0) {
      cell.textLabel.text = buddy.nickname;
    }
    else {
      cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",
                             buddy.nickname, nbUnreadMessages];
    }
  }
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // conversation room
  if (indexPath.row==0) {
    if ([self.delegate respondsToSelector:@selector(buddiesViewController:didSelectRoomName:)]) {
      [self.delegate buddiesViewController:self didSelectRoomName:self.roomName];
    }
  }
  
  // buddy
  else {
    if ([self.delegate respondsToSelector:@selector(buddiesViewController:didSelectBuddy:)]) {
      TBBuddy *buddy = [self buddyForIndexPath:indexPath];
      [self.delegate buddiesViewController:self didSelectBuddy:buddy];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)done:(id)sender {
  if ([self.delegate respondsToSelector:@selector(buddiesViewControllerHasFinished:)]) {
    [self.delegate buddiesViewControllerHasFinished:self];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesListDidChange:(NSNotification *)notification {
  //TBBuddy *buddy = notification.object;
  [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (TBBuddy *)buddyForIndexPath:(NSIndexPath *)indexPath {
  return [self.buddies objectAtIndex:indexPath.row-1];
}

@end
