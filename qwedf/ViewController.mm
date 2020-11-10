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


@interface AAPLRenderer : NSObject<MTKViewDelegate>
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

- (void)getViewRect:(CefRefPtr<CefBrowser>)browser
               rect:(CefRect&)rect;

- (void)onBrowserPaint:(CefRefPtr<CefBrowser>)browser
                  type:(CefRenderHandler::PaintElementType)type
            dirtyRects:(const CefRenderHandler::RectList)dirtyRects
                buffer:(const void*)buffer
                 width:(int)width
                height:(int)height;
@end


class SimpleHandler : public CefClient, public CefRenderHandler
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
    
    virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override
    {
        [renderer getViewRect:browser rect:rect];
    }
    
    virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                         PaintElementType type,
                         const RectList& dirtyRects,
                         const void* buffer,
                         int width,
                         int height) override
    {
        [renderer onBrowserPaint:browser type: type dirtyRects: dirtyRects buffer: buffer width: width height: height];
        //        uint64_t tid;
        //        pthread_threadid_np(NULL, &tid);
        //        NSLog(@"paint : %lld\n", tid);
        
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
    int i;
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLTexture> texture;
    id<MTLComputePipelineState> computePipelineState;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if (self)
    {
        device = mtkView.device;
        commandQueue = [device newCommandQueue];
        
        MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice: device];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"codinghorror" withExtension:@"png"];
        texture = [loader newTextureWithContentsOfURL:url options:nil error:nil];
       
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLFunction> computeShader = [library newFunctionWithName: @"compute_shader"];
        computePipelineState = [device newComputePipelineStateWithFunction:computeShader error: nil];
    }

    return self;
}


- (void)getViewRect:(CefRefPtr<CefBrowser>)browser rect:(CefRect&)rect
{
    rect.Set(0,0,1000,1000);
}

- (void)onBrowserPaint:(CefRefPtr<CefBrowser>)browser
                  type:(CefRenderHandler::PaintElementType)type
            dirtyRects:(const CefRenderHandler::RectList)dirtyRects
                buffer:(const void*)buffer
                 width:(int)width
                height:(int)height
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    
//    uint64_t tid;
//    pthread_threadid_np(NULL, &tid);
//    NSLog(@"draw : %lld\n", tid);
    
    
    // The render pass descriptor references the texture into which Metal should draw
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor == nil)
    {
        NSLog(@"currentRenderPassDescriptor failed");
    }

    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, sin(i++ / 2 / 3.14159)/2+0.5, 0, 1);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder endEncoding];
    
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (drawable != nil && computePipelineState != nil)
    {
        id<MTLTexture> drawingTexture = [drawable texture];
        
        if (drawingTexture != nil)
        {
           
            id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
            if (encoder != nil)
            {
                [encoder setComputePipelineState:computePipelineState];
                [encoder setTexture:texture atIndex:0];
                [encoder setTexture:drawingTexture atIndex:1];
                
                MTLSize threadGroupCount = MTLSizeMake(16, 16, 1);
                MTLSize threadGroups = MTLSizeMake(
                                                   texture.width / threadGroupCount.width,
                                                   texture.height / threadGroupCount.height,
                                                   1);
                [encoder dispatchThreadgroups:threadGroups threadsPerThreadgroup: threadGroupCount];
                [encoder endEncoding];
                
            }
            
        }
    }
    
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
    AAPLRenderer *renderer;
    SimpleHandler *simpleHandler;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    self.mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0);
    self.mtkView.framebufferOnly = false;
    
    renderer = [[AAPLRenderer alloc] initWithMetalKitView:self.mtkView];
    simpleHandler = new SimpleHandler(renderer);
    
    if(!renderer) {
        NSLog(@"Renderer initialization failed");
        return;
    }
    
    [renderer
     mtkView:self.mtkView
     drawableSizeWillChange:self.mtkView.drawableSize
     ];
    
    self.mtkView.delegate = renderer;
    
    
    CefWindowInfo window_info;
    window_info.SetAsWindowless(nil/*void *parent*/);
    const char kStartupURL[] = "https://www.google.com";
    
    
    CefBrowserHost::CreateBrowser(
                                  window_info,
                                  simpleHandler,
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
