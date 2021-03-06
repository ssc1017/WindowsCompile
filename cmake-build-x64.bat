@echo off

SETLOCAL ENABLEEXTENSIONS

set FULL_REBUILD=0
set BUILD_LUXCORE_ONLY=0
set BUILD_LUXMARK_ONLY=0
set LUXCORE_MINIMAL=0
set CMAKE_ONLY=0
set MSBUILD_PLATFORM=x64
set DISABLE_OPENCL=0
set CPU_PLATFORM=x64
set BUILD_TYPE=Release
set BUILD_DLL=0
set PYTHON_VERSION=37
set CPUCOUNT=/maxcpucount
set PRINT_USAGE=0

:ParseCmdParams
if "%1" EQU "" goto Start
if /i "%1" EQU "/?" set PRINT_USAGE=1
if /i "%1" EQU "luxcore" set BUILD_LUXCORE_ONLY=1
if /i "%1" EQU "luxmark" set BUILD_LUXMARK_ONLY=1
if /i "%1" EQU "/rebuild" set FULL_REBUILD=1
if /i "%1" EQU "/minimal" set LUXCORE_MINIMAL=1
if /i "%1" EQU "/cmake-only" set CMAKE_ONLY=1
if /i "%1" EQU "/no-ocl" set DISABLE_OPENCL=1
if /i "%1" EQU "/dll" set BUILD_DLL=1
if /i "%1" EQU "/debug" set BUILD_TYPE=Debug
if /i "%1" EQU "/python27" set PYTHON_VERSION=27
if /i "%1" EQU "/python35" set PYTHON_VERSION=35
if /i "%1" EQU "/python36" set PYTHON_VERSION=36
if /i "%1" EQU "/python37" set PYTHON_VERSION=37
if /i "%1" EQU "/python38" set PYTHON_VERSION=38
:: /cpucount[:n] specifies the number of concurrent processes used by msbuild
:: Default is to use all the available processors
set cpupar=%1
if /i "%cpupar:~0,9%" EQU "/cpucount" (
    set "CPUCOUNT=/maxcpucount%cpupar:~9%"
)

shift 
goto ParseCmdParams

:Start

if %PRINT_USAGE%==1 (
  echo Starts LuxCore build process
  echo:
  echo USAGE: cmake-build-x64.bat [options] [target]
  echo:
  echo Options:
  echo:  /?             Prints this help message and exits
  echo   /no-ocl        Disables OpenCL support in LuxCore
  echo   /dll           Builds LuxCore SDK version
  echo   /python^<xy^>    Builds pyluxcore.pyd module for Python version x.y
  echo                  Available versions: 27, 35, 36, 37, 38
  echo   /minimal       Builds only pyluxcore, pyluxcoretools and luxcoreui
  echo   /rebuild       Rebuilds everything from scratch
  echo   /cmake-only    Runs CMake to set up Visual Studio project files,
  echo                  but does not run MSBuild
  echo   /debug         Builds a debug version
  echo:
  echo Target:
  echo   Default behaviour is to build all the available targets, i.e. also LuxMark
  echo   is built if source is available.
  echo   To build a single target only, just specify it:
  echo   luxcore        Builds LuxCore only
  echo   luxmark        Builds LuxMark only (LuxCore must have been built already^)
  echo:
  echo Additional information about LuxCore build process is available at:
  echo   https://github.com/LuxCoreRender/WindowsCompile
  goto exit
)

if %FULL_REBUILD%==1 (
  echo =========================================
  echo ============  FULL REBUILD  =============
  echo =========================================
)

for %%a in (.) do set LUX_WINDOWS_BUILD_ROOT=%%~fa
for %%a in (support\bin) do set SUPPORT_BIN=%%~fa
for %%a in (..\LuxCore) do set LUXCORE_ROOT=%%~fa
for %%a in (..\LuxMark) do set LUXMARK_ROOT=%%~fa
for %%a in (..\WindowsCompileDeps) do set DEPS_DIR=%%~fa

echo Finding if CMake is installed...
for /f "tokens=*" %%a in ('where cmake') do SET CMAKE=%%~fa  

if exist "%CMAKE%" (
  echo CMake found at "%CMAKE%"
) else (
  goto CMakeNotFound
)

if not exist "%LUXCORE_ROOT%" goto LuxCoreNotFound

set WINDOWS_DEPS_RELEASE=LuxCoreRender_v2.3alpha0
if not exist "%DEPS_DIR%" (
    %SUPPORT_BIN%\wget https://github.com/LuxCoreRender/WindowsCompileDeps/releases/download/%WINDOWS_DEPS_RELEASE%/WindowsCompileDeps.7z
    %SUPPORT_BIN%\7z x -o%DEPS_DIR% WindowsCompileDeps.7z
)

:: Determine if we have CMake 2 or 3
for /F "tokens=3" %%G in ('cmd /c "%CMAKE%" --version ^| findstr /I /C:"cmake version"') do set CMAKE_VER=%%G
for /F "tokens=1 delims=." %%G in ("%CMAKE_VER%") do set CMAKE_VN_MAJOR=%%G
echo We are using CMake version: %CMAKE_VN_MAJOR%
:: Default values
set CMAKE_GENERATOR="Visual Studio 15 2017"
set CMAKE_TOOLSET=-T v141,host=x64
if "%CPU_PLATFORM%"=="x64" (
  set CMAKE_PLATFORM=-A %CPU_PLATFORM%
) else (
  set CMAKE_PLATFORM=
  set CMAKE_TOOLSET=
)

if %CMAKE_VN_MAJOR%==2 (
  echo You need CMake 3.11 or better to build LuxCoreRender
  goto CMakeNotFound
)

for %%a in (..\WindowsCompileDeps\include) do set INCLUDE_DIR=%%~fa
for %%a in (..\WindowsCompileDeps\%CPU_PLATFORM%\Release\lib) do set LIB_DIR=%%~fa
echo LIB_DIR: %LIB_DIR%

if %DISABLE_OPENCL% EQU 1 (
  echo -----------------------------------------
  echo Disabling OpenCL
  echo -----------------------------------------

  set OCL_OPTION=-DLUXRAYS_DISABLE_OPENCL=1
) else (
  if "%CPU_PLATFORM%"=="x86" (
    set OCL_OPTION=-DOPENCL_X86=1
  ) else (
    set OCL_OPTION=
  )
)

if %BUILD_DLL% EQU 1 (
  echo -----------------------------------------
  echo Enable LuxCore DLL
  echo -----------------------------------------

  set DLL_OPTION=-DBUILD_LUXCORE_DLL=1
) else (
  set DLL_OPTION=
)

set CMAKE_OPTS=-G %CMAKE_GENERATOR% %CMAKE_PLATFORM% %CMAKE_TOOLSET% -D CMAKE_INCLUDE_PATH="%INCLUDE_DIR%" -D CMAKE_LIBRARY_PATH="%LIB_DIR%" -D PYTHON_LIBRARY="%LIB_DIR%" -D PYTHON_V="%PYTHON_VERSION%" -D PYTHON_INCLUDE_DIR="%INCLUDE_DIR%\Python%PYTHON_VERSION%" -D CMAKE_BUILD_TYPE=%BUILD_TYPE% %OCL_OPTION% %DLL_OPTION%
rem To display only errors add: /clp:ErrorsOnly
set MSBUILD_OPTS=/nologo %CPUCOUNT% /verbosity:normal /toolsversion:15.0 /property:"Platform=%MSBUILD_PLATFORM%" /property:"Configuration=%BUILD_TYPE%" /p:WarningLevel=0

if %FULL_REBUILD%==1 rd /q /s Build_CMake
mkdir Build_CMake
cd Build_CMake

set LUXCORE_BUILD_ROOT=%CD%\LuxCore
set LUXMARK_BUILD_ROOT=%CD%\LuxMark

set CMAKE_CACHE=CMakeCache.txt

if %BUILD_LUXMARK_ONLY%==1 goto BuildLuxMark

:BuildLuxCore
mkdir %LUXCORE_BUILD_ROOT%
cd /d %LUXCORE_BUILD_ROOT%

if exist %CMAKE_CACHE% del %CMAKE_CACHE%
"%CMAKE%" %CMAKE_OPTS% -D LUXRAYS_CUSTOM_CONFIG=cmake\SpecializedConfig\Config_Windows.cmake %LUXCORE_ROOT%
if ERRORLEVEL 1 goto CMakeError

if %CMAKE_ONLY%==0 (
  if %LUXCORE_MINIMAL%==1 (
    msbuild %MSBUILD_OPTS% /target:pyluxcore,pyluxcoretools,luxcoreui LuxRays.sln
  ) else (
    msbuild %MSBUILD_OPTS% LuxRays.sln
  )
  if ERRORLEVEL 1 goto CMakeError
)

cd ..

if %BUILD_LUXCORE_ONLY%==1 goto exit

:BuildLuxMark
If Not Exist %LUXMARK_ROOT% (goto exit)

set CMAKE_OPTS=%CMAKE_OPTS% -D LuxRays_HOME=%LUXCORE_BUILD_ROOT% -D LUXRAYS_INCLUDE_DIRS=%LUXCORE_ROOT%\include -D LUXCORE_INCLUDE_DIRS=%LUXCORE_ROOT%\include

mkdir %LUXMARK_BUILD_ROOT%
cd /d %LUXMARK_BUILD_ROOT%

set CMAKE_PREFIX_PATH=..\..\..\WindowsCompileDeps\Qt5\
if exist %CMAKE_CACHE% del %CMAKE_CACHE%
"%CMAKE%" %CMAKE_OPTS% -D LUXMARK_CUSTOM_CONFIG=cmake\SpecializedConfig\Config_Windows.cmake %LUXMARK_ROOT%
if ERRORLEVEL 1 goto CMakeError

if %CMAKE_ONLY%==0 (
  msbuild %MSBUILD_OPTS% LuxMark.sln
  if ERRORLEVEL 1 goto CMakeError
)

cd ..

goto exit

:CMakeNotFound
echo --- FATAL ERROR: CMake not found ---
echo.
goto exit

:LuxCoreNotFound
goto GeneralNotFound

:GeneralNotFound
echo Please make sure you've cloned the repositories
echo so that they have the following structure:
echo   root_dir\LuxCore
echo   root_dir\LuxMark (optional)
echo   root_dir\WindowsCompile
echo   root_dir\WindowsCompileDeps
goto exit

:CMakeError
echo --- FATAL ERROR RUNNING CMAKE ---
exit /B 1
goto exit

:exit
goto :EOF
