//
//  main.m
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 06..
//

#import <Cocoa/Cocoa.h>
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    
//    // Newbie alert: new = alloc init.
//    // See https://stackoverflow.com/questions/719877/use-of-alloc-init-instead-of-new
//    SharedAppDelegate* delegate = [SharedAppDelegate new];
//    [NSApp setDelegate:delegate];

     CefMainArgs main_args;
//   CefRefPtr<CefApp> app = new BrowserApp();
    CefSettings settings;
//    CefInitialize(main_args, settings, app, NULL);
    
    return NSApplicationMain(argc, argv);
}
