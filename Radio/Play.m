//
//  Play.m
//  Radio
//
//  Created by Duncan Robertson on 06/10/2010.
//  Copyright 2010 whomwah. All rights reserved.
//

#import "Play.h"

NSString *const PlayDefaultSmallImage = @"http://cdn.last.fm/flatness/catalogue/noimage/2/default_artist_small.png";

@implementation Play

@synthesize artist, track, mbid, small_image, timestamp;

- (void)dealloc
{  
  [artist release];
  [track release];
  [mbid release];
  [small_image release];
  [timestamp release];
  
	[super dealloc];
}

- (NSString*)small_image
{
  if (!small_image || [small_image isEqual:@""]) {
    return PlayDefaultSmallImage;
  }
  
  return small_image;
}

@end
