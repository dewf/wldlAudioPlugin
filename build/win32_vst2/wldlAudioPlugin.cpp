// wldlAudioPlugin.cpp : Defines the exported functions for the DLL application.
//

#include "header.h"
#include "wldlAudioPlugin.h"
#include "../../source/MyVSTPlugin.h"

WLDLAUDIOPLUGIN_API AEffect* VSTPluginMain(audioMasterCallback audioMaster)
{
	// Get VST Version of the Host
	if (!audioMaster(0, audioMasterVersion, 0, 0, 0, 0))
		return 0;  // old version

	// Create the AudioEffect
	auto effect = MyVSTPlugin::CreateInstance(audioMaster);
	if (!effect)
		return 0;

	// Return the VST AEffect structur
	return effect->getAeffect();
}
