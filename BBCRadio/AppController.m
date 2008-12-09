//
//  AppController.m
//  BBCRadio
//
//  Created by Duncan Robertson on 09/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "AppController.h"


@implementation AppController

- (void)awakeFromNib
{
  NSURL *URL = [NSURL URLWithString:@"http://www.bbc.co.uk/iplayer/console/6music"];
  [[myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:URL]];
}

@end
