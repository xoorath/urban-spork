{
  "targets": [
    {
      "target_name": "CrossProcessRenderer",
      "sources": [ 
        "./Source/Electron/CrossProcessRenderer/CPR_Reciever.cpp" ,
        "./Source/Electron/CrossProcessRenderer/CPR_ToElectron.cpp"
        ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}