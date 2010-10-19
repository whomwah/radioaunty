//
//  BBCBroadcast.h
//  Radio
//
//  Created by Duncan Robertson on 27/05/2010.
//  Copyright 2010 Whomwah.com. All rights reserved.
//

/*
 {
 duration = 2700;
 end = "2010-05-27T18:00:00+01:00";
 "is_blanked" = 0;
 "is_repeat" = 1;
 programme =                     {
 "display_titles" =                         {
    subtitle = "05/05/2009";
    title = "Weakest Link";
 };
 media =                         {
 availability = "7 days left to watch";
 expires = "2010-06-03T17:59:00+01:00";
 format = video;
 };
 pid = b00kdr4y;
 position = "<null>";
 programme =                         {
 ownership =                             {
 service =                                 {
 key = bbcone;
 title = "BBC One";
 type = tv;
 };
 };
 pid = b006mgvw;
 title = "Weakest Link";
 type = brand;
 };
 "short_synopsis" = "Anne Robinson presents the quick-fire general knowledge quiz.";
 title = "05/05/2009";
 type = episode;
 };
 start = "2010-05-27T17:15:00+01:00";
 }
 */

#import <Cocoa/Cocoa.h>


@interface BBCBroadcast : NSObject {
  int duration;
  NSDate *end;
  NSDate *start;
  BOOL is_blanked;
  BOOL is_repeat;
  NSDictionary *display_titles;
  NSDictionary *media;
  NSString *short_synopsis;
  NSString *availability;
  NSString *pid;
  NSString *type;
}

@property (nonatomic, copy) NSString *short_synopsis;
@property (nonatomic, copy) NSString *availability;
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, retain) NSDictionary *display_titles;
@property (nonatomic, retain) NSDictionary *media;
@property (nonatomic, readonly, copy) NSString *programme_url;

- (id)initWithDictionary:(NSDictionary *)broadcast;

@end
