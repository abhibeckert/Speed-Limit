//
//  SLAppDelegate.m
//  Speed Limit Editor
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLEditorAppDelegate.h"

@interface SLEditorAppDelegate ()

@property (strong) SLMutableSpeedLimitStore *store;
@property (strong) NSURL *defaultExportUrl;
@property BOOL importInProgress;

@end

@implementation SLEditorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.store = [[SLMutableSpeedLimitStore alloc] init];
  
  self.wayCountLabel.stringValue = [NSString stringWithFormat:@"%li ways", (long)self.store.allWays.count];
}

- (IBAction)performImportOsmFile:(id)sender
{
  if (self.importInProgress) {
    NSBeep();
    return;
  }
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[@"osm", @"xml"];
  
  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    [self importOSMUrl:panel.URL];
    
    self.defaultExportUrl = [NSURL URLWithString:[panel.URL.absoluteString.stringByDeletingPathExtension stringByAppendingPathExtension:@"sld"]];
  }];
}

- (IBAction)saveAs:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.allowedFileTypes = @[@"sld"];
  panel.allowsOtherFileTypes = NO;
  panel.nameFieldStringValue = self.defaultExportUrl.lastPathComponent;
  
  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    [self.store writeToUrl:panel.URL];
    
    [[NSWorkspace sharedWorkspace] selectFile:panel.URL.path inFileViewerRootedAtPath:nil];
    [[NSApplication sharedApplication] terminate:self];
  }];
}

- (void)importOSMUrl:(NSURL *)osmUrl
{
  if (self.importInProgress) {
    NSBeep();
    return;
  }
  
  SLOSMImporter *importer = [[SLOSMImporter alloc] initWithStore:self.store importURL:osmUrl];
  
  self.importInProgress = YES;
  [self.progressBar setIndeterminate:YES];
  [self.progressBar setHidden:NO];
  [self.progressBar startAnimation:self];
  __block BOOL firstProgressUpdate = YES;
  
  [importer importWithCompletion:^{
    [self.progressBar stopAnimation:self];
    [self.progressBar setHidden:YES];
    
    self.importInProgress = NO;
    
    [self.wayList reloadData];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    self.wayCountLabel.stringValue = [NSString stringWithFormat:@"%@ ways. %.f%% speed limit coverage",
                                      [numberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:self.store.allWays.count]],
                                      round(((double)importer.countWaysWithSpeedLimit / (double)self.store.allWays.count) * 100.0)];
  } progressUpdates:^(float progress) {
    if (firstProgressUpdate) {
      [self.progressBar setIndeterminate:NO];
      self.progressBar.maxValue = 1.0;
      firstProgressUpdate = NO;
    }
    self.progressBar.doubleValue = progress;
  }];
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
