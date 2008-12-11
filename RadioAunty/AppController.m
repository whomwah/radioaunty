//
//  AppController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 09/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "AppController.h"
#import "PreferencesWindowController.h"

#define STARTUP_NETWORK 7;
#define CONSOLE_URL @"http://www.bbc.co.uk/iplayer/console/";

@implementation AppController

@synthesize stations;
@synthesize currentStation;

+ (void)initialize
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
  int i = STARTUP_NETWORK;
  [defaultValues setObject:[NSNumber numberWithInt:i] forKey:DSRDefaultStation];
  [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:DSRCheckForUpdates];
  [defaults registerDefaults:defaultValues];
  [defaults synchronize];
  NSLog(@"registered defaults: %@", defaultValues);
}

- (id) init {
  if (self = [super init]) {
    int startStationIndex = STARTUP_NETWORK;
    NSString * errorDesc = nil;
    NSPropertyListFormat format;
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"Stations" ofType:@"plist"];
    NSData * plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format errorDescription:&errorDesc];
    if (!temp) {
      NSLog(errorDesc);
      [errorDesc release];
    }
    
    self.stations = [temp objectForKey:@"Stations"];
    [self setUpStation:startStationIndex];
  }
  return self;
}

- (void)awakeFromNib
{
  [self loadUrl:[self currentStation]];
}

- (void)loadUrl:(NSDictionary *)station
{
  NSString * console = CONSOLE_URL;
  NSString * urlString = [console stringByAppendingString:[self keyForStation:station]]; 
  NSURL * URL = [NSURL URLWithString:urlString];
  [[myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:URL]];  
}

- (void)changeStation:(id)sender
{
  int i = [sender tag];
  [[[sender menu] itemWithTitle:[self labelForStation:[self currentStation]]] setState:NSOffState]; 
  [sender setState:NSOnState];
  [self setUpStation:i];
}

- (NSString *)keyForStation:(NSDictionary *)station
{
  return [station objectForKey:@"key"];
}

- (NSString *)labelForStation:(NSDictionary *)station
{
  return [station objectForKey:@"label"];
}

- (void)setUpStation:(int)index
{
  NSDictionary * station = [[self stations] objectAtIndex:index];
  self.currentStation = station;
  [self loadUrl:[self currentStation]];  
}

- (void)displayPreferenceWindow:(id)sender
{
	if (!preferencesWindowController) {
		preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
	[preferencesWindowController showWindow:self];
}

#pragma mark URL load Delegates

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
  [spinner startAnimation:(id)sender];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
  [spinner stopAnimation:(id)sender];  
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
  [self fetchErrorMessage:(id)sender];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
  [self fetchErrorMessage:(id)sender];  
}


#pragma mark URL fetch errors

- (void)fetchErrorMessage:(WebView *)sender
{
  [spinner stopAnimation:(id)sender];
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Try Again?"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:@"Error fetching the page"];
  [alert setInformativeText:@"Check you are connected to the internet?"];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert beginSheetModalForWindow:[myWebView window] 
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:nil];
  
  [alert release];  
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn) {
    NSLog(@"trying to load %@ again", [self currentStation]);
  [self loadUrl:[self currentStation]];
  }
  
  if (returnCode == NSAlertSecondButtonReturn) {
    NSLog(@"I must exit");
  }
}

@end
