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
#include "include/wrapper/cef_library_loader.h"
#include "AppDelegate.h"
#include "BrowserApp.h"

int main(int argc, const char * argv[]) {
    // Load the CEF framework library at runtime instead of linking directly
    // as required by the macOS sandbox implementation.
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInMain())
      return 1;
    
    @autoreleasepool {
        
        [NSApplication sharedApplication];
        
        CefMainArgs main_args;
        CefRefPtr<BrowserApp> app = new BrowserApp();
        CefSettings settings;
        
        AppDelegate* delegate = [[AppDelegate alloc] initWithCefApp:app.get()];
        [NSApp setDelegate:delegate];
        
        CefInitialize(main_args, settings, app, NULL);
        
        CefRunMessageLoop();
        
        //while (true) {
        //    CefDoMessageLoopWork();
        //}
      
    }
 
    
    return 0; //NSApplicationMain(argc, argv);
}
