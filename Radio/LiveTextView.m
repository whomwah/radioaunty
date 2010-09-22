//
//  LiveTextView.m
//  Radio
//
//  Created by Duncan Robertson on 10/09/2010.
//  Copyright 2010 whomwah.com All rights reserved.
//

#import "LiveTextView.h"


@implementation LiveTextView

@synthesize textArea;
@synthesize progressIndictor;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      textArea = [[NSTextField alloc] initWithFrame:frame];
      [textArea setBordered:NO];
      [textArea setDrawsBackground:NO];
      [textArea setFont:[NSFont boldSystemFontOfSize:10.0]];
      [[textArea cell] setBackgroundStyle:NSBackgroundStyleRaised];
      [textArea setFocusRingType:NSFocusRingTypeNone];
      
      [self addSubview:textArea];
      
      progressIndictor = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0,0,16,16)];
      [progressIndictor setControlSize:NSSmallControlSize];
      [progressIndictor setStyle:NSProgressIndicatorSpinningStyle];
      [progressIndictor setDisplayedWhenStopped:NO];
       
      [self addSubview:progressIndictor];
    }
    return self;
}

- (void)dealloc
{
  [progressIndictor release];
  [textArea release];
  
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
}

@end
