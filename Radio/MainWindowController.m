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
NSString * const DSRQuality = @"Quality";

#define EMP_WIDTH 512.0
#define EMP_HEIGHT 233.0

@implementation MainWindowController

@synthesize currentStation, currentSchedule;
@synthesize stations;
@synthesize dockView;
@synthesize drEmpViewController;

- (void)windowDidLoad
{
 	dockTile = [NSApp dockTile];
  self.drEmpViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
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
  [aEmpView setFrameSize:size];
  [aEmpView setNeedsDisplay:YES];
  
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
  int quality = [[NSUserDefaults standardUserDefaults] integerForKey:DSRQuality];
  
  [self setCurrentStation:station];
  if (quality != 1 || [station valueForKey:@"only_real_available"]) {
    [drEmpViewController setPlaybackFormat:@"liveReal"];
    [drEmpViewController setStreamUrl:[station valueForKey:@"realStreamUrl"]];
    [self resizeEmpTo:NSMakeSize(EMP_WIDTH, 243.0)];
  } else {
    [drEmpViewController setPlaybackFormat:@"live"];
    [self resizeEmpTo:NSMakeSize(EMP_WIDTH, EMP_HEIGHT)];
  }
  [drEmpViewController setDisplayTitle:@"BBC Radio"];
  [drEmpViewController setServiceKey:[station valueForKey:@"key"]];
  [drEmpViewController fetchEmp:[station valueForKey:@"empKey"]];
  [self buildDockTileForKey:[currentStation valueForKey:@"key"]];
	[dockTile setContentView:dockView];
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
  NSRect dockFrame = NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height);
  NSView *dockIconView = [[NSView alloc] initWithFrame:dockFrame];
  
  NSImageView *serviceIconView = [[NSImageView alloc] initWithFrame: 
                                  NSMakeRect(15, 0, dockTile.size.width, dockTile.size.height-10.0)];
  NSImage *serviceImg = [[NSImage alloc] initWithData:
                         [NSData dataWithData:[[NSImage imageNamed:key] TIFFRepresentation]]];
  [serviceIconView setImage:serviceImg];
  [serviceIconView setImageAlignment:NSImageAlignTopLeft];
  
	NSImageView *appIconView = [[NSImageView alloc] initWithFrame:dockFrame];
  NSImage *appIcon = [[NSImage alloc] initWithData:
                      [NSData dataWithData:[[NSImage imageNamed:@"radio_icon"] TIFFRepresentation]]];  
  [appIconView setImage:appIcon];
  
  [dockIconView addSubview:appIconView];
  [dockIconView addSubview:serviceIconView];
  [self setDockView:dockIconView];
  
  [dockIconView release];
  [serviceImg release];
  [appIcon release];
  [appIconView release];
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
    NSString *stitle = [[currentSchedule service] displayTitle];
    [drEmpViewController setDisplayTitle:stitle];
    [GrowlApplicationBridge notifyWithTitle:stitle
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
  NSFont *font = [NSFont userFontOfSize:13.0];
  NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
  [self clearMenu:scheduleMenu];
  int count = 0;
  
  for (Broadcast *broadcast in enumerator) {
    
    start = [[broadcast bStart] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    label = [NSMutableString stringWithFormat:@"%@ %@", start, [broadcast displayTitle]];
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" 
                                                                   action:NULL 
                                                            keyEquivalent:@""];
    
    if ([broadcast availableText]) {
      [label appendFormat:@" (%@)", [broadcast availableText]];
      [newItem setAction:@selector(fetchAOD:)];
    }
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:label
                                                                     attributes:attrsDictionary];
    
    [newItem setAttributedTitle:attrString];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    if ([broadcast isEqual:[currentSchedule currentBroadcast]] == YES)
      [newItem setState:NSOnState];
    [newItem setEnabled:YES];
    [newItem setTarget:self];
    [scheduleMenu addItem:newItem];
    [newItem release];
    [attrString release];
    count++;
  }
}

- (void)fetchAOD:(id)sender
{
  Broadcast *broadcast = [[currentSchedule broadcasts] objectAtIndex:[sender tag]];
  [self resizeEmpTo:NSMakeSize(EMP_WIDTH, EMP_HEIGHT)];
  [dockTile display];
  [drEmpViewController setDisplayTitle:[broadcast displayTitle]];
  [drEmpViewController setServiceKey:[[currentSchedule service] key]];
  [drEmpViewController setPlaybackFormat:@"emp"];
  [drEmpViewController setStreamUrl:nil];
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

- (void)redrawEmp
{
  [[drEmpViewController view] setNeedsDisplay:YES];  
}

@end
