@echo off
:: ensure we can get back to the callers directory when we're done, so we don't strand them.
set OD=%CD%
:: ensure we can start in the correct directory, even if this batch file is run from the current directory or one higher (more common)
set SCRIPT_DIR=%~dp0
CD %SCRIPT_DIR%
CD ../

echo [42m[30m=============================================================================[0m[0m
echo [42m[30mSETUP STARTED (wait for completion message, or use ctrl+c to cancel)         [0m[0m
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
    node ./Source/JS/decompress.js ./third_party/cef/depot_tools.zip ./third_party/cef/depot_tools
    node ./Source/JS/decompress.js third_party/cef/cef_binary_3.3202.1690.gcd6b88f_windows64.tar.bz2 third_party/cef/cef_binary_windows64/

) ELSE (
    echo [44m[37m^|- skipping decompression ---------------------------------------------------[0m[0m
)

echo [44m[37m^|- running genie project generation (urban spork)----------------------------[0m[0m
"./node_modules/bx/tools/bin/windows/genie.exe" vs2017

echo [44m[37m^|- running genie project generation (bgfx) ----------------------------------[0m[0m
cd node_modules/bgfx/
"../bx/tools/bin/windows/genie.exe" vs2017
CD %SCRIPT_DIR%
CD ../

echo [44m[37m^|- building cef wrapper -----------------------------------------------------[0m[0m
set CEF_USE_GN=1
set GN_ARGUMENTS=--ide=vs2017 --sln=cef --filters=//cef/*
python ./third_party/cef/automate/automate-git.py --download-dir=./third_party/cef/cef_git --depot-tools-dir=./third_party/cef/depot_tools --no-distrib --no-build


echo [42m[30m=============================================================================[0m[0m
echo [42m[30mSETUP COMPLETE (see above for any errors)                                    [0m[0m
echo [42m[30m=============================================================================[0m[0m

:: return to the callers directory
cd %OD%