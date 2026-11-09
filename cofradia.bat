@echo off
setlocal
title Cofradia - Repertorio

set "APP_ROOT=%~dp0"
set "WEB_DIR=%APP_ROOT%WEB"
set "API_DIR=%APP_ROOT%API"

echo.
echo  =========================================
echo    COFRADIA - Repertorio de Bombos
echo  =========================================
echo.

if not exist "%WEB_DIR%\package.json" (
  echo  ERROR: No se ha encontrado la aplicacion web en:
  echo  %WEB_DIR%
  echo.
  pause
  exit /b 1
)
if not exist "%API_DIR%\pom.xml" (
  echo  ERROR: No se ha encontrado la API en:
  echo  %API_DIR%
  echo.
  pause
  exit /b 1
)

REM --- 1) Base de datos (MySQL en Docker, puerto 3307) ---
where docker >nul 2>&1
if errorlevel 1 (
  echo  ERROR: Docker no esta disponible en el PATH.
  echo  Instala/inicia Docker Desktop y vuelve a ejecutar este script.
  echo.
  pause
  exit /b 1
)

echo  [1/3] Levantando la base de datos (MySQL)...
pushd "%API_DIR%"
docker compose up -d --wait db
if errorlevel 1 (
  echo.
  echo  ERROR: No se pudo arrancar la base de datos.
  popd
  pause
  exit /b 1
)
popd

REM --- FFmpeg (para convertir MP4 a MP3). Si no esta en el PATH, se busca en la instalacion de winget ---
where ffmpeg >nul 2>&1 && goto ffmpeg_ok
set "FFMPEG_BIN="
for /f "delims=" %%F in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*\bin\ffmpeg.exe" 2^>nul') do set "FFMPEG_BIN=%%~dpF"
if defined FFMPEG_BIN (
  set "COFRADIA_FFMPEG_PATH=%FFMPEG_BIN%ffmpeg.exe"
  set "COFRADIA_FFPROBE_PATH=%FFMPEG_BIN%ffprobe.exe"
  echo  FFmpeg: %FFMPEG_BIN%ffmpeg.exe
) else (
  echo  AVISO: FFmpeg no encontrado. Los MP4 se marcaran como error hasta instalarlo:  winget install Gyan.FFmpeg
)
:ffmpeg_ok

REM --- Regla de firewall para el puerto 4300 (acceso desde el movil en la misma red) ---
REM Necesita permisos de administrador; si no los hay, se ignora y basta con "Permitir" en el aviso de Windows.
netsh advfirewall firewall show rule name="Cofradia Web 4300" >nul 2>&1
if errorlevel 1 (
  netsh advfirewall firewall add rule name="Cofradia Web 4300" dir=in action=allow protocol=TCP localport=4300 >nul 2>&1
  if errorlevel 1 (
    echo  AVISO: no se pudo crear la regla de firewall ^(ejecuta el .bat como administrador una vez^).
  ) else (
    echo  Firewall: puerto 4300 permitido para la red local.
  )
)

REM --- 2) Backend (Spring Boot, puerto 8080) en ventana propia ---
echo  [2/3] Arrancando el backend (Spring Boot) en una ventana nueva...
start "Cofradia - API" cmd /k "cd /d ""%API_DIR%"" && mvn.cmd spring-boot:run"

REM --- IPs privadas de este PC; el certificado HTTPS debe incluirlas todas (si no, la tablet lo rechaza) ---
set "GIT_HOME="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "GIT_HOME=%ProgramFiles%\Git"
if not defined GIT_HOME if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "GIT_HOME=%LOCALAPPDATA%\Programs\Git"
if defined GIT_HOME set "PATH=%GIT_HOME%\usr\bin;%PATH%"
set "LAN_IPS="
set "NEED_CERT="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /r /c:"IPv4.*192\.168\." /c:"IPv4.*10\." /c:"IPv4.*172\.1[6-9]\." /c:"IPv4.*172\.2[0-9]\." /c:"IPv4.*172\.3[0-1]\."') do call :addip %%A
if not defined NEED_CERT goto cert_ok
if not defined GIT_HOME (
  echo  AVISO: Git for Windows no encontrado; no se puede regenerar el certificado HTTPS.
  goto cert_ok
)
echo  Regenerando el certificado HTTPS para: %LAN_IPS%
pushd "%WEB_DIR%\certs"
"%GIT_HOME%\bin\bash.exe" generate.sh %LAN_IPS% 10.8.0.4 100.100.183.6 >nul 2>&1
if errorlevel 1 echo  AVISO: no se pudo regenerar el certificado.
popd
:cert_ok

REM --- 3) Frontend (Angular, puerto 4300) en ventana propia ---
echo  [3/3] Arrancando el frontend (Angular) en una ventana nueva...
if not exist "%WEB_DIR%\node_modules" (
  echo.
  echo  Instalando dependencias de la aplicacion web...
  pushd "%WEB_DIR%"
  call npm.cmd install
  if errorlevel 1 (
    echo  ERROR: No se pudieron instalar las dependencias.
    popd
    pause
    exit /b 1
  )
  popd
)
REM --ssl: HTTPS. Imprescindible para grabar audio (microfono) desde el movil; los navegadores
REM solo permiten getUserMedia en contexto seguro (https o localhost).
start "Cofradia - Web" cmd /k "cd /d ""%WEB_DIR%"" && npx.cmd ng serve --host 0.0.0.0 --port 4300 --ssl"

echo.
echo  Servicios lanzados:
echo    - Base de datos : localhost:3307  (contenedor cofradia-db)
echo    - Backend       : http://localhost:8080
echo    - Frontend      : https://localhost:4300
for %%I in (%LAN_IPS%) do echo    - Desde el movil/tablet (misma wifi): https://%%I:4300
echo.
echo  La API solo se usa por dentro (proxy de ng serve), no hace falta abrir el 8080.
echo.
echo  NOTA: el certificado es autofirmado. En el movil, la primera vez el navegador
echo  avisara ("conexion no privada") -^> pulsa "Avanzado" y "Continuar". Luego ya
echo  pedira permiso de microfono al grabar.
echo.
echo  El backend tarda unos segundos en compilar y arrancar la primera vez.
echo  Abriendo el navegador cuando el frontend responda...
echo.

REM Espera a que Angular sirva la pagina antes de abrir el navegador (max ~90s)
set /a tries=0
:waitweb
timeout /t 3 /nobreak >nul
curl -sk -o nul https://localhost:4300 && goto openweb
set /a tries+=1
if %tries% lss 30 goto waitweb

:openweb
start "" https://localhost:4300

echo  Listo. Cierra las ventanas "Cofradia - API" y "Cofradia - Web" para detener los servicios.
echo  Para detener la base de datos:  cd API ^&^& docker compose down
echo.
pause
endlocal
exit /b

:addip
set "IP=%~1"
set "LAN_IPS=%LAN_IPS% %IP%"
if defined GIT_HOME openssl x509 -in "%WEB_DIR%\certs\dev.crt" -noout -ext subjectAltName 2>nul | findstr /r /c:"IP Address:%IP%," /c:"IP Address:%IP%$" >nul
if defined GIT_HOME if errorlevel 1 set "NEED_CERT=1"
goto :eof
