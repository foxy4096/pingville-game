@echo off

:: Set paths for both client and server projects
set CLIENT_PROJECT_PATH="E:\Documents\Projects\PingVille\PingVilleClient"
set SERVER_PROJECT_PATH="E:\Documents\Projects\PingVille\PingVilleServer"

:: Export the client project
echo Exporting Client...
cd %CLIENT_PROJECT_PATH%
"E:\Software\Applications\Godot\Godot_v3.5.2-stable_win64.exe" --no-window --export "Windows Desktop" "builds\client.exe"

:: Export the server project
echo Exporting Server...
cd %SERVER_PROJECT_PATH%
"E:\Software\Applications\Godot\Godot_v3.5.2-stable_win64.exe" --no-window --export "Windows Desktop" "builds\server.exe"

echo Done!
pause
