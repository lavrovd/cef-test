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

class MyCefClient : public CefClient,
                    public CefLifeSpanHandler {

  // CefLifeSpanHandler methods
  virtual void OnAfterCreated (CefRefPtr<CefBrowser> browser) OVERRIDE {
 
  }

  IMPLEMENT_REFCOUNTING (MyCefClient);
};


// Minimal implementation of CefApp for the browser process.
class BrowserApp : public CefApp, public CefBrowserProcessHandler {
 public:
  BrowserApp() {}

  // CefApp methods:
  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() OVERRIDE {
    return this;
  }

  // CefBrowserProcessHandler methods:
  void OnContextInitialized() OVERRIDE {
//      CefWindowInfo window_info;
//      const char kStartupURL[] = "https://www.google.com";
//
//      CefBrowserHost::CreateBrowser(
//          window_info,
//          new MyCefClient(),
//          kStartupURL,
//          CefBrowserSettings(),
//          nullptr,
//          nullptr);
  }

 private:
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
        
        CefMainArgs main_args;
        CefRefPtr<CefApp> app = new BrowserApp();
        CefSettings settings;
       
        CefInitialize(main_args, settings, app, NULL);
        
        CefRunMessageLoop();
        
        //while (true) {
        //    CefDoMessageLoopWork();
        //}
      
    }
 
    
    return 0; //NSApplicationMain(argc, argv);
}
