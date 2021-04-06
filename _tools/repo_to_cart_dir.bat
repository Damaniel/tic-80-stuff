@ECHO OFF

REM Copies the specified cart file in Lua format from the directory in the repo matching the cart name 
REM to the official cart location
REM (for example, copies the cart 'foo.lua' from foo\foo.lua in the repo to foo.lua in the cart directory)

COPY /Y ..\%1\%1.lua C:\Users\%USERNAME%\AppData\Roaming\com.nesbox.tic\TIC-80\%1.lua