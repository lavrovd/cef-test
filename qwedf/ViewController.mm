
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#import "include/cef_app.h"
#import "include/cef_browser.h"
#import "include/cef_client.h"
#pragma clang diagnostic pop


#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>
#import <mach/mach.h>
#import "ViewController.h"
#import "Renderer.h"

class CefHandler : public CefClient, public CefRenderHandler, public CefLifeSpanHandler {
public:
    CefRefPtr<CefBrowser> cefBrowser;
    
    CefHandler(Renderer* renderer) {
        this->renderer = renderer;
    }
    
    virtual CefRefPtr<CefRenderHandler> GetRenderHandler() override {
        return this;
    }
    
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override
    {
        return this;
    }
    
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> cefBrowser) override {
        this->cefBrowser = cefBrowser;
    }

    virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override {
        [renderer populateViewRect: rect];
    }
    
    virtual bool GetScreenInfo(CefRefPtr<CefBrowser> browser, CefScreenInfo& screenInfo) override {
        [renderer populateScreenInfo: screenInfo];
        return true;
    }
    
    virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                         PaintElementType type,
                         const RectList& dirtyRects,
                         const void* buffer,
                         int width,
                         int height
    ) override {
        [renderer paintType: type dirtyRects: dirtyRects buffer: buffer width: width height: height];
    }
    
private:
    Renderer* renderer;
    // Include the default reference counting implementation.
    IMPLEMENT_REFCOUNTING(CefHandler);
};


@interface ViewController()
@property (weak) IBOutlet MTKView *mtkView;
@end


@implementation ViewController {
    CefRefPtr<CefHandler> cefHandler;
}

typedef enum MouseEventKind : NSUInteger {
    kUp,
    kDown,
    kMove
} MouseEventKind;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    Renderer *renderer = [[Renderer alloc] initWithMetalKitView:self.mtkView];

    self.mtkView.delegate = renderer;
  
    cefHandler = new CefHandler(renderer);
  
    CefWindowInfo cefWindowInfo;
    cefWindowInfo.SetAsWindowless([self.view.window windowRef]);
    CefBrowserSettings cefBrowserSettings;
    CefBrowserHost::CreateBrowser(
                                  cefWindowInfo,
                                  cefHandler,
                                  //"https://google.com";
                                  //"http://localhost:9081/p/jnqrc6gaxhjc";
                                  //"https://codepen.io/jakeporritt88/pen/yJQpzv";
                                  "https://jsfiddle.net/yLtdp6c3/",
                                  cefBrowserSettings,
                                  nullptr,
                                  nullptr);
}

- (int)getModifiersForEvent:(NSEvent*)event {
    int modifiers = 0;
    
    if ([event modifierFlags] & NSEventModifierFlagControl)
        modifiers |= EVENTFLAG_CONTROL_DOWN;
    if ([event modifierFlags] & NSEventModifierFlagShift)
        modifiers |= EVENTFLAG_SHIFT_DOWN;
    if ([event modifierFlags] & NSEventModifierFlagOption)
        modifiers |= EVENTFLAG_ALT_DOWN;
    if ([event modifierFlags] & NSEventModifierFlagCommand)
        modifiers |= EVENTFLAG_COMMAND_DOWN;
    if ([event modifierFlags] & NSEventModifierFlagCapsLock)
        modifiers |= EVENTFLAG_CAPS_LOCK_ON;
    
    //  if ([event type] == NSEventTypeKeyUp ||
    //      [event type] == NSEventTypeKeyDown ||
    //      [event type] == NSEventTypeFlagsChanged
    //  ) {
    //    // Only perform this check for key events
    //    if ([self isKeyPadEvent:event])
    //      modifiers |= EVENTFLAG_IS_KEY_PAD;
    //  }
    
    // OS X does not have a modifier for NumLock, so I'm not entirely sure how to
    // set EVENTFLAG_NUM_LOCK_ON;
    //
    // There is no EVENTFLAG for the function key either.
   
    switch ([event type]) {
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeLeftMouseUp:
        case NSEventTypeLeftMouseDown:
            modifiers |= EVENTFLAG_LEFT_MOUSE_BUTTON;
            break;
        case NSEventTypeRightMouseDragged:
        case NSEventTypeRightMouseUp:
        case NSEventTypeRightMouseDown:
            modifiers |= EVENTFLAG_RIGHT_MOUSE_BUTTON;
            break;
        case NSEventTypeOtherMouseDragged:
        case NSEventTypeOtherMouseUp:
        case NSEventTypeOtherMouseDown:
            modifiers |= EVENTFLAG_MIDDLE_MOUSE_BUTTON;
            break;
        default:
            break;
    }
    
    return modifiers;
}


- (NSPoint)getClickPointForEvent:(NSEvent*)event {
  NSPoint windowLocal = [event locationInWindow];
  NSPoint contentLocal = [self.mtkView convertPoint:windowLocal fromView:nil];

  NSPoint point;
  point.x = contentLocal.x;
  point.y = [self.mtkView frame].size.height - contentLocal.y;  // Flip y.
  return point;
}

- (void)mouseEvent:(MouseEventKind)mouseEventKind
                at:(NSPoint)point
         modifiers:(int)modifiers
{
    CefRefPtr<CefBrowser> browser = cefHandler->cefBrowser;
    if (!browser || !browser.get()) {
        return;
    }
  
    CefMouseEvent mouseEvent;
    mouseEvent.x = point.x;
    mouseEvent.y = point.y;
    mouseEvent.modifiers = modifiers;
    
    switch(mouseEventKind){
        case MouseEventKind::kDown:
            browser->GetHost()->SendMouseClickEvent(
                        mouseEvent,
                        MBT_LEFT,
                        false,
                        1);
            
            break;
        case MouseEventKind::kUp:
            browser->GetHost()->SendMouseClickEvent(
                        mouseEvent,
                        MBT_LEFT,
                        true,
                        1);
            break;
        case MouseEventKind::kMove:
            browser->GetHost()->SendMouseMoveEvent(mouseEvent, false);
            break;
    }
    
   
}

- (void)viewDidLayout {
    CefRefPtr<CefBrowser> browser = cefHandler->cefBrowser;
    if (!browser || !browser.get()) {
        return;
    }
    browser->GetHost()->WasResized();
}

- (void)mouseDown:(NSEvent *)event {
    [self
        mouseEvent:MouseEventKind::kDown
        at: [self getClickPointForEvent: event]
        modifiers: [self getModifiersForEvent: event]
    ];
}

- (void)mouseMoved:(NSEvent *)event {
    [self
        mouseEvent:MouseEventKind::kMove
        at: [self getClickPointForEvent: event]
        modifiers: [self getModifiersForEvent: event]
    ];
}

- (void)mouseDragged:(NSEvent *)event {
    [self
        mouseEvent:MouseEventKind::kMove
        at: [self getClickPointForEvent: event]
        modifiers: [self getModifiersForEvent: event]
    ];
}

- (void)mouseUp:(NSEvent *)event {
    [self
        mouseEvent:MouseEventKind::kUp
        at: [self getClickPointForEvent: event]
        modifiers: [self getModifiersForEvent: event]
    ];
}


@end
