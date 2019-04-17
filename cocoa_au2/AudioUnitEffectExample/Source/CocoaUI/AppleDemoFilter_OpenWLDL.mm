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
    AudioUnit au;
    AUEventListenerRef auEventListener;

    wlWindow window; // handle to the dummy window surrounding the NSView
    int width;
    int height;
    dl_CTLineRef line;
    int mouseX, mouseY;
    bool mouseDown = false;
    
    void removeListeners();
public:
    DemoFilterView(int width, int height);
    ~DemoFilterView();
    inline int getHeight() { return height; }
    
    void setAU(AudioUnit au);
    void setWindow(wlWindow window);
    
    void onAUEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue);
    void repaint(dl_CGContextRef context, dl_CGRect rect);
    void resize(int newWidth, int newHeight);
    bool mouseEvent(WLMouseEvent *mouseEvent);
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
        case WLEventType_Mouse:
            event->handled = filterView->mouseEvent(&event->mouseEvent);
            break;
        case WLEventType_WindowDestroyed:
            delete filterView;
            break;
            
        case WLEventType_WindowResized:
            filterView->resize(event->resizeEvent.newWidth, event->resizeEvent.newHeight);
            break;
            
        case WLEventType_WindowRepaint: {
            auto platformContext = (CGContextRef)event->repaintEvent.platformContext;
            auto context = dl_CGContextCreateQuartz(platformContext, filterView->getHeight());
            
            auto rect = dl_CGRectMake(event->repaintEvent.x, event->repaintEvent.y, event->repaintEvent.width, event->repaintEvent.height);
            
            filterView->repaint(context, rect);
            
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
    
    auto intWidth = 900; //(int)size.width;
    auto intHeight = 300; //(int)size.height;
    printf("suggested size: %d,%d\n", (int)size.width, (int)size.height);
    auto filterView = new DemoFilterView(intWidth, intHeight);
    
    WLWindowProperties props = {};
    props.usedFields = WLWindowProp_Style;
    props.style = WLWindowStyle_PluginWindow;
    // pluginwindow style means it will create a dummy window,
    //   and there will be an "outparam" on the properties for the nsview that we're really after
    auto dummyWindow = wlWindowCreate(intWidth, intHeight, NULL, filterView, &props);
    if (dummyWindow) {
        
        filterView->setWindow(dummyWindow);
        filterView->setAU(inAU);
        
        return (NSView *)props.outParams.nsView; // the good stuff - what we came here for!
    }
    return NULL;
}

DemoFilterView::DemoFilterView(int width, int height)
    :width(width), height(height)
{
    // this is just a listener, not subbed to any specific AU yet
    AUEventListenerCreate(AUEventDispatcher, this,
                          CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.05, 0.05,
                          &auEventListener);
    
    auto font = dl_CTFontCreateWithName(dl_CFSTR("TimesNewRomanPSMT"), 80.0, NULL);
    auto attrs = dl_CFDictionaryCreateMutable(0);
    dl_CFDictionarySetValue(attrs, dl_kCTFontAttributeName, font);
    dl_CFDictionarySetValue(attrs, dl_kCTForegroundColorFromContextAttributeName, dl_kCFBooleanTrue);
    auto attrString = dl_CFAttributedStringCreate(dl_CFSTR("HELLO FROM OPENWL/DL"), attrs);
    
    line = dl_CTLineCreateWithAttributedString(attrString);
    
    dl_CFRelease(attrString);
    dl_CFRelease(attrs);
    dl_CFRelease(font);
}

DemoFilterView::~DemoFilterView()
{
    removeListeners();

    // and remove the listener itself ...
    AUListenerDispose(auEventListener);
    
    dl_CFRelease(line);
}

void DemoFilterView::removeListeners()
{
    // unsub from whatever was subscribed to, I guess
}

void DemoFilterView::setWindow(wlWindow inWindow)
{
    window = inWindow;
}

void DemoFilterView::setAU(AudioUnit inAU)
{
    au = inAU;
    
    // subscribe to desired events via AUEventListenerAddEventType
}

void DemoFilterView::repaint(dl_CGContextRef context, dl_CGRect rect)
{
    dl_CGContextSaveGState(context);
    
    // background
    dl_CGContextSetRGBFillColor(context, 0, 0, 0.3, 1);
    dl_CGContextFillRect(context, dl_CGRectMake(0, 0, width, height));
    
    // border line
    dl_CGContextSetRGBStrokeColor(context, 1, 1, 0, 1);
    dl_CGContextSetLineWidth(context, 2);
    dl_CGContextStrokeRect(context, dl_CGRectMake(10, 10, width - 20, height - 20));
    
    // text
    dl_CGContextSetTextMatrix(context, dl_CGAffineTransformIdentity);
    
    auto lineRect = dl_CTLineGetBoundsWithOptions(line, dl_kCTLineBoundsUseGlyphPathBounds);
    auto tx = (width - lineRect.size.width) / 2 - lineRect.origin.x; // lineRect.origin represents vector from text drawing position, to top/left of bounding rect
    auto ty = (height - lineRect.size.height) / 2 - lineRect.origin.y; // ... so we need to subtract that vector, to arrive at the text origin
    dl_CGContextSetTextPosition(context, tx, ty);
    dl_CGContextSetRGBFillColor(context, 0, 0.5, 1, 1);
    dl_CTLineDraw(line, context);
    
    // draw a circle at mouse pos (filled if pressed)
    dl_CGContextAddArc(context, (dl_CGFloat)mouseX, (dl_CGFloat)mouseY, 20.0, 0, M_PI * 2.0, 0);
    dl_CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
    dl_CGContextSetRGBFillColor(context, 1, 1, 0, 1);
    dl_CGContextDrawPath(context, mouseDown ? dl_kCGPathFill : dl_kCGPathStroke);
    
    dl_CGContextRestoreGState(context);
}

void DemoFilterView::resize(int newWidth, int newHeight)
{
    width = newWidth;
    height = newHeight;
}

bool DemoFilterView::mouseEvent(WLMouseEvent *mouseEvent)
{
    switch (mouseEvent->eventType) {
        case WLMouseEventType_MouseMove:
            mouseX = mouseEvent->x;
            mouseY = mouseEvent->y;
            wlWindowInvalidate(window, 0, 0, width, height);
            break;
        case WLMouseEventType_MouseDown:
            mouseDown = true;
            wlWindowInvalidate(window, 0, 0, width, height);
            break;
        case WLMouseEventType_MouseUp:
            mouseDown = false;
            wlWindowInvalidate(window, 0, 0, width, height);
            break;
        default:
            return false;
    }
    return true;
}

void DemoFilterView::onAUEvent(void *inObject, const AudioUnitEvent *inEvent, Float32 inValue)
{
    // nothing yet
}
