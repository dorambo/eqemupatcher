echo building....
set VERSION=0.0.0.1
set BUILD_CONFIGURATION=Release
set SERVER_NAME=The Hero Chronicles
set FILE_NAME=eqemupatcher
set FILELIST_URL=https://raw.githubusercontent.com/dorambo/eqemupatcher/master
set PATCHER_URL=https://raw.githubusercontent.com/dorambo/eqemupatcher/master/rof
"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" /m /p:Configuration=%BUILD_CONFIGURATION% /p:VERSION=%VERSION% /p:SERVER_NAME="%SERVER_NAME%" /p:FILELIST_URL="%FILELIST_URL%" /p:PATCHER_URL="%PATCHER_URL%" /p:FILE_NAME="%FILE_NAME%"
