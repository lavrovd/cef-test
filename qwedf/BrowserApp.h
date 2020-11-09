//
//  BrowserApp.h
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 09..
//
#include "include/cef_app.h"
#include "include/cef_browser.h"

#ifndef BrowserApp_h
#define BrowserApp_h

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


#endif /* BrowserApp_h */
