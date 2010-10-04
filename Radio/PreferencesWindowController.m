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
@synthesize lastFMEnabled;

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
  [lastFMEnabled release];
	
	[super dealloc];
}

- (IBAction)scrobbleState:(id)sender
{  
  if ([sender state] == 0) {
    [scrobbler clearSession];
  }
}

- (IBAction)authorise:(id)sender
{
  // start by clearing and stored credentials
  // as we be either settings them once recieved
  // or we are actually unauthorising
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setValue:@"" forKey:@"DefaultLastFMSession"];
  [ud setValue:@"" forKey:@"DefaultLastFMUser"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // disable the enable button, as it will
  // be enabled if everything goes ok
  [lastFMEnabled setEnabled:NO];
  
  // assume we are going to try and authorise. Anything
  // else we send the user off to last.fm to unauth and
  // we clear any data stored in the scrobbler object
  if ([[authButton title] isEqualToString:@"Authorise"]) {
    
    // fetch a temp request token
    [scrobbler fetchRequestToken];
    
  } else {   
    
    // set the text back to Authorise
    [self.authButton setTitle:@"Authorise"];
    
    // You can now send the user off to unauthorise
    NSURL *url = [NSURL URLWithString:[scrobbler urlToUnAuthoriseUser]];
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    // oh and clear the token from scrobbler
    [scrobbler clearSession];
    
  }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString *session = [ud objectForKey:@"DefaultLastFMSession"];
  
  // if we have a non empty session we're good to go
  if (![session isEqual:@""]) {
    
    // enable the scrobbling
    [lastFMEnabled setEnabled:YES];
    
    [self.authButton setTitle:@"Un-Authorise"];
    [self.lastFMLabel setStringValue:@"Click to un-authorise this application"];
    
  
  } else if ([[authButton title] isEqualToString:@"Authorise"]) {
    
    [self.lastFMLabel setStringValue:@"Click to authorise this application"];
  
  } else if ([[authButton title] isEqualToString:@"loading..."]) {
    
    // try and fetch the auth token 
    [scrobbler fetchWebServiceSession];
    
    [self.lastFMLabel setStringValue:@"just finalising the setup."];
    [lastFMEnabled setEnabled:NO];
    
  } else if ([[authButton title] isEqualToString:@"Un-Authorise"]) {
    
    [lastFMEnabled setEnabled:YES];
    [self.lastFMLabel setStringValue:@"Click to un-authorise this application"];
    
  }
}

- (void)windowWillClose:(NSNotification *)notification
{
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
