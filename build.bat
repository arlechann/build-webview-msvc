set script_dir=%~dp0

if exist "%script_dir%\webview.dll" exit /b 0

set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" set "vswhere=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" (
    echo ERROR: Failed to find vswhere.exe >&2
    exit /b 1
)

for /f "usebackq tokens=*" %%i in (`"%vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set vc_dir=%%i
)

set "vsdevcmd=%vc_dir%\Common7\Tools\vsdevcmd.bat"
if not exist "%vsdevcmd%" (
    echo Error: Failed to find MSVC. >&2
    exit /b 1
)

if not exist "%script_dir%\lib\webview2" (
   mkdir "%script_dir%\lib\webview2"
   curl -sSL "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2" | tar -xf - -C "%script_dir%\lib\webview2"
)

if not exist "%script_dir%\lib\build" mkdir "%script_dir%\lib\build"

call "%vsdevcmd%" -arch=x64 -host_arch=x64 || exit /b 1

cl /W4 /utf-8 /D "WEBVIEW_API=__declspec(dllexport)" /I "%script_dir%\lib\webview2\build\native\include" "%script_dir%\lib\webview2\build\native\x64\WebView2Loader.dll.lib" /std:c++17 /EHsc "/Fo%script_dir%\lib\build"\ "%script_dir%\webview\webview.cc" /link /DLL "/OUT:%script_dir%\webview.dll" || exit /b 1
