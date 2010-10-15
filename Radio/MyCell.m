//
//  MyCell.m
//  abFinder
//
//  Created by Duncan Robertson on 07/02/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import "MyCell.h"
#import "Play.h"

@implementation MyCell

- (void)setObjectValue:(id)object {
  id oldObjectValue = [self objectValue];
  if (object != oldObjectValue) {
    [object retain];
    //[oldObjectValue release];
    [super setObjectValue:[NSValue valueWithNonretainedObject:object]];
  }
}

- (id)objectValue {
  return [[super objectValue] nonretainedObjectValue];
}

- (NSString *)dateDiff:(NSDate *)origDate
{    
  NSDate *todayDate = [NSDate date];
  double ti = [origDate timeIntervalSinceDate:todayDate];
  NSString *s;
  ti = ti * -1;
  if(ti < 1) {
    return @"less than a minute ago";
  } else      if (ti < 60) {
    return @"less than a minute ago";
  } else if (ti < 3600) {
    int diff = round(ti / 60);
    s = (diff <= 1) ? @"" : @"s";
    return [NSString stringWithFormat:@"%d minute%@ ago", diff, s];
  } else if (ti < 86400) {
    int diff = round(ti / 60 / 60);
    s = (diff <= 1) ? @"" : @"s";
    return[NSString stringWithFormat:@"%d hour%@ ago", diff, s];
  } else if (ti < 2629743) {
    int diff = round(ti / 60 / 60 / 24);
    s = (diff <= 1) ? @"" : @"s";
    return[NSString stringWithFormat:@"%d day%@ ago", diff, s];
  } else {
    return @"never";
  }
}

- (void)drawInteriorWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView
{    
  Play *data = [self objectValue];	
  
	NSString *artistLabel = data.artist;
  NSString *trackLabel  = data.track;
  NSString *lastplayedLabel  = [self dateDiff:data.timestamp];  
  NSString *imageURL    = data.small_image;
  
  NSImage *icon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:imageURL]];
  [icon setFlipped:YES];
  
	NSRect anInsetRect = NSInsetRect(theCellFrame,5,2);
	int hspacing = 5;
	int vspacing = 0;
  
	NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
	[pStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  NSShadow *sh = [[[NSShadow alloc] init] autorelease];
  [sh setShadowOffset:NSMakeSize(0,-1)];
  [sh setShadowColor:[NSColor whiteColor]];
	
	NSMutableDictionary *artistAttr = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      [NSFont boldSystemFontOfSize:12.0],NSFontAttributeName,
                                      pStyle, NSParagraphStyleAttributeName,
                                      sh, NSShadowAttributeName,
                                      nil] autorelease];

	NSMutableDictionary *trackAttr  = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:10.0],NSFontAttributeName,
                                      pStyle, NSParagraphStyleAttributeName,
                                      sh, NSShadowAttributeName,
                                      nil] autorelease];
  
  NSMutableDictionary *lastplayedAttr  = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:9.0],NSFontAttributeName,
                                      pStyle, NSParagraphStyleAttributeName,
                                      nil] autorelease];
  
  [pStyle release];
  
	NSSize artistSize = [artistLabel sizeWithAttributes:artistAttr];
	NSSize trackSize  = [trackLabel sizeWithAttributes:trackAttr];

  NSRect iconBox   = NSMakeRect(anInsetRect.origin.x, anInsetRect.origin.y, 40,40);
  NSRect artistBox = NSMakeRect(hspacing + iconBox.origin.x + iconBox.size.width, 
                               anInsetRect.origin.y - 1,
                               anInsetRect.size.width - iconBox.size.width - hspacing,
                               anInsetRect.size.height);
  NSRect trackBox  = NSMakeRect(hspacing + iconBox.origin.x + iconBox.size.width, 
                                artistBox.origin.y + artistSize.height + vspacing,
                                anInsetRect.size.width - iconBox.size.width - hspacing - 20,
                                anInsetRect.size.height);
  NSRect lastplayedBox  = NSMakeRect(hspacing + iconBox.origin.x + iconBox.size.width, 
                                trackBox.origin.y + trackSize.height + vspacing - 1,
                                anInsetRect.size.width - iconBox.size.width - hspacing,
                                anInsetRect.size.height);
  
	if ([self isHighlighted]) {
		[artistAttr setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    [artistAttr removeObjectForKey:NSShadowAttributeName];
		[trackAttr setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    [trackAttr removeObjectForKey:NSShadowAttributeName];
		[lastplayedAttr setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	}	else {
		[artistAttr setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		[trackAttr setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		[lastplayedAttr setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	}
  
  [NSGraphicsContext saveGraphicsState];
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:iconBox xRadius:2 yRadius:2];
  [path addClip];
  [icon drawInRect:iconBox 
          fromRect:NSZeroRect 
          operation:NSCompositeSourceOver 
          fraction:1.0];
  [NSGraphicsContext restoreGraphicsState];
	
	[artistLabel drawInRect:artistBox withAttributes:artistAttr];
	[trackLabel drawInRect:trackBox withAttributes:trackAttr];
	[lastplayedLabel drawInRect:lastplayedBox withAttributes:lastplayedAttr];
  
  [icon release];
}

@end
