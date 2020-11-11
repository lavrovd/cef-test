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




class BrowserApp : public CefApp, public CefBrowserProcessHandler {
 public:
  BrowserApp(AppDelegate *appDelegate) {
      this->appDelegate = appDelegate;
  }

  // CefApp methods:
  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() OVERRIDE {
    return this;
  }

  // CefBrowserProcessHandler methods:
  void OnContextInitialized() OVERRIDE {
      [this->appDelegate OnContextInitialized];

  }

 private:
    AppDelegate *appDelegate;
    
  IMPLEMENT_REFCOUNTING(BrowserApp);
  DISALLOW_COPY_AND_ASSIGN(BrowserApp);
};



int main(int argc, const char * argv[]) {
    // Load the CEF framework library at runtime instead of linking directly
    // as required by the macOS sandbox implementation.
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInMain())
      return 1;
    
    @autoreleasepool {
        
        [NSApplication sharedApplication];
        
     
        AppDelegate* delegate = [AppDelegate new];
        [NSApp setDelegate:delegate];
        
        
        CefMainArgs main_args(2, new char*[]{
            "dummy",
            "--use-mock-keychain",
            //"--show-fps-counter",
            //"--disable-gpu-vsync",
            //"--disable-frame-rate-limit",
           
        });
      
       
        CefRefPtr<BrowserApp> app = new BrowserApp(delegate);
        CefSettings settings;
        //settings.windowless_rendering_enabled = true;
        CefInitialize(main_args, settings, app, NULL);
        
        CefRunMessageLoop();
        
        CefShutdown();
        //while (true) {
        //    CefDoMessageLoopWork();
        //}
      
    }
 
    
    return 0; //NSApplicationMain(argc, argv);
}
