@echo off 

IF NOT DEFINED DXCONFIGPATH (
  echo DXCONFIGPATH environment variable must be set!
  exit /b 1
)

SETLOCAL enabledelayedexpansion
TITLE Elasticsearch 1.5.2

rem This is a loop to protect against starting a second instance of elasticsearch which is VERY bad
sc query lr-elasticsearch | find "RUNNING"
if %errorlevel% EQU 0 (
  ECHO ERROR: Elasticsearch is still running
  exit /b 0
)

timeout /t 5 /nobreak

SET params='%*'
sc query MSSQLSERVER
SET HALF_HEAP=%errorlevel%
:loop
FOR /F "usebackq tokens=1* delims= " %%A IN (!params!) DO (
    SET current=%%A
    SET params='%%B'
	SET silent=N
	
	IF "!current!" == "-s" (
		SET silent=Y
	)
	IF "!current!" == "--silent" (
		SET silent=Y
	)	
	
	IF "!silent!" == "Y" (
		SET nopauseonerror=Y
	) ELSE (
	    IF "x!newparams!" NEQ "x" (
	        SET newparams=!newparams! !current!
        ) ELSE (
            SET newparams=!current!
        )
	)
	
    IF "x!params!" NEQ "x" (
		GOTO loop
	)
)

for /f "delims=" %%a in ('wmic OS get TotalVisibleMemorySize /Value') do @set %%a
if %TotalVisibleMemorySize% GEQ 125829120 (
  set ES_HEAP_SIZE=30g
  set ES_MAX_WORKING_SET=60000
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 67108864 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=30000
     set ES_HEAP_SIZE=16g
     goto :endifs
  ) 
  set ES_MAX_WORKING_SET=45000
  set ES_HEAP_SIZE=30g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 54525952 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=25000
     set ES_HEAP_SIZE=13g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=35000
  set ES_HEAP_SIZE=26g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 48234496 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=20000
     set ES_HEAP_SIZE=12g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=32000
  set ES_HEAP_SIZE=24g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 41943040 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=20000
     set ES_HEAP_SIZE=11g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=30000
  set ES_HEAP_SIZE=22g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 35651584 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=14000
     set ES_HEAP_SIZE=9g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=24000
  set ES_HEAP_SIZE=18g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 29360128 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=12000
     set ES_HEAP_SIZE=8g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=20000
  set ES_HEAP_SIZE=16g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 23068672 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=10000
     set ES_HEAP_SIZE=7g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=16000
  set ES_HEAP_SIZE=12g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 16777216 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=9000
     set ES_HEAP_SIZE=6g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=12000
  set ES_HEAP_SIZE=9g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 10485760 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=6000
     set ES_HEAP_SIZE=4g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=8000
  set ES_HEAP_SIZE=6g
  goto :endifs
) 
if %TotalVisibleMemorySize% GEQ 5242880 (
  if %HALF_HEAP% EQU 0 (
  	 set ES_MAX_WORKING_SET=2000
     set ES_HEAP_SIZE=1g
     goto :endifs
  )
  set ES_MAX_WORKING_SET=3000
  set ES_HEAP_SIZE=2g
  goto :endifs
) 
set ES_MAX_WORKING_SET=2048
set ES_HEAP_SIZE=1g
:endifs

CALL "%~dp0elasticsearch.in.bat"
IF %ERRORLEVEL% EQU 1 (
	IF NOT DEFINED nopauseonerror (
		PAUSE
	)
	EXIT /B %ERRORLEVEL%
)

@REM Ensure VIRTUAL_HOSTNAME is defined, since we rely on it
IF NOT DEFINED VIRTUAL_HOSTNAME (
   FOR /f %%i IN ('hostname') DO SET VIRTUAL_HOSTNAME=%%i
)

@REM Disable the -XX:-HeapDumpOnOutOfMemoryError option
"%JAVA_HOME%\bin\java" %JAVA_OPTS% %ES_JAVA_OPTS% -XX:-HeapDumpOnOutOfMemoryError  %ES_PARAMS% -Des.config="%DXCONFIGPATH%\elasticsearch\config\elasticsearch.yml" !newparams! -cp "%ES_CLASSPATH%" "org.elasticsearch.bootstrap.Elasticsearch"

REM "set the pid to the last item in the string, it should always be the pid"

for /f "tokens=*" %%a in ('wmic process where ^(name^="java.exe" ^) get ProcessID ^,commandline ^| findstr "\-Delasticsearch ^"') do (
  for %%A in (%%a) do set pid=%%A
)

Start "" "C:\Users\ben.aldrich\go\src\github.com\vrecan\LimitWorkingSet\LimitWorkingSet.exe" -pid=%pid% -max=%ES_MAX_WORKING_SET%

ENDLOCAL
