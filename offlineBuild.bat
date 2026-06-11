rem Cef 预编译版本 cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64.tar.bz2
rem 环境 vs2022 QT5.14.2，使用本地的 CefViewCore (thirdparty/ 目录下 )和 CEF 预编译包(已放到CefViewCore\dep 目录下)
rem QT_SDK_DIR 不用到 bin
rem 在CefView 跟目录下执行

call generate-win-x86_64.bat -DQT_SDK_DIR=C:\Qt\Qt5.14.2\5.14.2\msvc2017_64 -DFETCHCONTENT_SOURCE_DIR_CEFVIEWCORE=%cd%/thirdparty/CefViewCore -DFETCHCONTENT_FULLY_DISCONNECTED=ON
if errorlevel 1 exit /b 1

cmake --build .build/windows.x86_64 --config Release
if errorlevel 1 exit /b 1