//
//  DockView.m
//  RadioAunty
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
  [self setSubviews:[NSArray array]];
   
  NSImageView *appIconView = [[NSImageView alloc] initWithFrame:rect];
  [appIconView setImage:appIcon];
  [self addSubview:appIconView];

  if (networkIcon) {
    NSImageView *serviceIconView = [[NSImageView alloc] initWithFrame: 
                                    NSMakeRect(3, 7, 45.0, 40)];
    [serviceIconView setImage:networkIcon];
    [self addSubview:serviceIconView];
    [serviceIconView release];
  }

  [appIconView release];
}

@end
