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

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServersViewController ()

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, readonly) NSIndexPath *indexPathForAddCell;

- (void)loadDefaultServers;

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
    _servers = [NSMutableArray array];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  self.title = NSLocalizedString(@"Servers", @"Servers Screen Title");
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

  [self loadDefaultServers];
  
  // load sample servers
  for (int i = 1; i < 4; i++) {
    TBServer *server = [[TBServer alloc] init];
    server.name = [NSString stringWithFormat:@"Server %d", i];
    server.domain = @"crypto.cat";
    server.conferenceServer = @"conference.crypto.cat";
    server.readonly = NO;
    [self.servers addObject:server];
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
  
  if ([indexPath isEqual:self.indexPathForAddCell]) {
    cell.textLabel.text = NSLocalizedString(@"add server", @"add server");
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor tb_buttonTitleColor];
  }
  else {
    TBServer *server = [self.servers objectAtIndex:indexPath.row];
    cell.textLabel.text = server.name;
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor blackColor];
  }
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:self.indexPathForAddCell]) return YES;
  
  TBServer *server = [self.servers objectAtIndex:indexPath.row];
  return !server.isReadonly;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:self.indexPathForAddCell]) return UITableViewCellEditingStyleInsert;
  
  return UITableViewCellEditingStyleDelete;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
- (NSIndexPath *)indexPathForAddCell {
  return [NSIndexPath indexPathForRow:[self.servers count]
                            inSection:0];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadDefaultServers {
  TBServer *server = [[TBServer alloc] init];
  server.name = @"Cryptocat";
  server.domain = @"crypto.cat";
  server.conferenceServer = @"conference.crypto.cat";
  server.readonly = YES;
  [self.servers addObject:server];
}


@end
