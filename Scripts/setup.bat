:: Quock color reference: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd

@ECHO off
:: ensure we can get back to the callers directory when we're done, so we don't strand them.
SET OD=%CD%
:: ensure we can start in the correct directory, even if this batch file is run from the current directory or one higher (more common)
SET SCRIPT_DIR=%~dp0
CD %SCRIPT_DIR%
CD ../

ECHO [42m[30m=============================================================================[0m[0m
ECHO [42m[30mSETUP STARTED (wait for completion message, or use ctrl+c to cancel)         [0m[0m
ECHO [42m[30m=============================================================================[0m[0m

setlocal enabledelayedexpansion

SET argCount=0
for %%x in (%*) do (
   SET /A argCount+=1
   SET "argVec[!argCount!]=%%~x"
)

REM recognized arguments:
SET skip_decompress=FALSE
SET skip_genie=FALSE

for /L %%i in (1,1,%argCount%) do (
    IF "!argVec[%%i]!"=="skip_decompress" (
        SET skip_decompress=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_genie" (
        SET skip_genie=TRUE
    ) ELSE (
        ECHO [41m[37m^|- "!argVec[%%i]!" argument not recognized [0m[0m
    )
)

IF %skip_decompress%==TRUE (
    ECHO [44m[37m^|- skipping decompression ^(skip_decompress argument passed^)                  [0m[0m
) ELSE (
REM    node ./Source/JS/decompress.js ./third_party/something/something.zip ./third_party/something/something
REM    node ./Source/JS/decompress.js ./third_party/other/other.tar.bz2 ./third_party/other/other
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Build CrossProcessRenderer for nodejs

ECHO [44m[37m^|- running electron native plugin compilation -------------------------------[0m[0m

:: a workaround for electron-rebuild, see: https://github.com/electron/electron-rebuild/issues/215
ECHO {} > ./node_modules/bgfx/package.json
ECHO {} > ./node_modules/bx/package.json
ECHO {} > ./node_modules/bimg/package.json

call .\node_modules\.bin\electron-rebuild -f -w CrossProcessRenderer --debug
CD %SCRIPT_DIR%
CD ../

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Run GENie

IF %skip_genie%==TRUE (
    ECHO [44m[37m^|- skipping genie ^(skip_genie argument passed^)                               [0m[0m
) ELSE (
    REM get latest installed windows SDK version

    set "VSCMD_START_DIR=%CD%"
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

    echo [44m[37m^|- found windows sdk version is "%WindowsSDKVersion%"[0m[0m

    REM run GENie
    ECHO [44m[37m^|- running genie project generation ^(urban spork^)----------------------------[0m[0m
    "./node_modules/bx/tools/bin/windows/genie.exe" vs2017

    ECHO [44m[37m^|- running genie project generation ^(bgfx^) ----------------------------------[0m[0m
    cd node_modules/bgfx/
    "../bx/tools/bin/windows/genie.exe" --with-examples vs2017
    CD %SCRIPT_DIR%
    CD ../
)

GOTO:label_exit_success

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Exit messages

:label_exit_success
ECHO [42m[30m=============================================================================[0m[0m
ECHO [42m[30mSETUP COMPLETE (see above for any errors)                                    [0m[0m
ECHO [42m[30m=============================================================================[0m[0m
GOTO:label_exit


:label_exit_error
ECHO [41m[37m=============================================================================[0m[0m
ECHO [41m[37mSETUP EXITED EARLY (see above for any errors)                                [0m[0m
ECHO [41m[37m=============================================================================[0m[0m
GOTO:label_exit

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Cleanup

:label_exit
REM return to the callers directory
cd %OD%