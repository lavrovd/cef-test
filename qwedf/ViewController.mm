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

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

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


@interface AAPLRenderer : NSObject<MTKViewDelegate>
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
@end




// Main class performing the rendering
@implementation AAPLRenderer
{
    int i;
    id<MTLDevice> _device;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _commandQueue;
}




- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if (self)
    {
        _device = mtkView.device;

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
    }

    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    // The render pass descriptor references the texture into which Metal should draw
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor == nil) {
        NSLog(@"currentRenderPassDescriptor failed");
    }

    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, sin(i++ / 2 / 3.14159)/2+0.5, 0, 1);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder endEncoding];
    
    id<MTLDrawable> drawable = view.currentDrawable;
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end



@interface ViewController()
@property (weak) IBOutlet MTKView *mtkView;

@end


@implementation ViewController {
    MTKView *_view;
    AAPLRenderer *_renderer;
}


- (void)viewDidLoad {
    [super viewDidLoad];
  

    _view = self.mtkView;
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    self.mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0);

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];

    if(!_renderer) {
        NSLog(@"Renderer initialization failed");
        return;
    }

    [_renderer
        mtkView:self.mtkView
        drawableSizeWillChange:_view.drawableSize
     ];
    self.mtkView.delegate = _renderer;
    
 

    CefWindowInfo window_info;
   // window_info.SetAsWindowless(nil/*void *parent*/);
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
