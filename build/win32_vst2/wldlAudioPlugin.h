#include "../../source/MyVSTPlugin.h"

#ifdef WLDLAUDIOPLUGIN_EXPORTS
#define WLDLAUDIOPLUGIN_API __declspec(dllexport)
#else
#define WLDLAUDIOPLUGIN_API __declspec(dllimport)
#endif

extern "C" {
	WLDLAUDIOPLUGIN_API AEffect* VSTPluginMain(audioMasterCallback audioMaster);
}

