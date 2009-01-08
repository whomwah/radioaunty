//
//  Broadcast.h
//  Radio
//
//  Created by Duncan Robertson on 06/01/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Broadcast : NSObject {
  NSString *title;
  NSString *subtitle;
  NSString *displayTitle;
  NSString *displaySubtitle;
  NSString *shortSynopsis;
  NSString *pid;
  NSString *duration;
  NSDate   *bStart;
  NSDate   *bEnd;
  NSDate   *available;
  NSString *availableText;
}

@property(copy) NSString *title;
@property(copy) NSString *subtitle;
@property(copy) NSString *displayTitle;
@property(copy) NSString *displaySubtitle;
@property(copy) NSString *shortSynopsis;
@property(copy) NSString *pid;
@property(copy) NSString *duration;
@property(retain) NSDate *bStart;
@property(retain) NSDate *bEnd;
@property(retain) NSDate *available;
@property(copy) NSString *availableText;

- (id)initUsingBroadcastXML:(NSXMLNode *)node;
- (NSDate *)fetchDateForXPath:(NSString *)string withNode:(NSXMLNode *)node;

@end
