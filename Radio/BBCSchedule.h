//
//  BBCSchedule.h
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BBCSchedule : NSObject {
  NSMutableData *receivedData;
  NSXMLDocument *xmlDocument;
  float expectedLength;
  NSString *serviceKey;
  NSString *outletKey;
  NSString *displayTitle;
  NSString *serviceTitle;
  NSString *displaySynopsis;
  NSArray *broadcasts;
  NSDictionary *service;
  NSDate *lastUpdated;
  NSDictionary *currentBroadcast;
}

@property (retain) NSMutableData *receivedData;
@property (retain) NSString *displayTitle;
@property (retain) NSString *serviceTitle;
@property (retain) NSString *displaySynopsis;
@property (retain) NSDate *lastUpdated;
@property (retain) NSArray *broadcasts;
@property (retain) NSDictionary *currentBroadcast;
@property (readonly) NSDictionary *service;

- (id)initUsingService:(NSString *)sv outlet:(NSString *)ol;
- (NSURL *)buildUrl;
- (void)fetch:(NSURL *)url;

- (void)setServiceData;
- (void)setBroadcastData;
- (void)setCurrentBroadcastData;

- (NSDate *)fetchDateForXPath:(NSString *)string withNode:(NSXMLNode *)node;

// delagates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end
