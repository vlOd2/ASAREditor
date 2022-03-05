@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

:CHECK_DEPS
CALL :DSP_NAME

ECHO Checking for Node.JS...
WHERE node > NUl 2>&1
IF %ERRORLEVEL% GEQ 1 (
	ECHO Node.JS is not installed.
	ECHO Make sure it is installed and that it is added to %%PATH%%.
	PAUSE
	EXIT /B 1
)

ECHO Checking for ASAR...
WHERE asar > NUl 2>&1
SET ASAR_NOT_INSTALLED=FALSE

IF %ERRORLEVEL% GEQ 1 (
	SET ASAR_NOT_INSTALLED=TRUE
	ECHO ASAR is not installed.
	ECHO Installing ASAR...
	CALL npm install -g asar
)

if "%ASAR_NOT_INSTALLED%" EQU "TRUE" (
	ECHO Checking for ASAR...
	WHERE asar > NUl 2>&1
	IF %ERRORLEVEL% GEQ 1 (
		ECHO ASAR is still not in %%PATH%%.
		ECHO Make sure it installed correctly and restart the editor.
		PAUSE
		EXIT /B 1
	)
)
GOTO SETUP

:SETUP
SET VERSION_NR=1.0
SET DEBUG_ENABLED=FALSE

SET SHOULD_QUIT=FALSE
SET IS_DECOMPILED=FALSE
SET "CURRENT_FILE="

TITLE ASAR Editor
PUSHD %~dp0

CLS
CALL :DSP_NAME
ECHO Welcome to ASAR Editor!
ECHO Type "help" for help
ECHO.
GOTO MAIN

:MAIN
IF "%SHOULD_QUIT%" EQU "TRUE" (
	CLS
	TITLE %ComSpec%
	EXIT /B 0
)

SET /P "INPUT_CMD=%CD:\=/%:$ "
CALL :HANDLE_INP "%INPUT_CMD%"
ECHO.

GOTO MAIN

:HANDLE_INP
SET INPUT=%~1
 
FOR /F "tokens=1,2,3,4,5,6,7,8,9" %%1 IN ("%INPUT%") DO (
	SET INPUT_CMD=%%1
	SET INPUT_ARGS_0=%%2
	SET INPUT_ARGS_1=%%3
	SET INPUT_ARGS_2=%%4
	SET INPUT_ARGS_3=%%5
	SET INPUT_ARGS_4=%%6
	SET INPUT_ARGS_5=%%7
	SET INPUT_ARGS_6=%%8
	SET INPUT_ARGS_7=%%9
)

IF "%DEBUG_ENABLED%" EQU "TRUE" (
	ECHO %INPUT_CMD%
	ECHO %INPUT_ARGS_0%
	ECHO %INPUT_ARGS_1%
	ECHO %INPUT_ARGS_2%
	ECHO %INPUT_ARGS_3%
	ECHO %INPUT_ARGS_4%
	ECHO %INPUT_ARGS_5%
	ECHO %INPUT_ARGS_6%
	ECHO %INPUT_ARGS_7%
)

:: Help command
IF "%INPUT_CMD%" EQU "help" (
	CALL :DSP_HELP
) ELSE (
	:: Clear command
	IF "%INPUT_CMD%" EQU "clear" (
		CLS
	) ELSE (
		:: Info command
		IF "%INPUT_CMD%" EQU "info" (
			CALL :DSP_INFO
		) ELSE (
			:: Select command
			IF "%INPUT_CMD%" EQU "select" (
				IF "%INPUT_ARGS_0%" EQU "" (
					ECHO ERROR: No file specified.
					EXIT /B
				) ELSE (
					IF NOT EXIST "%INPUT_ARGS_0%" (
						ECHO ERROR: The system cannot find the specified file.
						EXIT /B
					)
				)
				
				SET CURRENT_FILE=%INPUT_ARGS_0%
				SET IS_DECOMPILED=FALSE
				IF EXIST "!CURRENT_FILE!_DECOMPILED" SET IS_DECOMPILED=TRUE
				
				ECHO You have selected the file !CURRENT_FILE!.
			) ELSE (
				:: Quit command
				IF "%INPUT_CMD%" EQU "quit" (
					SET SHOULD_QUIT=TRUE
				) ELSE (
					:: Decompile command
					IF "%INPUT_CMD%" EQU "decompile" (
						IF EXIST "!CURRENT_FILE!_DECOMPILED" SET IS_DECOMPILED=TRUE
						IF NOT EXIST "!CURRENT_FILE!_DECOMPILED" SET IS_DECOMPILED=FALSE
						
						IF "!IS_DECOMPILED!" EQU "TRUE" (
							ECHO ERROR: You have already decompiled the selected file.
							EXIT /B
						)
					
						IF "%CURRENT_FILE%" EQU "" (
							ECHO ERROR: You have not selected any file.
							EXIT /B
						)

						ECHO Decompiling "%CURRENT_FILE%"...
						CMD /C asar extract "%CURRENT_FILE%" "%CURRENT_FILE%_DECOMPILED"

						IF !ERRORLEVEL! EQU 1 (
							ECHO ERROR: An error has occured whilst decompiling "%CURRENT_FILE%".
							SET IS_DECOMPILED=FALSE
						) ELSE (
							ECHO Successfully decompiled "%CURRENT_FILE%" into "%CURRENT_FILE%_DECOMPILED".
							SET IS_DECOMPILED=TRUE
						)
					) ELSE (
						:: Compile command
						IF "%INPUT_CMD%" EQU "compile" (
							IF EXIST "!CURRENT_FILE!_DECOMPILED" SET IS_DECOMPILED=TRUE
							IF NOT EXIST "!CURRENT_FILE!_DECOMPILED" SET IS_DECOMPILED=FALSE
							
							IF "!IS_DECOMPILED!" EQU "FALSE" (
								ECHO ERROR: You have not decompiled the selected file.
								EXIT /B
							)
						
							IF "%CURRENT_FILE%" EQU "" (
								ECHO ERROR: You have not selected any file.
								EXIT /B
							)

							ECHO Compiling "%CURRENT_FILE%_COMPILED"...
							CMD /C asar pack "%CURRENT_FILE%_DECOMPILED" "%CURRENT_FILE%_COMPILED" --unpack "{*.node,*.dll}"

							IF !ERRORLEVEL! EQU 1 (
								ECHO ERROR: An error has occured whilst compiling "%CURRENT_FILE%".
							) ELSE (
								ECHO Successfully compiled "%CURRENT_FILE%" into "%CURRENT_FILE%_COMPILED".
							)
						) ELSE (
							ECHO Invalid command or operation. Type "help" for help.
						)
					)
				)
			)
		)
	)
)

EXIT /B

:DSP_NAME
ECHO ---------------
ECHO   ASAR Editor
ECHO ---------------
EXIT /B

:DSP_HELP
CALL :DSP_NAME
ECHO help - Displays this message
ECHO clear/cls - Clears the screen
ECHO info - Shows information
ECHO select ^<file^> - Selects the specified .asar file ^(must be in the current directory^)
ECHO decompile - Decompiles the selected file
ECHO compile - Compiles the decompiled files
ECHO quit - Quits the application
ECHO.
ECHO Note: When using "select", if the file specified is already decompiled it will detect that and allow compilation
EXIT /B

:DSP_INFO
CALL :DSP_NAME
ECHO Version: %VERSION_NR%
ECHO Created by: vlOd
EXIT /B