//
//  MainWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "EmpViewController.h"
#import "BBCBroadcast.h"
#import "BBCSchedule.h"
#import "DockView.h"
#import "pw_TvAndRadioBotPassword.h"

@implementation MainWindowController

@synthesize currentSchedule, windowTitle, scheduleTimer;

- (void)awakeFromNib
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  dockTile = [NSApp dockTile];
  stations = [ud arrayForKey:@"Stations"];
  currentStation = [stations objectAtIndex:[ud integerForKey:@"DefaultStation"]];
  dockIconView = [[DockView alloc] initWithFrame:
                          NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height) 
                                                 withKey:[currentStation objectForKey:@"key"]];
  [dockTile setContentView:dockIconView];
	[dockTile display];
  
  empViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  [[empViewController view] setFrameSize:[drMainView frame].size];
  [drMainView addSubview:[empViewController view]];
  [self fetchRADIO:currentStation];
  
  NSPoint point = NSPointFromString([ud stringForKey:@"DefaultEmpOrigin"]);
  NSRect rect = NSMakeRect(point.x, point.y,
                           [empViewController windowSize].width, 
                           [empViewController windowSize].height);

  [[self window] setFrame:rect display:NO];
}

- (void)windowDidLoad
{
  [self setNextResponder:empViewController];
  [empViewController handleResizeIcon];
  [self buildStationsMenu];
  self.windowTitle = @"BBC Radio";
  
  NSString *username = TWITTER_USER;
  NSString *password = TWITTER_PASS;
  
  twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
  [twitterEngine setUsername:username password:password];
  [twitterEngine setClientName:@"RadioAunty" 
                       version:@"1.11" 
                           URL:@"http://whomwah.github.com/radioaunty" 
                         token:@"radioaunty"];
}

- (void)dealloc
{
  [dockIconView release];
  [currentSchedule release];
	[empViewController release];
  [twitterEngine release];
	[super dealloc];
}

- (void)fetchRADIO:(NSDictionary *)station
{  
  currentStation = station;
  self.windowTitle = @"Loading...";
  [empViewController fetchEMP:currentStation];
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"key"]];
  [self fetchNewSchedule:nil];
}

- (void)fetchAOD:(id)sender
{
  [self stopScheduleTimer];
  BBCBroadcast *broadcast = [[currentSchedule broadcasts] objectAtIndex:[sender tag]];
  currentBroadcast = broadcast;  
  self.windowTitle = [currentSchedule broadcastDisplayTitleForIndex:[sender tag]];
  [empViewController fetchAOD:[broadcast pid]];
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"key"]];
  [self buildScheduleMenu];
  [self growl];
}

- (void)changeDockNetworkIconTo:(NSString *)service
{
  NSImage *img = [NSImage imageNamed:service];
  [dockIconView setNetworkIcon:img];
	[dockTile display];
}

- (void)fetchNewSchedule:(id)sender
{
  [currentSchedule removeObserver:self forKeyPath:@"broadcasts"];
  BBCSchedule *sc = [[BBCSchedule alloc] initUsingService:[currentStation objectForKey:@"key"] 
                                             outlet:[currentStation objectForKey:@"outlet"]];
  [sc fetchScheduleForDate:[NSDate date]];
  
  self.currentSchedule = sc;
  [currentSchedule addObserver:self
                    forKeyPath:@"broadcasts"
                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                       context:NULL];
  [sc release];  
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  if ([currentSchedule currBroadcast]) {
    currentBroadcast = [currentSchedule currBroadcast];
    self.windowTitle = [currentSchedule currentBroadcastDisplayTitle];
    [self buildScheduleMenu];
    [self startScheduleTimer];
    [self growl];
  }
}

- (void)growl
{
  NSImage *img = [[NSImage alloc] initWithData:[dockIconView dataWithPDFInsideRect:[dockIconView frame]]];
  [GrowlApplicationBridge notifyWithTitle:[[currentSchedule service] displayTitle]
                              description:[currentBroadcast displayTitle]
                         notificationName:@"Now playing"
                                 iconData:[img TIFFRepresentation]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  [img release];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultSendToTwitter"] == YES) {
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[self createTweet] 
                                                     forKey:@"tweet"];
    [NSTimer scheduledTimerWithTimeInterval:300.0 // 5 minutes
                                     target:self
                                   selector:@selector(tweet:)
                                   userInfo:dict
                                    repeats:NO];
  }
}

- (NSString *)createTweet
{
  return [NSString stringWithFormat:@"%@ is %@ %@ on %@ %@", 
              [self realOrTwitterName], 
              [self liveOrNotText], 
              [currentBroadcast displayTitle], 
              [[currentSchedule service] displayTitle], 
              [currentBroadcast programmesUrl]];
}


- (void)tweet:(id)sender
{
  NSString *oldTweet = [[sender userInfo] valueForKey:@"tweet"];
  NSString *newTweet = [self createTweet];
  NSLog(@"checking");
  if ([newTweet isEqualToString:oldTweet] && ((currentBroadcast && [empViewController isLive]) || ![empViewController isLive])) {
    [twitterEngine sendUpdate:newTweet];
    NSImage *twitter_logo = [NSImage imageNamed:@"robot"];
    [GrowlApplicationBridge notifyWithTitle:@"Sending to @radioandtvbot on Twitter.com"
                                description:newTweet
                           notificationName:@"Send to Twitter"
                                   iconData:[twitter_logo TIFFRepresentation]
                                   priority:1
                                   isSticky:NO
                               clickContext:nil];
  } else {
    NSLog(@"No tweet, you changed channels");
  }
}

- (NSString *)liveOrNotText
{
  if ([empViewController isLive]) {
    return @"listening to";
  } else {
    return @"catching up with"; 
  }
}

- (NSString *)realOrTwitterName
{
  NSString *uname = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultTwitterUsername"];
  if ([uname isEqualToString:@""] == YES) {
    return NSFullUserName();
  }  else {
    return [NSString stringWithFormat:@"@%@", uname];
  }  
}

- (void)stopScheduleTimer
{
  [scheduleTimer invalidate];
  self.scheduleTimer = nil;  
}

- (void)startScheduleTimer
{
  [self stopScheduleTimer];
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:[currentBroadcast bEnd]
                                            interval:0.0
                                              target:self
                                            selector:@selector(fetchNewSchedule:)
                                            userInfo:nil
                                             repeats:NO];
  NSLog(@"Timer started and will be fired again at %@", [currentBroadcast bEnd]);
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
  self.scheduleTimer = timer;
}

- (void)changeStation:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"DefaultStation"];
  [[[sender menu] itemWithTitle:[currentStation objectForKey:@"label"]] setState:NSOffState];
  [sender setState:NSOnState];
  [self fetchRADIO:[stations objectAtIndex:[sender tag]]];
}

#pragma mark Build Listen menu

- (void)buildStationsMenu
{
  NSMenuItem *newItem;
  NSMenu *listenMenu = [[[NSApp mainMenu] itemWithTitle:@"Listen"] submenu];
  int count = 0;
  
  for (NSDictionary *station in stations) {      
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[station valueForKey:@"label"] 
                                                                   action:@selector(changeStation:) 
                                                            keyEquivalent:@""];
    if ([currentStation isEqualTo:station] == YES) {
      [newItem setState:NSOnState];
    }
    
    [newItem setEnabled:YES];
    NSImage *img = [[NSImage imageNamed:[station valueForKey:@"key"]] copyWithZone:NULL];
    [img setSize:NSMakeSize(28.0, 28.0)];
    [newItem setImage:img];
    [newItem setTag:count];
    [newItem setTarget:self];
    [listenMenu insertItem:newItem atIndex:count+2];
    
    [newItem release];
    [img release];
    count++;
  }
}

- (void)clearMenu:(NSMenu *)menu
{
  for (NSMenuItem *item in [menu itemArray]) {  
    [menu removeItem:item];
  }
}

- (void)buildScheduleMenu
{
  NSMenuItem *newItem;
  NSString *start;
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  
  [self clearMenu:scheduleMenu];
  int count = 0;
  
  for (BBCBroadcast *broadcast in [currentSchedule broadcasts]) {
    
    start = [[broadcast bStart] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" 
                                                                   action:NULL 
                                                            keyEquivalent:@""];
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@ %@", start, [broadcast displayTitle]];
    NSString *state = @"";
    
    if ([broadcast isEqual:currentBroadcast] == YES) {
      state = @" NOW PLAYING";
      [newItem setState:NSOnState];
    } else if ([broadcast radioAvailability]) {
      [newItem setAction:@selector(fetchAOD:)]; 
    } else if ([broadcast isEqual:[currentSchedule currBroadcast]] == YES) {
      state = @" LIVE";
      [newItem setAction:@selector(refreshStation:)];
    }
    
    [str appendString:state];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:str];

    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange(0,[start length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange([start length]+1,[[broadcast displayTitle] length])];

    [string addAttribute:NSForegroundColorAttributeName
                   value:[NSColor lightGrayColor]
                   range:NSMakeRange(1+[start length]+[[broadcast displayTitle] length],[state length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:9]
                   range:NSMakeRange(1+[start length]+[[broadcast displayTitle] length],[state length])];

    [newItem setAttributedTitle:string];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    [newItem setEnabled:YES];
    [newItem setTarget:self];
    [scheduleMenu addItem:newItem];
    [newItem release];
    [string release];
    count++;
  }
}

- (void)redrawEmp
{
  [[empViewController view] setNeedsDisplay:YES];  
}

- (IBAction)refreshStation:(id)sender
{
  [self fetchRADIO:currentStation];
}

#pragma mark Main Window delegate

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
  NSSize pfs = proposedFrameSize;
  if ([empViewController isMinimized] == YES && [empViewController isReal] == NO) {
    pfs.height = [empViewController minimizedSize].height;
    if (pfs.width < 300.0)
      pfs.width = 300.0;
    if (pfs.width > 600.0)
      pfs.width = 600.0;      
    return pfs;
  } else {
    return [empViewController windowSize];
  }
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
  if ([empViewController isReal] == YES) {
    return NO;
  } else {
    return YES;
  }
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{ 
  NSRect result;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  result = [[self window] frame];
  
  if ([empViewController isMinimized] == YES) {
    [ud setBool:NO forKey:@"DefaultEmpMinimized"];
    [empViewController setIsMinimized:NO];
    result.origin.y = result.origin.y - [empViewController windowSize].height + 
                                        [empViewController minimizedSize].height;
  } else {
    result.origin.y = result.origin.y + [empViewController windowSize].height - 
                                        [empViewController minimizedSize].height;
    [ud setBool:YES forKey:@"DefaultEmpMinimized"];
    [empViewController setIsMinimized:YES];
  }

  [empViewController handleResizeIcon];
  result.size = [empViewController windowSize];
  return result;
}

#pragma mark MGTwitterEngineDelegate methods

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
  NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
  NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
        connectionIdentifier, 
        [error localizedDescription], 
        [error userInfo]);
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got statuses for %@:\r%@", connectionIdentifier, statuses);
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got user info for %@:\r%@", connectionIdentifier, userInfo);
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got search results for %@:\r%@", connectionIdentifier, searchResults);
}

- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got an image for %@: %@", connectionIdentifier, image);
}

- (void)connectionFinished
{
  NSLog(@"Connection finished");
}

@end
