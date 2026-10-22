@echo off
setlocal EnableExtensions

set "DEPLOY_DIR=%~dp0"
set "COMPOSE_FILE=%DEPLOY_DIR%docker-compose.yml"
set "ENV_FILE=%DEPLOY_DIR%.env"
set "KONG_FILE=%DEPLOY_DIR%kong\config\kong.yaml"

if not exist "%COMPOSE_FILE%" (
  echo No existe "%COMPOSE_FILE%".
  goto :error
)

if not exist "%ENV_FILE%" (
  echo No existe "%ENV_FILE%".
  goto :error
)

if not exist "%KONG_FILE%" (
  echo No existe "%KONG_FILE%".
  goto :error
)

for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
  if /I "%%A"=="ASEINT_ENV" set "ASEINT_ENV=%%B"
  if /I "%%A"=="ASEINT_DOCKER_NETWORK" set "ASEINT_DOCKER_NETWORK=%%B"
)

if "%ASEINT_ENV%"=="" (
  echo Falta ASEINT_ENV en "%ENV_FILE%".
  goto :error
)

if "%ASEINT_DOCKER_NETWORK%"=="" (
  echo Falta ASEINT_DOCKER_NETWORK en "%ENV_FILE%".
  goto :error
)

docker network inspect "%ASEINT_DOCKER_NETWORK%" >nul 2>nul
if errorlevel 1 (
  echo Creando red Docker "%ASEINT_DOCKER_NETWORK%"...
  docker network create "%ASEINT_DOCKER_NETWORK%"
  if errorlevel 1 goto :error
)

pushd "%DEPLOY_DIR%" >nul
if errorlevel 1 goto :error

echo Levantando infra ASEINT %ASEINT_ENV% desde "%DEPLOY_DIR%"...
docker compose --env-file "%ENV_FILE%" -f "%COMPOSE_FILE%" up -d
set "RESULT=%ERRORLEVEL%"

if "%RESULT%"=="0" docker compose --env-file "%ENV_FILE%" -f "%COMPOSE_FILE%" ps
popd >nul

if not "%RESULT%"=="0" goto :error

echo.
echo Infra ASEINT %ASEINT_ENV% levantada correctamente.
echo.
pause
exit /b 0

:error
echo.
echo ERROR: no se ha podido levantar la infra ASEINT.
echo Revisa los mensajes anteriores.
echo.
pause
exit /b 1
