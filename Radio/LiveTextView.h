//
//  LiveTextView.h
//  Radio
//
//  Created by Duncan Robertson on 10/09/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LiveTextView : NSView {
  NSTextField *textArea;
  NSProgressIndicator *progressIndictor;
}

@property (nonatomic, retain) NSTextField *textArea;
@property (nonatomic, retain) NSProgressIndicator *progressIndictor;

@end
