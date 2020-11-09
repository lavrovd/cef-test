//
//  ViewController.m
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 06..
//

#import "ViewController.h"
#import "AppDelegate.h"
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/wrapper/cef_library_loader.h"
#include "AppDelegate.h"


class SimpleHandler :
    public CefClient,
    public CefRenderHandler
{
 public:
   SimpleHandler() {
  
   }
    virtual CefRefPtr<CefRenderHandler> GetRenderHandler() override {
        return this;
    }

    virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override {
        rect.Set(0,0,100,100);
    }
    
    virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                         PaintElementType type,
                         const RectList& dirtyRects,
                         const void* buffer,
                         int width,
                         int height) override {
        NSLog(@"paint");
    }

    ///
 private:

  // Include the default reference counting implementation.
  IMPLEMENT_REFCOUNTING(SimpleHandler);
};


@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    CefWindowInfo window_info;
    window_info.SetAsWindowless(nil/*<#void *parent#>*/);
    const char kStartupURL[] = "https://www.google.com";

    
    CefBrowserHost::CreateBrowser(
      window_info,
      new SimpleHandler(),
      kStartupURL,
      CefBrowserSettings(),
      nullptr,
      nullptr);
 
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
