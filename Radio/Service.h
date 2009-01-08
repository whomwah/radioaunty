//
//  Service.h
//  Radio
//
//  Created by Duncan Robertson on 06/01/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Service : NSObject {
  NSString *key;
  NSString *title;
  NSString *desc;
  NSString *outletKey;
  NSString *outletTitle;
  NSString *outletDesc;
  NSString *displayTitle;
}

@property(copy) NSString *key;
@property(copy) NSString *title;
@property(copy) NSString *desc;
@property(copy) NSString *outletKey;
@property(copy) NSString *outletTitle;
@property(copy) NSString *outletDesc;
@property(copy) NSString *displayTitle;

- (id)initUsingServiceXML:(NSArray *)data;

@end
