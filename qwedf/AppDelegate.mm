//
//  AppDelegate.m
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 06..
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <Cocoa/Cocoa.h>


@interface AppDelegate () {
    bool finishedLaunching;
    bool contextInitialized;
    NSWindowController *windowController;
}
- (void) nextInitializationStep;
@end

@implementation AppDelegate

- (void) nextInitializationStep {
    @synchronized(self){
        if (finishedLaunching && contextInitialized) {
            NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
            windowController = [storyBoard instantiateInitialController];
            [windowController showWindow:self];
        }
    }
}

- (void)OnContextInitialized {
    contextInitialized = true;
    [self nextInitializationStep];
   
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    finishedLaunching = true;
    [self nextInitializationStep];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
