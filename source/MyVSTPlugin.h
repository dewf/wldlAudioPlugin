#pragma once

#include "VST2_SDK/public.sdk/source/vst2.x/audioeffectx.h"
#include "VST2_SDK/public.sdk/source/vst2.x/aeffeditor.h"
#include "../deps/openwl/source/openwl.h"
#include "../deps/opendl/source/opendl.h"

class MyVSTPlugin : public AudioEffectX
{
	MyVSTPlugin(audioMasterCallback audioMaster);
	~MyVSTPlugin();
public:
	static MyVSTPlugin *CreateInstance(audioMasterCallback audioMaster); // just kind of imitating the way the example does it, factory method

	// implementations
	bool getParameterProperties(VstInt32 index, VstParameterProperties* p);

	// required implementations:
	void processReplacing(float** inputs, float** outputs, VstInt32 sampleFrames) override;
};

#include <Windows.h>

class MyVSTEditor : public AEffEditor
{
	ERect rect;
	HWND parentWindow = nullptr;
	static bool librariesInitialized;
	wlWindow window;
	//
	dl_CTLineRef line;
	int mouseX = 0, mouseY = 0;
	bool mouseDown = false;
public:
	MyVSTEditor(MyVSTPlugin *plugin);
	~MyVSTEditor() override;

	bool getRect(ERect** rect) override;
	bool open(void* ptr) override;
	void close() override;

	// OpenWL event methods
	void repaint(dl_CGContextRef c, dl_CGRect &rect);
	bool mouseEvent(WLMouseEvent *mouseEvent);
};

