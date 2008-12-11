//
//  AppController.h
//  RadioAunty
//
//  Created by Duncan Robertson on 09/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface AppController : NSObject {
  IBOutlet WebView * myWebView;
  IBOutlet NSProgressIndicator * spinner;
  NSArray * stations;
  NSDictionary * currentStation;
}

@property (retain) NSArray * stations;
@property (retain) NSDictionary * currentStation;

- (void)loadUrl:(NSDictionary *)station;
- (void)changeStation:(id)sender;
- (void)fetchErrorMessage:(WebView *)sender;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;

- (void)setUpStation:(int)index;
- (NSString *)keyForStation:(NSDictionary *)station;
- (NSString *)labelForStation:(NSDictionary *)station;

@end
