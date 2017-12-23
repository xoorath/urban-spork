#include "CPR_Host.h"
#include "zmq.h"

namespace CPR_Host
{
namespace zmq 
{

struct S_Context {
public:
    S_Context() : m_Context(nullptr) 
    { 
    }

    ~S_Context() 
    {
        Destroy();
    }

    void Create()
    {
        if (m_Context == nullptr)
        {
            m_Context = zmq_ctx_new();
        }
    }

    void Destroy()
    {
        if (m_Context != nullptr)
        {
            zmq_ctx_destroy(m_Context);
            m_Context = nullptr;
        }
    }

    operator void*() { return m_Context; }
private:
    void* m_Context;
};

static S_Context ctx = S_Context();

}

void AnnounceHostReady()
{
    zmq::ctx.Create();
    zmq_ctx_set(zmq::ctx, 0, 0);
}
}