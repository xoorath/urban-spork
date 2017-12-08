#include <nan.h>
#define ExportMethod(name) exports->Set(Nan::New( #name ).ToLocalChecked(), Nan::New<v8::FunctionTemplate>(name)->GetFunction())
#define ExportLambda(name, lambda) exports->Set(Nan::New( #name ).ToLocalChecked(), Nan::New<v8::FunctionTemplate>( lambda )->GetFunction())

#include <windows.h> 
#include <stdio.h> 
#include <tchar.h>
#include <strsafe.h>

#define BUFSIZE 512
 
DWORD WINAPI InstanceThread(LPVOID); 
VOID GetAnswerToRequest(LPTSTR, LPTSTR, LPDWORD); 



void GetBuffer(const Nan::FunctionCallbackInfo<v8::Value>& info) {
  info.GetReturnValue().Set(Nan::New("world").ToLocalChecked());
}

void Init(v8::Local<v8::Object> exports) {
  ExportMethod(GetBuffer);
  ExportLambda(GetBuffer2, [](const Nan::FunctionCallbackInfo<v8::Value>& info){
    info.GetReturnValue().Set(Nan::New("world2").ToLocalChecked());
  });
}

NODE_MODULE(CrossProcessRenderer, Init)