//
//  MainWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "EmpViewController.h"
#import "Broadcast.h"
#import "Schedule.h"

NSString * const DSRDefaultStation = @"DefaultStation";
NSString * const DSRStations = @"Stations";
#define EMP_WIDTH 512.0
#define EMP_HEIGHT 271.0

@implementation MainWindowController

@synthesize currentStation, currentSchedule;
@synthesize stations;
@synthesize dockView;

- (void)windowDidLoad
{
 	dockTile = [NSApp dockTile];
  drEmpViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  [self setStations:[[NSUserDefaults standardUserDefaults] arrayForKey:DSRStations]];
  [self setCurrentStation:[stations objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:DSRDefaultStation]]];
  [self resizeEmpTo:NSMakeSize(EMP_WIDTH, EMP_HEIGHT)];
  [self buildStationsMenu];
  [self setAndLoadStation:currentStation];
}

- (void)dealloc
{
  [currentSchedule release];
	[drEmpViewController release];
	[super dealloc];
}

- (void)resizeEmpTo:(NSSize)size
{
  NSView *aEmpView = [drEmpViewController view];
  [aEmpView removeFromSuperview];
  
  NSSize currentSize = [drMainView frame].size; 
  float deltaWidth = size.width - currentSize.width;
  float deltaHeight = size.height - currentSize.height;
  
  NSWindow *w = [drMainView window];
  NSRect windowFrame = [w frame];
  windowFrame.size.width += deltaWidth;
  windowFrame.size.height += deltaHeight;
  windowFrame.origin.x -= deltaWidth/2;
  windowFrame.origin.y -= deltaHeight/2;
  
  [w setFrame:windowFrame display:YES animate:YES];
	[drMainView addSubview:aEmpView];
}

- (void)setAndLoadStation:(NSDictionary *)station
{  
  Schedule *cSchedule;
  
  NSLog(@"setAndLoadStation:%@", station);
  [self setCurrentStation:station];
  [self resizeEmpTo:NSMakeSize(EMP_WIDTH, EMP_HEIGHT)];
  [dockTile setBadgeLabel:@"live"];
  [dockTile display];
  [drEmpViewController setTitle:[station valueForKey:@"label"]];
  [drEmpViewController setServiceKey:[station valueForKey:@"key"]];
  [drEmpViewController fetchEmp:[station valueForKey:@"key"]];
  
  [self buildDockTileForKey:[currentStation valueForKey:@"key"]];
	[dockTile setContentView:dockView];
  [dockTile setBadgeLabel:@"live"];
	[dockTile display];
  
  [self unregisterCurrentScheduleForChangeNotificationForKey:@"currentBroadcast"];
  cSchedule = [[Schedule alloc] initUsingService:[currentStation valueForKey:@"key"] 
                                          outlet:[currentStation valueForKey:@"outlet"]];
  [self setCurrentSchedule:cSchedule];
  [self registerCurrentScheduleAsObserverForKey:@"currentBroadcast"];
  
  [cSchedule release];
}

- (void)buildDockTileForKey:(NSString *)key
{
  NSRect frame = NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height);
	NSImageView *dockImageView = [[NSImageView alloc] initWithFrame: frame];
  NSImage *img = [[NSImage alloc] initWithData:
                  [NSData dataWithData:[[NSImage imageNamed:key] TIFFRepresentation]]];
  [img setSize:NSMakeSize(dockTile.size.width/1.5, dockTile.size.height/1.5)];
	[dockImageView setImage:img];
  [self setDockView:dockImageView];
  [img release];
  [dockImageView release];
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
    [GrowlApplicationBridge notifyWithTitle:[[currentSchedule service] displayTitle]
                              description:[[currentSchedule currentBroadcast] displayTitle]
                         notificationName:@"Station about to play"
                                 iconData:[NSData dataWithData:
                                           [[NSImage imageNamed:[currentStation valueForKey:@"key"]] TIFFRepresentation]]
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
    NSImage *img = [[NSImage alloc] initWithData:[NSData dataWithData:
                                                  [[NSImage imageNamed:[station valueForKey:@"key"]] TIFFRepresentation]]];
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
  
  for (Broadcast *broadcast in enumerator) {
    
    start = [[broadcast bStart] descriptionWithCalendarFormat:@"%H:%M" 
                                                     timeZone:nil 
                                                       locale:nil];
    label = [NSMutableString stringWithFormat:@"%@ %@", start, [broadcast displayTitle]];
    
    if ([broadcast availableText]) {
      [label appendFormat:@" (%@)", [broadcast availableText]];
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
  Broadcast *broadcast = [[currentSchedule broadcasts] objectAtIndex:[sender tag]];
  [self resizeEmpTo:NSMakeSize(EMP_WIDTH, EMP_HEIGHT)];
  [dockTile setBadgeLabel:@"replay"];
  [dockTile display];
  [drEmpViewController setTitle:[broadcast displayTitle]];
  [drEmpViewController setServiceKey:[[currentSchedule service] key]];
  [drEmpViewController fetchEmp:[broadcast pid]];
  
  [GrowlApplicationBridge notifyWithTitle:[[currentSchedule service] displayTitle]
                              description:[broadcast displayTitle]
                         notificationName:@"Station about to play"
                                 iconData:[NSData dataWithData:
                                           [[NSImage imageNamed:[[currentSchedule service] key]] TIFFRepresentation]]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
}

@end
