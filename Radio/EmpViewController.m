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

- (void)awakeFromNib
{
  self.isMinimized = [[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultEmpMinimized"];
}

- (void)fetchEMP:(NSDictionary *)d
{
  data = d;
  markup = nil;
  [self displayEmpForKey:[data objectForKey:@"empKey"]];
  [self resizeEmpTo:[self windowSize]];
}

- (void)fetchAOD:(NSString *)s
{
  data = nil;
  markup = nil;
  [self displayEmpForKey:s];
}

- (void)handleResizeIcon
{
  NSWindow *w = [[self view] window];
  if ([self isMinimized] == NO || [self isReal] == YES) {
    [w setShowsResizeIndicator:NO];    
  } else {
    [w setShowsResizeIndicator:YES];
  } 
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
  if ([self isHighQuality] == NO || [self isReal] == YES) {
    return @"liveReal";
  } else {
    return @"live";    
  }
}

- (BOOL)isHighQuality
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if ([ud integerForKey:@"DefaultQuality"] == 1) {
    return YES;
  } else {
    return NO;    
  }
}

- (BOOL)isReal
{
  if ([self isHighQuality] == NO || [data objectForKey:@"only_real_available"]) {
    return YES;
  }
  return NO;
}

- (NSSize)minimizedSize
{
  return [self sizeForEmp:0];
}

- (void)displayEmpForKey:(NSString *)urlkey
{
  [self handleResizeIcon];
  NSString *path = [[NSBundle mainBundle] pathForResource:[self playbackFormat] 
                                                   ofType:@"html"];
  NSString *tmpl = [NSString stringWithContentsOfFile:path
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
  NSString *html;
  if ([self isReal]) {
    // REAL PLAYER
    self.isMinimized = NO;
    NSString *realUrl = [data valueForKey:@"realStreamUrl"];
    html = [NSString stringWithFormat:tmpl, urlkey, urlkey, realUrl, realUrl];
  } else {
    // FLASH PLAYER
    html = [NSString stringWithFormat:tmpl, urlkey, urlkey];
  }
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
  
  if ([self isReal] == YES) {
    // RealPlayer
    sizeInt = 2;
  } else if ([self isMinimized] == YES) {
    // minimized
    sizeInt = 0;  
  } else {
    // Normal Size
    sizeInt = 1;
  }
  
  return [self sizeForEmp:sizeInt]; 
}

- (NSSize)sizeForEmp:(int)index
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *s = [[ud arrayForKey:@"EmpSizes"] objectAtIndex:index];
  int w = [[s objectForKey:@"width"] intValue];
  int h = [[s objectForKey:@"height"] intValue];
  return NSMakeSize(w,h + 22.0);  
}

- (void)resizeEmpTo:(NSSize)size
{ 
  NSWindow *w = [[self view] window];
  NSSize currentSize = [w frame].size; 
  
  if (NSEqualSizes(size,currentSize) == YES)
    return;
  
  float deltaWidth = size.width - currentSize.width;
  float deltaHeight = size.height - currentSize.height;
  
  NSRect wf = [w frame];
  wf.size.width += deltaWidth;
  wf.size.height += deltaHeight;
  wf.origin.x -= deltaWidth/2;
  wf.origin.y -= deltaHeight/2;
  
  [w setFrame:wf display:YES animate:YES];
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
