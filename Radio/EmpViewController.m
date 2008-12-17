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

- (void)loadUrl:(NSDictionary *)station
{
  NSString * console = CONSOLE_URL;
  NSString * urlString = [console stringByAppendingString:[station valueForKey:@"key"]]; 
  NSURL * URL = [NSURL URLWithString:urlString];
  
  [GrowlApplicationBridge notifyWithTitle:[station valueForKey:@"label"]
                              description:[station valueForKey:@"blurb"]
                         notificationName:@"Station about to play"
                                 iconData:nil
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  
  [empView addSubview:preloaderView];
  [preloaderView positionInCenterOf:empView];
  [[empView mainFrame] loadRequest:[NSURLRequest requestWithURL:URL]]; 
  NSLog(@"Loading: %@", URL);
}

#pragma mark URL load Delegates

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Started to load the page");
  [preloaderView setHidden:NO];
  [spinner startAnimation:(id)sender];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Finshed loading page");
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
  [preloaderView setHidden:YES];
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"ok"];
  [alert setMessageText:@"Error fetching the page"];
  [alert setInformativeText:@"Check you are connected to the internet?"];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert beginSheetModalForWindow:[empView window]
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:nil];
  [alert release];  
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn) {
  }
}

@end
