//
//  AppDelegate.m
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 06..
//

#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>


@interface AppDelegate () {
    BrowserApp* browserApp;
    NSWindowController *myController;
}
@end

@implementation AppDelegate

- (id)initWithCefApp:(BrowserApp *)app {
    self = [super init];
    if (self) {
        browserApp = app;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
   
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    myController = [storyBoard instantiateInitialController];
    [myController showWindow:self];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
