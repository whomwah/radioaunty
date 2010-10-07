//
//  LiveTextView.h
//  Radio
//
//  Created by Duncan Robertson on 10/09/2010.
//  Copyright 2010 whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LiveTextView : NSView {
  NSString *text;
  NSTextField *textArea;
  NSProgressIndicator *progressIndictor;
}

@property (nonatomic, retain) NSTextField *textArea;
@property (nonatomic, retain) NSProgressIndicator *progressIndictor;
@property (nonatomic, copy) NSString *text;

- (void)progressIndictorOn;
- (void)progressIndictorOff;

@end
