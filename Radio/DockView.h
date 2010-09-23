//
//  DockView.h
//  RadioAunty
//
//  Created by Duncan Robertson on 11/03/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DockView : NSView {
  NSImage *networkIcon;
  NSImage *appIcon;
  
  NSImage *lastFMicon;
  BOOL showLastFM;
}

@property (nonatomic, retain) NSImage *networkIcon;
@property (nonatomic, retain) NSImage *lastFMicon;
@property (nonatomic, assign) BOOL showLastFM;

- (id)initWithFrame:(NSRect)frame withKey:(NSString *)key;

@end
