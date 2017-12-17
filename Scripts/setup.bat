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

where /q yarn
IF NOT %ERRORLEVEL%==0 (
    CALL :function_print_info_red "Error: cannot find yarn at path. See the readme file for project setup"
    CALL :function_print_info_red "instructions. Once yarn is installed, run 'yarn setup' insetad of"
    CALL :function_print_info_red "calling setup.bat directly."
    GOTO:label_exit_error
) ELSE (
    CALL :function_print_info_blue "yarn found"
)

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

SET WINDOWS_FIND=C:\Windows\System32\find.exe
IF NOT EXIST %WINDOWS_FIND% (
    REM other terminals such as cmder will use the unix find command by default.
    REM because of this we expect to find find.exe at a specific path.
    REM hopefully that works in most cases, or is obvious why it failed.
    CALL :function_print_info_red "Error: cannot find %WINDOWS_FIND%"
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Check for automation in .git
SETLOCAL

SET git_relative_ongitpull=Scripts/onGitPull.bat
SET git_postMergeHook=.git/hooks/post-merge

IF NOT EXIST %git_postMergeHook% (
    CALL :function_print_info_red "Error: cannot find %git_postMergeHook%"
    CALL :function_print_info_red "Are you running from a valid repo? the .git folder should be available."
    GOTO:label_exit_error
)

%WINDOWS_FIND% /c "%git_relative_ongitpull%" "%git_postMergeHook%"

IF NOT %ERRORLEVEL%==0 (
    CALL :function_prompt_githooks
) ELSE (
    CALL :function_print_info_green "found postMergeHook"
)


ENDLOCAL

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
    ) ELSE IF "!argVec[%%i]!"=="only_decompress" (
        CALL :function_skipall
        SET skip_decompres=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_electron" (
        SET skip_electron=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_electron" (
        CALL :function_skipall
        SET skip_electron=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_zmq" (
        SET skip_zmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_zmq" (
        CALL :function_skipall
        SET skip_zmq=FALSE
        SET skip_libsodium=FALSE
        SET skip_libzmq=FALSE
        SET skip_czmq=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_libsodium" (
        SET skip_libsodium=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_libsodium" (
        CALL :function_skipall
        SET skip_zmq=FALSE
        SET skip_libsodium=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_libzmq" (
        SET skip_libzmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_libzmq" (
        CALL :function_skipall
        SET skip_zmq=FALSE
        SET skip_libzmq=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_czmq" (
        SET skip_czmq=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_czmq" (
        CALL :function_skipall
        SET skip_zmq=FALSE
        SET skip_czmq=FALSE
    ) ELSE IF "!argVec[%%i]!"=="skip_genie" (
        SET skip_genie=TRUE
    ) ELSE IF "!argVec[%%i]!"=="only_genie" (
        CALL :function_skipall
        SET skip_genie=FALSE
    ) ELSE (
        CALL :function_print_info_red "!argVec[%%i]! argument not recognized"
    )
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Decompress any dependancies

IF %skip_decompress%==TRUE (
    CALL :function_print_info_blue "skipping decompression (skip_decompres used)"
) ELSE (
    SETLOCAL

    REM CALL :function_print_info_blue "running decompression"
    REM CALL :function_print_tip "add 'skip_decompress' to the command line to skip"
    REM CALL :function_print_tip "add 'only_decompress' to the command line to skip all others"

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
    CALL :function_print_info_blue "skipping electron (skip_electron used)"
) ELSE (
    SETLOCAL
    CALL :function_print_info_blue "running electron native plugin compilation"
    CALL :function_print_tip "add 'skip_electron' to the command line to skip"
    CALL :function_print_tip "add 'only_electron' to the command line to skip others"

    :: a workaround for electron-rebuild, see: https://github.com/electron/electron-rebuild/issues/215
    ECHO {} > ./node_modules/bgfx/package.json
    ECHO {} > ./node_modules/bx/package.json
    ECHO {} > ./node_modules/bimg/package.json
    ECHO {} > ./node_modules/libsodium/package.json
    ECHO {} > ./node_modules/libzmq/package.json
    ECHO {} > ./node_modules/czmq/package.json

    CALL %ELECTRON_REBUILD% -f -w CrossProcessRenderer --debug

    IF NOT %ERRORLEVEL%==0 (
        ECHO %ELECTRON_REBUILD% returned %ERRORLEVEL%
        CALL :function_print_info_red "electron compilation failed"
        ENDLOCAL
        GOTO:label_exit_error
    )
    CD %PROJECT_ROOT%

    ENDLOCAL
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Build 0MQ and its dependancies
REM basic instructions from https://github.com/zeromq/czmq, 
REM except we're using yarn (see: package.json) to get dependancies from git.

IF %skip_zmq%==TRUE (
    CALL :function_print_info_blue "skipping 0mq (skip_zmq used)"
) ELSE (
    SETLOCAL

    IF %skip_libsodium%==TRUE (
        CALL :function_print_info_blue "skipping libsodium (skip_libsodium used)"
    ) ELSE (
        CALL :function_print_info_blue "running libsodium compilation"
        CALL :function_print_tip "add 'skip_zmq' or 'skip_libsodium' to the command line to skip"
        CALL :function_print_tip "add 'only_zmq' or 'only_libsodium' to the command line to skip others"
        CD %LIBSODIUM_BUILD_ROOT%
        CALL buildbase.bat ..\vs2015\libsodium.sln 14
        ECHO buildbase.bat exited with code %ERRORLEVEL%
        IF NOT %ERRORLEVEL%==0 (
            CALL :function_print_info_red "libsodium compilation failed"
            ENDLOCAL
            GOTO:label_exit_error
        )
        CD %PROJECT_ROOT%
    )

    IF %skip_libzmq%==TRUE (
        CALL :function_print_info_blue "skipping libzmq (skip_libzmq used)"
    ) ELSE (
        CALL :function_print_info_blue "running libzmq compilation"
        CALL :function_print_tip "add 'skip_zmq' or 'skip_libzmq' to the command line to skip"
        CALL :function_print_tip "add 'only_zmq' or 'only_libzmq' to the command line to skip others"
        CD %LIBZMQ_BUILD_ROOT%
        CALL buildbase.bat ..\vs2015\libzmq.sln 14
        ECHO buildbase.bat exited with code %ERRORLEVEL%
        IF NOT %ERRORLEVEL%==0 (
            CALL :function_print_info_red "libzmq compilation failed"
            ENDLOCAL
            GOTO:label_exit_error
        )
        CD %PROJECT_ROOT%
    )

    IF %skip_czmq%==TRUE (
        CALL :function_print_info_blue "skipping czmq (known to fail)"
    ) ELSE (
        CALL :function_print_info_blue "czmq configuration"
        CALL :function_print_tip "add 'skip_zmq' or 'skip_czmq' to the command line to skip"
        CALL :function_print_tip "add 'only_zmq' or 'only_czmq' to the command line to skip others"
        CD %CZMQ_BUILD_ROOT%
        CALL .\configure.bat
        CD vs2015
        CALL :function_print_info_blue "czmq compilation"
        CALL .\build.bat
        ECHO build.bat exited with code %ERRORLEVEL%
        IF NOT %ERRORLEVEL%==0 (
            CALL :function_print_info_red "czmq compilation failed"
            ENDLOCAL
            GOTO:label_exit_error
        )
        CD %PROJECT_ROOT%
    )
    ENDLOCAL
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Run GENie

IF %skip_genie%==TRUE (
    CALL :function_print_info_blue "skipping GENie (skip_genie used)"
) ELSE (
    SETLOCAL
    CALL :function_print_info_blue "running GENie project generation (urban spork)"
    CALL :function_print_tip "add 'skip_genie' to the command line to skip"
    CALL :function_print_tip "add 'only_genie' to the command line to skip others"

    "./node_modules/bx/tools/bin/windows/genie.exe" vs2017

    ECHO genie.exe returned %ERRORLEVEL%
    IF NOT %ERRORLEVEL%==0 (
        CALL :function_print_info_red "urban spork project generation failed"
        ENDLOCAL
        GOTO:label_exit_error
    )

    CALL :function_print_info_blue "running GENie project generation (bgfx)"
    CALL :function_print_tip "add 'skip_genie' to the command line to skip"
    CALL :function_print_tip "add 'only_genie' to the command line to skip others"

    CD node_modules/bgfx/
    "../bx/tools/bin/windows/genie.exe" --with-examples vs2017

    ECHO genie.exe returned %ERRORLEVEL%
    IF NOT %ERRORLEVEL%==0 (
        CALL :function_print_info_red "urban spork project generation failed"
        ENDLOCAL
        GOTO:label_exit_error
    )

    CD %PROJECT_ROOT%
    ENDLOCAL
)

GOTO:label_exit_success

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Exit messages

:label_exit_success
CALL :function_print_bar_success
CALL :function_print_info_green "SETUP COMPLETE (see above for any errors)"
CALL :function_print_bar_success
GOTO:label_exit


:label_exit_error
CALL :function_print_bar_error
CALL :function_print_info_red "SETUP EXITED EARLY (see above for any errors)"
CALL :function_print_bar_error
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

:function_print_tip
SETLOCAL
SET "spaces=                                                                           "
SET param_text=%~1
SET "to_print=%param_text%%spaces%"
SET "to_print=^|- tip: %to_print:~0,69%"
ECHO [43m[35m%to_print%[0m[0m
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

:function_skipall
SET skip_decompress=TRUE
SET skip_genie=TRUE
SET skip_electron=TRUE
SET skip_zmq=TRUE
SET skip_libsodium=TRUE
SET skip_libzmq=TRUE
SET skip_czmq=TRUE
EXIT /B 0

:function_prompt_githooks_yes
SETLOCAL
CALL:function_print_info_blue "adding git hooks"
ECHO  
ECHO %git_relative_ongitpull% >> %git_postMergeHook%
ENDLOCAL
EXIT /B 0

:function_prompt_githooks_never
SETLOCAL
CALL:function_print_info_blue "adding git hooks"
ECHO  
ECHO # %git_relative_ongitpull% >> %git_postMergeHook%
ENDLOCAL
EXIT /B 0

:function_prompt_githooks_ask
SETLOCAL
SET /p "git_response=yes/no/never (yes): "

IF "%git_response%"=="yes" (
    CALL :function_prompt_githooks_yes
) ELSE IF "%git_response%"=="" (
    CALL :function_prompt_githooks_yes
) ELSE IF "%git_response%"=="no" (
    CALL :function_print_info_blue "no selected"
) ELSE IF "%git_response%"=="never" (
    CALL :function_print_info_blue "never selected"
    CALL :function_prompt_githooks_never
) ELSE (
    SET git_response=
    CALL :function_prompt_githooks_ask
)
ENDLOCAL
EXIT /B 0

:function_prompt_githooks
SETLOCAL
CALL :function_print_info_red "action needed, see below:"
ECHO It's reccomended that we automatically add a script that runs whenever you
ECHO pull in git. this script was not not found in file:
ECHO    %git_postMergeHook%
ECHO
ECHO Would you like to add this script to the git hook, so it's automatically run?

CALL :function_prompt_githooks_ask
ENDLOCAL
EXIT /B 0


REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: Cleanup

:label_exit
REM return to the callers directory
cd %OD%
EXIT %ERRORLEVEL%