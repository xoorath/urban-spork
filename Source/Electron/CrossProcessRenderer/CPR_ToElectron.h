#pragma once

#include <nan.h>

/**
 * CPR_ToElectron Handles piping data from the CPR_Reciever to the client 
 * javascript.
 * 
 * It's important to know how electron processes are managed, as it's a 
 * client server architecture that might not be intuitive if you're using 
 * it for the first time.
 * 
 * In short: The code you're reading now is part of a DLL loaded by the 
 * electron application (see: "../index.js"). This application spawns any 
 * number of windows that each work like their own "browser tab" if you 
 * will, running its own frontend javascript.
 * 
 * The CPR_ToElectron namespace here will take images provided by the 
 * CPR_Reciever and send them to the electron process. The electron process 
 * will then send that data to the appropriate front-end javascript to 
 * display to the user.
 */
namespace CPR_ToElectron
{
////////////////////////////////////////////////////////////////////////
// Initialization and lifetime events
////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
// Runtime API for communications with game proc.
////////////////////////////////////////////////////////////////////////
}