//
//  EmpViewController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "EmpViewController.h"

@implementation EmpViewController

@synthesize isMinimized;
@synthesize hasToolbar;
@synthesize viewSizes;

- (void)awakeFromNib
{
  self.isMinimized = [[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultEmpMinimized"];
  NSArray *sizes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"EmpSizes"];
  NSMutableArray *arry = [NSMutableArray array];
  for (NSDictionary *d in sizes) {
    [arry addObject:[d objectForKey:@"size"]];
  }
  self.viewSizes = arry;
  
  [[[self view] window] setShowsResizeIndicator:NO];
}

- (void)dealloc
{
  [viewSizes release];
  
	[super dealloc];
}

- (void)fetchEMP:(NSDictionary *)d
{
  data = d;
  markup = nil;
  [self displayEmpForKey:[data objectForKey:@"empKey"]];
}

- (void)fetchAOD:(NSString *)s
{
  data = nil;
  markup = nil;
  [self displayEmpForKey:s];
}

- (BOOL)isLive
{
  if (data) {
    return YES;
  } else {
    return NO;    
  }
}

- (NSString *)playbackFormat
{
  return [self isLive] ? @"live" : @"aod";
}

- (BOOL)isHighQuality
{
  return YES;
}

- (NSSize)minimizedSize
{
  return [self sizeForEmp:0];
}

- (void)displayEmpForKey:(NSString *)urlkey
{
  NSString *path = [[NSBundle mainBundle] pathForResource:[self playbackFormat] 
                                                   ofType:@"html"];
  NSString *tmpl = [NSString stringWithContentsOfFile:path
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
  NSString *html = [NSString stringWithFormat:tmpl, urlkey, urlkey, urlkey, urlkey];
  
  markup = html;
	
  [self makeRequest];
}

- (void)makeRequest
{
  [[empView mainFrame] loadHTMLString:markup baseURL:[NSURL URLWithString:@"http://www.bbc.co.uk/"]];  
}

- (NSSize)windowSize
{
  int sizeInt;
  
  if ([self isMinimized] == YES) {
    // minimized
    sizeInt  = 0;
  } else {
    // Normal Size
    sizeInt  = 1;
  }
  
  return [self sizeForEmp:sizeInt]; 
}

- (NSSize)sizeForEmp:(int)index
{  
  NSSize size = NSSizeFromString([viewSizes objectAtIndex:index]);
  size.height += 25.0;  
  
  return size;
}

#pragma mark URL load Delegates

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Started to load the page");
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Finshed loading page");
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
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Try again?"];
  [alert addButtonWithTitle:@"Quit"];
  [alert setMessageText:@"Error fetching stream"];
  [alert setInformativeText:@"Check you are connected to the Internet? \nand try again..."];
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
    return [self makeRequest];
  } else if (returnCode == NSAlertSecondButtonReturn) {
    return [NSApp terminate:self]; 
  }
}

@end
