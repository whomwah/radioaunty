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
#import "ListenMenuItem.h"
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
@synthesize currentStation;

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
 * Gives us a hook to the livetext hash table
 * in the AppDelegate
 **/

- (NSDictionary *)livetextLookup
{
	return [[NSApp delegate] livetextLookup];
}

/**
 * Lots of setup going on here
 **/

- (void)awakeFromNib
{  
  // fetch out the user defaults data, as we'll be using it a lot
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  // set the station list based on the user defaults
  stations = [ud arrayForKey:@"Services"];
  
  // set the current station based on the user defaults
  self.currentStation = [stations objectAtIndex:[ud integerForKey:@"DefaultStation"]];
  
  // create our custom dock icon view
  NSRect dockIconViewRect = NSMakeRect(0, 0, [NSApp dockTile].size.width, [NSApp dockTile].size.height);
  dockIconView = [[DockView alloc] initWithFrame:dockIconViewRect 
                                         withKey:[currentStation objectForKey:@"key"]];
  [[NSApp dockTile] setContentView:dockIconView];
	[[NSApp dockTile] display];
  
  // create our liveText view and add to the apps toolbar
  liveTextView = [[LiveTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 26)];
	[toolBar insertItemWithItemIdentifier:@"livetext" atIndex:0];
  
  // create our emp controller which handles the playing of audio
  empViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  [[empViewController view] setFrameSize:[drMainView frame].size];
  [drMainView addSubview:[empViewController view] 
              positioned:NSWindowBelow
              relativeTo:nil];
  
  // attempt to fetch the default radio station
  [self fetchRADIO:currentStation];

  // adjust window size based on if the toolbar is showing
  int toolBarAdjust = 0;
  if ([toolBar isVisible]) {    
    toolBarAdjust = 25;
  }

  // create the rect to use for setting the windows frame
  NSPoint point = NSPointFromString([ud stringForKey:@"DefaultEmpOrigin"]);
  NSRect rect = NSMakeRect(point.x, point.y,
                           [empViewController windowSize].width, 
                           [empViewController windowSize].height + toolBarAdjust);
  [[self window] setFrame:rect display:NO];
  
	// setup connecting to the XMPP host anonomously
  availableForSubscription = NO;
	[[self xmppStream] addDelegate:self];
	[[self xmppStream] setHostName:DR_XMPP_HOST];
  [[self xmppStream] setMyJID:[XMPPJID jidWithString:DR_XMPP_ANON]];
  
  // add xmpp capabilities storage  
  XMPPCapabilitiesCoreDataStorage *cap_core = [[XMPPCapabilitiesCoreDataStorage alloc] init];
  xmppCapabilities = [[XMPPCapabilities alloc] initWithStream:[self xmppStream] capabilitiesStorage:cap_core];
  [cap_core release];
	
  /*
  TODO - Impliment the Ad-Hoc Commands work
   
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
  */
  
  // create a pubsub connection
  pubsub = [[XMPPPubSub alloc] initWithStream:[self xmppStream]];
  [pubsub setPubsubService:[XMPPJID jidWithString:DR_XMPP_PUBSUB_SERVICE]];
  [pubsub addDelegate:self];
   
	// attempt to connect to the xmpp host
	NSError *error = nil;
  BOOL success = [[self xmppStream] connect:&error];
	
	if (!success) {
		NSLog(@"Error! %@", [error localizedDescription]);
	}
}

/**
 * Called when the main window has loaded
 **/

- (void)windowDidLoad
{
  // give the window a sane title
  self.windowTitle = @"BBC Radio";
  
  // build the stations menu
  [self buildStationsMenu];
}

/**
 * Make sure we dealloc stuff, although if this is called
 * I guess the app is quitting
 **/

- (void)dealloc
{
  [dockIconView release];
  [currentSchedule release];
	[empViewController release];
  [xmppCapabilities release];
  [pubsub release];
  [liveTextView release];
  [currentStation release];
  
	[super dealloc];
}


#pragma mark -
#pragma mark Live Text support
#pragma mark -

/**
 * A series of methods that help when switching stations and
 * handling the livetext subscriptions.
 **/

- (void)subscribeToLiveTextChannel:(NSString*)channel
{  
  // fail if no channel
  if (!channel) return;
  
  // subscribe to the specified station
  [pubsub subscribeToNode:[NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, channel] 
              withOptions:nil];
  
  // make sure we clear the liveTextField and then start the progress indicator
  [liveTextView progressIndictorOn];
}

- (void)unsubscribeToLiveTextChannel:(NSString*)channel
{
  // fail if no channel
  if (!channel) return;
  
  // unsubscribe to the specified station
  [pubsub unsubscribeFromNode:[NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, channel]];
  
  // clear the liveTextField and turn the progress indictor off
  [liveTextView progressIndictorOff];
}

- (void)switchSubscriptionFrom:(NSString*)previous to:(NSString*)next
{  
  // decide whether to switch subscription or not
  if ([[self xmppStream] isConnected]) {
    if (!availableForSubscription) return;
    
    if (previous) [self unsubscribeToLiveTextChannel:previous];
    if (next) [self subscribeToLiveTextChannel:next];
  }
}


#pragma -
#pragma NSToolbar delegate
#pragma -

/**
 * This delegate gets called when the toolbar is ready to insert a toolbar
 * defined by the identifier. It's here we create our custom toolbar
 * for displaying liveText
 **/

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

/**
 * This gets called when we want to switch live radio stations
 **/

- (void)fetchRADIO:(NSDictionary *)station
{  
  // set some kind of preload text
  self.windowTitle = @"Loading Schedule...";

  // fetch out the current station key for reuse
  NSString *currentStationKey = [currentStation objectForKey:@"key"];
  
  // if the channel we're switching to does not support
  // livetext, then hide the toolbar and do our
  // best to unsubscribe to any current livetext
  if ([[self livetextLookup] objectForKey:[station objectForKey:@"key"]]) {
    
    [[self window] setShowsToolbarButton:YES];
    [toolBar setVisible:YES];
    
    // turn the liveText progress indicator on
    [liveTextView progressIndictorOn];
    
    // switch subscriptions from any previous station to the new one
    [self switchSubscriptionFrom:[[self livetextLookup] objectForKey:currentStationKey] 
                              to:[[self livetextLookup] objectForKey:[station objectForKey:@"key"]]];
  } else {
    
    [[self window] setShowsToolbarButton:NO];
    [toolBar setVisible:NO];
    [self unsubscribeToLiveTextChannel:[[self livetextLookup] objectForKey:currentStationKey]];
  }

  // re-set the current station
  self.currentStation = station;
  
  // go and fetch the new schedule for this station 
  [self fetchNewSchedule:nil];
  
  // switch the app icon to reflect the new station
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"id"]];
  
  // clear our any scrobble information we have stored. This
  // won't do anything if we are not authorised to do so
  [[self scrobbler] flushBuffer];
  
  // make the call that actually loads the new station
  [empViewController fetchEMP:currentStation];
}

/**
 * This gets called when we want to switch to on-demand listening
 **/

- (void)fetchAOD:(id)sender
{
  // set the window title to something sane
  self.windowTitle = [currentSchedule broadcastDisplayTitleForIndex:[sender tag]];
  
  // hide the toolbar and any chance of revealing it
  [[self window] setShowsToolbarButton:NO];
  [toolBar setVisible:NO];

  // unsubscribe from the current livetext channel
  NSString *key = [[self livetextLookup] objectForKey:[currentStation objectForKey:@"key"]];
  if (key) [self unsubscribeToLiveTextChannel:key];
  
  // clear any progress indictors
  [liveTextView progressIndictorOff];
  
  // clear the schedule timer as we not listening to live radio
  [self stopScheduleTimer];
  
  // fetch out broadcast information based on the selected item in the menu
  BBCBroadcast *broadcast = [currentSchedule.broadcasts objectAtIndex:[sender tag]];
  
  // set the above as the current broadcast
  currentBroadcast = broadcast;  
  
  // switch the app icon to reflect the new station
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"id"]];
  
  // rebuild schedule menu to reflect the AODness
  [self buildScheduleMenu];
  
  // growl what we're listening to
  [self growl];
  
  // clear our any scrobble information we have stored. This
  // won't do anything if we are not authorised to do so
  [[self scrobbler] flushBuffer];
  
  // make the call that fetches the on-demand and plays it
  [empViewController fetchAOD:[broadcast pid]];
}

/**
 * This switches the network icon to reflect the service key passed. It will
 * also display the fact that the app is scobbling if available
 **/

- (void)changeDockNetworkIconTo:(NSString *)key
{
  // fetch the network icon and add it to the docicon
  NSImage *img = [NSImage imageNamed:key];
  [dockIconView setNetworkIcon:img];
  
  // update the dock
	[[NSApp dockTile] display];
}

/**
 * Fetches a new schedule from the BBC
 **/

- (void)fetchNewSchedule:(id)sender
{  
  // stop observing the broadcasts instance variable
  [currentSchedule removeObserver:self forKeyPath:@"broadcasts"];
  
  // fetch the user defined stations
  NSDictionary *serviceSelection = [[NSUserDefaults standardUserDefaults] objectForKey:@"ServiceSelection"];
  
  // decide which outlet is used, if any
  NSArray *outlets = [currentStation objectForKey:@"outlets"];
  NSString *outlet = nil;
  
  if (outlets) {
    
    // loop through outlets and choose which one matches
    // the one in our selections.
    for (NSDictionary *ol in outlets) {
      NSString *match = [serviceSelection objectForKey:[currentStation objectForKey:@"id"]];
      if (match && [match isEqual:[ol objectForKey:@"id"]]) {
        outlet = [ol objectForKey:@"key"];
        break;
      }
    }
    
    // if none match, select the first
    if (!outlet) {
      outlet = [[outlets objectAtIndex:0] objectForKey:@"key"];
    }
    
  }
  
  // create a new schedule object using the current outlet and key
  BBCSchedule *sc = [[BBCSchedule alloc] initUsingNetwork:[currentStation objectForKey:@"key"] 
                                                andOutlet:outlet];
  
  // make the call to fetch the data
  [sc fetchScheduleForDate:[NSDate date]];
  
  // set this instance to the current schedule
  self.currentSchedule = sc;
  
  // add an observer that watches to see when we have new broadcasts
  [currentSchedule addObserver:self
                    forKeyPath:@"broadcasts"
                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                       context:NULL];
  
  // free some memory
  [sc release];  
}

/**
 * any observers will call this method if something changes. We can then find
 * out what changed and decide the next move
 **/

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  // do we have a current_broadcast, probably a new one
  if (currentSchedule.current_broadcast) {
    // set the newly changed broadcast
    currentBroadcast = currentSchedule.current_broadcast;
    
    // update the window title
    self.windowTitle = [currentSchedule.service title];
    
    // update the schedule menu
    [self buildScheduleMenu];
    
    // start the schedule timer
    [self startScheduleTimer];
    
    // tell everyone
    [self growl];
  }
}

/**
 * Fires off a growl message that let's people know which station and show
 * we are listening to.
 **/

- (void)growl
{
  // create a new image based on the dock icon
  NSImage *img = [[NSImage alloc] initWithData:[dockIconView dataWithPDFInsideRect:[dockIconView frame]]];

  // fire off the message
  [GrowlApplicationBridge notifyWithTitle:[currentSchedule.service title]
                              description:[[currentBroadcast display_titles] objectForKey:@"title"]
                         notificationName:@"Now on air"
                                 iconData:[img TIFFRepresentation]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  // free some memory
  [img release];
}

/**
 * stop the schedule timer that adjusts to which show is live
 **/

- (void)stopScheduleTimer
{
  [scheduleTimer invalidate];
  self.scheduleTimer = nil;  
}

/**
 * start the schedule timer and invalidate any that are running. This
 * method is used to update the schedule when ever a show comes to the
 * end. It calls fetchNewBroadcast, which in turn makes sure the UI
 * reflects the new schedule data
 **/

- (void)startScheduleTimer
{
  // stop the timer, just in case it's running
  [self stopScheduleTimer];
  
  // set a timer that loads the schedule again when the 
  // current broadcast has finshed
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:currentBroadcast.end
                                            interval:0.0
                                              target:self
                                            selector:@selector(fetchNewSchedule:)
                                            userInfo:nil
                                             repeats:NO];
  
  // add the timer to the current run loop
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
  
  // assign the timer to something so we can turn it off
  // when we need to
  self.scheduleTimer = timer;
}

/**
 * Called when someone selects a new station from the menu
 **/

- (void)changeStation:(id)sender
{
  // update the default station, the app always start on the last
  // station selected
  [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"DefaultStation"];

  // go and fetch the new station based on the selected menu item
  [self fetchRADIO:[stations objectAtIndex:[sender tag]]];
  
  // re-build the station menu
  [self buildStationsMenu];
}

#pragma mark -
#pragma mark Build Listen menu
#pragma mark -


// How about just passing in the station and index and infuring the rest ????

- (NSMenuItem*)createStation:(NSDictionary*)station 
                   withTitle:(NSAttributedString*)title
                      andKey:(NSString*)key 
                    forIndex:(int)index
{  
  // create a new menu item with the station name as the title
  ListenMenuItem *menuItem = [[[ListenMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
  
  // set it to enable if it's the current station
  if ([currentStation isEqualTo:station] == YES) {
    [menuItem setState:NSOnState];
  }
  
  // create the station image used in the menu
  NSImage *img = [NSImage imageNamed:[station objectForKey:@"id"]];
  [img setSize:NSMakeSize(50.0, 28.0)];
  [menuItem setImage:img];
  
  // set a bunch other object attributes
  [menuItem setAttributedTitle:title];
  [menuItem setAction:@selector(changeStation:)];
  [menuItem setEnabled:YES];
  [menuItem setTag:index];
  [menuItem setTarget:self];
  
  return menuItem;
}

/**
 * Build the station list you see in the Listen menu bar
 **/

- (void)buildStationsMenu
{
  // fetch out the Listen menu bar
  NSMenu *listenMenu = [[[NSApp mainMenu] itemWithTitle:@"Listen"] submenu];

  int count = 0;
  int skipToAllowForExtraItems = 2;
  
  // clear the menu
  for (id item in [listenMenu itemArray]) {  
    if (count >= skipToAllowForExtraItems) {
      [listenMenu removeItem:item];
    }
    count++;
  }
  
  // loop through all the stations and add them to the menu
  count = 0;
  for (NSDictionary *station in stations) {
    
    // try and find the station in our selections list
    NSString *selectionKey = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ServiceSelection"] 
                              objectForKey:[station objectForKey:@"id"]];
    
    // find the station index for use as a menu tag
    int stationIndex = [stations indexOfObject:station];
    
    if (selectionKey) {
      
      // check to see if we have an outlet or outlets
      if ([selectionKey isKindOfClass:[NSString class]] && ![selectionKey isEqual:@""]) {
        
        // we only need to choose one outlet
        for (NSDictionary *outlet in [station objectForKey:@"outlets"]) {
          
          if ([[outlet objectForKey:@"id"] isEqual:selectionKey]) {
            
            // create a new menu item
            ListenMenuItem *menuItem = [[[ListenMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
            
            // set it to enable if it's the current station
            if ([currentStation isEqualTo:station] == YES) {
              [menuItem setState:NSOnState];
            }
            
            menuItem.stationTitle = [station valueForKey:@"title"];
            menuItem.outletTitle  = [outlet valueForKey:@"title"];
            [menuItem setStation];
            [menuItem setTag:stationIndex];
            [menuItem setIconForId:[station valueForKey:@"id"]];
            [menuItem setAction:@selector(changeStation:)];
            [menuItem setTarget:self];
            
            // add the menuitem to our menu
            [listenMenu insertItem:menuItem atIndex:count+skipToAllowForExtraItems];

            count++;          
          }
        }

      } else {
        
        // create a new menu item
        ListenMenuItem *menuItem = [[[ListenMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
        
        // set it to enable if it's the current station
        if ([currentStation isEqualTo:station] == YES) {
          [menuItem setState:NSOnState];
        }
        
        menuItem.stationTitle = [station valueForKey:@"title"];
        [menuItem setStation];
        [menuItem setTag:stationIndex];
        [menuItem setIconForId:[station valueForKey:@"id"]];
        [menuItem setAction:@selector(changeStation:)];
        [menuItem setTarget:self];
         
        // add the menuitem to our menu
        [listenMenu insertItem:menuItem atIndex:count+skipToAllowForExtraItems];
        
        count++;
      }
    }

  }
}

/**
 * Clears the menu passed in
 **/

- (void)clearMenu:(NSMenu *)menu
{
  for (NSMenuItem *item in [menu itemArray]) {  
    [menu removeItem:item];
  }
}

/**
 * Build the menu used to display the schedule
 **/

- (void)buildScheduleMenu
{
  // fetch out the 'Schedule' menu, ready to build
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  
  
  // clear the current menu
  [self clearMenu:scheduleMenu];
  
  // loop through all the broadcasts
  int count = 0;
  NSMenuItem *newItem;
  NSString *start;
  for (BBCBroadcast *broadcast in [currentSchedule broadcasts]) {
 
    // create a string of the start time in HH:MM
    start = [broadcast.start descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    
    // create a new menu item
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] init];
    
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@  %@", start, 
                            [broadcast.display_titles objectForKey:@"title"]];
    
    NSString *state = @"";
    if ([broadcast isEqual:currentBroadcast] == YES) {
      state = @" NOW PLAYING";
      [newItem setState:NSOnState];
      [newItem setAction:NULL];
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
  
  NSString *key = [[self livetextLookup] objectForKey:[currentStation objectForKey:@"key"]];
  if (key) [self subscribeToLiveTextChannel:key];
  availableForSubscription = YES;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{	
  NSLog(@"XMPP Connection has disconnected");
  [liveTextView progressIndictorOff];
  liveTextView.text = DR_CONTENT_UNAVAILABLE;
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
  [liveTextView progressIndictorOff];
  liveTextView.text = DR_CONTENT_UNAVAILABLE;
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
    [liveTextView progressIndictorOff];
    liveTextView.text = txt;
  }
}

@end
