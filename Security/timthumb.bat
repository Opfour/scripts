@ECHO OFF
ECHO Downloading newest timthumb script
wget -O "%temp%\thumb.php" http://timthumb.googlecode.com/svn/trunk/timthumb.php 1>NUL 2>NUL
IF NOT EXIST "%temp%\thumb.php" GOTO Fail
ECHO Locating timthumb scripts
for /f "delims=" %%a in ('dir /s /b "%plesk_vhosts%" ^| find /v "\Servers\" ^| findstr /E "thumb.php"') do findstr /M /C:"timthumb" "%%a" > "%temp%\list3"
ECHO Backing up and updating the located scripts
FOR /f %%a in ('type "%temp%\list3"') DO (move /y "%%a" "%%a.bak" 1>NUL 2>NUL && copy /y "%temp%\thumb.php" "%%a") 1>NUL 2>NUL
ECHO Done, cleaning up
del /q /f "%temp%\thumb.php" 1>NUL 2>NUL
ECHO The following files were replaced (No output means timthumb was not found)
type "%temp%\list3" 2>NUL
del /q /f "%temp%\list3" 1>NUL 2>NUL
GOTO Done
:Fail
ECHO unable to fetch current timthumb script (http://timthumb.googlecode.com/svn/trunk/timthumb.php), exiting
:Done
