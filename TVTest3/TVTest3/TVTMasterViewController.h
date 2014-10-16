//
//  TVTMasterViewController.h
//  TVTest3
//
//  Created by Могрин on 10/15/14.
//  Copyright (c) 2014 Могрин. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVTDirectory.h"
#import <CoreData/CoreData.h>

@interface TVTMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray *directories;
@property (nonatomic, retain) TVTDirectory *runDirectory;
@property (nonatomic, retain) NSNumber *runDirectoryId;



@end
