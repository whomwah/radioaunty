//
//  PreferencesWindowController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "Scrobble.h"
#import "JSON.h"
#import "GDataHTTPFetcher.h"
#import "AppDelegate.h"
#import "MainWindowController.h"

@implementation PreferencesWindowController

@synthesize scrobbler;
@synthesize authButton;
@synthesize lastFMLabel;
@synthesize lastFMEnabled;
@synthesize radioServices;
@synthesize radioServicesFavs;

- (id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) {
		return nil;
	}
  
	return self;
}

- (void)awakeFromNib
{
  NSDictionary *favs = [[NSUserDefaults standardUserDefaults] objectForKey:@"ServiceSelection"];
  self.radioServicesFavs = [[NSMutableDictionary alloc] initWithCapacity:[favs count]];
  [radioServicesFavs addEntriesFromDictionary:favs];
  
  [outlineView reloadData];
}

- (void)dealloc
{
	[scrobbler release];
  [authButton release];
  [lastFMLabel release];
  [lastFMEnabled release];
  [radioServices release];
  [radioServicesFavs release];
	
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

- (void)windowDidResignKey:(NSNotification *)notification
{
  // syncronise any user defaults
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // make sure we re-build the station menu, as we
  // may have made some changes to the stations
  [[[NSApp delegate] mainWindowController] buildStationsMenu];
}


#pragma mark -
#pragma mark NSTabView
#pragma mark -

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
  if ([[tabViewItem identifier] isEqual:@"stations"]) {
    //NSString *urlStr = @"http://localhost/~duncan/services.json";
    NSString *urlStr = @"http://www.bbc.co.uk/programmes/services.json";
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    GDataHTTPFetcher *serviceFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
    [serviceFetcher beginFetchWithDelegate:self
                         didFinishSelector:@selector(serviceFetcher:finishedWithData:)
                           didFailSelector:@selector(serviceFetcher:failedWithError:)];
  }
}

- (void)serviceFetcher:(GDataHTTPFetcher *)serviceFetcher failedWithError:(NSError *)error
{
  NSString *errorStr = [[error userInfo] objectForKey:@"NSLocalizedDescription"];
  NSLog(@"serviceFetcher: %@", errorStr);  
}

- (void)serviceFetcher:(GDataHTTPFetcher *)serviceFetcher finishedWithData:(NSData *)retrievedData
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  SBJSON *parser = [[SBJSON alloc] init];
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];    
  NSDictionary *result = [parser objectWithString:result_string error:nil];
  
  // replace any existing version of the services data with
  // only the radio data from the services.json
  NSArray *allservices = [result objectForKey:@"services"];
  if (allservices) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == 'radio'"];
    NSArray *services = [allservices filteredArrayUsingPredicate:predicate];
    if ([services count] > 0) {
      [ud setValue:services forKey:@"Services"];
      [ud synchronize];
      
      self.radioServices = services;
      [outlineView reloadData];
      [outlineView expandItem:nil expandChildren:YES];
    }
  }
  
  [parser release];
  [result_string release];
}


#pragma mark -
#pragma mark NSOutlineView delegates
#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{  
  if (!radioServices) return 0;
    
  NSArray *outlets = [item objectForKey:@"outlets"];
  if (outlets) {
    return [outlets count]; 
  } else {
    return [radioServices count];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if ([item isKindOfClass:[NSDictionary class]] && [item objectForKey:@"outlets"]) {
    return YES;
  }
  
  return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{ 
  if (item == nil) {
    item = radioServices;
  }
 
  if ([item isKindOfClass:[NSArray class]]) {
    return [item objectAtIndex:index];
  }
  
  if ([item isKindOfClass:[NSDictionary class]]) {
    return [[item objectForKey:@"outlets"] objectAtIndex:index];
  }
  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if ([item isKindOfClass:[NSDictionary class]]) {
    if ([[tableColumn identifier] isEqual:@"title"]) {
      
      NSString *resultStr = [item objectForKey:@"title"];
      NSDictionary *currentSt = [[[NSApp delegate] mainWindowController] currentStation];
      NSString *currentStSelected = [radioServicesFavs objectForKey:[currentSt objectForKey:@"id"]];
      
      if (currentStSelected && ([[item objectForKey:@"id"] isEqual:[currentSt objectForKey:@"id"]] ||
                                [[item objectForKey:@"id"] isEqual:currentStSelected])) {
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName, 
                                         nil];
        NSAttributedString *str = [[[NSAttributedString alloc] initWithString:[item objectForKey:@"title"] 
                                                                  attributes:attrsDictionary] autorelease];
        
        return str;
      }
      
      return resultStr;
    }
    
    if ([[tableColumn identifier] isEqual:@"active"]) {
      NSString *itemID = [item objectForKey:@"id"];
      NSString *selectKey = [radioServicesFavs objectForKey:itemID];
      
      if (selectKey || [[radioServicesFavs allValues] containsObject:itemID]) {
        return [NSNumber numberWithBool:YES];
      } else {
        return [NSNumber numberWithBool:NO]; 
      }
    }
  }

  return nil;
}

- (void)onClickTick:(id)sender
{    
  id item = [sender itemAtRow:[sender clickedRow]];
  NSString *bbcid = [item objectForKey:@"id"];
  
  if ([item objectForKey:@"type"]) {
    
    if ([radioServicesFavs objectForKey:bbcid]) {
      
      // You must have at least one station in your list
      if ([radioServicesFavs count] > 1) {
        [radioServicesFavs removeObjectForKey:bbcid];
      }
      
    } else {
      
      [radioServicesFavs removeObjectForKey:bbcid];
      [radioServicesFavs setObject:@"" forKey:bbcid];
    
    }
    
  } else {
    
    NSString *pbbcid = [[sender parentForItem:item] objectForKey:@"id"];
    NSString *match = [radioServicesFavs objectForKey:pbbcid];

    if (match && [match isEqual:bbcid]) {
      // You must have at least one station in your list
      if ([radioServicesFavs count] > 1) {
        [radioServicesFavs removeObjectForKey:pbbcid];
      }
    } else {
      [radioServicesFavs removeObjectForKey:pbbcid];
      [radioServicesFavs setObject:bbcid forKey:pbbcid];
    }
      
  }
  
  [outlineView reloadData];
  
  [[NSUserDefaults standardUserDefaults] setObject:radioServicesFavs forKey:@"ServiceSelection"];
}

- (void)outlineView:(NSOutlineView *)outlineView 
    willDisplayCell:(id)cell 
     forTableColumn:(NSTableColumn *)tableColumn 
               item:(id)item
{      
  NSDictionary *currentSt = [[[NSApp delegate] mainWindowController] currentStation];
  NSString *currentStSelected = [radioServicesFavs objectForKey:[currentSt objectForKey:@"id"]];
  
  if ([[tableColumn identifier] isEqual:@"active"]) {
    NSArray *outlets = [item objectForKey:@"outlets"];
    
    if (currentStSelected && ([[item objectForKey:@"id"] isEqual:[currentSt objectForKey:@"id"]] ||
                              [[item objectForKey:@"id"] isEqual:currentStSelected])) {
      [cell setEnabled:NO];
    } else {
      [cell setEnabled:YES]; 
    }

    if (outlets) {
      [cell setTransparent:YES];
    } else {      
      [cell setTarget:self];
      [cell setAction:@selector(onClickTick:)];
      [cell setTransparent:NO];
    }
  }
}

@end
