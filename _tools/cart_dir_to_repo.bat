@ECHO OFF

REM Copies the specified cart file in Lua format to the directory in the repo matching the cart name
REM (for example, copies the cart 'foo.lua' from the cart directory to foo\foo.lua in the repo)

COPY /Y C:\Users\%USERNAME%\AppData\Roaming\com.nesbox.tic\TIC-80\%1.lua ..\%1\%1.lua