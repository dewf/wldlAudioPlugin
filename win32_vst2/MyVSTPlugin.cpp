#include "MyVSTPlugin.h"

#define _USE_MATH_DEFINES
#include <math.h>

MyVSTPlugin::MyVSTPlugin(audioMasterCallback audioMaster)
	:AudioEffectX(audioMaster, 1, 1)
{
	setEditor(new MyVSTEditor(this));
}

MyVSTPlugin::~MyVSTPlugin()
{
	// AudioEffect() base class deletes the editor for us
}

MyVSTPlugin * MyVSTPlugin::CreateInstance(audioMasterCallback audioMaster)
{
	// I guess in theory there could be an exception here or whatever,
	//   in which case we'd return NULL
	return new MyVSTPlugin(audioMaster);
}

bool MyVSTPlugin::getParameterProperties(VstInt32 index, VstParameterProperties * p)
{
	// we just have one parameter, index doesn't matter
	memset(p, 0, sizeof(VstParameterProperties));
	strcpy_s(p->label, kVstMaxLabelLen, "Just One Parameter");
	p->flags = 0;
	strcpy_s(p->shortLabel, kVstMaxShortLabelLen, "Jst1Pm");

	return true;
}

void MyVSTPlugin::processReplacing(float ** inputs, float ** outputs, VstInt32 sampleFrames)
{
	for (VstInt32 i = 0; i < cEffect.numOutputs; i++) {
		for (VstInt32 j = 0; j < sampleFrames; j++) {
			// blessed silence
			outputs[i][j] = 0.0f;
		}
	}
}

// ================= editor methods ================================

int CDECL eventCallback(wlWindow window, struct WLEvent *event, void *userData)
{
	auto editor = (MyVSTEditor *)userData;

	event->handled = true;
	switch (event->eventType) {
	case WLEventType_WindowRepaint: {
		auto platformContext = (WLPlatformContextD2D *)event->repaintEvent.platformContext;
		auto context = dl_CGContextCreateD2D(platformContext->target);

		auto rect = dl_CGRectMake(event->repaintEvent.x, event->repaintEvent.y, event->repaintEvent.width, event->repaintEvent.height);
		editor->repaint(context, rect);

		dl_CGContextRelease(context);
		break;
	}
	case WLEventType_Mouse: {
		event->handled = editor->mouseEvent(&event->mouseEvent);
		break;
	}
	case WLEventType_D2DTargetRecreated: {
		dl_D2DTargetRecreated(event->d2dTargetRecreatedEvent.newTarget, event->d2dTargetRecreatedEvent.oldTarget);
		break;
	}
	default:
		event->handled = false;
	}
	return 0;
}

bool libraryInitializer()
{
	WLPlatformOptions wlOptions;
	wlOptions.useDirect2D = true;
	wlInit(eventCallback, &wlOptions);

	DLPlatformOptions dlOptions;
	dlOptions.factory = wlOptions.outParams.factory;
	dl_Init(&dlOptions);

	return true;
}
bool MyVSTEditor::librariesInitialized = libraryInitializer();

const VstInt16 EDITOR_WIDTH = 1024;
const VstInt16 EDITOR_HEIGHT = 300;

MyVSTEditor::MyVSTEditor(MyVSTPlugin * plugin)
	:AEffEditor(plugin)
{
	rect.left = 0;
	rect.top = 0;
	rect.right = EDITOR_WIDTH;
	rect.bottom = EDITOR_HEIGHT;

	auto font = dl_CTFontCreateWithName(dl_CFSTR("Times New Roman"), 80.0, nullptr);
	auto attrs = dl_CFDictionaryCreateMutable(0);
	dl_CFDictionarySetValue(attrs, dl_kCTFontAttributeName, font);
	dl_CFDictionarySetValue(attrs, dl_kCTForegroundColorFromContextAttributeName, dl_kCFBooleanTrue);
	auto attrString = dl_CFAttributedStringCreate(dl_CFSTR("HELLO FROM OPENWL/DL"), attrs);

	line = dl_CTLineCreateWithAttributedString(attrString);

	dl_CFRelease(attrString);
	dl_CFRelease(attrs);
	dl_CFRelease(font);
}

MyVSTEditor::~MyVSTEditor()
{
	dl_CFRelease(line);
}

bool MyVSTEditor::getRect(ERect ** rect)
{
	*rect = &this->rect;
	return true;
}

bool MyVSTEditor::open(void * ptr)
{
	parentWindow = (HWND)ptr;

	WLWindowProperties props;
	props.usedFields = WLWindowProp_Style | WLWindowProp_NativeParent;
	props.style = WLWindowStyle_PluginWindow;
	props.nativeParent = parentWindow;

	window = wlWindowCreate(EDITOR_WIDTH, EDITOR_HEIGHT, "VST Window test", this, &props);
	wlWindowShow(window);

	// no event loop required, this is all being executed by the host app in its GUI thread

	return true;
}

void MyVSTEditor::close()
{
	wlWindowDestroy(window);
}

void MyVSTEditor::repaint(dl_CGContextRef c, dl_CGRect &rect)
{
	dl_CGContextSaveGState(c);

	dl_CGContextSetRGBFillColor(c, 0, 0, 0, 1);
	dl_CGContextFillRect(c, rect);

	// yo yo yo
	dl_CGContextSetTextMatrix(c, dl_CGAffineTransformIdentity);

	auto lineRect = dl_CTLineGetBoundsWithOptions(line, dl_kCTLineBoundsUseGlyphPathBounds);
	auto tx = (EDITOR_WIDTH - lineRect.size.width) / 2 - lineRect.origin.x; // lineRect.origin represents vector from text drawing position, to top/left of bounding rect
	auto ty = (EDITOR_HEIGHT - lineRect.size.height) / 2 - lineRect.origin.y; // ... so we need to subtract that vector, to arrive at the text origin
	dl_CGContextSetTextPosition(c, tx, ty);
	dl_CGContextSetRGBFillColor(c, 0, 0.5, 1, 1);
	dl_CTLineDraw(line, c);
	// ====

	// draw a circle at mouse pos (filled if pressed)
	dl_CGContextAddArc(c, (dl_CGFloat)mouseX, (dl_CGFloat)mouseY, 20.0, 0, M_PI * 2.0, 0);
	dl_CGContextSetRGBStrokeColor(c, 1, 0, 0, 1);
	dl_CGContextSetRGBFillColor(c, 1, 1, 0, 1);
	dl_CGContextDrawPath(c, mouseDown ? dl_kCGPathFill : dl_kCGPathStroke);

	dl_CGContextRestoreGState(c);
}

bool MyVSTEditor::mouseEvent(WLMouseEvent *mouseEvent)
{
	switch (mouseEvent->eventType) {
	case WLMouseEventType_MouseMove: {
		mouseX = mouseEvent->x;
		mouseY = mouseEvent->y;
		wlWindowInvalidate(window, 0, 0, 0, 0);
		break;
	}
	case WLMouseEventType_MouseDown:
	{
		if (mouseEvent->button == WLMouseButton_Left) {
			mouseDown = true;
			wlWindowInvalidate(window, 0, 0, 0, 0);
		}
		break;
	}
	case WLMouseEventType_MouseUp:
	{
		if (mouseEvent->button == WLMouseButton_Left) {
			mouseDown = false;
			wlWindowInvalidate(window, 0, 0, 0, 0);
		}
		break;
	}
	default:
		return false;
	}
	return true;
}

