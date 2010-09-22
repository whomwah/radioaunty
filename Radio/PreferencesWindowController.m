//
//  PreferencesWindowController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "Scrobble.h"

@implementation PreferencesWindowController

@synthesize scrobbler;
@synthesize authButton;
@synthesize lastFMLabel;

- (id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) {
		return nil;
	}	
	return self;
}

- (void)dealloc
{
	[scrobbler release];
  [authButton release];
  [lastFMLabel release];
	
	[super dealloc];
}

- (IBAction)authorise:(id)sender
{
  if ([[authButton title] isEqualToString:@"Continue"]) {
    [scrobbler fetchWebServiceSession];
  } else if ([[authButton title] isEqualToString:@"Un-Authorise"]) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:@"" forKey:@"DefaultLastFMSession"];
    [ud setValue:@"" forKey:@"DefaultLastFMUser"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.authButton setTitle:@"Authorise"];
    
    // You can now send the user off to unauthorise
    NSURL *url = [NSURL URLWithString:[scrobbler urlToUnAuthoriseUser]];
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    // oh and clear the token from scrobbler
    [scrobbler setSessionToken:nil];
  } else {
    [scrobbler fetchRequestToken];
  }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString *session = [ud objectForKey:@"DefaultLastFMSession"];
  
  // if we have a non empty session token just show how to un-auth
  if (![session isEqual:@""]) {
    [self.authButton setTitle:@"Un-Authorise"];
    [self.lastFMLabel setStringValue:@"Click to un-authorise this application"];
  }
  
  // other options
  if ([[authButton title] isEqualToString:@"Authorise"]) 
  {
    [self.lastFMLabel setStringValue:@"Click to authorise this application"];
  } else if ([[authButton title] isEqualToString:@"Continue"])
  {
    [self.lastFMLabel setStringValue:@"Let's just finalise the setup."];
  } else if ([[authButton title] isEqualToString:@"Un-Authorise"])
  {
    [self.lastFMLabel setStringValue:@"Click to un-authorise this application"];
  }
}

- (void)windowWillClose:(NSNotification *)notification
{
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
