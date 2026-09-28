@echo off
title Rojo Server - Roblox Anti-Cheat Suite
color 0B
echo =====================================================================
echo           ROJO SERVER - ROBLOX ANTI-CHEAT DEMO SUITE
echo =====================================================================
echo.
echo [1] Abre Roblox Studio.
echo [2] Abre un Baseplate en blanco o cualquier juego donde quieras probar.
echo [3] En la pestana "Plugins", haz clic en el plugin de Rojo y presiona "Connect".
echo.
echo El servidor local de Rojo esta escuchando en el puerto 34872...
echo (Presiona Ctrl + C para detener el servidor en cualquier momento)
echo =====================================================================
echo.
rojo.exe serve default.project.json
pause
