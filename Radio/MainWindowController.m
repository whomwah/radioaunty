//
//  MainWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "EmpViewController.h"

NSString * const DSRDefaultStation = @"DefaultStation";
NSString * const DSRStations = @"Stations";

@implementation MainWindowController

@synthesize wTitle;
@synthesize currentStation;
@synthesize stations;

- (void)windowDidLoad
{
	self.stations = [[NSUserDefaults standardUserDefaults] arrayForKey:DSRStations];
  self.currentStation = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DSRDefaultStation];
  self.wTitle = [[self currentStation] valueForKey:@"label"];
  
  drEmpViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  
  NSView * aEmpView = [drEmpViewController view];
  NSSize currentSize = [drMainView frame].size; 
  NSSize newSize = [aEmpView frame].size;
  float deltaWidth = newSize.width - currentSize.width;
  float deltaHeight = newSize.height - currentSize.height;
  
  NSWindow * w = [drMainView window];
  NSRect windowFrame = [w frame];
  windowFrame.size.width += deltaWidth;
  windowFrame.size.height += deltaHeight;
  windowFrame.origin.x -= deltaWidth/2;
  windowFrame.origin.y -= deltaHeight/2;
  
  [w setFrame:windowFrame
      display:YES
      animate:YES];
  
	[drMainView addSubview:aEmpView];
}

- (void)dealloc
{
	[drEmpViewController release];
	[super dealloc];
}

- (NSDictionary *)findStationForId:(int)key
{
  NSEnumerator * enumerator = [[self stations] objectEnumerator];
  
  for (NSDictionary * station in enumerator) {  
    if ([[NSNumber numberWithInt:key] isEqual:[station valueForKey:@"id"]]) {
      NSLog(@"Found station: %@", station);
      return station;
      break;
    }
  }
  
  return nil;
}

- (void)setAndLoadStation:(NSDictionary *)station
{
  self.currentStation = station;  
  [drEmpViewController loadUrl:[self currentStation]];  
}

@end
