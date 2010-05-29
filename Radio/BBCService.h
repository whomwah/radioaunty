//
//  BBCService.h
//  Radio
//
//  Created by Duncan Robertson on 27/05/2010.
//  Copyright 2010 Whomwah.com. All rights reserved.
//

/*
{
 service =         {
  key = radio1;
  outlet =             {
    key = england;
    title = "Radio 1 England";
  };
  title = "BBC Radio 1";
  type = radio;
};
*/

#import <Cocoa/Cocoa.h>


@interface BBCService : NSObject {
  NSString *key;
  NSString *title;
  NSString *type;
  NSDictionary *outlet;
}

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, retain) NSDictionary *outlet;

- (id)initWithDictionary:(NSDictionary *)service;
- (NSString *)display_title;

@end
