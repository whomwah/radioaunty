//
//  DockView.m
//  Radio
//
//  Created by Duncan Robertson on 11/03/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import "DockView.h"


@implementation DockView

@synthesize networkIcon;

- (id)initWithFrame:(NSRect)frame withKey:(NSString *)key 
{
  self = [super initWithFrame:frame];
  if (self) {
    self.networkIcon = [NSImage imageNamed:key];
    appIcon = [NSImage imageNamed:@"radio_icon"];
  }
  return self;
}

- (void)drawRect:(NSRect)rect
{
  NSImageView *serviceIconView = [[NSImageView alloc] initWithFrame: 
                                  NSMakeRect(15, rect.size.height - [networkIcon size].height - 5, 
                                             [networkIcon size].width, 
                                             [networkIcon size].height)];
  
  [serviceIconView setImage:networkIcon];
  [serviceIconView setImageAlignment:NSImageAlignTopLeft];
  
  NSRect dockFrame = NSMakeRect(0, 0, rect.size.width, rect.size.height);
  NSImageView *appIconView = [[NSImageView alloc] initWithFrame:dockFrame];
  
  [appIconView setImage:appIcon];
  [self addSubview:appIconView];
  [self addSubview:serviceIconView];
  
  [serviceIconView release];
  [appIconView release];
}

@end
