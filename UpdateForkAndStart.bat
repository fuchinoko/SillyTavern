@echo off
@setlocal enabledelayedexpansion
pushd %~dp0

echo Checking Git installation
git --version > nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed on this system. Skipping update.
    echo If you installed with a zip file, you will need to download the new zip and install it manually.
    goto end
)

REM Checking current branch
FOR /F "tokens=*" %%i IN ('git rev-parse --abbrev-ref HEAD') DO SET CURRENT_BRANCH=%%i
echo Current branch: %CURRENT_BRANCH%

REM Checking for automatic branch switching configuration
set AUTO_SWITCH=
FOR /F "tokens=*" %%j IN ('git config --local script.autoSwitch') DO SET AUTO_SWITCH=%%j

SET TARGET_BRANCH=%CURRENT_BRANCH%

if NOT "!AUTO_SWITCH!"=="" (
    if "!AUTO_SWITCH!"=="s" (
        goto autoswitch-staging
    )
    if "!AUTO_SWITCH!"=="r" (
        goto autoswitch-release
    )

    if "!AUTO_SWITCH!"=="staging" (
        :autoswitch-staging
        echo Auto-switching to staging branch
        git checkout staging
        SET TARGET_BRANCH=staging
        goto update
    )
    if "!AUTO_SWITCH!"=="release" (
        :autoswitch-release
        echo Auto-switching to release branch
        git checkout release
        SET TARGET_BRANCH=release
        goto update
    )

    echo Auto-switching defined to stay on current branch
    goto update
)

if "!CURRENT_BRANCH!"=="staging" (
    echo Staying on the current branch
    goto update
)
if "!CURRENT_BRANCH!"=="release" (
    echo Staying on the current branch
    goto update
)

echo You are not on 'staging' or 'release'. You are on '!CURRENT_BRANCH!'.
set /p "CHOICE=Do you want to switch to 'staging' (s), 'release' (r), or stay (any other key)? "
if /i "!CHOICE!"=="s" (
    echo Switching to staging branch
    git checkout staging
    SET TARGET_BRANCH=staging
    goto update
)
if /i "!CHOICE!"=="r" (
    echo Switching to release branch
    git checkout release
    SET TARGET_BRANCH=release
    goto update
)

echo Staying on the current branch

:update
if "%TARGET_BRANCH%" == "release" (
    REM Fetch from origin and merge/rebase updates
    git fetch origin && echo Merging updates from 'origin' && git merge origin/%TARGET_BRANCH%

    REM Check for errors after merging from origin
    if %errorlevel% neq 0 (
        echo There were errors while merging from origin. Please check manually.
        goto end
    )

    REM Fetch from upstream and merge/rebase updates
    git fetch upstream && echo Merging updates from 'upstream' && git merge upstream/%TARGET_BRANCH%

    REM Check for errors after merging from upstream
    if %errorlevel% neq 0 (
        echo There were errors while merging from upstream. Please check manually.
        goto end
    )

    REM Pushing changes to origin
    echo Pushing changes to origin
    git push origin
    if %errorlevel% neq 0 (
        echo There were errors while pushing to origin. Please check manuall
        goto end
    )

    goto install
)

REM Default behavior for non-release branches or if no choice was made for release branch
echo Fetching updates from 'origin'
git fetch origin && echo Merging updates against 'origin' && git merge origin/%TARGET_BRANCH%

:install
if %errorlevel% neq 0 (
    echo There were errors while updating. Please check manually.
    goto end
)

echo Installing npm packages and starting server
set NODE_ENV=production
call npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev
node server.js %*

:end
pause
popd