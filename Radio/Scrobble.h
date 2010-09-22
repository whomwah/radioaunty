//
//  Scrobble.h
//  Radio
//
//  Created by Duncan Robertson on 20/09/2010.
//  Copyright 2010 whomwah.com All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@protocol ScrobbleDelegate;

@interface Scrobble : NSObject {
  BOOL handshake;
  NSString *protocolVersion;
  NSString *clientId;
  NSString *clientVersion;
  NSString *user;
  NSString *apiKey;
  NSString *apiSecret;
  NSString *tmpAuthToken;
  NSString *sessionToken;
  NSString *sessionUser;
  
  id <ScrobbleDelegate> delegate;
}

@property (nonatomic, assign) id <ScrobbleDelegate> delegate;
@property (nonatomic, copy) NSString *protocolVersion;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *clientVersion;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *apiSecret;
@property (nonatomic, copy) NSString *tmpAuthToken;
@property (nonatomic, copy) NSString *sessionToken;
@property (nonatomic, copy, readonly) NSString *sessionUser;

- (id)initWithApiKey:(NSString *)apikey andSecret:(NSString *)secret;
- (void)fetchRequestToken;
- (void)fetchWebServiceSession;
- (NSString*)urlToAuthoriseUser;
- (NSString*)urlToUnAuthoriseUser;
- (BOOL)isAuthorised;
- (void)sendNowPlayingArtist:(NSString*)artist andTrack:(NSString*)track;
- (void)scrobbleTrack:(NSString*)track andArtist:(NSString*)artist;

@end

@protocol ScrobbleDelegate <NSObject>
@optional
- (void)scrobbleDidGetRequestToken:(Scrobble*)sender;
- (void)scrobble:(Scrobble*)sender didNotGetRequestToken:(NSError*)error;
- (void)scrobbleDidGetSessionToken:(Scrobble*)sender;
- (void)scrobble:(Scrobble*)sender didNotGetSessionToken:(NSError*)error;
- (void)scrobble:(Scrobble*)sender didSendNowPlaying:(NSDictionary*)response;
- (void)scrobble:(Scrobble*)sender didNotSendNowPlaying:(NSError*)error;
- (void)scrobble:(Scrobble*)sender didScrobble:(NSDictionary*)response;
- (void)scrobble:(Scrobble*)sender didNotScrobble:(NSError*)error;
@end
