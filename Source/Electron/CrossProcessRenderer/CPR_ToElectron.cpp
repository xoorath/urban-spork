#include "CPR_ToElectron.h"

#include <nan.h>
#include <functional>

#include "CPR_Reciever.h"

namespace
{

static class CPR_ToElectronInternal : public Nan::ObjectWrap
{
  public:
    static void Register_On(const Nan::FunctionCallbackInfo<v8::Value> &info);
    static void Announce(const Nan::FunctionCallbackInfo<v8::Value> &info);

    static void OnImageRecieved(T_ImageData imageData);

    void Register_OnRecieveImage(v8::Local<v8::Function> imageDataCallback)
    {
        m_ImageDataCallback.Reset(imageDataCallback);
    }

    void Announce_EditorReady()
    {
        CPR_Reciever::Subscribe_OnImageRecieved(CPR_ToElectronInternal::OnImageRecieved);
        CPR_Reciever::AnnounceEditorReady();
    }

    void CallImageDataCallback(T_ImageData text)
    {
        v8::Isolate *isolate = v8::Isolate::GetCurrent();
        v8::Local<v8::Value> dataVal = Nan::New(text).ToLocalChecked();
        v8::Local<v8::Function>::New(isolate, m_ImageDataCallback)->Call(isolate->GetCurrentContext()->Global(), 1, &dataVal);
    }

    static void New(const Nan::FunctionCallbackInfo<v8::Value> &info)
    {
        if (info.IsConstructCall())
        {
            // Invoked as constructor: `new CPR_ToElectronInternal(...)`
            CPR_ToElectronInternal *obj = new CPR_ToElectronInternal();
            obj->Wrap(info.This());
            info.GetReturnValue().Set(info.This());
        }
        else
        {
            // Invoked as plain function `CPR_ToElectronInternal(...)`, turn into construct call.
            v8::Local<v8::Function> cons = Nan::New<v8::Function>(constructor);
            info.GetReturnValue().Set(cons->NewInstance(0, 0));
        }
    }

    void SetupElectronBindings(v8::Local<v8::Object> exports)
    {
        Nan::HandleScope scope;

        // Prepare constructor template
        v8::Local<v8::FunctionTemplate> tpl = Nan::New<v8::FunctionTemplate>(New);
        tpl->SetClassName(Nan::New("CPR_ToElectronInternal").ToLocalChecked());
        tpl->InstanceTemplate()->SetInternalFieldCount(1);

        // Prototype
        Nan::SetPrototypeMethod(tpl, "on", Register_On);
        Nan::SetPrototypeMethod(tpl, "announce", Announce);

        constructor.Reset(tpl->GetFunction());
        exports->Set(Nan::New("CPR").ToLocalChecked(), tpl->GetFunction());
    }

    ~CPR_ToElectronInternal()
    {
        constructor.Reset();
        m_ImageDataCallback.Reset();
    }

  private:
    static Nan::Persistent<v8::Function> constructor;

    Nan::Persistent<v8::Function> m_ImageDataCallback;
} s_CPR_ToElectron;

/* static */ Nan::Persistent<v8::Function> CPR_ToElectronInternal::constructor;

/* static */ void CPR_ToElectronInternal::Register_On(const Nan::FunctionCallbackInfo<v8::Value> &info)
{
    Nan::HandleScope scope;

    std::string textRegistration = *v8::String::Utf8Value(info[0].As<v8::String>());
    if (textRegistration == "image")
    {
        v8::Isolate *isolate = v8::Isolate::GetCurrent();
        s_CPR_ToElectron.Register_OnRecieveImage(v8::Local<v8::Function>::New(isolate, info[1].As<v8::Function>()));
    }

    info.GetReturnValue().SetUndefined();
}

/* static */ void CPR_ToElectronInternal::Announce(const Nan::FunctionCallbackInfo<v8::Value> &info)
{
    Nan::HandleScope scope;
    std::string textAnnouncement = *v8::String::Utf8Value(info[0].As<v8::String>());
    if (textAnnouncement == "ready")
    {
        s_CPR_ToElectron.Announce_EditorReady();
    }
    info.GetReturnValue().SetUndefined();
}

/* static */ void CPR_ToElectronInternal::OnImageRecieved(T_ImageData imageData)
{
    s_CPR_ToElectron.CallImageDataCallback(imageData);
}
}

namespace CPR_ToElectron
{

void SetupElectronBindings(v8::Local<v8::Object> exports)
{
    s_CPR_ToElectron.SetupElectronBindings(exports);
}

} // CPR_ToElectron

NODE_MODULE(CrossProcessRenderer, CPR_ToElectron::SetupElectronBindings)