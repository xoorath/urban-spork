:: Quock color reference: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd

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

setlocal enabledelayedexpansion

set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "argVec[!argCount!]=%%~x"
)

:: recognized arguments:
set skip_decompress=FALSE
set skip_genie=FALSE

for /L %%i in (1,1,%argCount%) do (
    IF "!argVec[%%i]!"=="skip_decompress" (
        set skip_decompress=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_genie" (
        set skip_genie=TRUE
    ) ELSE (
        echo [41m[37m^|- "!argVec[%%i]!" argument not recognized [0m[0m
    )
)

IF %skip_decompress%==TRUE (
    echo [44m[37m^|- skipping decompression ^(skip_decompress argument passed^)                  [0m[0m
) ELSE (
REM    node ./Source/JS/decompress.js ./third_party/something/something.zip ./third_party/something/something
REM    node ./Source/JS/decompress.js ./third_party/other/other.tar.bz2 ./third_party/other/other
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Build CrossProcessRenderer for nodejs

echo [44m[37m^|- running electron native plugin compilation -------------------------------[0m[0m

:: a workaround for electron-rebuild, see: https://github.com/electron/electron-rebuild/issues/215
echo {} > ./node_modules/bgfx/package.json
echo {} > ./node_modules/bx/package.json
echo {} > ./node_modules/bimg/package.json

call .\node_modules\.bin\electron-rebuild
CD %SCRIPT_DIR%
CD ../

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Run GENie

IF %skip_genie%==TRUE (
    echo [44m[37m^|- skipping genie ^(skip_genie argument passed^)                               [0m[0m
) ELSE (
    echo [44m[37m^|- running genie project generation ^(urban spork^)----------------------------[0m[0m
    "./node_modules/bx/tools/bin/windows/genie.exe" vs2017

    echo [44m[37m^|- running genie project generation ^(bgfx^) ----------------------------------[0m[0m
    cd node_modules/bgfx/
    "../bx/tools/bin/windows/genie.exe" --with-examples vs2017
    CD %SCRIPT_DIR%
    CD ../
)

goto:label_exit_success

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Exit messages

:label_exit_success
echo [42m[30m=============================================================================[0m[0m
echo [42m[30mSETUP COMPLETE (see above for any errors)                                    [0m[0m
echo [42m[30m=============================================================================[0m[0m
goto:label_exit


:label_exit_error
echo [41m[37m=============================================================================[0m[0m
echo [41m[37mSETUP EXITED EARLY (see above for any errors)                                [0m[0m
echo [41m[37m=============================================================================[0m[0m
goto:label_exit

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Cleanup

:label_exit
:: return to the callers directory
cd %OD%