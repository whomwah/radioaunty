//
//  MainWindowController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "settings.h"
#import "MainWindowController.h"
#import "EmpViewController.h"
#import "BBCBroadcast.h"
#import "BBCSchedule.h"
#import "DockView.h"
#import "LiveTextView.h"
#import "ListenMenuItem.h"
#import "ScheduleMenuItem.h"
#import "ScheduleMenuListItem.h"
#import "AppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPPubSub.h"

@implementation MainWindowController

@synthesize windowTitle;
@synthesize liveTextView;
@synthesize scheduleTimer;
@synthesize schedules;
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
  [[empViewController view] setFrameSize:[mainView frame].size];
  [mainView addSubview:[empViewController view] 
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
	[[self xmppStream] addDelegate:self];
	[[self xmppStream] setHostName:DR_XMPP_HOST];
  [[self xmppStream] setMyJID:[XMPPJID jidWithString:DR_XMPP_ANON]];
  
  // add xmpp capabilities storage  
  XMPPCapabilitiesCoreDataStorage *cap_core = [[XMPPCapabilitiesCoreDataStorage alloc] init];
  xmppCapabilities = [[XMPPCapabilities alloc] initWithStream:[self xmppStream] capabilitiesStorage:cap_core];
  [cap_core release];
  
  // create a pubsub connection
  pubsub = [[XMPPPubSub alloc] initWithStream:[self xmppStream]];
  [pubsub setPubsubService:[XMPPJID jidWithString:DR_XMPP_PUBSUB_SERVICE]];
  [pubsub addDelegate:self];
  
  // setup somewhere to store the subscriptions
  subscriptions = [[NSMutableArray arrayWithCapacity:1] retain];
   
	// attempt to connect to the xmpp host
	NSError *error = nil;
  BOOL success = [[self xmppStream] connect:&error];
	
	if (!success) {
		DLog(@"Error! %@", [error localizedDescription]);
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
	[empViewController release];
  [xmppCapabilities release];
  [pubsub release];
  [liveTextView release];
  [currentStation release];
  [schedules release];
  
	[super dealloc];
}


#pragma mark -
#pragma mark Live Text support
#pragma mark -

/**
 * Will attempt to unsubscibe to all livetext streams
 **/

- (void)unsubscribeFromLiveTextChannels
{
  // fail if no subscriptions or not connected
  if (([subscriptions count] < 1) || ![[self xmppStream] isConnected]) return;
  
  // unsubsubscribe from all subscritions
  for (NSString *channel in subscriptions) {
    // unsubscribe to the specified station
    [pubsub unsubscribeFromNode:[NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, channel]];
    
    DLog(@"unsubscribing to channel: %@", channel);
  }
  
  // clear subscriptions
  [subscriptions removeAllObjects];
  
  // clear the liveTextField and turn the progress indictor off
  [liveTextView progressIndictorOff];
}

/**
 * Will attempt to subscibe to passedin channel
 **/

- (void)subscribeToLiveTextChannel:(NSString*)channel
{    
  // fail if no channel or not connected
  if (!channel || ![[self xmppStream] isConnected]) return;
  
  // fetch the livetext key for this channel
  NSString *key = [[self livetextLookup] objectForKey:channel];
  
  // return if we are already subscribed to the channel provided
  if (!key || ([subscriptions indexOfObject:channel] != NSNotFound)) return;
  
  // we should only be subscribed to one channel at a time,
  // so let's unsubscribe the rest
  [self unsubscribeFromLiveTextChannels];
  
  DLog(@"subscribing to channel: %@", key);
  
  // turn the liveText progress indicator on
  [liveTextView progressIndictorOn];
  
  // subscribe to the specified station
  [pubsub subscribeToNode:[NSString stringWithFormat:@"%@%@", DR_XMPP_PUBSUB_NODE, key] 
              withOptions:nil];
  
  // add out channel to the subscriptions list
  [subscriptions addObject:key];
  
  // make sure we clear the liveTextField and then start the progress indicator
  [liveTextView progressIndictorOn];
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

  // fetch out the station key for reuse
  NSString *stationKey = [station objectForKey:@"key"];
  
  // logging
  DLog(@"Fetching LIVE: %@", stationKey);
  
  // if the channel we're switching to does not support
  // livetext, then hide the toolbar and do our
  // best to unsubscribe to any current livetext
  if ([[self livetextLookup] objectForKey:stationKey]) {
    
    // subscribe to the new station
    [self subscribeToLiveTextChannel:stationKey];

  } else {
    
    // clear the subscriptions
    [[self window] setShowsToolbarButton:NO];
    [toolBar setVisible:NO];
    [self unsubscribeFromLiveTextChannels];
  }

  // re-set the current station
  self.currentStation = station;
  
  // go and fetch the new schedule for this station 
  [self prepareSchedules:nil];
  
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
  BBCSchedule *s;
  
  // set the tag
  int tag = [[sender performSelector:@selector(parentItem)] tag];
  if (tag < 1) {
    // set the current schedule
    s = [self currentSchedule];
  } else {
    // set one of the 7 day catchup
    s = [schedules objectAtIndex:(tag/100)];
  }
  
  // set the window title to something sane
  self.windowTitle = [s broadcastDisplayTitleForIndex:[sender tag]];
  
  // hide the toolbar and any chance of revealing it
  [[self window] setShowsToolbarButton:NO];
  [toolBar setVisible:NO];

  // unsubscribe from the current livetext channel
  [self unsubscribeFromLiveTextChannels];
  
  // logging
  DLog(@"Fetching AOD: %@", [currentStation objectForKey:@"key"]);
  
  // clear any progress indictors
  [liveTextView progressIndictorOff];
  
  // clear the schedule timer as we not listening to live radio
  [self stopScheduleTimer];
  
  // fetch out broadcast information based on the selected item in the menu
  BBCBroadcast *broadcast = [s.broadcasts objectAtIndex:[sender tag]];
  
  // set the above as the current broadcast
  currentBroadcast = broadcast;  
  
  // switch the app icon to reflect the new station
  [self changeDockNetworkIconTo:[currentStation objectForKey:@"id"]];
  
  // rebuild schedule menu to reflect the AODness
  [self buildSchedule];
  
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
 * Fires off a growl message that let's people know which station and show
 * we are listening to.
 **/

- (void)growl
{
  // create a new image based on the dock icon
  NSImage *img = [[NSImage alloc] initWithData:[dockIconView dataWithPDFInsideRect:[dockIconView frame]]];

  // fire off the message
  [GrowlApplicationBridge notifyWithTitle:[[self currentSchedule].service title]
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
            ListenMenuItem *menuItem = [[ListenMenuItem allocWithZone:[NSMenu menuZone]] init];
            
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

            [menuItem release];
            count++;          
          }
        }

      } else {
        
        // create a new menu item
        ListenMenuItem *menuItem = [[ListenMenuItem allocWithZone:[NSMenu menuZone]] init];
        
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
        
        [menuItem release];
        count++;
      }
    }

  }
}

#pragma mark -
#pragma mark Build Schedule menu
#pragma mark -

/**
 * Fetch the first item in the schedules array as
 * this will be the current day
 **/

- (BBCSchedule*)currentSchedule
{
  if (schedules) {
    return [schedules objectAtIndex:0];
  }
  return nil;
}

/**
 * Fetches a new schedule from the BBC
 **/

- (void)prepareSchedules:(id)sender
{   
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
  
  // if we have created schedules before we would have
  // added many observers, which we need to remove
  if (schedules) {
    for (BBCSchedule *s in schedules) {
      [s removeObserver:self forKeyPath:@"broadcasts"];     
    }
  }
  
  // how far do we want to go back based
  // on the 7 day window for AOD
  int noDaysToShow = 8;

  // create our schedules array
  self.schedules = [NSMutableArray arrayWithCapacity:noDaysToShow];
  
  // set a initial date of now
  NSDate *d = [NSDate date];
  
  // set up date components
  NSDateComponents *components = [[NSDateComponents alloc] init];

  // create a calendar
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  
  // loop through and create the schedules
  for (int i=0; i<noDaysToShow; i++) {
    
    // create a new schedule object
    BBCSchedule *sc = [[BBCSchedule alloc] initUsingNetwork:[currentStation objectForKey:@"key"] 
                                                  andOutlet:outlet];
    sc.date = d;
    
    // only actually fetch the current schedule
    //if (i < 1) [sc fetch];
    [sc fetch];
    
    // add an observer that watches to see when we have new broadcasts
    [sc addObserver:self
         forKeyPath:@"broadcasts"
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
    
    // add the schedule to the list
    [schedules addObject:sc];
    
    // free me
    [sc release];
    
    // increment the date by -1 day
    [components setDay:-1];
    d = [gregorian dateByAddingComponents:components toDate:d options:0];
  }
  
  [components release];
  [gregorian release];
}

/**
 * any observers will call this method if something changes. We can then find
 * out what changed and decide the next move
 **/

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{  
  // if we're not dealing with a BBCSchedule, return;
  if (![object isKindOfClass:[BBCSchedule class]]) {
    return;
  }
  
  // do we have a current_broadcast, probably a new one
  if ([object isEqual:[self currentSchedule]] &&
      [self currentSchedule].current_broadcast) {
    
    // set the newly changed broadcast
    currentBroadcast = [self currentSchedule].current_broadcast;
    
    // update the window title
    self.windowTitle = [[self currentSchedule].service title];
    
    // update the schedule menu
    [self buildSchedule];
    
    // start the schedule timer
    [self startScheduleTimer];
    
    // tell everyone
    [self growl];
  } else {
    // rebuild the schedules menu
    // TODO: This is overkill at the moment as we erbuild
    // the whole schedule menu rather than the one that has changed
    [self buildSchedule];
  }

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
                                            selector:@selector(prepareSchedules:)
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
 * Constructs and returns an NSMenuItem containing an NSMenu
 * of schedule menuitems for a specified day
 **/

- (NSMenuItem*)constructScheduleMenu:(BBCSchedule*)schedule
{
  // format the schedule date into a readable date string for the menu title
  NSString *day = [schedule.date descriptionWithCalendarFormat:@"%A %d %B" timeZone:nil locale:nil];
  
  // create a menu item that will act as the entry poiny for the submenu
  ScheduleMenuListItem *scheduleMenuItem = [[[ScheduleMenuListItem alloc] init] autorelease];
  scheduleMenuItem.title = day;
  [scheduleMenuItem setTag:[schedules indexOfObject:schedule]*100];
  [scheduleMenuItem createLabel];
  
  // create the submenu to hold all the schedule items
  NSMenu *subMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  
  // set a counter
  int count = 0;
  
  // loop through all the broadcasts and add them to the submenu
  ScheduleMenuItem *mitem;
  for (BBCBroadcast *broadcast in schedule.broadcasts) {
    
    // create a new menu item
    mitem = [[ScheduleMenuItem alloc] init];
    mitem.start = broadcast.start;
    mitem.title = [broadcast.display_titles objectForKey:@"title"];
    mitem.availability = broadcast.availability;
    mitem.short_synopsis = broadcast.short_synopsis;
    [mitem setTarget:self];
    
    if ([broadcast isEqual:currentBroadcast]) {
      mitem.currentState = @"NOW PLAYING";
      [mitem setState:NSOnState];
      [mitem setAction:NULL];
      
      // display so you know that the parent has an active child
      [scheduleMenuItem setState:NSMixedState];
      
    } else if (broadcast.media && [[broadcast.media objectForKey:@"format"] isEqualToString:@"audio"]) {
      [mitem setAction:@selector(fetchAOD:)];
    }
    
    [mitem createLabel];
    [mitem setEnabled:YES];
    [mitem setTag:count];
    [mitem setEnabled:YES];
    [subMenu addItem:mitem];
    [mitem release];
    
    count++;
  }
  
  // add the submenu to the menu item
  [scheduleMenuItem setSubmenu:subMenu];
  [subMenu release];
  
  return scheduleMenuItem;
}

/**
 * Build the menu used to display the schedule
 * NOTE: Not used yet
 **/

- (void)menuWillOpen:(NSMenu *)menu
{
}

/**
 * Creates the schedule menu you see in the main menu of the applications
 **/

- (void)buildSchedule
{
  // fetch out the 'Schedule' menu, ready to build
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  

  int count = 0;
  
  // clear the current menu
  for (NSMenuItem *item in [scheduleMenu itemArray]) {  
    [scheduleMenu removeItem:item];
  }
  
  // add previous schedules
  for (BBCSchedule *s in schedules) {    
    if (count > 0) {    
      [scheduleMenu addItem:[self constructScheduleMenu:s]];
    }
    
    count++;
  }

  // add the separator between days and the current schedule
  [scheduleMenu addItem:[NSMenuItem separatorItem]];
  
  // loop through all the broadcasts
  count = 0;
  ScheduleMenuItem *newItem;
  for (BBCBroadcast *broadcast in [self currentSchedule].broadcasts) {
     
    // create a new menu item
    newItem = [[ScheduleMenuItem alloc] init];
    newItem.start = broadcast.start;
    newItem.title = [broadcast.display_titles objectForKey:@"title"];
    newItem.availability = broadcast.availability;
    newItem.short_synopsis = broadcast.short_synopsis;
    [newItem setTarget:self];
    
    if ([broadcast isEqual:currentBroadcast]) {
      newItem.currentState = @"NOW PLAYING";
      [newItem setState:NSOnState];
      [newItem setAction:NULL];
    } else if ([broadcast isEqual:[self currentSchedule].current_broadcast]) {
      newItem.currentState = @"LIVE";
      [newItem setAction:@selector(refreshStation:)];
    } else if (broadcast.media && [[broadcast.media objectForKey:@"format"] isEqualToString:@"audio"]) {
      [newItem setAction:@selector(fetchAOD:)];
    }
    
    [newItem createLabel];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    [newItem setEnabled:YES];
    [scheduleMenu addItem:newItem];
    [newItem release];
    
    count++;
  }
}

/**
 * Causes the emp view to redraw itself
 **/

- (void)redrawEmp
{
  [[empViewController view] setNeedsDisplay:YES];  
}

/**
 * behaves as though you have choosen another station. This is
 * a bit of a helper if the station does not load as expected. It's
 * like pressing the refresh/reload button in your browser
 **/

- (IBAction)refreshStation:(id)sender
{
  [self fetchRADIO:currentStation];
}

#pragma mark -
#pragma mark Main Window delegate
#pragma mark -

/**
 * called when you click away from the application. It is here
 * we attempt to keep the app at the top of the window stack
 **/

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
  DLog(@"Attempting to Authorise Anonymously...");
  
	NSError *error = nil;
	BOOL success;
	success = [[self xmppStream] authenticateAnonymously:&error];
	
	if (!success) {
		DLog(@"Error! %@", [error localizedDescription]);
    [liveTextView progressIndictorOff];
    [[self window] setShowsToolbarButton:NO];
    [toolBar setVisible:NO];
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{	
  DLog(@"Authenticated ok");
  
  // Send presence
  
	[self goOnline];
  
  // unsubscribe subscribe to the livetext node of the current station
  // TODO This is clearly messy and needs to be done properly
  
  [self subscribeToLiveTextChannel:[currentStation objectForKey:@"key"]];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{	
  DLog(@"XMPP Connection has disconnected");
  [liveTextView progressIndictorOff];
  [[self window] setShowsToolbarButton:NO];
  [toolBar setVisible:NO];
}

- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender
{
  DLog(@"XMPP Connection told to disconnected");
}

- (void)xmppStream:(XMPPStream *)sender didNotConnect:(NSError *)error
{
  DLog(@"XMPP Connection did not even connect?");
  [liveTextView progressIndictorOff];
  [[self window] setShowsToolbarButton:NO];
  [toolBar setVisible:NO];
}

#pragma mark -
#pragma mark XMPPPubSub Delegate Methods
#pragma mark -

- (void)xmppPubSub:(XMPPPubSub *)sender didSubscribe:(XMPPIQ *)iq
{
  DLog(@"pubsub subscribed");
  [[self window] setShowsToolbarButton:YES];
  [toolBar setVisible:YES];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didCreateNode:(NSString*)node withIQ:(XMPPIQ *)iq
{
  DLog(@"pubsub created node");
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveError:(XMPPIQ *)iq
{
  DLog(@"pubsub error: %@", iq);
  [liveTextView progressIndictorOff];
  [[self window] setShowsToolbarButton:NO];
  [toolBar setVisible:NO];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveResult:(XMPPIQ *)iq
{
  DLog(@"pubsub result");
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
        DLog(@"Error! %@", [error localizedDescription]);
      }
    }
  }
  
  DLog(@"Message: %@", txt);
  
  if (liveTextView) {
    [liveTextView progressIndictorOff];
    liveTextView.text = txt;
  }
}

@end
