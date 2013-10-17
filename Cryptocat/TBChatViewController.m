//
//  TBChatViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBChatViewController.h"
#import "TBXMPPMessagesHandler.h"
#import "TBBuddiesViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController () <
  UITableViewDataSource,
  UITableViewDelegate,
  TBBuddiesViewControllerDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) NSMutableDictionary *messagesForConversation;
@property (nonatomic, strong) NSString *currentRoomName;

- (void)startObservingKeyboard;
- (void)stopObservingKeyboard;
- (IBAction)sendMessage:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBChatViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
	
  self.title = self.roomName;
  self.currentRoomName = self.roomName;
  
  self.messagesForConversation = [NSMutableDictionary dictionary];
  [self.messagesForConversation setObject:[NSMutableArray array] forKey:self.roomName];
  
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupMessage:)
                        name:TBDidReceiveGroupChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateMessage:)
                        name:TBDidReceivePrivateChatMessageNotification
                      object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self startObservingKeyboard];
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [self stopObservingKeyboard];
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // -- buddies
  if ([segue.identifier isEqualToString:@"BuddiesSegueID"]) {
    UINavigationController *nc = segue.destinationViewController;
    TBBuddiesViewController *bvc = (TBBuddiesViewController *)nc.topViewController;
    bvc.delegate = self;
    bvc.roomName = self.roomName;
    bvc.usernames = self.usernames;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellID = @"cellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellID];
  }

  NSMutableArray *messages = [self.messagesForConversation objectForKey:self.currentRoomName];
  cell.textLabel.text = [messages objectAtIndex:indexPath.row];
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *messages = [self.messagesForConversation objectForKey:self.currentRoomName];
  return [messages count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupMessage:(NSNotification *)notification {
  NSString *roomName = notification.object;
  NSString *message = [notification.userInfo objectForKey:@"message"];
  NSString *sender = [notification.userInfo objectForKey:@"sender"];
  
  NSString *receivedMessage = [NSString stringWithFormat:@"%@ : %@", sender, message];
  [[self.messagesForConversation objectForKey:roomName] addObject:receivedMessage];
  [self.tableView reloadData];
  TBLOG(@"-- received message in %@ from %@: %@", roomName, sender, message);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateMessage:(NSNotification *)notification {
  NSString *message = [notification.userInfo objectForKey:@"message"];
  if ([message isEqualToString:@""]) return ;
  
  NSString *roomName = notification.object;
  
  roomName = [roomName stringByReplacingOccurrencesOfString:@"cryptocatdev@conference.crypto.cat/"
                                                 withString:@""];
  
  NSString *sender = roomName;
  NSString *receivedMessage = [NSString stringWithFormat:@"%@ : %@", sender, message];
  
  if ([self.messagesForConversation objectForKey:roomName]==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:roomName];
  }
  
  [[self.messagesForConversation objectForKey:roomName] addObject:receivedMessage];
  [self.tableView reloadData];
  TBLOG(@"-- received private message from %@: %@", sender, message);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = self.tableView.contentInset;
  contentInsets.bottom+=keyboardSize.height;
  
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;
  
  CGRect toolbarFrame = self.toolbarView.frame;
  toolbarFrame.origin.y-=keyboardSize.height;

  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];

  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  self.toolbarView.frame = toolbarFrame;
  
  [UIView commitAnimations];
  // end animation
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillBeHidden:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = self.tableView.contentInset;
  contentInsets.bottom-=keyboardSize.height;
  
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;

  CGRect toolbarFrame = self.toolbarView.frame;
  toolbarFrame.origin.y+=keyboardSize.height;
  self.toolbarView.frame = toolbarFrame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startObservingKeyboard {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopObservingKeyboard {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)sendMessage:(id)sender {
  NSString *message = self.textField.text;
  [[self.messagesForConversation objectForKey:self.currentRoomName] addObject:message];
  [self.tableView reloadData];
  self.textField.text = @"";
  
  // group chat message
  if ([self.roomName isEqualToString:self.currentRoomName]) {
    if ([self.delegate respondsToSelector:@selector(chatViewController:didAskToSendMessage:)]) {
      [self.delegate chatViewController:self didAskToSendMessage:message];
    }
  }
  // private chat message
  else {
    if ([self.delegate
         respondsToSelector:@selector(chatViewController:didAskToSendMessage:toUser:)]) {
      NSString *recipient = [NSString stringWithFormat:
                             @"cryptocatdev@conference.crypto.cat/%@", self.currentRoomName];
      [self.delegate chatViewController:self
                    didAskToSendMessage:message
                                 toUser:recipient];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBBuddiesViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewControllerHasFinished:(TBBuddiesViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
        didSelectConversation:(NSString *)conversation {
  self.title = conversation;
  self.currentRoomName = conversation;
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
  }];
}

@end
