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


class MyCefClient : public CefClient,
                    public CefLifeSpanHandler {

  // CefLifeSpanHandler methods
  virtual void OnAfterCreated (CefRefPtr<CefBrowser> browser) OVERRIDE {
    // The call to setDockIcon() in applicationDidFinishLaunching()
    // is enough when running tiny via 'tiny.app/Contents/MacOS/tiny',
    // but not enough when running it via 'open tiny.app'?!
   // setDockIcon();
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
      CefWindowInfo window_info;
      const char kStartupURL[] = "https://www.google.com";
      
      CefBrowserHost::CreateBrowser(
          window_info,
          new MyCefClient(),
          kStartupURL,
          CefBrowserSettings(),
          nullptr,
          nullptr);
  }

 private:
  IMPLEMENT_REFCOUNTING(BrowserApp);
  DISALLOW_COPY_AND_ASSIGN(BrowserApp);
};


@interface SharedAppDelegate : NSObject <NSApplicationDelegate>
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end

@implementation SharedAppDelegate

// Called immediately before the event loop starts.
// Right place for setting up app level things.
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
//    id menubar = [[NSMenu new] autorelease];
//    id appMenuItem = [[NSMenuItem new] autorelease];
//    [menubar addItem:appMenuItem];
//    [NSApp setMainMenu:menubar];
//    id appMenu = [[NSMenu new] autorelease];
//    id appName = [[NSProcessInfo processInfo] processName];
//    id quitTitle = [@"Quit " stringByAppendingString:appName];
//    id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle
//                         action:@selector(terminate:) keyEquivalent:@"q"]
//                         autorelease];
//    [appMenu addItem:quitMenuItem];
//    [appMenuItem setSubmenu:appMenu];
//    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

// Called when the event loop has been started,
// document double clicks have already been processed,
// but no events have been executed yet.
// Right place for setting up event loop level things.
// Also right place for setting dock icon, since doing it earlier
// won't override the default one set by NSApp.
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
//    // Set dock icon if desired
//    setDockIcon();
//
//    // Push app to foreground
//    [g_window makeKeyAndOrderFront:nil];
//    [NSApp activateIgnoringOtherApps:YES];
}
@end




int main(int argc, const char * argv[]) {
    // Load the CEF framework library at runtime instead of linking directly
    // as required by the macOS sandbox implementation.
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInMain())
      return 1;

    
    @autoreleasepool {
        
        [NSApplication sharedApplication];

        SharedAppDelegate* delegate = [SharedAppDelegate new];
        [NSApp setDelegate:delegate];
        
        CefMainArgs main_args;
        CefRefPtr<CefApp> app = new BrowserApp();
        CefSettings settings;
        CefInitialize(main_args, settings, app, NULL);
        CefRunMessageLoop();
        
    }
 
    
    return 0; //NSApplicationMain(argc, argv);
}
