//
//  MainWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "EmpViewController.h"
#import "BBCSchedule.h"

NSString * const DSRDefaultStation = @"DefaultStation";
NSString * const DSRStations = @"Stations";

@implementation MainWindowController

@synthesize currentStation;
@synthesize stations;
@synthesize bbcSchedule;

- (void)windowDidLoad
{
	self.stations = [[NSUserDefaults standardUserDefaults] arrayForKey:DSRStations];
  self.currentStation = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DSRDefaultStation];
  
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


- (void)setNowPlaying
{
  BBCSchedule * nn = [[BBCSchedule alloc] initUsingService:[[self currentStation] valueForKey:@"key"] 
                                                    outlet:[[self currentStation] valueForKey:@"outlet"]];
  self.bbcSchedule = nn;
  
  if (!bbcSchedule.display_title) {
    bbcSchedule.display_title = [[self currentStation] valueForKey:@"label"];
  }
  if (!bbcSchedule.display_title) {
    bbcSchedule.short_synopsis = @"";
  }
  
  [nn release];
}

@end
