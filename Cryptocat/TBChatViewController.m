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
#import "TBMeViewController.h"
#import "TBMessage.h"
#import "TBBuddy.h"
#import "TBChateStateNotification.h"
#import "TBPresenceNotification.h"
#import "TBMessageCell.h"
#import "TBComposingCell.h"
#import "TBPresenceCell.h"
#import "TBChatToolbarView.h"
#import "UIColor+Cryptocat.h"
#import "SVWebViewController.h"

#define kPausedMessageTimer   5.0
#define kTableViewPaddingTop  17.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController () <
  UITableViewDataSource,
  UITableViewDelegate,
  TBBuddiesViewControllerDelegate,
  TBMeViewControllerDelegate,
  TBMessageCellDelegate,
  TBChatToolbarViewDelegate,
  UITextViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TBChatToolbarView *toolbarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarViewBottomConstraint;
@property (nonatomic, strong) NSMutableDictionary *messagesForConversation;
@property (nonatomic, strong) NSString *currentRoomName;
@property (nonatomic, strong) TBBuddy *currentRecipient;
@property (strong, readwrite) NSTimer *composingTimer;
@property (nonatomic, assign, getter=isTyping) BOOL typing;
@property (nonatomic, assign) NSUInteger nbUnreadMessagesInRoom;
@property (nonatomic, strong) NSMutableDictionary *nbUnreadMessagesForBuddy;
@property (nonatomic, strong) NSString *defaultNavLeftItemTitle;
@property (nonatomic, readonly) NSMutableArray *messages;

- (void)startObservingKeyboard;
- (void)stopObservingKeyboard;
- (IBAction)sendMessage:(id)sender;
- (BOOL)isInConversationRoom;
- (void)setupTypingTimer;
- (void)cancelTypingTimer;
- (void)didStartComposing;
- (void)didPauseComposing;
- (void)didEndComposing;
- (void)updateUnreadMessagesCounter;
- (void)scrollToLatestMessage;
- (void)addMessage:(id)message forKey:(NSString *)key;
- (void)removeChatStateNotification:(TBChateStateNotification *)chatStateNotification
                             forKey:(NSString *)key;
- (void)removeAllChatStateNotificationsForBuddy:(TBBuddy *)buddy forKey:(NSString *)key;
- (void)setChatTextViewStateEnabled:(BOOL)enabled;

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
- (void)dealloc {
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter removeObserver:self name:TBDidReceiveGroupChatMessageNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceivePrivateChatMessageNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceiveGroupChatStateNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceivePrivateChatStateNotification object:nil];
  [defaultCenter removeObserver:self name:TBBuddyDidSignInNotification object:nil];
  [defaultCenter removeObserver:self name:TBBuddyDidSignOutNotification object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self=[super initWithCoder:aDecoder]) {
    _typing = NO;
    _messagesForConversation = [NSMutableDictionary dictionary];
    _nbUnreadMessagesInRoom = 0;
    _nbUnreadMessagesForBuddy = [NSMutableDictionary dictionary];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	 
  self.defaultNavLeftItemTitle = NSLocalizedString(@"Buddies",
                                                   @"Buddies Button Title on Chat Screen");
  self.navigationItem.leftBarButtonItem.title = self.defaultNavLeftItemTitle;
  self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Me",
                                                                @"Me Button Title on Chat Screen");
  
  
  self.view.backgroundColor = [UIColor tb_backgroundColor];
  self.tableView.backgroundColor = self.view.backgroundColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.contentInset = UIEdgeInsetsMake(kTableViewPaddingTop, 0.0, 0.0, 0.0);

  self.toolbarView.delegate = self;
  self.toolbarView.textView.delegate = self;
  [self.toolbarView.sendButton addTarget:self
                                  action:@selector(sendMessage:)
                        forControlEvents:UIControlEventTouchUpInside];

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupMessage:)
                        name:TBDidReceiveGroupChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateMessage:)
                        name:TBDidReceivePrivateChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupStateNotification:)
                        name:TBDidReceiveGroupChatStateNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateStateNotification:)
                        name:TBDidReceivePrivateChatStateNotification
                      object:nil];
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
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self setNeedsStatusBarAppearanceUpdate];

  // the first time the view appears, after the loginVC is dismissed
  if (self.currentRoomName==nil) {
    self.currentRoomName = self.roomName;
    self.title = self.roomName;
    [self.tableView reloadData];
  }
  
  [self startObservingKeyboard];
  [self setChatTextViewStateEnabled:YES];
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
    bvc.currentRoomName = self.currentRoomName;
    bvc.buddies = self.buddies;
    bvc.nbUnreadMessagesInRoom = self.nbUnreadMessagesInRoom;
    bvc.nbUnreadMessagesForBuddy = self.nbUnreadMessagesForBuddy;
  }
  
  // -- me
  else if ([segue.identifier isEqualToString:@"MeSegueID"]) {
    UINavigationController *nc = segue.destinationViewController;
    TBMeViewController *mvc = (TBMeViewController *)nc.topViewController;
    mvc.delegate = self;
    mvc.me = self.me;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cleanupConversations {
  self.messagesForConversation = [NSMutableDictionary dictionary];
  [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  id message = [self.messages objectAtIndex:indexPath.row];

  // -- message cell
  if ([message isKindOfClass:[TBMessage class]]) {
    static NSString *messageCellID = @"MessageCellID";
    TBMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:messageCellID];
    if (cell == nil) {
      [tableView registerClass:[TBMessageCell class] forCellReuseIdentifier:messageCellID];
      cell = [[TBMessageCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:messageCellID];
    }

    TBMessage *msg = message;
    cell.senderName = msg.sender.nickname;
    cell.meSpeaking = [msg.sender isEqual:self.me];
    cell.isErrorMessage = msg.isErrorMessage;
    cell.message = msg.text;
    if (msg.isWarningMessage) {
      cell.warningMessage = msg.warningText;
    }
    else {
      cell.warningMessage = nil;
    }
    cell.backgroundColor = self.tableView.backgroundColor;
    cell.delegate = self;
    return cell;
  }
  
  // -- composing cell
  else if ([message isKindOfClass:[TBChateStateNotification class]]) {
    static NSString *chatStateCellID = @"ChatStateCellID";
    TBComposingCell *cell = [tableView dequeueReusableCellWithIdentifier:chatStateCellID];
    if (cell == nil) {
      [tableView registerClass:[TBComposingCell class] forCellReuseIdentifier:chatStateCellID];
      cell = [[TBComposingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:chatStateCellID];
    }

    TBChateStateNotification *csn = message;
    cell.senderName = csn.sender.nickname;
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
  }
  
  // -- presence cell
  else if ([message isKindOfClass:[TBPresenceNotification class]]) {
    static NSString *presenceCellID = @"PresenceCellID";
    TBPresenceCell *cell = [tableView dequeueReusableCellWithIdentifier:presenceCellID];
    if (cell == nil) {
      [tableView registerClass:[TBPresenceCell class] forCellReuseIdentifier:presenceCellID];
      cell = [[TBPresenceCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:presenceCellID];
    }
    
    TBPresenceNotification *pn = message;
    cell.username = pn.sender.nickname;
    cell.timestamp = pn.timestamp;
    cell.isSignIn = pn.isOnline;
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *messages = self.messages;
  return [messages count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  id message = [self.messages objectAtIndex:indexPath.row];
  
  // -- message
  if ([message isKindOfClass:[TBMessage class]]) {
    TBMessage *msg = (TBMessage *)message;
    return [TBMessageCell heightForCellWithSenderName:msg.sender.nickname
                                                 text:msg.text
                                          warningText:msg.warningText];
  }
  
  // -- chat state
  else if ([message isKindOfClass:[TBChateStateNotification class]]) {
    return [TBComposingCell height];
  }
  
  // -- presence
  else if ([message isKindOfClass:[TBPresenceNotification class]]) {
    return [TBPresenceCell height];
  }
  
  return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupMessage:(NSNotification *)notification {
  TBMessage *message = notification.object;
  NSError *error = [notification.userInfo objectForKey:@"error"];
  
  // -- this is an error message
  if (message==nil) {
    if (error!=nil &&
        [error.domain isEqualToString:TBErrorDomainGroupChatMessage] &&
        error.code==TBErrorCodeUnreadableMessage) {
      NSString *errorMessage = NSLocalizedString(@"Warning: You have received an unreadable \
message from %@. This may indicate an untrustworthy user or messages that \
failed to be received. You may also be running an outdated \
version of Cryptocat. Please check for updates.", @"Error Message Text");
      message = [[TBMessage alloc] init];
      message.sender = [error.userInfo objectForKey:TBErrorCodeUnreadableMessageSenderKey];
      message.text = [NSString stringWithFormat:errorMessage, message.sender.nickname];
      message.isErrorMessage = YES;
    }
  }
  
  // -- this is a message, that may contains errors
  else if (error!=nil &&
           [error.domain isEqualToString:@"TBErrorDomainGroupChatMessage"] &&
           error.code==TBErrorCodeMissingRecipients) {
    NSArray *missingRecipients = [error.userInfo objectForKey:TBErrorCodeMissingRecipientsKey];
    NSString *warningMessage = NSLocalizedString(@"Warning: this message was not sent to: %@",
                                  @"Warning message when a message is not sent to all recipients");
    NSString *missingRecipientsString = [missingRecipients componentsJoinedByString:@", "];
    message.warningText = [NSString stringWithFormat:warningMessage, missingRecipientsString];
  }
  
  if (message==nil) return;
  
  NSString *roomName = message.sender.roomName;
  
  [self addMessage:message forKey:roomName];
  
  if ([self isInConversationRoom]) {
    [self.tableView reloadData];
    [self scrollToLatestMessage];
  }
  else {
    self.nbUnreadMessagesInRoom+=1;
    [self updateUnreadMessagesCounter];
  }
  TBLOG(@"-- received message in %@ from %@: %@", roomName, message.sender.fullname, message.text);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateMessage:(NSNotification *)notification {
  TBMessage *message = notification.object;
  
  if ([message.text isEqualToString:@""]) return ;
  
  [self addMessage:message forKey:message.sender.fullname];
  
  if (![self isInConversationRoom] && [self.currentRecipient isEqual:message.sender]) {
    [self.tableView reloadData];
    [self scrollToLatestMessage];
  }
  else {
    NSString *buddyName = message.sender.fullname;
    NSInteger nbUnreadMessages = [[self.nbUnreadMessagesForBuddy objectForKey:buddyName]
                                  integerValue];
    nbUnreadMessages+=1;
    [self.nbUnreadMessagesForBuddy setObject:[NSNumber numberWithInteger:nbUnreadMessages]
                                      forKey:buddyName];
    [self updateUnreadMessagesCounter];
  }
  
  TBLOG(@"-- received private message from %@: %@", message.sender.fullname, message.text);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupStateNotification:(NSNotification *)notification {
  TBChateStateNotification *csn = notification.object;
  NSString *roomName = csn.sender.roomName;
  
  if ([csn isComposingNotification]) {
    [self removeAllChatStateNotificationsForBuddy:csn.sender forKey:roomName];
    [self addMessage:csn forKey:roomName];
  }
  else {
    [self removeChatStateNotification:csn forKey:roomName];
  }
  
  [self.tableView reloadData];
  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateStateNotification:(NSNotification *)notification {
  TBChateStateNotification *csn = notification.object;
  
  if ([csn isComposingNotification]) {
    [self removeAllChatStateNotificationsForBuddy:csn.sender forKey:csn.sender.fullname];
    [self addMessage:csn forKey:csn.sender.fullname];
  }
  else {
    [self removeChatStateNotification:csn forKey:csn.sender.fullname];
  }
  
  [self.tableView reloadData];
  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesListDidChange:(NSNotification *)notification {
  TBBuddy *buddy = notification.object;
  NSString *roomName = buddy.roomName;
  BOOL isOnline = [notification.name isEqualToString:TBBuddyDidSignInNotification];
  
  TBPresenceNotification *pn = [[TBPresenceNotification alloc] init];
  pn.sender = buddy;
  pn.online = isOnline;
  pn.timestamp = [NSDate date];
  
  // remove remaining typing notif since the user logged out
  if (!isOnline) {
    [self removeAllChatStateNotificationsForBuddy:buddy forKey:roomName];
  }
  
  [self addMessage:pn forKey:roomName];
  [self.tableView reloadData];
  [self scrollToLatestMessage];

  if ([self.currentRecipient isEqual:buddy]) {
    [self setChatTextViewStateEnabled:isOnline];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat keyboardHeight = isPortrait ? keyboardSize.height : keyboardSize.width;
  
  // get the animation info
  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];
  
  // update the toolbarView constraints
  self.toolbarViewBottomConstraint.constant = keyboardHeight;
  
  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  [self.view layoutIfNeeded];
  
  [UIView commitAnimations];
  // end animation

  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillBeHidden:(NSNotification *)notification {
  // update the toolbarView constraints
  self.toolbarViewBottomConstraint.constant = 0; //keyboardHeight;
  
  [self.view layoutIfNeeded];
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
- (BOOL)isInConversationRoom {
  return [self.roomName isEqualToString:self.currentRoomName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setupTypingTimer {
  [self cancelTypingTimer];
  TBLOG(@"-- starting the timer");
  self.composingTimer = [NSTimer scheduledTimerWithTimeInterval:kPausedMessageTimer
                                                         target:self
                                                       selector:@selector(typingDidPause)
                                                       userInfo:nil
                                                        repeats:NO];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancelTypingTimer {
  if (self.composingTimer) {
    TBLOG(@"-- cancelling the timer");
    [self.composingTimer invalidate];
    self.composingTimer = nil;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didStartComposing {
  self.typing = YES;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidStartComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidStartComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didPauseComposing {
  self.typing = NO;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidPauseComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidPauseComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didEndComposing {
  self.typing = NO;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidEndComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidEndComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateUnreadMessagesCounter {
  NSInteger totalUnreadMSGCount = self.nbUnreadMessagesInRoom;
  TBLOG(@"-- self.nbUnreadMessagesInRoom : %d", self.nbUnreadMessagesInRoom);
  for (NSString *buddyName in self.nbUnreadMessagesForBuddy) {
    NSNumber *nbUnreadMessages = [self.nbUnreadMessagesForBuddy objectForKey:buddyName];
    totalUnreadMSGCount+=[nbUnreadMessages integerValue];
    TBLOG(@"-- nb unread msgs for %@ : %d", buddyName, [nbUnreadMessages integerValue]);
  }
  
  if (totalUnreadMSGCount==0) {
    self.navigationItem.leftBarButtonItem.title = self.defaultNavLeftItemTitle;
  }
  else {
    self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@"%@ (%d)",
                                                   self.defaultNavLeftItemTitle,
                                                   totalUnreadMSGCount];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollToLatestMessage {
  NSUInteger nbMessages = [self.messages count];
  if (nbMessages==0) return;
  
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nbMessages-1 inSection:0];
  [self.tableView scrollToRowAtIndexPath:indexPath
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableArray *)messages {
  return [self.messagesForConversation objectForKey:self.currentRoomName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addMessage:(id)message forKey:(NSString *)key {
  if ([self.messagesForConversation objectForKey:key]==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:key];
  }
  
  [[self.messagesForConversation objectForKey:key] addObject:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeChatStateNotification:(TBChateStateNotification *)chatStateNotification
                             forKey:(NSString *)key {
  NSMutableArray *messages = [self.messagesForConversation objectForKey:key];
  id messageToRemove = nil;
  
  for (id message in messages) {
    if ([message isKindOfClass:[TBChateStateNotification class]] &&
        [((TBChateStateNotification *)message).sender isEqual:chatStateNotification.sender]) {
      messageToRemove = message;
      break;
    }
  }
  
  [messages removeObject:messageToRemove];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeAllChatStateNotificationsForBuddy:(TBBuddy *)buddy forKey:(NSString *)key {
  NSMutableArray *messages = [self.messagesForConversation objectForKey:key];
  NSUInteger nbMessages = [messages count];
  NSMutableIndexSet *indexesOfMessagesToRemove = [NSMutableIndexSet indexSet];
  
  for (NSUInteger i=0; i < nbMessages; i++) {
    id message = [messages objectAtIndex:i];
    if ([message isKindOfClass:[TBChateStateNotification class]] &&
        [((TBChateStateNotification *)message).sender isEqual:buddy]) {
      [indexesOfMessagesToRemove addIndex:i];
    }
  }
  
  [messages removeObjectsAtIndexes:indexesOfMessagesToRemove];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setChatTextViewStateEnabled:(BOOL)enabled {
  self.toolbarView.textView.backgroundColor = enabled ?
    [UIColor whiteColor] : [UIColor colorWithRed:0.964 green:0.963 blue:0.984 alpha:1.000];
  self.toolbarView.textView.textColor = enabled ?
    [UIColor blackColor] : [UIColor colorWithRed:0.775 green:0.772 blue:0.779 alpha:1.000];
  self.toolbarView.textView.editable = enabled;
  
  // if there was some text in the textView, enable the send button
  if (enabled && ![self.toolbarView.textView.text isEqualToString:@""]) {
    self.toolbarView.sendButton.enabled = YES;
  }
  else {
    self.toolbarView.sendButton.enabled = NO;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)sendMessage:(id)sender {
  TBMessage *message = [[TBMessage alloc] init];
  message.text = self.toolbarView.textView.text;
  message.sender = self.me;
  
  if (self.messages==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:self.currentRoomName];
  }

  [self.messages addObject:message];
  [self.tableView reloadData];
  [self scrollToLatestMessage];
  self.toolbarView.textView.text = @"";
  self.toolbarView.sendButton.enabled = NO;
  
  [self cancelTypingTimer];
  
  // group chat message
  if ([self isInConversationRoom]) {
    if ([self.delegate respondsToSelector:@selector(chatViewController:didAskToSendMessage:)]) {
      [self.delegate chatViewController:self didAskToSendMessage:message.text];
    }
  }
  // private chat message
  else {
    if ([self.delegate
         respondsToSelector:@selector(chatViewController:didAskToSendMessage:toUser:)]) {
      [self.delegate chatViewController:self
                    didAskToSendMessage:message.text
                                 toUser:self.currentRecipient];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)typingDidPause {
  TBLOG(@"-- timer fired");
  [self cancelTypingTimer];
  [self didPauseComposing];
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
            didSelectRoomName:(NSString *)roomName {
  self.title = roomName;
  self.currentRoomName = roomName;
  self.currentRecipient = nil;
  self.nbUnreadMessagesInRoom = 0;
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
    [self updateUnreadMessagesCounter];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
               didSelectBuddy:(TBBuddy *)buddy {
  self.title = buddy.nickname;
  self.currentRoomName = buddy.fullname;
  self.currentRecipient = buddy;
  [self.nbUnreadMessagesForBuddy setObject:[NSNumber numberWithInt:0] forKey:buddy.fullname];
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
    [self updateUnreadMessagesCounter];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
   didAskFingerprintsForBuddy:(TBBuddy *)buddy {
  if ([self.delegate
       respondsToSelector:@selector(chatViewController:didAskFingerprintsForBuddy:)]) {
    [self.delegate chatViewController:self didAskFingerprintsForBuddy:buddy];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBMeViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)meViewControllerHasFinished:(TBMeViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)meViewControllerDidAskToLogout:(TBMeViewController *)controller {
  if ([self.delegate respondsToSelector:@selector(chatViewControllerDidAskToLogout:)]) {
    [self dismissViewControllerAnimated:NO completion:^{
      [self.delegate chatViewControllerDidAskToLogout:self];
    }];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
  NSUInteger oldLength = textView.text.length;
  NSUInteger newLength = textView.text.length + text.length - range.length;
  
  self.toolbarView.sendButton.enabled = newLength > 0;
  
  // if there's a string in the input field
  if (newLength > 0) {
    // if there wasn't a string in the input field before or typing had paused
    if (oldLength==0  || !self.isTyping) {
      TBLOG(@"-- composing");
      [self didStartComposing];
    }
    
    // start/restart timer
    [self setupTypingTimer];
  }
  else {
    // all the chars in the input field have been deleted
    TBLOG(@"-- active");
    [self cancelTypingTimer];
    [self didEndComposing];
  }
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBMessageCellDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)messageCell:(TBMessageCell *)cell
shouldInteractWithURL:(NSURL *)URL
            inRange:(NSRange)characterRange {
  if ([URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"]) {
    SVModalWebViewController *wvc = [[SVModalWebViewController alloc] initWithURL:URL];
    wvc.navigationBar.barStyle = UIBarStyleBlack;
    [self presentViewController:wvc animated:YES completion:NULL];
  }
  
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBChatToolbarViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatToolbarViewView:(TBChatToolbarView *)toolbarView
       willChangeFromHeight:(CGFloat)fromHeight
                   toHeight:(CGFloat)toHeight {
  CGFloat diff = toHeight - fromHeight;
  self.toolbarViewHeightConstraint.constant+=diff;
  
  CGPoint contentOffset = self.tableView.contentOffset;
  contentOffset.y+=diff;
  self.tableView.contentOffset = contentOffset;
  
  [self.view layoutIfNeeded];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatToolbarViewView:(TBChatToolbarView *)toolbarView
        didChangeFromHeight:(CGFloat)fromHeight
                   toHeight:(CGFloat)toHeight {
}

@end
