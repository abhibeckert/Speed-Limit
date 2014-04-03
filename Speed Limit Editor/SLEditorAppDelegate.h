//
//  SLAppDelegate.h
//  Speed Limit Editor
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Cocoa/Cocoa.h>
#import "SLSpeedLimitStore.h"
#import "SLMutableSpeedLimitStore.h"
#import "SLOSMImporter.h"

@interface SLEditorAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *wayList;
@property (weak) IBOutlet NSTextField *wayCountLabel;
@property (weak) IBOutlet NSProgressIndicator *progressBar;

- (IBAction)performImportOsmFile:(id)sender;
- (IBAction)saveAs:(id)sender;

@end
