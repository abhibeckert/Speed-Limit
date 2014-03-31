//
//  SLAppDelegate.m
//  Speed Limit Editor
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import "SLEditorAppDelegate.h"

@interface SLEditorAppDelegate ()

@property (strong) SLMutableSpeedLimitStore *store;

@end

@implementation SLEditorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.store = [[SLMutableSpeedLimitStore alloc] init];
  
  self.wayCountLabel.stringValue = [NSString stringWithFormat:@"%li ways", (long)self.store.allWays.count];
}

- (IBAction)performImportOsmFile:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[@"osm", @"xml"];
  
  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    [self importOSMUrl:panel.URL];
  }];
}

- (IBAction)saveAs:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.allowedFileTypes = @[@"sld"];
  panel.allowsOtherFileTypes = NO;
  
  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    [self.store writeToUrl:panel.URL];
  }];
}

- (void)importOSMUrl:(NSURL *)osmUrl
{
  SLOSMImporter *importer = [[SLOSMImporter alloc] initWithStore:self.store importURL:osmUrl];
  
  [importer import];
  
  [self.wayList reloadData];
  self.wayCountLabel.stringValue = [NSString stringWithFormat:@"%li ways", (long)self.store.allWays.count];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return self.store.allWays.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  SLWay *way = [self.store.allWays objectAtIndex:row];
  
  if ([tableColumn.identifier isEqualToString:@"name"]) {
    return way.name;
  } else if ([tableColumn.identifier isEqualToString:@"speed"]) {
    return [NSString stringWithFormat:@"%li", (long)way.speedLimit];
  }
  
  NSLog(@"unknown column %@", tableColumn.identifier);
  return nil;
}


@end
