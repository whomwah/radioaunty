//
//  AppDelegate.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "HistoryWindowController.h"
#import "XMPP.h"
#import "Scrobble.h"
#import "Play.h"
#import "settings.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5
// SCNetworkConnectionFlags was renamed to SCNetworkReachabilityFlags in 10.6
typedef SCNetworkConnectionFlags SCNetworkReachabilityFlags;
#endif

@implementation AppDelegate

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize scrobbler;
@synthesize livetextLookup;
@synthesize mainWindowController;

- (id)init
{
	if (self = [super init])
	{
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		NSString *errorDesc = nil;
		NSPropertyListFormat format;
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
		NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
		NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
																					propertyListFromData:plistXML
																					mutabilityOption:NSPropertyListMutableContainersAndLeaves
																					format:&format 
																					errorDescription:&errorDesc];
		if (!temp) {
			NSLog(@"Error: %@", errorDesc);
			[errorDesc release];
		}
    
		[defaultValues setObject:[temp objectForKey:@"Services"] forKey:@"Services"];
		[defaultValues setObject:[temp objectForKey:@"ServiceSelection"] forKey:@"ServiceSelection"];
		[defaultValues setObject:[temp objectForKey:@"EmpSizes"] forKey:@"EmpSizes"];
		[defaultValues setObject:[temp objectForKey:@"DefaultAlwaysOnTop"] forKey:@"DefaultAlwaysOnTop"];
		[defaultValues setObject:[temp objectForKey:@"DefaultStation"] forKey:@"DefaultStation"];
		[defaultValues setObject:[temp objectForKey:@"DefaultEmpSize"] forKey:@"DefaultEmpSize"];
		[defaultValues setObject:[temp objectForKey:@"DefaultEmpMinimized"] forKey:@"DefaultEmpMinimized"];
		[defaultValues setObject:[temp objectForKey:@"DefaultEmpOrigin"] forKey:@"DefaultEmpOrigin"];

    // lastFM defaults
		[defaultValues setObject:[temp objectForKey:@"DefaultLastFMUser"] forKey:@"DefaultLastFMUser"];
		[defaultValues setObject:[temp objectForKey:@"DefaultLastFMSession"] forKey:@"DefaultLastFMSession"];
		[defaultValues setObject:[temp objectForKey:@"DefaultLastFMEnabled"] forKey:@"DefaultLastFMEnabled"];
    
    // livetext
    livetextLookup = [[temp objectForKey:@"LiveText"] retain];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		[ud registerDefaults:defaultValues];
    
		// create the main XMPP object
		xmppStream  = [[XMPPStream alloc] init];
    
    // create a recreation object to attempt to restart us
    xmppReconnect = [[XMPPReconnect alloc] initWithStream:xmppStream];
    
    // create the lastFM scobbling client
    scrobbler = [[Scrobble alloc] initWithApiKey:DR_LASTFM_APIKEY andSecret:DR_LASTFM_SECRET];
    [scrobbler setSessionToken:[ud objectForKey:@"DefaultLastFMSession"]];
    [scrobbler setSessionUser:[ud objectForKey:@"DefaultLastFMUser"]];
    [scrobbler setClientId:@"aty"];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  
  [xmppReconnect addDelegate:self];
  [GrowlApplicationBridge setGrowlDelegate:self];
  [scrobbler setDelegate:self];
  
  mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[[mainWindowController window] makeMainWindow];
	[[mainWindowController window] makeKeyAndOrderFront:self];
}

- (void)dealloc
{
	[mainWindowController release];
	[xmppStream release];
  [xmppReconnect release];
  [scrobbler release];
	[preferencesWindowController release];
  [livetextLookup release];
	
	[super dealloc];
}


- (void)applicationDidUnhide:(NSNotification *)aNotification
{
  [mainWindowController redrawEmp];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSRect wf = [[mainWindowController window] frame];
  [ud setValue:NSStringFromPoint(wf.origin) forKey:@"DefaultEmpOrigin"];
  [ud synchronize];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
	return YES;
}

- (void)displayPreferenceWindow:(id)sender
{
	if (!preferencesWindowController) {
    preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
  
  [preferencesWindowController setScrobbler:scrobbler];
	[preferencesWindowController showWindow:self];
}


- (void)displayHistoryWindow:(id)sender
{
	if (!historyWindowController) {
    historyWindowController = [[HistoryWindowController alloc] init];
	}
  
  historyWindowController.historyItems = scrobbler.scrobbleHistory;
  [historyWindowController reloadData];  
	[historyWindowController showWindow:self];
}


- (IBAction)visitIplayerSite:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"http://www.bbc.co.uk/iplayer"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction)visitTermsAndCondSite:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"http://iplayerhelp.external.bbc.co.uk/help/about_iplayer/termscon"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction)visitHelpSite:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"http://iplayerhelp.external.bbc.co.uk/help/"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}


#pragma mark -
#pragma mark Auto Reconnect
#pragma mark -

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
	NSLog(@"---------- xmppReconnect:shouldAttemptAutoReconnect: ----------");
	
	return YES;
}


#pragma mark -
#pragma mark LastFM scobbler delegate methods
#pragma mark -

- (void)scrobbleDidGetRequestToken:(Scrobble*)sender
{
  // we set the button text so we have a hook when the
  // response comes back ok
  [[preferencesWindowController authButton] setTitle:@"loading..."];
  
  // You can now send the user off to authorise
  NSURL *url = [NSURL URLWithString:[sender urlToAuthoriseUser]];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)scrobble:(Scrobble*)sender didNotGetRequestToken:(NSError*)error
{
  // adjust the preferences to reflect error
  NSString *errorStr = [[error userInfo] objectForKey:@"NSLocalizedDescription"];
  [[preferencesWindowController lastFMLabel] setStringValue:errorStr];  
}

- (void)scrobbleDidGetSessionToken:(Scrobble*)sender
{  
  // store the credentials for later use
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setValue:sender.sessionToken forKey:@"DefaultLastFMSession"];
  [ud setValue:sender.sessionUser forKey:@"DefaultLastFMUser"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // adjust the preferences to reflect authorisation
  [[preferencesWindowController authButton] setTitle:@"Un-Authorise"];
  [[preferencesWindowController lastFMLabel] setStringValue:@"Click to un-authorise this application"];
  [[preferencesWindowController lastFMEnabled] setEnabled:YES]; 
}

- (void)scrobble:(Scrobble*)sender didNotGetSessionToken:(NSError*)error
{
  // adjust the preferences to reflect error
  NSString *errorStr = [[error userInfo] objectForKey:@"NSLocalizedDescription"];
  [[preferencesWindowController lastFMLabel] setStringValue:errorStr];
  
  // Clear any stored credentials
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setValue:@"" forKey:@"DefaultLastFMSession"];
  [ud setValue:@"" forKey:@"DefaultLastFMUser"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // adjust the preferences to reflect authorisation
  [[preferencesWindowController authButton] setTitle:@"Authorise"];
  [[preferencesWindowController lastFMLabel] setStringValue:@"Click to authorise this application"];
  [[preferencesWindowController lastFMEnabled] setEnabled:NO];
}

- (void)scrobble:(Scrobble*)sender didNotDoScrobbleHandshake:(NSError*)error
{
  // adjust the preferences to reflect error
  NSString *errorStr = [[error userInfo] objectForKey:@"NSLocalizedDescription"];
  NSLog(@"HandshakeError: %@", errorStr);
}

- (void)scrobble:(Scrobble*)sender didSendNowPlaying:(NSString*)response;
{
  NSLog(@"NowPlaying: %@", response);
}

- (void)scrobble:(Scrobble*)sender didScrobble:(NSString*)response
{
  NSLog(@"Scrobbled: %@", response);  
}

- (void)scrobble:(Scrobble*)sender didNotAddToHistory:(NSError*)error
{
  NSString *errorStr = [[error userInfo] objectForKey:@"NSLocalizedDescription"];
  NSLog(@"didNotAddToHistory: %@", errorStr);  
}

- (void)scrobble:(Scrobble*)sender didAddToHistory:(Play*)play
{
  if (historyWindowController) { 
    historyWindowController.historyItems = scrobbler.scrobbleHistory;
    [historyWindowController reloadData];
  }
  
  float resizeWidth  = 100.0;
  float resizeHeight = 100.0;
  
  NSImage *sourceImage  = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:play.small_image]];
  NSImage *resizedImage = [[NSImage alloc] initWithSize: NSMakeSize(resizeWidth, resizeHeight)];
  
  NSSize originalSize = [sourceImage size];
  
  [NSGraphicsContext saveGraphicsState];
  [resizedImage lockFocus];
  
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, resizeWidth, resizeHeight)
                                                       xRadius:10
                                                       yRadius:10];
  [path addClip];
  [sourceImage drawInRect:NSMakeRect(0, 0, resizeWidth, resizeHeight)
                 fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) 
                operation:NSCompositeSourceOver 
                 fraction:1.0];
  
  [resizedImage unlockFocus];
  [NSGraphicsContext restoreGraphicsState];
  
  [GrowlApplicationBridge notifyWithTitle:play.artist
                              description:play.track
                         notificationName:@"Now playing"
                                 iconData:[resizedImage TIFFRepresentation]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  [sourceImage release];
  [resizedImage release];
}

@end
