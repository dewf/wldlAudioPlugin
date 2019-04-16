#include "AppleDemoFilter_OpenWLDL.h"

#import "../../../../deps/openwl/source/openwl.h"
#import "../../../../deps/opendl/source/opendl.h"

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

#include <stdio.h>

int eventCallback(wlWindow window, struct WLEvent *event, void *userData);

static bool initFrameworks() {
    WLPlatformOptions wlOpts;
    wlOpts.pluginSlaveMode = true; // essential! otherwise it will collide with the host program and everything breaks
    wlInit(eventCallback, &wlOpts);
    
    DLPlatformOptions dlOpts = {};
    dl_Init(&dlOpts);
    
    return true;
}

class DemoFilterView
{
    int width;
    int height;
public:
    DemoFilterView(int width, int height);
    ~DemoFilterView();
    inline int getHeight() { return height; }
    
    void onAUEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue);
    void repaint(dl_CGContextRef context);
    void resize(int newWidth, int newHeight);
};

void AUEventDispatcher(void *inRefCon, void *inObject, const AudioUnitEvent *inEvent, UInt64 inHostTime, Float32 inValue)
{
    auto filterView = (DemoFilterView *)inRefCon;
    filterView->onAUEvent(inObject, inEvent, inValue);
}

int eventCallback(wlWindow window, struct WLEvent *event, void *userData)
{
    auto filterView = (DemoFilterView *)userData;
    
    event->handled = true;
    switch (event->eventType) {
        case WLEventType_WindowResized:
            filterView->resize(event->resizeEvent.newWidth, event->resizeEvent.newHeight);
            break;
            
        case WLEventType_WindowRepaint: {
            auto platformContext = (CGContextRef)event->repaintEvent.platformContext;
            auto context = dl_CGContextCreateQuartz(platformContext, filterView->getHeight());
            
            filterView->repaint(context);
            
            dl_CGContextRelease(context);
            break;
        }
        default:
            event->handled = false;
    }
    return 0;
}

NSView *AppleDemoFilter_CreateWLViewFor(AudioUnit inAU, NSSize size)
{
    static bool initialized = false;
    if (!initialized) {
        initFrameworks();
        initialized = true;
    }
    
    if (inAU) {
        auto intWidth = 900; //(int)size.width;
        auto intHeight = 300; //(int)size.height;
        printf("suggested size: %d,%d\n", (int)size.width, (int)size.height);
        auto filterView = new DemoFilterView(intWidth, intHeight);
        
        wlWindow dummyWindow;
        auto ns_view = wlWindowCreateNSViewOnly(intWidth, intHeight, filterView, &dummyWindow);
        if (ns_view) {
            
            // attach various callbacks and such
            AUEventListenerRef auEventListener;
            AUEventListenerCreate(AUEventDispatcher, filterView,
                                  CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.05, 0.05,
                                  &auEventListener);
            
            return ns_view;
        }
    }
    return NULL;
}

DemoFilterView::DemoFilterView(int width, int height)
    :width(width), height(height)
{
    // nothing yet
}

DemoFilterView::~DemoFilterView()
{
    // nothing yet
}

void DemoFilterView::repaint(dl_CGContextRef context)
{
    dl_CGContextSaveGState(context);
    
    dl_CGContextSetRGBFillColor(context, 0, 0, 0.3, 1);
    dl_CGContextFillRect(context, dl_CGRectMake(0, 0, width, height));
    
    dl_CGContextSetRGBStrokeColor(context, 1, 1, 0, 1);
    dl_CGContextSetLineWidth(context, 2);
    dl_CGContextStrokeRect(context, dl_CGRectMake(10, 10, width - 20, height - 20));
    
    dl_CGContextRestoreGState(context);
}

void DemoFilterView::resize(int newWidth, int newHeight)
{
    width = newWidth;
    height = newHeight;
}

void DemoFilterView::onAUEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue)
{
    // nothing yet
}
