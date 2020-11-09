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


@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    CefWindowInfo window_info;
    const char kStartupURL[] = "https://www.google.com";

    CefBrowserHost::CreateBrowser(
      window_info,
      nil, //new MyCefClient(),
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
