//
//  SLAppDelegate.h
//  Speed Limit Editor
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SLSpeedLimitStore.h"
#import "SLMutableSpeedLimitStore.h"
#import "SLOSMImporter.h"

@interface SLEditorAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *wayList;
@property (weak) IBOutlet NSTextField *wayCountLabel;

- (IBAction)performImportOsmFile:(id)sender;
- (IBAction)saveAs:(id)sender;

@end
