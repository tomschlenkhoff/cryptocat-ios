//
//  TBBuddiesViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 17/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBBuddiesViewController.h"
#import "TBBuddyViewController.h"
#import "TBBuddy.h"

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
  // buddy
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
