//
//  EmpViewController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface EmpViewController : NSViewController {
  IBOutlet WebView *empView;
  NSDictionary *data;
  NSString *markup;
  BOOL isMinimized;
}

@property (nonatomic) BOOL isMinimized;


- (void)handleResizeIcon;
- (BOOL)isLive;
- (void)makeRequest;
- (BOOL)isHighQuality;
- (BOOL)isReal;
- (NSSize)minimizedSize;
- (NSSize)windowSize;
- (NSString *)playbackFormat;
- (NSSize)sizeForEmp:(int)index;
- (void)resizeEmpTo:(NSSize)size;
- (void)fetchEMP:(NSDictionary *)d;
- (void)fetchAOD:(NSString *)s;
- (void)displayEmpForKey:(NSString *)urlkey;
- (void)fetchErrorMessage:(WebView *)sender;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;

@end