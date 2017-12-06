:: note for the future:
:: If you ever get around to making the build process bullet proof, it's good to note that automate-git.py seems to reserve 5GB of space on disk for the download.

:: todo: fix and remove
echo "this was never setup correctly. You should probably abort. (ctrl+c)"
pause

set origin_directory=%cd%
set build_cef_directory=%~dp0
cd %build_cef_directory%

cd ../node_modules/cef/tools/automate/

:: See: https://bitbucket.org/chromiumembedded/cef/wiki/AutomatedBuildSetup#markdown-header-windows-configuration
set CEF_USE_GN=1
set GN_DEFINES=is_official_build=true
set GYP_DEFINES=buildtype=Official
set GYP_MSVS_VERSION=2015
set CEF_ARCHIVE_FORMAT=tar.bz2
:: note, I had to exclude --branch=%cef_branch%, master didn't seem to work for cef_branch.
python ./automate-git.py --download-dir=D:/Projects/Github/urban-spork/temp/ --minimal-distrib --client-distrib --force-clean

goto complete

errors:
pause

complete:
cd %origin_directory%