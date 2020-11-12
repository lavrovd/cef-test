#import "include/cef_app.h"
#import "include/cef_browser.h"
#import "include/cef_client.h"
#import "include/wrapper/cef_library_loader.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>
#import <mach/mach.h>
#import "ViewController.h"

struct ShaderParameters {
    simd::float2 mouse;
};

typedef enum MouseEventKind : NSUInteger {
    kUp,
    kDown,
    kMove
} MouseEventKind;


@interface AAPLRenderer : NSObject<MTKViewDelegate>
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

- (void)getViewRect:(CefRefPtr<CefBrowser>)getViewRect
               rect:(CefRect&)rect;


- (void)getScreenInfo:(CefRefPtr<CefBrowser>)browser
          screen_info:(CefScreenInfo&)screen_info;
    
    
- (void)onBrowserPaint:(CefRefPtr<CefBrowser>)browser
                  type:(CefRenderHandler::PaintElementType)type
            dirtyRects:(const CefRenderHandler::RectList)dirtyRects
                buffer:(const void*)buffer
                 width:(int)width
                height:(int)height;

- (void)setBrowser:(CefRefPtr<CefBrowser>)browser;

- (void)mouseEvent:(MouseEventKind)mouseEventKind
                at:(NSPoint)point
         modifiers:(int)modifiers;


@end


@interface MetalView : MTKView<NSWindowDelegate> {
    AAPLRenderer* renderer;
}
- (void)setRenderer:(AAPLRenderer*)renderer;
@end

@implementation MetalView

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
  NSPoint contentLocal = [self convertPoint:windowLocal fromView:nil];

  NSPoint point;
  point.x = contentLocal.x;
  point.y = [self frame].size.height - contentLocal.y;  // Flip y.
  return point;
}

- (void) viewWillMoveToWindow:(NSWindow *)newWindow {
    // Setup a new tracking area when the view is added to the window.
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options: (NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseDown:(NSEvent *)event {
    [renderer mouseEvent:MouseEventKind::kDown at: [self getClickPointForEvent: event] modifiers: [self getModifiersForEvent: event]];
}

- (void)mouseMoved:(NSEvent *)event {
    [renderer mouseEvent:MouseEventKind::kMove at: [self getClickPointForEvent: event] modifiers: [self getModifiersForEvent: event]];
}

- (void)mouseDragged:(NSEvent *)event {
    [renderer mouseEvent:MouseEventKind::kMove at: [self getClickPointForEvent: event] modifiers: [self getModifiersForEvent: event]];
}

- (void)mouseUp:(NSEvent *)event {
    [renderer mouseEvent:MouseEventKind::kUp at: [self getClickPointForEvent: event] modifiers: [self getModifiersForEvent: event]];
}

- (void)setRenderer:(AAPLRenderer*)_renderer {
    renderer = _renderer;
}
@end



class SimpleHandler : public CefClient, public CefRenderHandler, public CefLifeSpanHandler
{
public:
    SimpleHandler(AAPLRenderer* renderer)
    {
        this->renderer = renderer;
    }
    
    virtual CefRefPtr<CefRenderHandler> GetRenderHandler() override
    {
        return this;
    }
    
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override
    {
        return this;
    }
    
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        [renderer setBrowser:browser];
    }

    virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override
    {
        [renderer getViewRect:browser rect:rect];
    }
    
    virtual bool GetScreenInfo(CefRefPtr<CefBrowser> browser,
                               CefScreenInfo& screen_info) override {
        [renderer getScreenInfo:browser screen_info:screen_info];
        return true;
    }
    
    virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                         PaintElementType type,
                         const RectList& dirtyRects,
                         const void* buffer,
                         int width,
                         int height) override
    {
            
        [renderer onBrowserPaint:browser type: type dirtyRects: dirtyRects buffer: buffer width: width height: height];
    
    }
    
    
    virtual void OnAcceleratedPaint(CefRefPtr<CefBrowser> browser,
                                    PaintElementType type,
                                    const RectList& dirtyRects,
                                    void* shared_handle) override
    {
        NSLog(@"XXX");
    }
    
    ///
private:
    AAPLRenderer* renderer;
    // Include the default reference counting implementation.
    IMPLEMENT_REFCOUNTING(SimpleHandler);
};



// Main class performing the rendering
@implementation AAPLRenderer
{
    NSDate *date;
    float fps;
    int i;
    MTKView * mtkView;
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLTexture> texture;
    id<MTLComputePipelineState> computePipelineState;
    
    CGSize size;
    CefRefPtr<CefBrowser> browser;
}

- (void)mouseEvent:(MouseEventKind)mouseEventKind at:(NSPoint)point modifiers:(int)modifiers
{
    if (!browser || !browser.get()) {
        return;
    }
  
    CefMouseEvent mouseEvent;
    mouseEvent.x = point.x;
    mouseEvent.y = point.y;
    mouseEvent.modifiers = modifiers;
    // NSLog(@"mouseEvent %d %d", mouseEvent.x, mouseEvent.y);
    
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

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)_mtkView
{
    self = [super init];
    if (self)
    {
        mtkView = _mtkView;
        device = mtkView.device;
        commandQueue = [device newCommandQueue];

        
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLFunction> computeShader = [library newFunctionWithName: @"compute_shader"];
        computePipelineState = [device newComputePipelineStateWithFunction:computeShader error: nil];
    }

    return self;
}

- (void)setBrowser:(CefRefPtr<CefBrowser>)_browser
{
    browser = _browser;
}

- (void)getViewRect:(CefRefPtr<CefBrowser>)browser
               rect:(CefRect&)rect
{
    if (size.width > 0) {
        float deviceScaleFactor = [self getDeviceScaleFactor];
        rect.Set(0,0, (int)size.width / deviceScaleFactor, (int)size.height / deviceScaleFactor);
    }
}

- (float)getDeviceScaleFactor {
    return [[NSScreen mainScreen] backingScaleFactor];
}

- (void) getScreenInfo:(CefRefPtr<CefBrowser>)browser
           screen_info:(CefScreenInfo&) screen_info
{
    screen_info.device_scale_factor = [self getDeviceScaleFactor];

}

- (void)onBrowserPaint:(CefRefPtr<CefBrowser>)browser
                  type:(CefRenderHandler::PaintElementType)type
            dirtyRects:(const CefRenderHandler::RectList)dirtyRects
                buffer:(const void*)buffer
                 width:(int)width
                height:(int)height
{
   
    CefRenderHandler::RectList::const_iterator i = dirtyRects.begin();
    
    if(!texture || texture.width < width || texture.height < height){
        
        MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
        textureDescriptor.width = width;
        textureDescriptor.height = height;
        texture = [device newTextureWithDescriptor:textureDescriptor];
        int x = 0;
        int y = 0;
        int w = width;
        int h = height;
        MTLRegion region = MTLRegionMake2D(x, y, w, h);
        [texture replaceRegion:region mipmapLevel:0 withBytes:(char*)buffer + (y * width + x) * 4 bytesPerRow:4 * width];
    } else {
        for (; i != dirtyRects.end(); ++i) {
            const CefRect& rect = *i;
            
            int x = rect.x;
            int y = rect.y;
            int w = rect.width;
            int h = rect.height;
            NSLog(@"dirty x: %d, y: %d, w: %d, h: %d", x, y, w, h);
            MTLRegion region = MTLRegionMake2D(x, y, w, h);
            
            [texture
                replaceRegion:region
                mipmapLevel:0
                withBytes:(char*)buffer + (y * width + x) * 4
                bytesPerRow:4 * width
             ];
           
        }
    }
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    
    // The render pass descriptor references the texture into which Metal should draw
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor == nil)
    {
        NSLog(@"currentRenderPassDescriptor failed");
    }

    i++;
    renderPassDescriptor.colorAttachments[0].clearColor =
        MTLClearColorMake(
                  sin(i / 2 / 3.14159 / 17)/2+0.5,
                  sin(i / 2 / 3.14159 / 20)/2+0.5,
                  sin(i / 2 / 3.14159 / 13)/2+0.5,
                  1);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder endEncoding];
    
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (drawable != nil && computePipelineState != nil)
    {
        id<MTLTexture> drawingTexture = [drawable texture];
        
        if (drawingTexture != nil && texture != nil)
        {
           
            id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
            if (encoder != nil)
            {
                ShaderParameters params;
               
                
                
                CGEventRef dummyEvent = CGEventCreate(NULL);
                CGPoint point = CGEventGetLocation(dummyEvent);
                float scaleFactor = [self getDeviceScaleFactor];
                params.mouse = simd::make_float2(point.x * scaleFactor, point.y * scaleFactor);
                CFRelease(dummyEvent);
                
                
                [encoder setComputePipelineState:computePipelineState];
                
                [encoder
                    setBytes: &params
                    length: sizeof(params)
                    atIndex: 0
                 ];
                [encoder setTexture:texture atIndex:1];
                [encoder setTexture:drawingTexture atIndex:2];
                [encoder setTexture:drawingTexture atIndex:3];
              
                NSUInteger w = computePipelineState.threadExecutionWidth;
                NSUInteger h = computePipelineState.maxTotalThreadsPerThreadgroup / w;
                MTLSize threadsPerThreadgroup = MTLSizeMake(w, h, 1);
                
                MTLSize threadsPerGrid = MTLSizeMake(
                                                   texture.width,
                                                   texture.height,
                                                   1);
                [encoder
                    dispatchThreads:threadsPerGrid
                    threadsPerThreadgroup:threadsPerThreadgroup
                ];
                [encoder endEncoding];
                
            }
            
        }
    }
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    if (date) {
        double frameTimeMs = -1000 * [date timeIntervalSinceNow];
        double smoothing = 0.9;
        
        fps = fps * smoothing + (1000 / frameTimeMs) * (1.0 - smoothing);
       // NSLog(@"fps: %f, frametime: %f", fps, frameTimeMs);
      
    }
    
    date = [NSDate date];
}

- (void)mtkView:(nonnull MetalView *)view drawableSizeWillChange:(CGSize)_size
{
    size = _size;
    if (browser) {
        browser->GetHost()->WasResized();
    }
}

@end



@interface ViewController()
@property (weak) IBOutlet MetalView *mtkView;

@end


@implementation ViewController {
    AAPLRenderer *renderer;
    SimpleHandler *simpleHandler;
}


- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    self.mtkView.clearColor = MTLClearColorMake(0,0,0,0);
    self.mtkView.framebufferOnly = false;
    // self.mtkView.preferredFramesPerSecond = 30;
   
    
    renderer = [[AAPLRenderer alloc] initWithMetalKitView:self.mtkView];
    
    [self.mtkView setRenderer: renderer];
    
    simpleHandler = new SimpleHandler(renderer);
    
    if (!renderer) {
        NSLog(@"Renderer initialization failed");
        return;
    }
    
    [renderer
        mtkView:self.mtkView
        drawableSizeWillChange:self.mtkView.drawableSize
     ];
    
    self.mtkView.delegate = renderer;
    
    
    CefWindowInfo window_info;
    
    window_info.SetAsWindowless([self.view.window windowRef]);
    CefBrowserSettings settings;
   
    const char kStartupURL[] =
        //"https://google.com";
        //"http://localhost:9081/p/jnqrc6gaxhjc";
        //"https://codepen.io/jakeporritt88/pen/yJQpzv";
        "https://jsfiddle.net/yLtdp6c3/";
        
    
    CefBrowserHost::CreateBrowser(
                                  window_info,
                                  simpleHandler,
                                  kStartupURL,
                                  settings,
                                  nullptr,
                                  nullptr);
}

@end
