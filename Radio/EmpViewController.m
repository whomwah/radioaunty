//
//  EmpViewController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "EmpViewController.h"
#import "Preloader.h"

#define CONSOLE_URL @"http://www.bbc.co.uk/iplayer/console/";

@implementation EmpViewController

@synthesize currentURL;
@synthesize station;

- (void)loadUrl:(NSDictionary *)stationData
{
  NSString *console = CONSOLE_URL;
  [self setStation:stationData];
  NSString *urlString = [console stringByAppendingString:[station valueForKey:@"key"]]; 
  [self setCurrentURL:[NSURL URLWithString:urlString]];
  [self makeURLRequest];
}

- (void)makeURLRequest
{
  [[empView mainFrame] loadRequest:[NSURLRequest requestWithURL:currentURL]]; 
  NSLog(@"Loading: %@", currentURL);
}

#pragma mark URL load Delegates

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Started to load the page");
  if ([[empView subviews] indexOfObject:preloaderView] == NSNotFound) {
    [empView addSubview:preloaderView];
    [preloaderView positionInCenterOf:empView];
  }
  [preloaderView setHidden:NO];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Finshed loading page");
  [[[[NSApp mainWindow] windowController] dockTile] setBadgeLabel:@"live"];
  [[[[NSApp mainWindow] windowController] dockTile] display];
  [preloaderView setHidden:YES];
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
  [preloaderView removeFromSuperview];
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"try again?"];
  [alert setMessageText:[NSString stringWithFormat:@"Error fetching %@", [station valueForKey:@"label"]]];
  [alert setInformativeText:@"Check you are connected to the Internet? \nand try again..."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert setIcon:[NSImage imageNamed:[station valueForKey:@"key"]]];
  [alert beginSheetModalForWindow:[empView window]
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:nil];
  [alert release];  
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn) {
    return [self makeURLRequest];
  }
}

@end
