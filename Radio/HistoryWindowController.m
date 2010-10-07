//
//  HistoryWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 04/10/2010.
//  Copyright 2010 whomwah.com. All rights reserved.
//

#import "HistoryWindowController.h"
#import "MyCell.h"
#import "Play.h"

@implementation HistoryWindowController

@synthesize historyItems;
@synthesize filteredHistoryItems;

- (id)init
{
	if (![super initWithWindowNibName:@"History"]) {
		return nil;
	}

  self.historyItems = [NSMutableArray array];
  
	return self;
}

- (void)awakeFromNib
{
  [tableView setBackgroundColor:[NSColor clearColor]];
  [tableView setIntercellSpacing:NSMakeSize(0,1)];
  [tableView setRowHeight:44];
  
  MyCell *cell = [[[MyCell alloc] init] autorelease];
	[[tableView tableColumnWithIdentifier:@"theTableColumn"] setDataCell:cell];
}

- (void)dealloc
{	
  [historyItems release];
  [filteredHistoryItems release];
  
	[super dealloc];
}

- (void)reloadData
{
  self.filteredHistoryItems = historyItems;
  [tableView reloadData];
}

- (IBAction)updateFilter:sender
{      
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(artist CONTAINS[c] %@) OR (track CONTAINS[c] %@)", 
                            [sender stringValue], [sender stringValue]];
  NSArray *results = [filteredHistoryItems filteredArrayUsingPredicate:predicate];
  self.filteredHistoryItems = [results count] > 0 ? results : historyItems;
  [tableView reloadData];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{  
  return [filteredHistoryItems objectAtIndex:row];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [filteredHistoryItems count];
}

@end
