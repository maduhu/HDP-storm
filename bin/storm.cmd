@echo off

@rem Licensed to the Apache Software Foundation (ASF) under one
@rem or more contributor license agreements.  See the NOTICE file
@rem distributed with this work for additional information
@rem regarding copyright ownership.  The ASF licenses this file
@rem to you under the Apache License, Version 2.0 (the
@rem "License"); you may not use this file except in compliance
@rem with the License.  You may obtain a copy of the License at
@rem
@rem http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.

@rem The storm command script
@rem
@rem Environment Variables
@rem
@rem   JAVA_HOME        The java implementation to use.  Overrides JAVA_HOME.
@rem
@rem   STORM_CLASSPATH Extra Java CLASSPATH entries.
@rem
@rem   STORM_HEAPSIZE  The maximum amount of heap to use, in MB.
@rem                    Default is 1000.
@rem
@rem   STORM_OPTS      Extra Java runtime options.
@rem
@rem   STORM_CONF_DIR  Alternate conf dir. Default is ${STORM_HOME}/conf.
@rem
@rem   STORM_ROOT_LOGGER The root appender. Default is INFO,console
@rem

@rem if running as a service, log to (daily rolling) files instead of console
set script_path=%~dp0

if "%1" == "--service" (
  if not defined HADOOP_ROOT_LOGGER (
    set STORM_ROOT_LOGGER=INFO,DRFA
  )
  set service_entry=true
  shift
)

:main
  setlocal enabledelayedexpansion

  set storm-command=%1

  if not "%storm-command%" == "jar" (
    set set_storm_options=true
  )

  call %script_path%storm-config.cmd

  if not defined storm-command (
      goto print_usage
  )

  call :make_command_arguments %*

  if not defined STORM_LOG_FILE (
    set STORM_LOG_FILE=-Dlogfile.name=%storm-command%.log
  )
  set shellcommands=classpath help version
  for %%i in ( %shellcommands% ) do (
    if %storm-command% == %%i set shellcommand=true
  )
  if defined shellcommand (
    call :%storm-command% %*
    goto :eof
  )

  set corecommands=activate deactivate dev-zookeeper drpc kill list nimbus logviewer rebalance remoteconfvalue repl shell supervisor ui
  for %%i in ( %corecommands% ) do (
    if %storm-command% == %%i set corecommand=true
  )
  if defined corecommand (
    call :%storm-command% %storm-command-arguments%
  ) else (
    set CLASS=%storm-command%
  )

  if %storm-command% == jar (
    set config-options=
 
    goto start
    :start
    shift
    if [%1] == [] goto done

    if '%1'=='-c' (
      set c-opt=first
      goto start
    )

    if "%c-opt%"=="first" (
      set config-options=%config-options%,%1
      set c-opt=second
      goto start
    )

    if "%c-opt%"=="second" (
      set config-options=%config-options%=%1
      set c-opt=
      goto start
    )

    set args=%args% %1
    goto start

    :done
    for /F "tokens=1,2,*" %%a in ("%args%") do (
      set first-arg=%%a
      set second-arg=%%b
      set remaining-args=%%c
    )
    set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS% -Dstorm.jar=%first-arg%
    set STORM_OPTS=%STORM_OPTS% -Dstorm.options=%config-options%
    set CLASSPATH=%CLASSPATH%;%first-arg%
    set CLASS=%second-arg%
    set storm-command-arguments=%remaining-args%

  )

  if defined STORM_DEBUG (
    %JAVA% %JAVA_HEAP_MAX% %STORM_OPTS% %STORM_LOG_FILE% %CLASS% %storm-command-arguments%
  )
  set path=%PATH%;%STORM_BIN_DIR%;%STORM_SBIN_DIR%
  set java_arguments=%JAVA_HEAP_MAX% %STORM_OPTS% %STORM_LOG_FILE% -classpath %CLASSPATH% %CLASS% %storm-command-arguments%
  if defined service_entry (
    call :makeServiceXml %java_arguments%
  ) else (
    call %JAVA% %java_arguments%
  )
  exit /b %ERRORLEVEL%
  goto :eof

:activate
  set CLASS=backtype.storm.command.activate
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:classpath
  echo %CLASSPATH%
  goto :eof

:deactivate
  set CLASS=backtype.storm.command.deactivate
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:dev-zookeeper
  set CLASS=backtype.storm.command.dev_zookeeper
  set STORM_OPTS=%STORM_SERVER_OPTS% %STORM_OPTS%
  goto :eof

:drpc
  set CLASS=backtype.storm.daemon.drpc
  %JAVA% -client -Dstorm.options= -Dstorm.conf.file= -cp %CLASSPATH% backtype.storm.command.config_value drpc.childopts > %CMD_TEMP_FILE%
  FOR /F "delims=" %%i in (%CMD_TEMP_FILE%) do (
     FOR /F "tokens=1,* delims= " %%a in ("%%i") do (
    if %%a == VALUE: (
     set CHILDOPTS=%%b
     call :set_childopts)
    )
  )
  goto :eof

:help
  call :print_usage
  goto :eof

:kill
  set CLASS=backtype.storm.command.kill_topology
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:list
  set CLASS=backtype.storm.command.list
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:logviewer
  set CLASS=backtype.storm.daemon.logviewer
   %JAVA% -client -Dstorm.options= -Dstorm.conf.file= -cp %CLASSPATH% backtype.storm.command.config_value logviewer.childopts > %CMD_TEMP_FILE%
  FOR /F "delims=" %%i in (%CMD_TEMP_FILE%) do (
     FOR /F "tokens=1,* delims= " %%a in ("%%i") do (
    if %%a == VALUE: (
     set CHILDOPTS=%%b
     call :set_childopts)
    )
  )
  goto :eof

:nimbus
  set CLASS=backtype.storm.daemon.nimbus
  %JAVA% -client -Dstorm.options= -Dstorm.conf.file= -cp %CLASSPATH% backtype.storm.command.config_value nimbus.childopts > %CMD_TEMP_FILE%
  FOR /F "delims=" %%i in (%CMD_TEMP_FILE%) do (
     FOR /F "tokens=1,* delims= " %%a in ("%%i") do (
    if %%a == VALUE: (
     set CHILDOPTS=%%b
     call :set_childopts)
    )
  )
  goto :eof

:rebalance
  set CLASS=backtype.storm.command.rebalance
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:remoteconfvalue
  set CLASS=backtype.storm.command.config_value
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:repl
  set CLASS=clojure.main
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:shell
  set CLASS=backtype.storm.command.shell_submission
  set STORM_OPTS=%STORM_CLIENT_OPTS% %STORM_OPTS%
  goto :eof

:supervisor
  set CLASS=backtype.storm.daemon.supervisor
  %JAVA% -client -Dstorm.options= -Dstorm.conf.file= -cp %CLASSPATH% backtype.storm.command.config_value supervisor.childopts > %CMD_TEMP_FILE%
  FOR /F "delims=" %%i in (%CMD_TEMP_FILE%) do (
     FOR /F "tokens=1,* delims= " %%a in ("%%i") do (
    if %%a == VALUE: (
     set CHILDOPTS=%%b
     call :set_childopts)
    )
  )
  goto :eof

:ui
  set CLASS=backtype.storm.ui.core
  set CLASSPATH=%CLASSPATH%;%STORM_HOME%
  %JAVA% -client -Dstorm.options= -Dstorm.conf.file= -cp %CLASSPATH% backtype.storm.command.config_value ui.childopts > %CMD_TEMP_FILE%
  FOR /F "delims=" %%i in (%CMD_TEMP_FILE%) do (
     FOR /F "tokens=1,* delims= " %%a in ("%%i") do (
    if %%a == VALUE: (
     set CHILDOPTS=%%b
     call :set_childopts)
    )
  )
  goto :eof

:version
  type %STORM_HOME%\RELEASE
  goto :eof

:makeServiceXml
  set arguments=%*
  @echo ^<service^>
  @echo   ^<id^>storm_%storm-command%^</id^>
  @echo   ^<name^>storm_%storm-command%^</name^>
  @echo   ^<description^>This service runs Storm %storm-command%^</description^>
  @echo   ^<executable^>%JAVA%^</executable^>
  @echo   ^<arguments^>%arguments%^</arguments^>
  @echo ^</service^>
  goto :eof

:make_command_arguments
  if [%2] == [] goto :eof
  if "%1" == "--service" (
    shift
  )
  shift
  set _stormarguments=

  :MakeCmdArgsLoop
  if [%1]==[] goto :EndLoop

  if not defined _stormarguments (
    set _stormarguments=%1
  ) else (
    set _stormarguments=!_stormarguments! %1
  )
  shift
  goto :MakeCmdArgsLoop
  :EndLoop
  set storm-command-arguments=%_stormarguments%
  goto :eof

:set_childopts
  set STORM_OPTS=%STORM_SERVER_OPTS% %STORM_OPTS% %CHILDOPTS%
  del /F %CMD_TEMP_FILE%
  goto :eof

:print_usage
  @echo Usage: storm COMMAND
  @echo where COMMAND is one of:
  @echo   activate             activates the specified topology's spouts
  @echo   classpath            prints the classpath used by the storm client when running commands
  @echo   deactivate           deactivates the specified topology's spouts
  @echo   dev-zookeeper        launches a fresh dev/test Zookeeper server
  @echo   drpc                 launches a DRPC daemon
  @echo   help
  @echo   jar ^<jar^>          run a jar file
  @echo   kill                 kills the topology with the name topology-name
  @echo   list                 list the running topologies and their statuses
  @echo   logviewer            launches the log viewer daemon
  @echo   nimbus               launches the nimbus daemon
  @echo   rebalance            redistribute or change the parallelism of a running topology
  @echo   remoteconfvalue      prints value for conf-name from cluster config ../conf/storm.yaml merged with defaults.yaml
  @echo   repl                 opens up a Clojure REPL
  @echo   remoteconfvalue      prints value for conf-name from cluster config ../conf/storm.yaml merged with defaults.yaml
  @echo   shell                storm shell
  @echo   supervisor           launches the supervisor daemon
  @echo   ui                   launches the UI daemon
  @echo   version              print the version
  @echo.
  @echo  or
  @echo   CLASSNAME            run the class named CLASSNAME
  @echo Most commands print help when invoked w/o parameters.

endlocal
