//
//  Preloader.h
//  Radio
//
//  Created by Duncan Robertson on 16/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Preloader : NSView {
  IBOutlet NSProgressIndicator *spinner;
  NSBezierPath *path;
}

@property (retain) NSBezierPath *path;

- (void)positionInCenterOf:(NSView *)view;

@end
