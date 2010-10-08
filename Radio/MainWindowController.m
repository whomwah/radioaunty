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
#import "LiveTextView.h"
#import "AppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "settings.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPAdHocCommands.h"
#import "XMPPPubSub.h"

#define DR_CONTENT_UNAVAILABLE @"Livetext currently unavailable"
#define DR_CONTENT_AWAITING    @"Awaiting livetext..."

@implementation MainWindowController

@synthesize currentSchedule;
@synthesize windowTitle;
@synthesize liveTextView;
@synthesize scheduleTimer;
@synthesize xmppCapabilities;
@synthesize pubsub;
@synthesize anonJID;

/**
 * Gives us a hook to the xmmpStream object setup
 * in the AppDelegate
 **/

- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

/**
 * Gives us a hook to the scrobble object setup
 * in the AppDelegate
 **/

- (Scrobble *)scrobbler
{
	return [[NSApp delegate] scrobbler];
}

/**
 * Lots of setup going on here
 **/

- (void)awakeFromNib
{
  // fetch out the user defaults data, as we'll be using it a lot
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  // give ourself easy access to the dock tile
  NSDockTile *dockTile = [NSApp dockTile];
  stations = [ud arrayForKey:@"Stations"];
  currentStation = [stations objectAtIndex:[ud integerForKey:@"DefaultStation"]];
  
  // sort our the dock view
  
  dockIconView = [[DockView alloc] initWithFrame:
                          NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height) 
                          withKey:[currentStation objectForKey:@"key"]];
  [[NSApp dockTile] setContentView:dockIconView];
	[[NSApp dockTile] display];
  
  // setup of the ToolBar
  liveTextView = [[LiveTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 26)];
	[toolBar insertItemWithItemIdentifier:@"livetext" atIndex:0];
  
  empViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  [[empViewController view] setFrameSize:[drMainView frame].size];
  [drMainView addSubview:[empViewController view] 
              positioned:NSWindowBelow
              relativeTo:nil];
  [self fetchRADIO:currentStation];
  
  NSPoint point = NSPointFromString([ud stringForKey:@"DefaultEmpOrigin"]);
  
  // adjust to allow for toolbar
  int toolBarAdjust = 0;
  if ([toolBar isVisible]) {    
    toolBarAdjust = 25;
  }
  
  NSRect rect = NSMakeRect(point.x, point.y,
                           [empViewController windowSize].width, 
                           [empViewController windowSize].height + toolBarAdjust);

  [[self window] setFrame:rect display:NO];
  
	// setup connecting to the XMPP host anonomously
  
  availableForSubscription = NO;
	
	[[self xmppStream] addDelegate:self];
	[[self xmppStream] setHostName:DR_XMPP_HOST];
  [[self xmppStream] setMyJID:[XMPPJID jidWithString:DR_XMPP_ANON]];
  
  // choose a storage method for xmpp capabilities storage
  
  XMPPCapabilitiesCoreDataStorage *cap_core = [[XMPPCapabilitiesCoreDataStorage alloc] init];
  xmppCapabilities = [[XMPPCapabilities alloc] initWithStream:[self xmppStream] capabilitiesStorage:cap_core];
  [cap_core release];
	
  // add the commands the application supports
  
  /*
  XMPPAdHocCommands *ahc = [[XMPPAdHocCommands alloc] initWithStream:[self xmppStream]];
  XMPPJID *jid = [XMPPJID jidWithString:@"tv@xmpp.local"];
  [ahc addCommandWithNode:@"station"          andName:@"Switch to station <key>"             andJID:jid];
  [ahc addCommandWithNode:@"station-up"       andName:@"Switch to next station"              andJID:jid];
  [ahc addCommandWithNode:@"station-down"     andName:@"Switch to previous station"          andJID:jid];
  [ahc addCommandWithNode:@"station-now"      andName:@"What's on the current station now"   andJID:jid];
  [ahc addCommandWithNode:@"station-next"     andName:@"What's on the current station next"  andJID:jid];
  [ahc addCommandWithNode:@"station-list"     andName:@"List all available stations"         andJID:jid];
  [ahc addCommandWithNode:@"station-schedule" andName:@"Schedule for station <key>"          andJID:jid];
  [ahc addDelegate:self];
  NSLog(@"commands: %@", [ahc commands]);
  */
  
  // create a pubsub connection
  
  pubsub = [[XMPPPubSub alloc] initWithStream:[self xmppStream]];
  [pubsub setPubsubService:[XMPPJID jidWithString:DR_XMPP_PUBSUB_SERVICE]];
  [pubsub addDelegate:self];
   
	// attempt to connect to your host

	NSError *error = nil;
  BOOL success;
  success = [[self xmppStream] connect:&error];
	
	if (!success) {
		NSLog(@"Error! %@", [error localizedDescription]);
	}
}

- (void)windowDidLoad
{
  self.windowTitle = @"BBC Radio";
  
  [self setNextResponder:empViewController];
  [self buildStationsMenu];
}

- (void)dealloc
{
  [dockIconView release];
  [currentSchedule release];
	[empViewController release];
  [xmppCapabilities release];
  [pubsub release];
  [liveTextView release];
  
	[super dealloc];
}


#pragma mark -
#pragma mark Live Text support
#pragma mark -

- (void)subscribeToLiveTextChannel:(NSString*)channel
{  
  NSString *node = [NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, channel];
  
  [pubsub subscribeToNode:node withOptions:nil];
  NSLog(@"subscribing to : %@", node);  
  
  liveTextView.text = nil;
  [liveTextView progressIndictorOn];
}

- (void)unsubscribeToLiveTextChannel:(NSString*)channel
{
  NSString *node = [NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, channel];
  
  [pubsub unsubscribeFromNode:node];
  NSLog(@"unsubscribing from : %@", node);
  
  liveTextView.text = nil;
  [liveTextView progressIndictorOff];
}

- (void)switchSubscriptionFrom:(NSString*)previous to:(NSString*)next
{
  if ([[self xmppStream] isConnected])
  {
    if (!availableForSubscription) return;
    
    NSLog(@"Switching to previous: %@ next: %@", previous, next);
    [self unsubscribeToLiveTextChannel:previous];
    [self subscribeToLiveTextChannel:next];
  }
}


#pragma -
#pragma NSToolbar delegate
#pragma -

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar 
     itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag
{      
  NSToolbarItem *liveTextToolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:@"livetext"] autorelease];  
  [liveTextToolbarItem setView:liveTextView];
  
	return liveTextToolbarItem;
}




#pragma mark -
#pragma mark Emp methods
#pragma mark -

- (void)fetchRADIO:(NSDictionary *)station
{  
  self.windowTitle = @"Loading Schedule...";
  
  liveTextView.text = nil;
  [liveTextView progressIndictorOn];
  
  [self switchSubscriptionFrom:[currentStation objectForKey:@"livetext_node"] 
                            to:[station objectForKey:@"livetext_node"]];
  
  currentStation = station;  
  [empViewController fetchEMP:currentStation];
  
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"key"]];
  [self fetchNewSchedule:nil];
  
  [[self scrobbler] flushBuffer];
}

- (void)fetchAOD:(id)sender
{
  liveTextView.text = @"Livetext not available";
  [liveTextView progressIndictorOff];
  
  [self stopScheduleTimer];
  BBCBroadcast *broadcast = [currentSchedule.broadcasts objectAtIndex:[sender tag]];
  currentBroadcast = broadcast;  
  self.windowTitle = [currentSchedule broadcastDisplayTitleForIndex:[sender tag]];
  [empViewController fetchAOD:[broadcast pid]];
  
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"key"]];
  [self buildScheduleMenu];
  [self growl];
  
  [[self scrobbler] flushBuffer];
}

- (void)changeDockNetworkIconTo:(NSString *)service
{
  NSImage *img = [NSImage imageNamed:service];
  [dockIconView setNetworkIcon:img];
  
  if ([[self scrobbler] isAuthorised]) {
    [dockIconView setShowLastFM:YES];
  } else {
    [dockIconView setShowLastFM:NO];
  }
  
	[[NSApp dockTile] display];
}

- (void)fetchNewSchedule:(id)sender
{
  [currentSchedule removeObserver:self forKeyPath:@"broadcasts"];
  BBCSchedule *sc = [[BBCSchedule alloc] initUsingNetwork:[currentStation objectForKey:@"key"] 
                                                andOutlet:[currentStation objectForKey:@"outlet"]];
  
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
  if (currentSchedule.current_broadcast) {
    currentBroadcast = currentSchedule.current_broadcast;
    self.windowTitle = [currentSchedule.service title];
    [self buildScheduleMenu];
    [self startScheduleTimer];
    [self growl];
  }
}

- (void)growl
{
  NSImage *img = [[NSImage alloc] initWithData:[dockIconView dataWithPDFInsideRect:[dockIconView frame]]];
  [GrowlApplicationBridge notifyWithTitle:[currentSchedule.service title]
                              description:[[currentBroadcast display_titles] objectForKey:@"title"]
                         notificationName:@"Now on air"
                                 iconData:[img TIFFRepresentation]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  [img release];
}

- (NSString *)liveOrNotText
{
  if ([empViewController isLive]) {
    return @"listening to";
  } else {
    return @"catching up with"; 
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
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:currentBroadcast.end
                                            interval:0.0
                                              target:self
                                            selector:@selector(fetchNewSchedule:)
                                            userInfo:nil
                                             repeats:NO];
  NSLog(@"Timer started and will be fired again at %@", currentBroadcast.end);
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
    
    start = [broadcast.start descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" 
                                                                   action:NULL 
                                                            keyEquivalent:@""];
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@  %@", start, [broadcast.display_titles objectForKey:@"title"]];
    NSString *state = @"";
    
    if ([broadcast isEqual:currentBroadcast] == YES) {
      state = @" NOW PLAYING";
      [newItem setState:NSOnState];
    } else if ([broadcast isEqual:currentSchedule.current_broadcast] == YES) {
      state = @" LIVE";
      [newItem setAction:@selector(refreshStation:)];
    } else if (broadcast.media && [[broadcast.media objectForKey:@"format"] isEqualToString:@"audio"]) {
      [newItem setAction:@selector(fetchAOD:)]; 
    }
    
    [str appendString:state];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:str];
    NSString *display_title = [broadcast.display_titles objectForKey:@"title"];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange(0,[start length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange([start length]+1,[display_title length])];

    [string addAttribute:NSForegroundColorAttributeName
                   value:[NSColor lightGrayColor]
                   range:NSMakeRange(2+[start length]+[display_title length],[state length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:9]
                   range:NSMakeRange(2+[start length]+[display_title length],[state length])];

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

- (void)windowDidResignMain:(NSNotification *)notification
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
    [[self window] setLevel:NSMainMenuWindowLevel];
  } else {
    [[self window] setLevel:NSNormalWindowLevel];
  }
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{  
  return [window frame].size;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{  
  return YES;
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

  result.size = [empViewController windowSize];
  
  // adjust to allow for toolbar
  if ([toolBar isVisible]) {    
    result.size.height = result.size.height + 28;
  } else {
    result.size.height = result.size.height - 3;
  }
  
  return result;
}


#pragma mark -
#pragma mark Presence Management
#pragma mark -

- (void)goOnline
{
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
  NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
  [status setStringValue:@"RadioAunty is Ready..."];
  [presence addChild:status];
  
	[[self xmppStream] sendElement:presence];
}


- (void)goOffline
{
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addAttributeWithName:@"type" stringValue:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}


#pragma mark -
#pragma mark XMPPClient Delegate Methods
#pragma mark -

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{	
  NSLog(@"Attempting to Authorise Anonymously...");
  
	NSError *error = nil;
	BOOL success;
	success = [[self xmppStream] authenticateAnonymously:&error];
	
	if (!success) {
		NSLog(@"Error! %@", [error localizedDescription]);
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{	
  NSLog(@"Authenticated ok");
  
  // Send presence
  
	[self goOnline];
  
  // unsubscribe subscribe to the livetext node of the current station
  // TODO This is clearly messy and needs to be done properly
  
  [self subscribeToLiveTextChannel:[currentStation objectForKey:@"livetext_node"]];
  availableForSubscription = YES;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{	
  NSLog(@"XMPP Connection has disconnected");
  liveTextView.text = DR_CONTENT_UNAVAILABLE;
  [liveTextView progressIndictorOff];
}

- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender
{
  NSLog(@"XMPP Connection told to disconnected");
}

- (void)xmppStream:(XMPPStream *)sender didNotConnect:(NSError *)error
{
  NSLog(@"XMPP Connection did not even connect?");
}


#pragma mark -
#pragma mark XMPPAdHocCommands Delegate Methods
#pragma mark -

- (void)xmppAdHocCommands:(XMPPAdHocCommands *)sender didReceiveCommand:(NSString*)command forIQ:(XMPPIQ *)iq
{
  // handle all incoming commands
  //
  // <iq type='set' to='responder@domain' id='exec1'>
  //   <command xmlns='http://jabber.org/protocol/commands' node='list' action='execute'/>
  // </iq>
  
  if ([iq isResultIQ] && [command isEqualToString:@"station"] == YES) {
    
    // return a list of stations as part 1 of a multistage command

    XMPPIQ *iqRes = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
    NSXMLElement *cmdElement = [NSXMLElement elementWithName:@"command" xmlns:@"http://jabber.org/protocol/commands"];
    [cmdElement addAttributeWithName:@"node" stringValue:@"command"];
    [cmdElement addAttributeWithName:@"sessionid" stringValue:[XMPPStream generateUUID]];
    [cmdElement addAttributeWithName:@"status" stringValue:@"executing"];
    
    NSXMLElement *xForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [cmdElement addAttributeWithName:@"type" stringValue:@"result"];
    
    NSXMLElement *title = [NSXMLElement elementWithName:@"title"];
    [title setStringValue:@"Available Stations"];
    [xForm addChild:title];
    
    // actually add the stations
    
    int count = 0;
    for (NSDictionary *station in stations) {
      NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
      [field addAttributeWithName:@"var" stringValue:[NSString stringWithFormat:@"%i", count]];
      [field addAttributeWithName:@"label" stringValue:[station valueForKey:@"label"]];
      [xForm addChild:field];
      count++;
    }
    
    [cmdElement addChild:xForm];
    [iq addChild:cmdElement];

    NSLog(@"Sending return command");
    [[sender xmppStream] sendElement:iqRes];
  }
  
  NSLog(@"command %@", command);
}


#pragma mark -
#pragma mark XMPPPubSub Delegate Methods
#pragma mark -

- (void)xmppPubSub:(XMPPPubSub *)sender didSubscribe:(XMPPIQ *)iq
{
  NSLog(@"pubsub subscribed");
}

- (void)xmppPubSub:(XMPPPubSub *)sender didCreateNode:(NSString*)node withIQ:(XMPPIQ *)iq
{
  NSLog(@"pubsub created node");
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveError:(XMPPIQ *)iq
{
  NSLog(@"pubsub error: %@", iq);
  liveTextView.text = DR_CONTENT_UNAVAILABLE;
  [liveTextView progressIndictorOff];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveResult:(XMPPIQ *)iq
{
  NSLog(@"pubsub result");
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveMessage:(XMPPMessage *)message
{
  //if ([message elementForName:@"delay"]) return;
  
  NSString *txt = [[[[[message elementForName:@"event"] 
                               elementForName:@"items"] 
                               elementForName:@"item"] 
                               elementForName:@"text"] stringValue];
  
  if (!txt) return;
  
  NSString *match = @"Now playing: ";
  if ([txt hasPrefix:match])
  {
    // first remove the now playing bit
    NSString *string = [txt stringByReplacingOccurrencesOfString:match withString:@""];
    NSRange split = [string rangeOfString:@" by "];
    NSString *track  = [string substringWithRange:NSMakeRange(0,split.location)];
    NSString *artist = [string substringWithRange:NSMakeRange(split.location+split.length,
                                                              [string length]-split.location-split.length-1)];
    
    // has the user allowed the app to scrobble
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultLastFMEnabled"] == YES)
        && [[self scrobbler] isAuthorised]) {
      
      // scrobble track and artist      
      NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                              track, @"track",
                              artist, @"artist",
                              [currentStation objectForKey:@"key"], @"network",
                              nil];
      
      NSError *error = nil;      
      BOOL success = [[self scrobbler] scrobbleWithParams:params error:&error];
      
      if (!success) {
        NSLog(@"Error! %@", [error localizedDescription]);
      }
    }
  }
  
  NSLog(@"Message: %@", txt);
  
  if (liveTextView) {
    liveTextView.text = txt;
    [liveTextView progressIndictorOff];
  }
}

@end
