//
//  AppController.h
//  RadioAunty
//
//  Created by Duncan Robertson on 09/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class PreferencesWindowController;

@interface AppController : NSObject {
  IBOutlet WebView * myWebView;
  IBOutlet NSMenu * listenMenu;
  IBOutlet NSProgressIndicator * spinner;
  NSArray * stations;
  NSDictionary * currentStation;
  PreferencesWindowController * preferencesWindowController;
}

@property (retain) NSArray * stations;
@property (retain) NSDictionary * currentStation;

- (IBAction)changeStation:(id)sender;
- (IBAction)refreshCurrentStation:(id)sender;
- (IBAction)displayPreferenceWindow:(id)sender;
- (void)loadUrl:(NSDictionary *)station;
- (void)fetchErrorMessage:(WebView *)sender;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;

- (void)buildMenu;
- (void)setAndLoadStation:(NSDictionary *)station;
- (NSString *)keyForStation:(NSDictionary *)station;
- (NSString *)labelForStation:(NSDictionary *)station;
- (NSNumber *)idForStation:(NSDictionary *)station;
- (NSDictionary *)findStationForId:(int)key;

@end
