Echo off

set BOOST_VER_U=1_43_0
set BOOST_VER_P=1.43.0

set PYTHON2_VER=2.6.6
set PYTHON3_VER=3.1.2

set ZLIB_VER_P=1.2.3
set ZLIB_VER_N=123

set FREEIMAGE_VER_P=3.14.1
set FREEIMAGE_VER_N=3141

set QT_VER=4.6.2

set GLEW_VER=1.5.5

:: NVIDIA CUDA Toolkits
:: http://developer.download.nvidia.com/compute/cuda/3_1/toolkit/cudatoolkit_3.1_win_32.exe
:: http://developer.download.nvidia.com/compute/cuda/3_1/toolkit/cudatoolkit_3.1_win_64.exe
:: Cannot be extracted with 7z and don't work OOTB with luxrays src
:: Older NV kits
:: http://developer.download.nvidia.com/compute/cuda/2_3/opencl/sdk/gpucomputingsdk_2.3a_win_32.exe
:: http://developer.download.nvidia.com/compute/cuda/2_3/opencl/sdk/gpucomputingsdk_2.3a_win_64.exe

:: AMD/ATI STREAM SDKs
:: Need to detect or ask about vista/win7 or XP variant
:: http://developer.amd.com/Downloads/ati-stream-sdk-v2.2-vista-win7-32.exe
:: http://developer.amd.com/Downloads/ati-stream-sdk-v2.2-vista-win7-64.exe
:: http://developer.amd.com/Downloads/ati-stream-sdk-v2.2-xp32.exe
:: http://developer.amd.com/Downloads/ati-stream-sdk-v2.2-xp64.exe
:: Can be extracted with 7z - provides ati-stream-sdk-v2.2-vista-win7-32\Packages\Apps\ATIStreamSDK_Dev.msi
:: .msi can be extracted with 7z - but provides junk/obfuscated files :(


echo.
echo **************************************************************************
echo * Startup                                                                *
echo **************************************************************************
echo.
echo We are going to download and extract sources for:
echo   Boost %BOOST_VER_P%                             http://www.boost.org/
echo   QT %QT_VER%                                 http://qt.nokia.com/
echo   zlib %ZLIB_VER_P%                               http://www.zlib.net/
echo   bzip 1.0.5                               http://www.bzip.org/
echo   FreeImage %FREEIMAGE_VER_P%                         http://freeimage.sf.net/
echo   sqlite 3.5.9                             http://www.sqlite.org/
echo   Python %PYTHON2_VER% ^& Python %PYTHON3_VER%              http://www.python.org/
echo   GLEW %GLEW_VER%                               http://glew.sourceforge.net/
echo.
echo Downloading and extracting all this source code will require over 1GB, and
echo building it will require several gigs more. Make sure you have plenty of space
echo available on this drive, at least 15GB.
echo.
echo This script will use 2 pre-built binaries to download and extract source
echo code from the internet:
echo  1: GNU wget.exe       from http://gnuwin32.sourceforge.net/packages/wget.htm
echo  2: 7za.exe (7-zip)    from http://7-zip.org/download.html
echo.
echo If you do not wish to execute these binaries for any reason, PRESS CTRL-C NOW
echo Otherwise,
pause


echo.
echo **************************************************************************
echo * Checking environment                                                   *
echo **************************************************************************
set WGET="%CD%\support\bin\wget.exe"
%WGET% --version 1> nul 2>&1
if ERRORLEVEL 9009 (
    echo.
    echo Cannot execute wget. Aborting.
    exit /b -1
)
set UNZIPBIN="%CD%\support\bin\7za.exe"
%UNZIPBIN% > nul
if ERRORLEVEL 9009 (
    echo.
    echo Cannot execute unzip. Aborting.
    exit /b -1
)


set DOWNLOADS="%CD%\..\downloads"
:: resolve relative path
FOR %%G in (%DOWNLOADS%) do (
    set DOWNLOADS="%%~fG"
)

set D32="%CD%\..\deps\x86"
FOR %%G in (%D32%) do (
    set D32="%%~fG"
)
set D32R=%D32:"=%

set D64="%CD%\..\deps\x64"
FOR %%G in (%D64%) do (
    set D64="%%~fG"
)
set D64R=%D64:"=%

mkdir %DOWNLOADS% 2> nul
mkdir %D32% 2> nul
mkdir %D64% 2> nul

echo %DOWNLOADS%
echo %D32%
echo %D64%
echo OK

echo @Echo off > build-vars.bat
echo set LUX_WINDOWS_BUILD_ROOT="%CD%" >> build-vars.bat

echo Windows Registry Editor Version 5.00 > build-vars.reg
echo. >> build-vars.reg
echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment]>> build-vars.reg
echo "LUX_WINDOWS_BUILD_ROOT"="%CD:\=\\%" >> build-vars.reg


:boost
IF NOT EXIST %DOWNLOADS%\boost_%BOOST_VER_U%.zip (
    echo.
    echo **************************************************************************
    echo * Downloading Boost                                                      *
    echo **************************************************************************
    %WGET% http://sourceforge.net/projects/boost/files/boost/%BOOST_VER_P%/boost_%BOOST_VER_U%.zip/download -O %DOWNLOADS%\boost_%BOOST_VER_U%.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting Boost                                                       *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\boost_%BOOST_VER_U%.zip -o%D32% > nul
%UNZIPBIN% x -y %DOWNLOADS%\boost_%BOOST_VER_U%.zip -o%D64% > nul

echo set LUX_X86_BOOST_ROOT=%D32%\boost_%BOOST_VER_U%>> build-vars.bat
echo set LUX_X64_BOOST_ROOT=%D64%\boost_%BOOST_VER_U%>> build-vars.bat

echo "LUX_X86_BOOST_ROOT"="%D32R:\=\\%\\boost_%BOOST_VER_U%">> build-vars.reg
echo "LUX_X64_BOOST_ROOT"="%D64R:\=\\%\\boost_%BOOST_VER_U%">> build-vars.reg


:qt
IF NOT EXIST %DOWNLOADS%\qt-everywhere-opensource-src-%QT_VER%.zip (
    echo.
    echo **************************************************************************
    echo * Downloading QT                                                         *
    echo **************************************************************************
    %WGET% http://get.qt.nokia.com/qt/source/qt-everywhere-opensource-src-%QT_VER%.zip -O %DOWNLOADS%\qt-everywhere-opensource-src-%QT_VER%.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting QT                                                          *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\qt-everywhere-opensource-src-%QT_VER%.zip -o%D32% > nul
%UNZIPBIN% x -y %DOWNLOADS%\qt-everywhere-opensource-src-%QT_VER%.zip -o%D64% > nul

echo set LUX_X86_QT_ROOT=%D32%\qt-everywhere-opensource-src-%QT_VER%>> build-vars.bat
echo set LUX_X64_QT_ROOT=%D64%\qt-everywhere-opensource-src-%QT_VER%>> build-vars.bat

echo "LUX_X86_QT_ROOT"="%D32R:\=\\%\\qt-everywhere-opensource-src-%QT_VER%">> build-vars.reg
echo "LUX_X64_QT_ROOT"="%D64R:\=\\%\\qt-everywhere-opensource-src-%QT_VER%">> build-vars.reg


:zlib
IF NOT EXIST %DOWNLOADS%\zlib%ZLIB_VER_N%.zip (
    echo.
    echo **************************************************************************
    echo * Downloading zlib                                                       *
    echo **************************************************************************
    %WGET% http://sourceforge.net/projects/libpng/files/zlib/%ZLIB_VER_P%/zlib%ZLIB_VER_N%.zip/download -O %DOWNLOADS%\zlib%ZLIB_VER_N%.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting zlib                                                        *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\zlib%ZLIB_VER_N%.zip -o%D32%\zlib-%ZLIB_VER_P% > nul
%UNZIPBIN% x -y %DOWNLOADS%\zlib%ZLIB_VER_N%.zip -o%D64%\zlib-%ZLIB_VER_P% > nul

echo set LUX_X86_ZLIB_ROOT=%D32%\zlib-%ZLIB_VER_P%>> build-vars.bat
echo set LUX_X64_ZLIB_ROOT=%D64%\zlib-%ZLIB_VER_P%>> build-vars.bat


:bzip
IF NOT EXIST %DOWNLOADS%\bzip2-1.0.5.tar.gz (
    echo.
    echo **************************************************************************
    echo * Downloading bzip                                                       *
    echo **************************************************************************
    %WGET% http://www.bzip.org/1.0.5/bzip2-1.0.5.tar.gz -O %DOWNLOADS%\bzip2-1.0.5.tar.gz
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting bzip                                                        *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\bzip2-1.0.5.tar.gz > nul
%UNZIPBIN% x -y bzip2-1.0.5.tar -o%D32% > nul
%UNZIPBIN% x -y bzip2-1.0.5.tar -o%D64% > nul
del bzip2-1.0.5.tar

echo set LUX_X86_BZIP_ROOT=%D32%\bzip2-1.0.5>> build-vars.bat
echo set LUX_X64_BZIP_ROOT=%D64%\bzip2-1.0.5>> build-vars.bat


:freeimage
IF NOT EXIST %DOWNLOADS%\FreeImage%FREEIMAGE_VER_N%.zip (
    echo.
    echo **************************************************************************
    echo * Downloading FreeImage                                                  *
    echo **************************************************************************
    %WGET% http://downloads.sourceforge.net/freeimage/FreeImage%FREEIMAGE_VER_N%.zip -O %DOWNLOADS%\FreeImage%FREEIMAGE_VER_N%.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting FreeImage                                                   *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\FreeImage%FREEIMAGE_VER_N%.zip -o%D32%\FreeImage%FREEIMAGE_VER_N% > nul
%UNZIPBIN% x -y %DOWNLOADS%\FreeImage%FREEIMAGE_VER_N%.zip -o%D64%\FreeImage%FREEIMAGE_VER_N% > nul

echo set LUX_X86_FREEIMAGE_ROOT=%D32%\FreeImage%FREEIMAGE_VER_N%>> build-vars.bat
echo set LUX_X64_FREEIMAGE_ROOT=%D64%\FreeImage%FREEIMAGE_VER_N%>> build-vars.bat


echo "LUX_X86_FREEIMAGE_ROOT"="%D32R:\=\\%\\FreeImage%FREEIMAGE_VER_N%">> build-vars.reg
echo "LUX_X64_FREEIMAGE_ROOT"="%D64R:\=\\%\\FreeImage%FREEIMAGE_VER_N%">> build-vars.reg


:sqlite
IF NOT EXIST %DOWNLOADS%\sqlite-amalgamation-3_5_9.zip (
    echo.
    echo **************************************************************************
    echo * Downloading sqlite                                                     *
    echo **************************************************************************
    %WGET% http://www.sqlite.org/sqlite-amalgamation-3_5_9.zip -O %DOWNLOADS%\sqlite-amalgamation-3_5_9.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting sqlite                                                      *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\sqlite-amalgamation-3_5_9.zip -o%D32%\sqlite-3.5.9 > nul
%UNZIPBIN% x -y %DOWNLOADS%\sqlite-amalgamation-3_5_9.zip -o%D64%\sqlite-3.5.9 > nul

echo set LUX_X86_SQLITE_ROOT=%D32%\sqlite-3.5.9>> build-vars.bat
echo set LUX_X64_SQLITE_ROOT=%D64%\sqlite-3.5.9>> build-vars.bat


:python2
IF NOT EXIST %DOWNLOADS%\Python-%PYTHON2_VER%.tgz (
    echo.
    echo **************************************************************************
    echo * Downloading Python 2                                                   *
    echo **************************************************************************
    %WGET% http://python.org/ftp/python/%PYTHON2_VER%/Python-%PYTHON2_VER%.tgz -O %DOWNLOADS%\Python-%PYTHON2_VER%.tgz
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting Python 2                                                    *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\Python-%PYTHON2_VER%.tgz > nul
%UNZIPBIN% x -y Python-%PYTHON2_VER%.tar -o%D32% > nul
%UNZIPBIN% x -y Python-%PYTHON2_VER%.tar -o%D64% > nul
del Python-%PYTHON2_VER%.tar

echo set LUX_X86_PYTHON2_ROOT=%D32%\Python-%PYTHON2_VER%>> build-vars.bat
echo set LUX_X64_PYTHON2_ROOT=%D64%\Python-%PYTHON2_VER%>> build-vars.bat

echo "LUX_X86_PYTHON2_ROOT"="%D32R:\=\\%\\Python-%PYTHON2_VER%">> build-vars.reg
echo "LUX_X64_PYTHON2_ROOT"="%D64R:\=\\%\\Python-%PYTHON2_VER%">> build-vars.reg


:python3
IF NOT EXIST %DOWNLOADS%\Python-%PYTHON3_VER%.tgz (
    echo.
    echo **************************************************************************
    echo * Downloading Python 3                                                   *
    echo **************************************************************************
    %WGET% http://python.org/ftp/python/%PYTHON3_VER%/Python-%PYTHON3_VER%.tgz -O %DOWNLOADS%\Python-%PYTHON3_VER%.tgz
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting Python 3                                                    *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\Python-%PYTHON3_VER%.tgz > nul
%UNZIPBIN% x -y Python-%PYTHON3_VER%.tar -o%D32% > nul
%UNZIPBIN% x -y Python-%PYTHON3_VER%.tar -o%D64% > nul
del Python-%PYTHON3_VER%.tar

echo set LUX_X86_PYTHON3_ROOT=%D32%\Python-%PYTHON3_VER%>> build-vars.bat
echo set LUX_X64_PYTHON3_ROOT=%D64%\Python-%PYTHON3_VER%>> build-vars.bat

echo "LUX_X86_PYTHON3_ROOT"="%D32R:\=\\%\\Python-%PYTHON3_VER%">> build-vars.reg
echo "LUX_X64_PYTHON3_ROOT"="%D64R:\=\\%\\Python-%PYTHON3_VER%">> build-vars.reg


:glew
IF NOT EXIST %DOWNLOADS%\glew-%GLEW_VER%.zip (
    echo.
    echo **************************************************************************
    echo * Downloading GLEW                                                       *
    echo **************************************************************************
    %WGET% http://sourceforge.net/projects/glew/files/glew/%GLEW_VER%/glew-%GLEW_VER%.zip/download -O %DOWNLOADS%\glew-%GLEW_VER%.zip
    if ERRORLEVEL 1 (
        echo.
        echo Download failed. Are you connected to the internet?
        exit /b -1
    )
)
echo.
echo **************************************************************************
echo * Extracting GLEW                                                        *
echo **************************************************************************
%UNZIPBIN% x -y %DOWNLOADS%\glew-%GLEW_VER%.zip -o%D32%\ > nul
%UNZIPBIN% x -y %DOWNLOADS%\glew-%GLEW_VER%.zip -o%D64%\ > nul

echo set LUX_X86_GLEW_ROOT=%D32%\glew-%GLEW_VER%>> build-vars.bat
echo set LUX_X64_GLEW_ROOT=%D64%\glew-%GLEW_VER%>> build-vars.bat

echo "LUX_X86_GLEW_ROOT"="%D32R:\=\\%\\glew-%GLEW_VER%">> build-vars.reg
echo "LUX_X64_GLEW_ROOT"="%D64R:\=\\%\\glew-%GLEW_VER%">> build-vars.reg


echo.
echo **************************************************************************
echo * DONE                                                                   *
echo **************************************************************************
echo.
echo I have created a batch file build-vars.bat that will set the required path
echo variables for building.
echo.
echo I have also created a registry file build-vars.reg that will permanently set 
echo the required path variables for building. After importing this into the 
echo registry, you'll need to log out and back in for the changes to take effect.
echo.
echo To build for x86 you can now run build-x86.bat from a Visual Studio Command
echo Prompt window.
echo.
echo To build for x64 you can now run build-x64.bat from a Visual Studio Command
echo Prompt window.
echo.
