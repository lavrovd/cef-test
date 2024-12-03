
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
#import "AnimationController.h"

class CefHandler : public CefClient,
                   public CefRenderHandler,
                   public CefLifeSpanHandler,
                   public CefLoadHandler {
public:
    CefRefPtr<CefBrowser> cefBrowser;
    
    CefHandler(Renderer* renderer) {
        this->renderer = renderer;
    }
    
    virtual CefRefPtr<CefLoadHandler> GetLoadHandler() override {
        return this;
    }
    virtual void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                             CefRefPtr<CefFrame> frame,
                             int httpStatusCode) override {
       if (frame->IsMain()) {
           // Now it's safe to inject the animation controller
           dispatch_async(dispatch_get_main_queue(), ^{
               AnimationController* controller = new AnimationController();
               controller->injectControlScript(browser);
               controller->setTotalFrames(browser, 100);
               delete controller;
           });
       }
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
    AnimationController animationController;
    bool isPlaying;
    int currentFrame;
    int totalFrames;
    float frameRate;
}

typedef enum MouseEventKind : NSUInteger {
    kUp,
    kDown,
    kMove
} MouseEventKind;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize default values
    isPlaying = false;
    currentFrame = 0;
    totalFrames = 100;
    frameRate = 30.0;
    
    [self setupControls];
    
    // Get the controls view
    NSView *controlsView = [self.timelineSlider superview];
    
    // Adjust the MTKView frame to account for controls
    NSRect mtkFrame = self.mtkView.frame;
    mtkFrame.size.height -= controlsView.frame.size.height;
    mtkFrame.origin.y = controlsView.frame.size.height;
    self.mtkView.frame = mtkFrame;
    
    
    Renderer *renderer = [[Renderer alloc] initWithMetalKitView:self.mtkView];

    self.mtkView.delegate = renderer;
  
    cefHandler = new CefHandler(renderer);
  
    CefWindowInfo cefWindowInfo;
    cefWindowInfo.SetAsWindowless([self.view.window windowRef]);
    CefBrowserSettings cefBrowserSettings;
    CefBrowserHost::CreateBrowser(
                                  cefWindowInfo,
                                  cefHandler,
                                  //"https://encse.github.io/cef-test/demo.html",
                                  "https://lavrovd.github.io/cef-test/titles.html",
                                  cefBrowserSettings,
                                  nullptr,
                                  nullptr);
    
    // After browser creation, you need to wait for the browser to be fully created
    // This should be done in the CefHandler's OnLoadEnd callback
    // For now, we'll add a small delay as an example
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->animationController.injectControlScript(self->cefHandler->cefBrowser);
        self->animationController.setTotalFrames(self->cefHandler->cefBrowser, 100); // Set to desired frame count
    });
}

- (void)setupControls {
    // Create controls view with black background
    NSView *controlsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.view.frame.size.width, 50)];
    controlsView.wantsLayer = YES;
    controlsView.layer.backgroundColor = NSColor.blackColor.CGColor;
    [self.view addSubview:controlsView];
    
    // Debug frame
    NSLog(@"Controls view frame: %@", NSStringFromRect(controlsView.frame));
    
    // Play/Pause Button
    NSButton *playButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 80, 30)];
    [playButton setButtonType:NSButtonTypePushOnPushOff];  // Fixed enum name
    [playButton setBezelStyle:NSBezelStyleRounded];
    [playButton setTitle:@"Play"];
    [playButton setTarget:self];
    [playButton setAction:@selector(togglePlayPause:)];
    [controlsView addSubview:playButton];
    self.playPauseButton = playButton;
    
    // Timeline Slider
    NSSlider *slider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 15, 300, 20)];
    [slider setMinValue:0];
    [slider setMaxValue:totalFrames];
    [slider setTarget:self];
    [slider setAction:@selector(timelineSliderChanged:)];
    [controlsView addSubview:slider];
    self.timelineSlider = slider;
    
    // Current Frame Label
    NSTextField *frameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(410, 15, 60, 20)];
    frameLabel.stringValue = @"0/100";
    frameLabel.editable = NO;
    frameLabel.selectable = NO;
    frameLabel.bezeled = NO;
    frameLabel.drawsBackground = NO;
    frameLabel.textColor = [NSColor whiteColor];
    [controlsView addSubview:frameLabel];
    self.currentFrameLabel = frameLabel;
    
    // Frame Rate Presets
    NSPopUpButton *fpsButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(480, 15, 100, 20)];
    [fpsButton addItemsWithTitles:@[@"24 fps", @"25 fps", @"30 fps"]];
    [fpsButton setTarget:self];
    [fpsButton setAction:@selector(frameRatePresetChanged:)];
    [controlsView addSubview:fpsButton];
    self.frameRatePresets = fpsButton;
    
    // Total Frames Input
    NSTextField *framesField = [[NSTextField alloc] initWithFrame:NSMakeRect(590, 15, 60, 20)];
    framesField.stringValue = @"100";
    framesField.editable = YES;
    framesField.bezeled = YES;
    framesField.backgroundColor = [NSColor darkGrayColor];
    framesField.textColor = [NSColor whiteColor];
    [framesField setTarget:self];
    [framesField setAction:@selector(totalFramesChanged:)];
    [controlsView addSubview:framesField];
    self.totalFramesField = framesField;
    
    // Print debug info for all subviews
    for (NSView *view in controlsView.subviews) {
        NSLog(@"Subview: %@ Frame: %@", [view class], NSStringFromRect(view.frame));
    }
}
// Control event handlers
- (void)togglePlayPause:(id)sender {
    isPlaying = !isPlaying;
    [self.playPauseButton setTitle:isPlaying ? @"Pause" : @"Play"];
    
    if (isPlaying) {
        animationController.play(cefHandler->cefBrowser);
    } else {
        animationController.pause(cefHandler->cefBrowser);
    }
}

- (void)timelineSliderChanged:(NSSlider *)sender {
    int frame = [sender intValue];
    animationController.seekToFrame(cefHandler->cefBrowser, frame);
    [self updateFrameDisplay:frame];
}

- (void)frameRatePresetChanged:(NSPopUpButton *)sender {
    int fps = 30;
    switch ([sender indexOfSelectedItem]) {
        case 0: fps = 24; break;
        case 1: fps = 25; break;
        case 2: fps = 30; break;
    }
    frameRate = fps;
    animationController.setFrameRate(cefHandler->cefBrowser, fps);
}

- (void)totalFramesChanged:(NSTextField *)sender {
    totalFrames = [sender intValue];
    [self.timelineSlider setMaxValue:totalFrames];
    animationController.setTotalFrames(cefHandler->cefBrowser, totalFrames);
}

- (void)updateFrameDisplay:(int)frame {
    [self.currentFrameLabel setStringValue:[NSString stringWithFormat:@"%d/%d", frame, totalFrames]];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
    // Update controls view frame
    NSView *controlsView = [self.timelineSlider superview];
    if (controlsView) {
        NSRect frame = controlsView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.origin.y = 0;
        controlsView.frame = frame;
        
        // Adjust MTKView frame
        NSRect mtkFrame = self.mtkView.frame;
        mtkFrame.size.height = self.view.frame.size.height - frame.size.height;
        mtkFrame.origin.y = frame.size.height;
        self.mtkView.frame = mtkFrame;
    }
    
    // Existing CEF resize code
    CefRefPtr<CefBrowser> browser = cefHandler->cefBrowser;
    if (!browser || !browser.get()) {
        return;
    }
    browser->GetHost()->WasResized();
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

//- (void)viewDidLayout {
//    CefRefPtr<CefBrowser> browser = cefHandler->cefBrowser;
//    if (!browser || !browser.get()) {
//        return;
//    }
//    browser->GetHost()->WasResized();
//}

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
