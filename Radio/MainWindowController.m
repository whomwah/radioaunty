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
@synthesize currentSchedule;
@synthesize stations;
@synthesize dockTile;

- (void)windowDidLoad
{
 	self.dockTile = [NSApp dockTile];
  drEmpViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  self.stations = [[NSUserDefaults standardUserDefaults] arrayForKey:DSRStations];
  self.currentStation = [stations objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:DSRDefaultStation]];
  
  NSView *aEmpView = [drEmpViewController view];
  NSSize currentSize = [drMainView frame].size; 
  NSSize newSize = [aEmpView frame].size;
  float deltaWidth = newSize.width - currentSize.width;
  float deltaHeight = newSize.height - currentSize.height;
  
  NSWindow *w = [drMainView window];
  NSRect windowFrame = [w frame];
  windowFrame.size.width += deltaWidth;
  windowFrame.size.height += deltaHeight;
  windowFrame.origin.x -= deltaWidth/2;
  windowFrame.origin.y -= deltaHeight/2;
  
  [w setFrame:windowFrame display:YES animate:YES];
  
	[drMainView addSubview:aEmpView];
  [self buildStationsMenu];
  [self setAndLoadStation:currentStation];
}

- (void)dealloc
{
  [currentSchedule release];
	[drEmpViewController release];
	[super dealloc];
}

- (void)setAndLoadStation:(NSDictionary *)station
{  
  NSImage *img;
  NSImageView *dockImageView;
  BBCSchedule *cSchedule;
  
  NSLog(@"setAndLoadStation:%@", station);
  [self setCurrentStation:station];
  [drEmpViewController loadUrl:[self currentStation]];
  
	NSRect frame = NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height);
	dockImageView = [[NSImageView alloc] initWithFrame: frame];
  img = [[NSImage alloc] initWithData:[NSData dataWithData:[[NSImage imageNamed:[currentStation valueForKey:@"key"]] TIFFRepresentation]]];
  [img setSize:NSMakeSize(dockTile.size.width/1.5, dockTile.size.height/1.5)];
	[dockImageView setImage:img];
	[dockTile setContentView: dockImageView];
  [dockTile setBadgeLabel:@"live"];
	[dockTile display];
  
  [self unregisterCurrentScheduleForChangeNotificationForKey:@"currentBroadcast"];
  cSchedule = [[BBCSchedule alloc] initUsingService:[[self currentStation] valueForKey:@"key"] 
                                             outlet:[[self currentStation] valueForKey:@"outlet"]];
  [self setCurrentSchedule:cSchedule];
  [self registerCurrentScheduleAsObserverForKey:@"currentBroadcast"];
  
  [img release];
  [dockImageView release];  
  [cSchedule release];
}

- (void)changeStation:(id)sender
{
  [[[sender menu] itemWithTitle:[currentStation valueForKey:@"label"]] setState:NSOffState];
  [sender setState:NSOnState];
  [self setAndLoadStation:[stations objectAtIndex:[sender tag]]];
}

- (void)registerCurrentScheduleAsObserverForKey:(NSString *)key
{
  [currentSchedule addObserver:self
                    forKeyPath:key
                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                       context:NULL];
}

- (void)unregisterCurrentScheduleForChangeNotificationForKey:(NSString *)key
{
  [currentSchedule removeObserver:self forKeyPath:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  [self buildScheduleMenu];
  if ([currentSchedule currentBroadcast]) {
    [GrowlApplicationBridge notifyWithTitle:[currentSchedule valueForKey:@"serviceDisplayTitle"]
                              description:[[currentSchedule currentBroadcast] valueForKey:@"displayTitle"]
                         notificationName:@"Station about to play"
                                 iconData:[NSData dataWithData:[[NSImage imageNamed:[currentStation valueForKey:@"key"]] TIFFRepresentation]]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  }
}

#pragma mark Build Listen menu

- (void)buildStationsMenu
{
  NSMenuItem *newItem;
  NSMenu *listenMenu = [[[NSApp mainMenu] itemWithTitle:@"Listen"] submenu];
  NSEnumerator *enumerator = [stations objectEnumerator];
  int count = 0;
  
  for (NSDictionary *station in enumerator) {      
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[station valueForKey:@"label"] 
                                                                   action:@selector(changeStation:) 
                                                            keyEquivalent:@""];
    
    if ([currentStation isEqualTo:station] == YES)
      [newItem setState:NSOnState];
    [newItem setEnabled:YES];
    NSImage *img = [[NSImage alloc] initWithData:[NSData dataWithData:[[NSImage imageNamed:[station valueForKey:@"key"]] TIFFRepresentation]]];
    [img setSize:NSMakeSize(20.0, 20.0)];
    [newItem setImage:img];
    [newItem setTag:count];
    [newItem setTarget:self];
    [listenMenu addItem:newItem];
    
    [img release];
    [newItem release];
    count++;
  }
}

- (void)clearMenu:(NSMenu *)menu
{
  NSEnumerator *enumerator = [[menu itemArray] objectEnumerator];
  for (NSMenuItem *item in enumerator) {  
    [menu removeItem:item];
  }
}

- (void)buildScheduleMenu
{
  NSMenuItem *newItem;
  NSString *start;
  NSMutableString *label;
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  
  NSEnumerator *enumerator = [[currentSchedule broadcasts] objectEnumerator];
  [self clearMenu:scheduleMenu];
  int count = 0;
  
  for (NSDictionary *broadcast in enumerator) {  
    start = [[broadcast valueForKey:@"start"] descriptionWithCalendarFormat:@"%H:%M" 
                                                                   timeZone:nil 
                                                                     locale:nil];
    label = [NSMutableString stringWithFormat:@"%@ %@", start, [broadcast valueForKey:@"displayTitle"]];
    
    if ([broadcast valueForKey:@"availableText"]) {
      [label appendFormat:@" (%@)", [broadcast valueForKey:@"availableText"]];
      newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label 
                                                                     action:@selector(fetchAOD:) 
                                                              keyEquivalent:@""];
    } else {
      newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label 
                                                                     action:NULL 
                                                              keyEquivalent:@""];      
    }
    
    [newItem setEnabled:YES];
    [newItem setTag:count];
    if ([broadcast isEqual:[currentSchedule currentBroadcast]] == YES) {
      [newItem setState:NSOnState];
    }
    [newItem setEnabled:YES];
    [newItem setTarget:self];
    [scheduleMenu addItem:newItem];
    [newItem release];
    count++;
  }
}

- (void)fetchAOD:(id)sender
{
  // NOTE READY YET!
}

@end
