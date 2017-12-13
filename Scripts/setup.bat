@ECHO off
:: ensure we can get back to the callers directory when we're done, so we don't strand them.
SET OD=%CD%
:: ensure we can start in the correct directory, even if this batch file is run from the current directory or one higher (more common)
SET SCRIPT_DIR=%~dp0
CD %SCRIPT_DIR%
CD ../
SET PROJECT_ROOT=%CD%

CALL :function_print_bar_success
CALL :function_print_info_green "SETUP STARTED (wait for completion message, or use ctrl_c to cancel)"
CALL :function_print_bar_success

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Check for script dependancies, fail nicely if missing

REM Check that git exists at the path.
where /q git
IF NOT %ERRORLEVEL%==0 (
    CALL :function_print_info_red "Error: cannot find git.exe at path. Try installing it from: "
    CALL :function_print_info_red "https://git-scm.com/download/win. "
    CALL :function_print_info_red ""
    CALL :function_print_info_red "To test if git is installed correctly, run git --version"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "git found"
)

IF NOT DEFINED VCVARS_64 (
    set VCVARS_64="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
)

IF NOT EXIST %VCVARS_64% (
    CALL :function_print_info_red "Error: cannot find file:"
    SETLOCAL
    SET VCVARS_64_ESC=%VCVARS_64:(=^(%
    SET VCVARS_64_ESC=%VCVARS_64:)=^)%
    ECHO %VCVARS_64_ESC:"='%
    ENDLOCAL
    CALL :function_print_info_red "Please ensure Visual Studio 2017 in installed, and the above path exists."
    CALL :function_print_info_red "If Visual studio is installed but at a different path, the variable"
    CALL :function_print_info_red "VCVARS_64 can be set to the path of your installed vcvars64.bat. "
    CALL :function_print_info_red ""
    CALL :function_print_info_red "This can be done (for example), by running 'set VCVARS_64=yourpath'"
    CALL :function_print_info_red "before running this setup process. This will be reset when the terminal"
    CALL :function_print_info_red "running this setup closes."

    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "Visual studio 2017 vars file found"
)

REM get latest installed windows SDK version
set "VSCMD_START_DIR=%CD%"
CALL %VCVARS_64%
IF NOT %ERRORLEVEL%==0 (
    CALL :function_print_info_red "vcvars64.bat failed! Error code: %ERRORLEVEL%"
    GOTO:label_exit_error
)
IF "%WindowsSDKVersion%"=="" (
    CALL :function_print_info_red "Error: Windows SDK version could not be determined by vcvars64.bat."
    CALL :function_print_info_red "If it is, try restarting your console window to clear conflicting variables."
    GOTO:label_exit_error
)
CALL :function_print_info_blue "found windows sdk version is: %WindowsSDKVersion%"

REM Check that electron-rebuild exists.
SET ELECTRON_REBUILD="./node_modules/.bin/electron-rebuild"
IF NOT EXIST %ELECTRON_REBUILD% (
    CALL :function_print_info_red "ERROR: cannot find %ELECTRON_REBUILD%"
    CALL :function_print_info_red "did you run 'yarn install' before 'yarn setup'?"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "electron-rebuild found"
)


REM Check that GENie exists
SET GENIE_EXE="./node_modules/bx/tools/bin/windows/genie.exe"
IF NOT EXIST %GENIE_EXE% (
    CALL :function_print_info_red "Error: cannot find %GENIE_EXE%"
    CALL :function_print_info_red "did you run 'yarn install' before 'yarn setup'?"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "GENie found"
)

SET LIBSODIUM_BUILD_ROOT=".\node_modules\libsodium\builds\msvc\build"
IF NOT EXIST %LIBSODIUM_BUILD_ROOT% (
    CALL :function_print_info_red "Error: cannot find %LIBSODIUM_BUILD_ROOT%"
    CALL :function_print_info_red "did you run 'yarn install' before 'yarn setup'?"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "libsodium build root found"
)

SET LIBZMQ_BUILD_ROOT=".\node_modules\libzmq\builds\msvc\build\"
IF NOT EXIST %LIBZMQ_BUILD_ROOT% (
    CALL :function_print_info_red "Error: cannot find %LIBZMQ_BUILD_ROOT%"
    CALL :function_print_info_red "did you run 'yarn install' before 'yarn setup'?"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "libzmq build root found"
)

SET CZMQ_BUILD_ROOT=".\node_modules\czmq\builds\msvc"
IF NOT EXIST %CZMQ_BUILD_ROOT% (
    CALL :function_print_info_red "Error: cannot find %CZMQ_BUILD_ROOT%"
    CALL :function_print_info_red "did you run 'yarn install' before 'yarn setup'?"
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "czmq build root found"
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Package arguments into checkable flags

SETLOCAL enabledelayedexpansion

SET argCount=0
FOR %%x in (%*) do (
   SET /A argCount+=1
   SET "argVec[!argCount!]=%%~x"
)

REM recognized arguments
SET skip_decompress=FALSE
SET skip_genie=FALSE
SET skip_electron=FALSE

SET skip_zmq=FALSE
SET skip_libsodium=FALSE
SET skip_libzmq=FALSE
SET skip_czmq=TRUE

for /L %%i in (1,1,%argCount%) do (
    IF "!argVec[%%i]!"=="skip_decompress" (
        SET skip_decompress=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_electron" (
        SET skip_electron=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_zmq" (
        SET skip_zmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_libsodium" (
        SET skip_libsodium=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_libzmq" (
        SET skip_libzmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_czmq" (
        SET skip_czmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="skip_genie" (
        SET skip_genie=TRUE
    ) ELSE (
        CALL :function_print_info_red "!argVec[%%i]! argument not recognized"
    )
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Decompress any dependancies

IF %skip_decompress%==TRUE (
    ECHO [44m[37m^|- skipping decompression ^(skip_decompress argument passed^)                  [0m[0m
) ELSE (
    SETLOCAL

    REM ECHO [44m[37m^|- running decompression                                                      [0m[0m

    REM node ./Source/JS/decompress.js ./third_party/something/something.zip ./third_party/something/something
    REM node ./Source/JS/decompress.js ./third_party/other/other.tar.bz2 ./third_party/other/other

    IF NOT %ERRORLEVEL%==0 (
        ECHO Decompression failed! Error code: %ERRORLEVEL%
        GOTO:label_exit_error
    )
    ENDLOCAL
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Build CrossProcessRenderer for nodejs

IF %skip_electron%==TRUE (
    ECHO [44m[37m^|- skipping electron ^(skip_electron argument passed^)                         [0m[0m
) ELSE (
    SETLOCAL
    CALL :function_print_info_blue "running electron native plugin compilation"
    CALL :function_print_info_blue "(((this can be skipped by adding 'skip_electron' to the command line)))"

    :: a workaround for electron-rebuild, see: https://github.com/electron/electron-rebuild/issues/215
    ECHO {} > ./node_modules/bgfx/package.json
    ECHO {} > ./node_modules/bx/package.json
    ECHO {} > ./node_modules/bimg/package.json
    ECHO {} > ./node_modules/libsodium/package.json
    ECHO {} > ./node_modules/libzmq/package.json
    ECHO {} > ./node_modules/czmq/package.json

    CALL %ELECTRON_REBUILD% -f -w CrossProcessRenderer --debug

    IF NOT %ERRORLEVEL%==0 (
        ECHO electron compilation failed! Error code: %ERRORLEVEL%
        ENDLOCAL
        GOTO:label_exit_error
    )
    CD %PROJECT_ROOT%

    ENDLOCAL
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Build 0MQ and its dependancies
REM instructions from https://github.com/zeromq/czmq, 
REM except we're using yarn (see: package.json) to get dependancies from git.

IF %skip_zmq%==TRUE (
    CALL :function_print_info_blue "skipping 0mq ^(skip_zmq argument passed^)"
) ELSE (
    SETLOCAL

    IF %skip_libsodium%==TRUE (
        CALL :function_print_info_blue "skipping libsodium ^(skip_libsodium argument passed^)"
    ) ELSE (
        ECHO [44m[37m^|- running libsodium compilation                                             [0m[0m
        CD %LIBSODIUM_BUILD_ROOT%
        CALL buildbase.bat ..\vs2015\libsodium.sln 14
        IF NOT %ERRORLEVEL%==0 (
            ECHO lib sodium compilation failed! Error code: %ERRORLEVEL%
            ENDLOCAL
            GOTO:label_exit_error
        ) ELSE (
            ECHO buildbase.bat exited with code %ERRORLEVEL%
        )
        CD %PROJECT_ROOT%
    )

    IF %skip_libzmq%==TRUE (
        CALL :function_print_info_blue "skipping libzmq ^(skip_libzmq argument passed^)"
    ) ELSE (
        ECHO [44m[37m^|- running libzmq compilation                                                [0m[0m
        CD %LIBZMQ_BUILD_ROOT%
        CALL buildbase.bat ..\vs2015\libzmq.sln 14
        IF NOT %ERRORLEVEL%==0 (
            ECHO lib zmq compilation failed! Error code: %ERRORLEVEL%
            ENDLOCAL
            GOTO:label_exit_error
        ) ELSE (
            ECHO buildbase.bat exited with code %ERRORLEVEL%
        )
        CD %PROJECT_ROOT%
    )

    IF %skip_czmq%==TRUE (
        CALL :function_print_info_blue "skipping czmq ^(known to fail^)"
    ) ELSE (
        
        ECHO [44m[37m^|- czmq configuration                                                        [0m[0m
        CD %CZMQ_BUILD_ROOT%
        CALL .\configure.bat
        CD vs2015
        ECHO [44m[37m^|- czmq compilation                                                          [0m[0m
        CALL .\build.bat
        IF NOT %ERRORLEVEL%==0 (
            ECHO 0mq compilation failed! Error code: %ERRORLEVEL%
            ENDLOCAL
            GOTO:label_exit_error
        ) ELSE (
            ECHO build.bat exited with code %ERRORLEVEL%
        )
        CD %PROJECT_ROOT%
    )
    ENDLOCAL
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Run GENie

IF %skip_genie%==TRUE (
    ECHO [44m[37m^|- skipping genie ^(skip_genie argument passed^)                               [0m[0m
) ELSE (
    SETLOCAL
    ECHO [44m[37m^|- running genie prep ^(environment vars^)                                     [0m[0m

    REM run GENie
    ECHO [44m[37m^|- running genie project generation ^(urban spork^)                            [0m[0m
    "./node_modules/bx/tools/bin/windows/genie.exe" vs2017

    IF NOT %ERRORLEVEL%==0 (
        ECHO urban-spork project generation failed! Error code: %ERRORLEVEL%
        ENDLOCAL
        GOTO:label_exit_error
    )

    ECHO [44m[37m^|- running genie project generation ^(bgfx^)                                   [0m[0m
    CD node_modules/bgfx/
    "../bx/tools/bin/windows/genie.exe" --with-examples vs2017

    IF NOT %ERRORLEVEL%==0 (
        ECHO bgfx project generation failed! Error code: %ERRORLEVEL%
        ENDLOCAL
        GOTO:label_exit_error
    )

    CD %PROJECT_ROOT%
    ENDLOCAL
)

GOTO:label_exit_success

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Exit messages

:label_exit_success
ECHO [42m[30m^|============================================================================[0m[0m
ECHO [42m[30m^|- SETUP COMPLETE ^(see above for any errors^)                                 [0m[0m
ECHO [42m[30m^|============================================================================[0m[0m
GOTO:label_exit


:label_exit_error
ECHO [41m[37m^|============================================================================[0m[0m
ECHO [41m[37m^|- SETUP EXITED EARLY ^(see above for any errors^)                             [0m[0m
ECHO [41m[37m^|============================================================================[0m[0m
GOTO:label_exit

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Functions
REM Quick color reference: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd
:function_print_info_green
SETLOCAL
SET "spaces=                                                                           "
SET param_text=%~1
SET "to_print=%param_text%%spaces%"
SET "to_print=^|- %to_print:~0,74%"
ECHO [42m[30m%to_print%[0m[0m
ENDLOCAL
EXIT /B 0

:function_print_info_blue
SETLOCAL
SET "spaces=                                                                           "
SET param_text=%~1
SET "to_print=%param_text%%spaces%"
SET "to_print=^|- %to_print:~0,74%"
ECHO [44m[37m%to_print%[0m[0m
ENDLOCAL
EXIT /B 0

:function_print_info_red
SETLOCAL
SET "spaces=                                                                           "
SET param_text=%~1
SET "to_print=%param_text%%spaces%"
SET "to_print=^|- %to_print:~0,74%"
ECHO [41m[37m%to_print%[0m[0m
ENDLOCAL
EXIT /B 0

:function_print_bar_success
SETLOCAL
ECHO [42m[30m^|============================================================================[0m[0m
ENDLOCAL
EXIT /B 0

:function_print_bar_error
SETLOCAL
ECHO [41m[37m^|============================================================================[0m[0m
ENDLOCAL
EXIT /B 0

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Cleanup

:label_exit
REM return to the callers directory
cd %OD%