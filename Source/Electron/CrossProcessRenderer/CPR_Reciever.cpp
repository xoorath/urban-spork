#include "CPR_Reciever.h"
#include <vector>

#include <iostream>

#include "CPR_ToElectron.h"
#include "zmq.h"

////////////////////////////////////////////////////////////////////////////////////////// CPR
namespace
{
static class CPR_RecieverInternal
{
  private:
    T_ImageDataHandler m_ImageDataHandler;

  public:
    void AnnounceEditorReady()
    {
        CPR_ToElectron::Log("zmq setup starting");
        
        void* zmq = nullptr;
        zmq = zmq_ctx_new();
        
        CPR_ToElectron::Log("zmq setup new called");

        zmq_ctx_destroy(zmq);

        CPR_ToElectron::Log("destroy called");
        // TODO: link to other processes (see 0mq?)
        // share an image buffer with them, and send that off to CPR_ToElectron for rendering on the front end
    }

    void Subscribe_OnImageRecieved(T_ImageDataHandler imageDataHandler)
    {
        m_ImageDataHandler = imageDataHandler;
    }

} s_CPR_Reciever;
}

////////////////////////////////////////////////////////////////////////////////////////// CRP Wrapper

namespace CPR_Reciever
{

void AnnounceEditorReady()
{
    s_CPR_Reciever.AnnounceEditorReady();
}
void Subscribe_OnImageRecieved(T_ImageDataHandler imageDataHandler)
{
    s_CPR_Reciever.Subscribe_OnImageRecieved(imageDataHandler);
}
}