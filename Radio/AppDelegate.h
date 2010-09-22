//
//  AppDelegate.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "XMPP.h"
#import "Scrobble.h"

@class MainWindowController;
@class PreferencesWindowController;
@class XMPPReconnect;
@class XMPPStream;
@class Scrobble;

@interface AppDelegate : NSObject <GrowlApplicationBridgeDelegate, ScrobbleDelegate>
{
	MainWindowController *drMainWindowController;
  PreferencesWindowController *preferencesWindowController;
	
	XMPPStream *xmppStream;
	XMPPReconnect *xmppReconnect;
  Scrobble *scrobbler;
}

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, readonly) Scrobble *scrobbler;

- (IBAction)displayPreferenceWindow:(id)sender;
- (IBAction)visitIplayerSite:(id)sender;
- (IBAction)visitTermsAndCondSite:(id)sender;
- (IBAction)visitHelpSite:(id)sender;

@end
