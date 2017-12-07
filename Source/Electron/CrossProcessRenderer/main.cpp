#include <nan.h>

#define ExportMethod(name) exports->Set(Nan::New( #name ).ToLocalChecked(), Nan::New<v8::FunctionTemplate>(name)->GetFunction())

void GetBuffer(const Nan::FunctionCallbackInfo<v8::Value>& info) {
  info.GetReturnValue().Set(Nan::New("world").ToLocalChecked());
}

void Init(v8::Local<v8::Object> exports) {
  ExportMethod(GetBuffer);
}

NODE_MODULE(CrossProcessRenderer, Init)