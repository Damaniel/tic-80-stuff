@ECHO OFF

REM Copies the specified cart file in Lua format to the directory in the repo matching the cart name
REM (for example, copies the cart 'foo.lua' from the cart directory to foo\foo.lua in the repo)
REM
REM Note that only the non-code parts of the file are copied over.  The script that does that
REM work (import_media_data.py) requires Python 3.x.

copy /Y C:\Users\%USERNAME%\AppData\Roaming\com.nesbox.tic\TIC-80\%1.lua ..\%1\%1_cartdir.lua
python import_media_data.py ..\%1\%1_cartdir.lua ..\%1\%1.lua
del ..\%1\%1_cartdir.lua
