//
//  Scrobble.m
//  Radio
//
//  Created by Duncan Robertson on 20/09/2010.
//  Copyright 2010 whomwah.com All rights reserved.
//

#import "Scrobble.h"
#import "JSON.h"
#import "GDataHTTPFetcher.h"

#define LFM_HANDSHAKE       @"http://post.audioscrobbler.com"
#define LFM_API_2_0         @"http://ws.audioscrobbler.com/2.0/"
#define LFM_REQUEST_TOKEN   @"http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=%@&api_sig=%@&format=json"
#define LFM_REQUEST_SESSION @"http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=%@&token=%@&api_sig=%@&format=json"
#define LFM_UP_NOWPLAYING   @"method=user.updateNowPlaying&api_key=%@&artist=%@&track=%@&sk=%@&api_sig=%@&format=json"
#define LFM_UP_SCROBBLE     @"method=track.scrobble&api_key=%@&artist=%@&track=%@&sk=%@&api_sig=%@&timestamp=%@&format=json"

#define LFM_AUTH            @"http://www.last.fm/api/auth/?api_key=%@&token=%@"
#define LFM_UNAUTH          @"http://www.last.fm/settings/applications"

@interface Scrobble (PrivateMethods)
- (NSString*)sigForMethod:(NSString*)method withOptions:(NSDictionary*)options;
@end


@implementation Scrobble

@synthesize delegate;
@synthesize protocolVersion;
@synthesize clientId;
@synthesize clientVersion;
@synthesize user;
@synthesize apiKey;
@synthesize apiSecret;
@synthesize tmpAuthToken;
@synthesize sessionToken;
@synthesize sessionUser;

- (id)init
{
  [self dealloc];
  @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                 reason:@"Dedicated initializer: initWithApiKey:andSessionKey:" 
                               userInfo:nil];
  return nil;
}


- (void)dealloc
{  
  [protocolVersion release];
  [clientId release];
  [clientVersion release];
  [user release];
  [apiKey release];
  [apiSecret release];
  [tmpAuthToken release];
  [sessionUser release];
  [sessionToken release];
  
	[super dealloc];
}


- (id)initWithApiKey:(NSString *)apikey andSecret:(NSString *)secret
{
  if (![super init]) return nil;
  
  self.apiKey           = apikey; 
  self.apiSecret        = secret;
  self.protocolVersion  = @"1.2.1";
  self.clientId         = @"tst";
  self.clientVersion    = @"1.0";
  
  handshake = YES;
  
  return self;
}


#pragma mark -
#pragma mark Utilities
#pragma mark -

- (NSString*)toMD5:(NSString*)concat
{
  // generate md5 hash from string
  // from http://www.saobart.com/md5-has-in-objective-c/
  
  const char *concat_str = [concat UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(concat_str, strlen(concat_str), result);
  NSMutableString *hash = [NSMutableString string];
  for (int i = 0; i < 16; i++) {
    [hash appendFormat:@"%02X", result[i]];
  }
  return [hash lowercaseString];  
}


- (NSString*)sigForMethod:(NSString*)method withOptions:(NSDictionary*)options
{
  // create tmp mutable storage
  NSMutableDictionary *opts = [[NSMutableDictionary alloc] initWithCapacity:2];
  
  // add any potential options
  if (options) [opts setDictionary:options];
  
  // add the required options
  [opts setObject:method forKey:@"method"];
  [opts setObject:self.apiKey forKey:@"api_key"];
  
  // make an array of keys, so you can order them
  NSArray *keys = [[opts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];  
  // create the string to return
  NSMutableString *result = [NSMutableString stringWithCapacity:[self.apiKey length]];
  
  // loop through keys
  for (NSString *key in keys) {
    [result appendString:[NSString stringWithFormat:@"%@%@", key, [opts objectForKey:key]]];
  }
  
  // add the secret
  [result appendString:self.apiSecret];
  
  NSLog(@"api_sig: %@", result);
  
  // free some memory
  [opts release];
  
  // return a md5 hash of the results
  return [self toMD5:result];
}

- (BOOL)isAuthorised
{
  if (sessionToken != nil && ![sessionToken isEqual:@""]) {
    return YES;
  }
  
  return NO;
}

- (NSString*)urlToUnAuthoriseUser
{
  return LFM_UNAUTH;
}


#pragma mark -
#pragma mark Scrobble methods
#pragma mark -

- (void)scrobbleTrack:(NSString*)track andArtist:(NSString*)artist
{  
  // only attempt this is you can
  if (![self isAuthorised]) return;
  
  // timestamp
  NSString *ts = [NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]];

  // create an options dictionary
  NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                        self.sessionToken, @"sk",
                        track, @"track",
                        artist, @"artist",
                        ts, @"timestamp",
                        nil];
  
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"track.scrobble" withOptions:opts]; 
  
  // create the url
  NSString *params = [NSString stringWithFormat:LFM_UP_SCROBBLE, self.apiKey, 
                      artist, track, self.sessionToken, sig, ts];
  
  // create the request and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LFM_API_2_0]];
  GDataHTTPFetcher *scrobbleTrack = [GDataHTTPFetcher httpFetcherWithRequest:request];
  [scrobbleTrack setPostData:[params dataUsingEncoding:NSUTF8StringEncoding]];
  
  // send the request
  [scrobbleTrack beginFetchWithDelegate:self
                      didFinishSelector:@selector(scrobbleTrack:finishedWithData:)
                        didFailSelector:@selector(scrobbleTrack:failedWithError:)];
}

- (void)scrobbleTrack:(GDataHTTPFetcher *)scrobbleTrack failedWithError:(NSError *)error
{
  NSLog(@"scrobbleTrack error: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
  [[self delegate] scrobble:self didNotScrobble:error];
}

- (void)scrobbleTrack:(GDataHTTPFetcher *)scrobbleTrack finishedWithData:(NSData *)retrievedData
{  
  // create a JSON parser
  SBJSON *parser = [[SBJSON alloc] init];
  
  // fetch the result as a string
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  
  // send back response
  [[self delegate] scrobble:self didScrobble:[parser objectWithString:result_string error:nil]];
}


- (void)sendNowPlayingArtist:(NSString*)artist andTrack:(NSString*)track
{  
  // only attempt this is you can
  if (![self isAuthorised]) return;
  
  // create an options dictionary
  NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                        self.sessionToken, @"sk",
                        track, @"track",
                        artist, @"artist",
                        nil];
  
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"user.updateNowPlaying" withOptions:opts]; 
  
  // create the url
  NSString *params = [NSString stringWithFormat:LFM_UP_NOWPLAYING, self.apiKey, 
                      artist, track, self.sessionToken, sig];

  // create the request and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LFM_API_2_0]];
  GDataHTTPFetcher *sendNowPlaying = [GDataHTTPFetcher httpFetcherWithRequest:request];
  [sendNowPlaying setPostData:[params dataUsingEncoding:NSUTF8StringEncoding]];
  
  // send the request
  [sendNowPlaying beginFetchWithDelegate:self
                       didFinishSelector:@selector(sendNowPlaying:finishedWithData:)
                         didFailSelector:@selector(sendNowPlaying:failedWithError:)];
}

- (void)sendNowPlaying:(GDataHTTPFetcher *)sendNowPlaying failedWithError:(NSError *)error
{
  NSLog(@"sendNowPlaying error: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
  [[self delegate] scrobble:self didNotSendNowPlaying:error];
}

- (void)sendNowPlaying:(GDataHTTPFetcher *)sendNowPlaying finishedWithData:(NSData *)retrievedData
{  
  // create a JSON parser
  SBJSON *parser = [[SBJSON alloc] init];
  
  // fetch the result as a string
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
 
  // send back response
  [[self delegate] scrobble:self didSendNowPlaying:[parser objectWithString:result_string error:nil]];
}


#pragma mark -
#pragma mark fetch auth token
#pragma mark -

- (void)fetchRequestToken
{
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"auth.getToken" withOptions:nil]; 
  
  // build the final url
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:LFM_REQUEST_TOKEN, self.apiKey, sig]];
  
  // build our request and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher* tokenFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];

  // send the request
  [tokenFetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(tokenFetcher:finishedWithData:)
                    didFailSelector:@selector(tokenFetcher:failedWithError:)];  
}

- (void)tokenFetcher:(GDataHTTPFetcher *)tokenFetcher failedWithError:(NSError *)error
{
  NSLog(@"fetchRequestToken error: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
  [[self delegate] scrobble:self didNotGetRequestToken:error];
}

- (void)tokenFetcher:(GDataHTTPFetcher *)tokenFetcher finishedWithData:(NSData *)retrievedData
{
  // create a JSON parser
  SBJSON *parser = [[SBJSON alloc] init];
  
  // fetch the result as a string
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  
  // parse the json string
  self.tmpAuthToken = [[parser objectWithString:result_string error:nil] objectForKey:@"token"];
  
  // we're done with the parser
  [parser release];
  [result_string release];
  
  // pass the delegate the token
  [[self delegate] scrobbleDidGetRequestToken:self];
}


#pragma mark -
#pragma mark fetch web service session
#pragma mark -

- (void)fetchWebServiceSession
{                         
  // create an options dictionary
  NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                        self.tmpAuthToken, @"token",
                        nil];
  
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"auth.getSession" withOptions:opts]; 
  
  // create the final url
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:LFM_REQUEST_SESSION, 
                                     self.apiKey, self.tmpAuthToken, sig]];
  
  // create a request object and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher* sessionFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
  
  // make the request
  [sessionFetcher beginFetchWithDelegate:self
                     didFinishSelector:@selector(sessionFetcher:finishedWithData:)
                       didFailSelector:@selector(sessionFetcher:failedWithError:)];
  
  // clear the tmp auth token
  tmpAuthToken = nil;
}

- (void)sessionFetcher:(GDataHTTPFetcher *)tokenFetcher failedWithError:(NSError *)error
{
  NSLog(@"fetchWebServiceSession error: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
  [[self delegate] scrobble:self didNotGetSessionToken:error];
}

- (void)sessionFetcher:(GDataHTTPFetcher *)tokenFetcher finishedWithData:(NSData *)retrievedData
{
  // create a JSON parser
  SBJSON *parser = [[SBJSON alloc] init];
  
  // fetch the result as a string
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  
  // parse the json string
  NSDictionary *results = [[parser objectWithString:result_string error:nil] objectForKey:@"session"];
  sessionToken = [[results objectForKey:@"key"] retain];
  sessionUser = [[results objectForKey:@"name"] retain];
  
  // we're done with the parser and string
  [parser release];
  [result_string release];
  
  // pass the delegate through
  [[self delegate] scrobbleDidGetSessionToken:self];
}


#pragma mark -
#pragma mark return the url to auth a user
#pragma mark -

- (NSString*)urlToAuthoriseUser
{
  if (!tmpAuthToken) {
    NSLog(@"Error: No tmp auth token present");
  }
  
  return [NSString stringWithFormat:LFM_AUTH, apiKey, tmpAuthToken];
}


@end
