//
//  TBServersViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 22/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBServersViewController.h"
#import "TBServer.h"
#import "UIColor+Cryptocat.h"
#import "TBServerViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServersViewController () <TBServerViewControllerDelegate>

@property (nonatomic, readonly) NSArray *servers;
@property (nonatomic, strong) TBServer *currentServer;
@property (nonatomic, readonly) NSIndexPath *indexPathForAddCell;
@property (nonatomic, strong) NSString *serverNameConflictErrorMessage;
@property (nonatomic, strong) NSString *serverRequiredFieldsErrorMessage;

- (void)showErrorMessage:(NSString *)errorMessage;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBServersViewController

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
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self=[super initWithCoder:aDecoder]) {
    _serverNameConflictErrorMessage = NSLocalizedString(
                            @"A server with this name already exists. Please choose another name.", @"Server Name already exists error message");
    _serverRequiredFieldsErrorMessage = NSLocalizedString(@"All fields are required.",
                                            @"All Fields are required error message for server");
    _currentServer = nil;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.currentServer = [TBServer currentServer];
  
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  self.title = NSLocalizedString(@"Servers", @"Servers Screen Title");
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // -- server details
  if ([segue.identifier isEqualToString:@"ServerSegueID"]) {
    NSIndexPath *indexPath = sender;
    TBServer *server = [self.servers objectAtIndex:indexPath.row];
    TBServerViewController *svc = segue.destinationViewController;
    svc.delegate = self;
    svc.server = server;
    svc.serverIndexPath = indexPath;
  }
  
  // -- new server
  else if ([segue.identifier isEqualToString:@"NewServerSegueID"]) {
    UINavigationController *nc = segue.destinationViewController;
    nc.navigationBar.barStyle = UIBarStyleBlack;
    TBServerViewController *svc = (TBServerViewController *)nc.topViewController;
    svc.delegate = self;
    svc.server = nil;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  
  if (editing) {
    [self.tableView insertRowsAtIndexPaths:@[self.indexPathForAddCell]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  else {
    [self.tableView deleteRowsAtIndexPaths:@[self.indexPathForAddCell]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // editing mode
  if (self.isEditing) {
    if ([indexPath isEqual:[self indexPathForAddCell]]) {
      [self performSegueWithIdentifier:@"NewServerSegueID" sender:nil];
    }
    else {
      [self performSegueWithIdentifier:@"ServerSegueID" sender:indexPath];
    }
  }
  
  // normal mode
  else {
    TBServer *server = [self.servers objectAtIndex:indexPath.row];
    [TBServer setCurrentServer:server];
    self.currentServer = server;
    [self.tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  // only there to avoid editing mode when swiping a cell
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  // only there to avoid editing mode when swiping a cell
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
  NSUInteger nbServers = [self.servers count];
  return self.isEditing ? nbServers+1 : nbServers;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"ServerCellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                          forIndexPath:indexPath];
  TBLOG(@"-- cellForRowAtIndexPath : %@", indexPath);
  if ([indexPath isEqual:self.indexPathForAddCell]) {
    cell.textLabel.text = NSLocalizedString(@"add server", @"add server");
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor tb_buttonTitleColor];
  }
  else {
    TBServer *server = [self.servers objectAtIndex:indexPath.row];
    cell.textLabel.text = server.name;
    cell.textLabel.textColor = [UIColor blackColor];
    if ([server.name isEqualToString:self.currentServer.name]) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:self.indexPathForAddCell]) return UITableViewCellEditingStyleInsert;
  
  TBServer *server = [self.servers objectAtIndex:indexPath.row];
  
  return server.isReadonly ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView
shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:self.indexPathForAddCell]) return YES;
  
  TBServer *server = [self.servers objectAtIndex:indexPath.row];
  return server.isReadonly ? NO : YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
      TBServer *server = [self.servers objectAtIndex:indexPath.row];
      BOOL isCurrentServer = [[TBServer currentServer].name isEqualToString:server.name];
      [TBServer deleteServer:server];
      
      // if the deleted server was the current server, set a new current server
      if (isCurrentServer) {
        TBServer *firstServer = [self.servers objectAtIndex:0];
        [TBServer setCurrentServer:firstServer];
        self.currentServer = firstServer;
        NSIndexPath *firstServerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[firstServerIndexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
      }
      else {
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
      }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
      [self performSegueWithIdentifier:@"NewServerSegueID" sender:nil];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)servers {
  return [TBServer servers];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)indexPathForAddCell {
  return [NSIndexPath indexPathForRow:[self.servers count]
                            inSection:0];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showErrorMessage:(NSString *)errorMessage {
  NSString *title = NSLocalizedString(@"Error", @"Server Creation/Modification Error Alert Title");
  NSString *cancelTitle = NSLocalizedString(@"Ok", @"Error Alert View Ok Button Title");
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                               message:errorMessage
                                              delegate:self
                                     cancelButtonTitle:cancelTitle
                                     otherButtonTitles:nil];
  [av show];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBServerViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)serverViewController:(TBServerViewController *)controller
             didCreateServer:(TBServer *)server {
  if ([server.name isEqualToString:@""] ||
      [server.domain isEqualToString:@""] ||
      [server.conferenceServer isEqualToString:@""]) {
    [self showErrorMessage:self.serverRequiredFieldsErrorMessage];
  }
  else {
    if ([TBServer addServer:server]) {
      [self dismissViewControllerAnimated:YES completion:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([self.servers count]-1) inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
      }];
    }
    else {
      [self showErrorMessage:self.serverNameConflictErrorMessage];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)serverViewController:(TBServerViewController *)controller
             didUpdateServer:(TBServer *)server
                     atIndexPath:(NSIndexPath *)indexPath {
  if ([server.name isEqualToString:@""] ||
      [server.domain isEqualToString:@""] ||
      [server.conferenceServer isEqualToString:@""]) {
    [self showErrorMessage:self.serverRequiredFieldsErrorMessage];
  }
  else {
    if ([TBServer updateServer:server atIndex:indexPath.row]) {
      [self.navigationController popViewControllerAnimated:YES];
      [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
      [self showErrorMessage:self.serverNameConflictErrorMessage];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)serverViewControllerDidCancel:(TBServerViewController *)controller {
  TBLOGMARK;
  [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
