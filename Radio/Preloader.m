//
//  Preloader.m
//  Radio
//
//  Created by Duncan Robertson on 16/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "Preloader.h"


@implementation Preloader

@synthesize path;

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.path = [NSBezierPath bezierPath];
    [[self path] appendBezierPathWithRoundedRect:[self bounds] xRadius:15 yRadius:15];
  }
  return self;
}

- (void)drawRect:(NSRect)rect {
  NSColor * background = [NSColor colorWithCalibratedRed:0.8 green: 0.8  blue: 0.8  alpha:1.0];
  [background set];
  [[self path] fill];
}

- (void)positionInCenterOf:(NSView *)view
{
  [self setFrameOrigin:NSMakePoint([view bounds].size.width / 2 - [self bounds].size.width / 2, 
                                   ([view bounds].size.height / 2 - [self bounds].size.height / 2) + 30)]; 
}

@end
