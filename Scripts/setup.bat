@echo off
:: ensure we can get back to the callers directory when we're done, so we don't strand them.
set OD=%CD%
:: ensure we can start in the correct directory, even if this batch file is run from the current directory or one higher (more common)
set SCRIPT_DIR=%~dp0
CD %SCRIPT_DIR%
CD ../

echo [42m[30m=============================================================================[0m[0m
echo [42m[30mSETUP STARTED (wait for completion message, or ctrl+c to cancel)             [0m[0m
echo [42m[30m=============================================================================[0m[0m

set skip_decompress=%1

IF NOT "%skip_decompress%"=="skip_decompress" (
    echo ^|- decompression can be skipped by adding skip_decompress to the command line
    echo ^|- this can be useful if you have already decompressed dependancies and simply
    echo ^|- want to run the rest of the setup process.
    echo ^|- example:
    echo ^|-     ./Scripts/setup.bat skip_decompress
    echo ^|-   or
    echo ^|-     yarn setup skip_decompress
    node ./Source/JS/decompress.js ./third_party/cef/depot_tools.zip /third_party/cef/depot_tools

) ELSE (
    echo [44m[37m^|- skipping decompression ---------------------------------------------------[0m[0m
)

echo [44m[37m^|- building cef wrapper -----------------------------------------------------[0m[0m


echo [44m[37m^|- running genie project generation -----------------------------------------[0m[0m
"./node_modules/bx/tools/bin/windows/genie.exe" vs2017

echo [42m[30m=============================================================================[0m[0m
echo [42m[30mSETUP COMPLETE                                                               [0m[0m
echo [42m[30m=============================================================================[0m[0m

:: return to the callers directory
cd %OD%