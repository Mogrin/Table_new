//
//  TVTMasterViewController.m
//  TVTest3
//
//  Created by Могрин on 10/15/14.
//  Copyright (c) 2014 Могрин. All rights reserved.
//

#import "TVTMasterViewController.h"
#import "TVTDirectory.h"

@interface TVTMasterViewController ()

@end

@implementation TVTMasterViewController

@synthesize directories;
@synthesize runDirectory;
@synthesize runDirectoryId;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.runDirectoryId = 0;
    
    UIBarButtonItem *editButton = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self
                                  action:@selector(insertNewObject:)];
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    NSArray *rightButtons = [[NSArray alloc] initWithObjects: addButton, editButton, nil];
    self.navigationItem.rightBarButtonItems = rightButtons;
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                   target:self
                                   action:@selector(goBack:)];
    
    self.navigationItem.leftBarButtonItem = leftButton;
    self.navigationItem.leftBarButtonItem.enabled = false;
    
    TVTDirectory *dir = [[TVTDirectory alloc] init];
    TVTDirectory *dir1 = [[TVTDirectory alloc] init];
    dir.title = @"name"; dir1.title = @"name2";
    self.directories = [NSMutableArray arrayWithObjects: dir, dir1, nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)insertNewObject:(id)sender
{
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"Создать контакт", nil)
                           message:NSLocalizedString(@"", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"Создать", nil)
                           otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *str = [[alertView textFieldAtIndex:0] text];
    if(str.length >= 1) {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObject *dir = [NSEntityDescription insertNewObjectForEntityForName:@"TVTDirectory"
                                                                    inManagedObjectContext:context];
        [dir setValue:str forKey:@"title"];
        [dir setValue:[[NSNumber alloc] initWithInt:[NSDate timeIntervalSinceReferenceDate]] forKey:@"id"];
        [dir setValue:self.runDirectoryId forKey:@"parentId"];
        
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
            abort();
        }
        
        [self.directories insertObject:dir atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];      
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadTable];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.directories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSManagedObject *dir = [self.directories objectAtIndex:indexPath.row];
    cell.textLabel.text = [dir valueForKey:@"title"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *tmpDir = [self.directories objectAtIndex:indexPath.row];
        NSManagedObjectContext *tmpObjCntx = [self managedObjectContext];
        [tmpObjCntx deleteObject:tmpDir];
        
        [self removeChildren:[tmpDir valueForKey:@"id"]];
        
        NSError *error = nil;
        if (![tmpObjCntx save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        [self.directories removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void) removeChildren:(NSNumber*)id_ {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TVTDirectory"];
    NSPredicate *predicateID = [NSPredicate predicateWithFormat:@"parentId == %d", [id_ integerValue]];
    [fetchRequest setPredicate:predicateID];
    NSMutableArray *CategoriesToRemove = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    
    for(NSManagedObject *n in CategoriesToRemove){
        [self removeChildren:[n valueForKey:@"id"]];
        [managedObjectContext deleteObject:n];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.runDirectoryId = [[self.directories objectAtIndex:indexPath.row] valueForKey:@"id"];
    [self reloadTable];
}

-(void)goBack{
    self.runDirectoryId = [self.runDirectory valueForKey:@"parentId"];
    [self reloadTable];
}

-(void)reloadTable {
    [self.directories removeAllObjects];
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TVTDirectory"];
    NSPredicate *predicateID = [NSPredicate predicateWithFormat:@"parentId == %d", [self.runDirectoryId integerValue]];
    [fetchRequest setPredicate:predicateID];
    self.directories = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    [self.tableView reloadData];
    
    if(self.runDirectoryId == 0 ){
        self.navigationItem.title = NSLocalizedString(@"Main Title", nil);
        self.navigationItem.leftBarButtonItem.enabled = false;
    } else {
        NSPredicate *predicateForCurCatID = [NSPredicate predicateWithFormat:@"id == %d", [self.runDirectoryId integerValue]];
        [fetchRequest setPredicate:predicateForCurCatID];
        NSArray *tmpDirectory = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
        self.runDirectory = [tmpDirectory objectAtIndex:0];
        self.runDirectoryId = [self.runDirectory valueForKey:@"id"];
        self.navigationItem.title = [self.runDirectory valueForKey:@"title"];
        self.navigationItem.leftBarButtonItem.enabled = true;
    }
    
    [self.tableView reloadData];
    
}

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

/*- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.return NO;
    NO;
}*/

/*- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}/*
/*
 #pragma mark - Fetched results controller
 
 - (NSFetchedResultsController *)fetchedResultsController
 {
 if (_fetchedResultsController != nil) {
 return _fetchedResultsController;
 }
 
 NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
 // Edit the entity name as appropriate.
 NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
 [fetchRequest setEntity:entity];
 
 // Set the batch size to a suitable number.
 [fetchRequest setFetchBatchSize:20];
 
 // Edit the sort key as appropriate.
 NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
 NSArray *sortDescriptors = @[sortDescriptor];
 
 [fetchRequest setSortDescriptors:sortDescriptors];
 
 // Edit the section name key path and cache name if appropriate.
 // nil for section name key path means "no sections".
 NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
 aFetchedResultsController.delegate = self;
 self.fetchedResultsController = aFetchedResultsController;
 
 NSError *error = nil;
 if (![self.fetchedResultsController performFetch:&error]) {
 // Replace this implementation with code to handle the error appropriately.
 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
 abort();
 }
 
 return _fetchedResultsController;
 }
 
 - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
 {
 [self.tableView beginUpdates];
 }
 
 - (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
 atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
 {
 switch(type) {
 case NSFetchedResultsChangeInsert:
 [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
 break;
 
 case NSFetchedResultsChangeDelete:
 [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
 break;
 }
 }
 
 - (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
 atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
 newIndexPath:(NSIndexPath *)newIndexPath
 {
 UITableView *tableView = self.tableView;
 
 switch(type) {
 case NSFetchedResultsChangeInsert:
 [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
 break;
 
 case NSFetchedResultsChangeDelete:
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 break;
 
 case NSFetchedResultsChangeUpdate:
 [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
 break;
 
 case NSFetchedResultsChangeMove:
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
 break;
 }
 }
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 [self.tableView endUpdates];
 }
 */

@end
