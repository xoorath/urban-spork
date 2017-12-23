{
  "targets": [
    {
      "target_name": "CrossProcessRenderer",
      "sources": [ 
        "./Source/Electron/CrossProcessRenderer/CPR_Reciever.cpp" ,
        "./Source/Electron/CrossProcessRenderer/CPR_ToElectron.cpp"
        ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")",
        "./node_modules/libzmq/include"
      ],
      "link_settings" : {
        "libraries":[
          "../node_modules/libzmq/bin/x64/Debug/v140/dynamic/libzmq.lib"
        ]
      },
      "copies":[{
        "destination":"build/Release",
        "files": [
          "./node_modules/libzmq/bin/x64/Debug/v140/dynamic/libzmq.dll" 
        ]
      }]
    }
  ]
}