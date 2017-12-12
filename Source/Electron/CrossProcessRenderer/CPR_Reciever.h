#pragma once

#include <functional>
#include <string>

typedef std::string T_ImageData;
typedef std::function<void(T_ImageData)> T_ImageDataHandler;

/**
 * CPR_Reciever Handles the editor side of the communication pipeline with the game process.
 * 
 * 1) CPR_Reciever broadcasts to any listening game processes to anounce that it's available for rendering.
 *          [game proc]: shuts its window down, or prevents its creation. begins streaming image data to the editor proc.
 * 2) CPR_Reciever recieves an image data stream from the game processes.
 * 3) CPR_Reciever calls back it's listner (main.cpp) with a usable image to display.
 * 4) The rest of the CPR_Reciever API is now available for communication to and from the game proc.
 * 
 * Known issues:
 * We don't yet handle having multiple editor processes, currently the behaviour of 
 * running multiple editors is undefined.
 */
namespace CPR_Reciever 
{
    ////////////////////////////////////////////////////////////////////////
    // Initialization and lifetime events
    ////////////////////////////////////////////////////////////////////////

    // Let any listening game processes know that we're ready to recieve a stream of image data.
    void AnnounceEditorReady();

    // Subscribe to the OnImageRecieved event for ready to use image data.
    // note: only one subscriber is supported.
    void Subscribe_OnImageRecieved(T_ImageDataHandler);

    ////////////////////////////////////////////////////////////////////////
    // Runtime API for communications with game proc.
    ////////////////////////////////////////////////////////////////////////
}