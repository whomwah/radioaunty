//
//  HistoryWindowController.h
//  Radio
//
//  Created by Duncan Robertson on 04/10/2010.
//  Copyright 2010 whomwah.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HistoryWindowController : NSWindowController {
  NSMutableArray *historyItems;
  NSArray *filteredHistoryItems;
  IBOutlet NSTableView *tableView;
  IBOutlet NSSearchField *searchField;
}

@property (nonatomic, retain) NSMutableArray *historyItems;
@property (nonatomic, retain) NSArray *filteredHistoryItems;

- (void)reloadData;
- (IBAction)updateFilter:sender;

@end
