{
  "targets": [
    {
      "target_name": "CrossProcessRenderer",
      "sources": [ "./Source/Electron/CrossProcessRenderer/main.cpp" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}