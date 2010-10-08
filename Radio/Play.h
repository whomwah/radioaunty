//
//  Play.h
//  Radio
//
//  Created by Duncan Robertson on 06/10/2010.
//  Copyright 2010 whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Play : NSObject {
  NSString *artist;
  NSString *track;
  NSString *mbid;
  NSString *small_image;
  NSString *signature;
  NSDate *timestamp;
}

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *track;
@property (nonatomic, copy) NSString *mbid;
@property (nonatomic, copy) NSString *small_image;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, retain) NSDate *timestamp;

@end