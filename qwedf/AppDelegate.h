//
//  AppDelegate.h
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 06..
//

#import <Cocoa/Cocoa.h>
#import "BrowserApp.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
-(id) initWithCefApp:(BrowserApp *)app;

@end

