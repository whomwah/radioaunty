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

@synthesize url, title, serviceKey;

- (void)fetchEmp:(NSString *)keyString
{
  NSString *console = CONSOLE_URL;
  NSString *urlString = [console stringByAppendingString:keyString]; 
  [self setUrl:[NSURL URLWithString:urlString]];
  [self makeRequest];
}

- (void)makeRequest
{
  NSLog(@"Loading: %@", url);
  [[empView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];  
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
  [alert addButtonWithTitle:@"Try again?"];
  [alert addButtonWithTitle:@"Quit"];
  [alert setMessageText:[NSString stringWithFormat:@"Error fetching %@", title]];
  [alert setInformativeText:@"Check you are connected to the Internet? \nand try again..."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert setIcon:[NSImage imageNamed:serviceKey]];
  [alert beginSheetModalForWindow:[empView window]
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:nil];
  [alert release];  
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn) {
    return [self makeRequest];
  } else if (returnCode == NSAlertSecondButtonReturn) {
    return [NSApp terminate:self]; 
  }
}

@end
