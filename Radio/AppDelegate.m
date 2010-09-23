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
#import "XMPP.h"
#import "Scrobble.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5
// SCNetworkConnectionFlags was renamed to SCNetworkReachabilityFlags in 10.6
typedef SCNetworkConnectionFlags SCNetworkReachabilityFlags;
#endif

@implementation AppDelegate

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize scrobbler;

- (id)init
{
	if((self = [super init]))
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
		
		[defaultValues setObject:[temp objectForKey:@"Stations"] forKey:@"Stations"];
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
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		[ud registerDefaults:defaultValues];
		
		// create the main XMPP object
		xmppStream  = [[XMPPStream alloc] init];
    
    // create a recreation object to attempt to restart us
    xmppReconnect = [[XMPPReconnect alloc] initWithStream:xmppStream];
    
    // create the lastFM scobbling client
    scrobbler = [[Scrobble alloc] initWithApiKey:@"88f73b675f92581846cbd666b6a1d861" 
                                       andSecret:@"f65c9a148a07c9f6cca912890bae1cbd"];
    [scrobbler setSessionToken:[ud objectForKey:@"DefaultLastFMSession"]];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  
  [xmppReconnect addDelegate:self];
  [GrowlApplicationBridge setGrowlDelegate:self];
  [scrobbler setDelegate:self];
  
  drMainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[[drMainWindowController window] makeMainWindow];
	[[drMainWindowController window] makeKeyAndOrderFront:self];
}


- (void)dealloc
{
	[drMainWindowController release];
	[xmppStream release];
  [xmppReconnect release];
  [scrobbler release];
	[preferencesWindowController release];
	
	[super dealloc];
}


- (void)applicationDidUnhide:(NSNotification *)aNotification
{
  [drMainWindowController redrawEmp];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSRect wf = [[drMainWindowController window] frame];
  [ud setValue:NSStringFromPoint(wf.origin) forKey:@"DefaultEmpOrigin"];
  [[NSUserDefaults standardUserDefaults] synchronize];
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
  // first set the auth button in preferences to the next state
  [[preferencesWindowController authButton] setTitle:@"Continue"];
  
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
  // store them for later use
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
  
  // reset all the bits and pieces
  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setValue:@"" forKey:@"DefaultLastFMSession"];
  [ud setValue:@"" forKey:@"DefaultLastFMUser"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // adjust the preferences to reflect authorisation
  [[preferencesWindowController authButton] setTitle:@"Authorise"];
  [[preferencesWindowController lastFMEnabled] setEnabled:NO];
}

- (void)scrobble:(Scrobble*)sender didSendNowPlaying:(NSDictionary*)response
{
  NSLog(@"NowPlaying: %@", response);
}

- (void)scrobble:(Scrobble*)sender didScrobble:(NSDictionary*)response
{
  NSLog(@"Scrobbled: %@", response);  
}

@end
