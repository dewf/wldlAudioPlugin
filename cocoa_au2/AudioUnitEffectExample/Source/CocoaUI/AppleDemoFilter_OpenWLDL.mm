#include "AppleDemoFilter_OpenWLDL.h"

#import "../../../../deps/openwl/source/openwl.h"
#import "../../../../deps/opendl/source/opendl.h"

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

int eventCallback(wlWindow window, struct WLEvent *event, void *userData);

static bool initFrameworks() {
    WLPlatformOptions wlOpts;
    wlOpts.pluginSlaveMode = true; // essential! otherwise it will collide with the host program and everything breaks
    wlInit(eventCallback, &wlOpts);
    
//    DLPlatformOptions dlOpts;
//    dlOpts.reserved = 0;
//    dl_Init(&dlOpts);
    
    return true;
}

class DemoFilterView
{
public:
    DemoFilterView();
    ~DemoFilterView();
    
    void onEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue);
};

void AUEventDispatcher(void *inRefCon, void *inObject, const AudioUnitEvent *inEvent, UInt64 inHostTime, Float32 inValue)
{
    auto dfvObject = (DemoFilterView *)inRefCon;
    dfvObject->onEvent(inObject, inEvent, inValue);
}

int eventCallback(wlWindow window, struct WLEvent *event, void *userData)
{
    auto dfvObject = (DemoFilterView *)userData;
    
    event->handled = true;
    switch (event->eventType) {
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
        auto dfvObject = new DemoFilterView;
        
        wlWindow dummyWindow;
        auto view = wlWindowCreateNSViewOnly(900, 400, dfvObject, &dummyWindow);
        if (view) {
            AUEventListenerRef auEventListener;

            // attach various callbacks and such
            AUEventListenerCreate(AUEventDispatcher, dfvObject,
                                  CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.05, 0.05,
                                  &auEventListener);
            
            return view;
        }
    }
    return NULL;
}
    
DemoFilterView::DemoFilterView()
{
    // nothing yet
}
DemoFilterView::~DemoFilterView()
{
    // nothing yet
}
void DemoFilterView::onEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue)
{
    // nothing yet
}

