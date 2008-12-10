//
//  AppController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 09/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "AppController.h"


@implementation AppController

- (id) init {
  if (self = [super init]) {
    /*
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Stations" ofType:@"plist"];
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format errorDescription:&errorDesc];
    if (!temp) {
      NSLog(errorDesc);
      [errorDesc release];
    }
    //self.personName = [temp objectForKey:@"Name"];
    //self.phoneNumbers = [NSMutableArray arrayWithArray:[temp objectForKey:@"Phones"]];
    */
  }
  return self;
}

- (void)awakeFromNib
{
  [self loadUrl];
}

- (void)loadUrl
{
  NSURL *URL = [NSURL URLWithString:@"http://www.bbc.co.uk/iplayer/console/6music"];
  [[myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:URL]];  
}

- (void)changeStation:(id)sender
{
  int i = [sender tag];
  NSLog(@"station changed to: %d", i);
}

#pragma mark URL Delegates

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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertFirstButtonReturn) {
    [self loadUrl];
  }
  
  if (returnCode == NSAlertSecondButtonReturn) {
    NSLog(@"I must exit");
  }
}

@end
