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
@synthesize lastFMicon;
@synthesize showLastFM;

- (id)initWithFrame:(NSRect)frame withKey:(NSString *)key 
{
  self = [super initWithFrame:frame];
  if (self) {
    self.networkIcon = [NSImage imageNamed:key];
    appIcon = [NSImage imageNamed:@"radio_icon"];
    
    self.lastFMicon = [NSImage imageNamed:@"lastFM"];
    showLastFM = NO;
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
                                    NSMakeRect(15, rect.size.height - [networkIcon size].height - 5, 
                                               [networkIcon size].width, [networkIcon size].height)];
    [serviceIconView setImage:networkIcon];
    [self addSubview:serviceIconView];
    [serviceIconView release];
  }
  
  if (showLastFM) {
    NSImageView *lastfmIconView = [[NSImageView alloc] initWithFrame: 
                                    NSMakeRect(60, rect.size.height - [lastFMicon size].height - 5, 
                                               [lastFMicon size].width, [lastFMicon size].height)];
    [lastfmIconView setImage:lastFMicon];
    [self addSubview:lastfmIconView];
    [lastfmIconView release];
  }

  [appIconView release];
}

@end
