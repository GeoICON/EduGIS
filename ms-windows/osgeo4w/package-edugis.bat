@echo off
REM ***************************************************************************
REM    package.cmd
REM    ---------------------
REM    begin                : July 2009
REM    copyright            : (C) 2009 by Juergen E. Fischer
REM    email                : jef at norbit dot de
REM ***************************************************************************
REM *                                                                         *
REM *   This program is free software; you can redistribute it and/or modify  *
REM *   it under the terms of the GNU General Public License as published by  *
REM *   the Free Software Foundation; either version 2 of the License, or     *
REM *   (at your option) any later version.                                   *
REM *                                                                         *
REM *   Special version for building EduGIS. Created by GeoICON Pte. Ltd.     *
REM *                                                                         *
REM ***************************************************************************
set VERSION=%1
set PACKAGE=%2
set PACKAGENAME=%3

if "%VERSION%"=="" goto usage
if "%PACKAGE%"=="" goto usage
if "%PACKAGENAME%"=="" goto usage

set ARCH=x86

set BUILDDIR=%CD%\build
set LOG=%BUILDDIR%\build.log

if "%OSGEO4W_ROOT%"=="" (
  set OSGEO4W_ROOT=C:\OSGeo4W
)

if not exist "%BUILDDIR%" mkdir %BUILDDIR%
if not exist "%BUILDDIR%" (echo could not create build directory %BUILDDIR% & goto error)

REM ***************************************************************************
REM Setup environment *********************************************************
REM ***************************************************************************

set PYTHONPATH=

call "c:\programs\msvs2010\VC\vcvarsall.bat" x86

for %%f in (%OSGEO4W_ROOT%\etc\ini\*.bat) do call "%%f"

set INCLUDE=%INCLUDE%;%OSGEO4W_ROOT%\include
set LIB=%LIB%;%OSGEO4W_ROOT%\lib

set GRASS_VERSION=6.4.4

REM ***************************************************************************

set O4W_ROOT=%OSGEO4W_ROOT:\=/%

if not "%PROGRAMFILES(X86)%"=="" set PF86=%PROGRAMFILES(X86)%
if "%PF86%"=="" set PF86=%PROGRAMFILES%
if "%PF86%"=="" (echo PROGRAMFILES not set & goto error)

REM -G "NMake Makefiles" ^
REM -G "Visual Studio 10 2010" ^

REM set CLCACHE_CL=c:\programs\msvs2010\VC\bin\cl.exe
REM set CLCACHE_CL=c:\programs\msvs2010\VC\bin\cl.real.exe
REM set CLCACHE_LOG=1
REM set CLCACHE_DIR=c:\clcache
REM set CLCACHE_NODIRECT=1

REM -D CMAKE_C_COMPILER=c:/programs/clcache/dist/clcache.exe ^
REM -D CMAKE_CXX_COMPILER=c:/programs/clcache/dist/clcache.exe

set CMAKE_OPT=^
  -G "Visual Studio 10 2010" ^
  -D SIP_BINARY_PATH=%O4W_ROOT%/apps/Python27/sip.exe ^
  -D QWT_LIBRARY=%O4W_ROOT%/lib/qwt.lib ^
  -D BUILD_TESTING=FALSE

set BUILDCONF=Release

cd ..\..
set SRCDIR=%CD%

if "%BUILDDIR:~1,1%"==":" %BUILDDIR:~0,2%
cd %BUILDDIR%

if exist repackage goto package

if not exist build.log goto build

REM
REM try renaming the logfile to see if it's locked
REM

if exist build.tmp del build.tmp
if exist build.tmp (echo could not remove build.tmp & goto error)

ren build.log build.tmp
if exist build.log goto locked
if not exist build.tmp goto locked

ren build.tmp build.log
if exist build.tmp goto locked
if not exist build.log goto locked

goto build

:locked
echo Logfile locked
if exist build.tmp del build.tmp
goto error

:build

echo BEGIN: %DATE% %TIME%

set >buildenv.log

if exist qgsversion.h del qgsversion.h

if exist CMakeCache.txt goto skipcmake

echo CMAKE: %DATE% %TIME%
if errorlevel 1 goto error

rem -D CMAKE_CXX_FLAGS_RELEASE="/MD /MP /O2 /Ob2 /D NDEBUG" ^
rem -D CMAKE_CXX_FLAGS_DEBUG="/MDd /MP /Od /Ob0 /D DEBUG /D QGISDEBUG=1" ^
rem -D CMAKE_CXX_FLAGS_RELEASE="/MD /MP /O2 /Ob2 /DEBUG /INCREMENTAL /D QGISDEBUG=1" ^  
rem -D TEST_DATA_DIR=c:/Projects/EduGIS/EduGIS/tests/testdata ^
rem -D TEST_SERVER_URL=http://example.com ^

cmake %CMAKE_OPT% ^
  -D PEDANTIC=TRUE ^
  -D WITH_QSPATIALITE=TRUE ^
  -D WITH_SERVER=FALSE ^
  -D SERVER_SKIP_ECW=TRUE ^
  -D WITH_GLOBE=FALSE ^
  -D WITH_TOUCH=FALSE ^
  -D WITH_ORACLE=FALSE ^
  -D WITH_GRASS=FALSE ^
  -D WITH_CUSTOM_WIDGETS=TRUE ^
  -D CMAKE_CXX_FLAGS_RELEASE="/MD /MP /Od /Ob0" ^
  -D CMAKE_SHARED_LINKER_FLAGS="/INCREMENTAL /DEBUG" ^
  -D CMAKE_MODULE_LINKER_FLAGS="/INCREMENTAL /DEBUG" ^
  -D CMAKE_BUILD_TYPE=%BUILDCONF% ^
  -D CMAKE_CONFIGURATION_TYPES=%BUILDCONF% ^
  -D GEOS_LIBRARY=%O4W_ROOT%/lib/geos_c.lib ^
  -D SQLITE3_LIBRARY=%O4W_ROOT%/lib/sqlite3_i.lib ^
  -D SPATIALITE_LIBRARY=%O4W_ROOT%/lib/spatialite_i.lib ^
  -D PYTHON_EXECUTABLE=%O4W_ROOT%/bin/python.exe ^
  -D PYTHON_INCLUDE_PATH=%O4W_ROOT%/apps/Python27/include ^
  -D PYTHON_LIBRARY=%O4W_ROOT%/apps/Python27/libs/python27.lib ^
  -D QT_BINARY_DIR=%O4W_ROOT%/bin ^
  -D QT_LIBRARY_DIR=%O4W_ROOT%/lib ^
  -D QT_HEADERS_DIR=%O4W_ROOT%/include/qt4 ^
  -D QWT_INCLUDE_DIR=%O4W_ROOT%/include/qwt ^
  -D CMAKE_INSTALL_PREFIX=%O4W_ROOT%/apps/%PACKAGENAME% ^
  -D FCGI_INCLUDE_DIR=%O4W_ROOT%/include ^
  -D FCGI_LIBRARY=%O4W_ROOT%/lib/libfcgi.lib ^
  -D WITH_INTERNAL_JINJA2=FALSE ^
  -D WITH_INTERNAL_MARKUPSAFE=FALSE ^
  -D WITH_INTERNAL_PYGMENTS=FALSE ^
  -D WITH_INTERNAL_DATEUTIL=FALSE ^
  -D WITH_INTERNAL_PYTZ=FALSE ^
  %SRCDIR%
if errorlevel 1 (echo cmake failed & goto error)

:skipcmake
if exist noclean (echo skip clean & goto skipclean)
echo CLEAN: %DATE% %TIME%
cmake --build %BUILDDIR% --target clean --config %BUILDCONF%
if errorlevel 1 (echo clean failed & goto error)

:skipclean
echo ALL_BUILD: %DATE% %TIME%
cmake --build %BUILDDIR% --config %BUILDCONF%
if errorlevel 1 cmake --build %BUILDDIR% --config %BUILDCONF%
if errorlevel 1 (echo build failed twice & goto error)

if not exist ..\skiptests (
   echo RUN_TESTS: %DATE% %TIME%
   cmake --build %BUILDDIR% --target Experimental --config %BUILDCONF%
   if errorlevel 1 echo TESTS WERE NOT SUCCESSFUL.
)

set PKGDIR=%OSGEO4W_ROOT%\apps\%PACKAGENAME%

if exist %PKGDIR% (
  echo REMOVE: %DATE% %TIME%
  rmdir /s /q %PKGDIR%
)

echo INSTALL: %DATE% %TIME%
cmake --build %BUILDDIR% --target INSTALL --config %BUILDCONF%
if errorlevel 1 (echo INSTALL failed & goto error)

:package
echo PACKAGE: %DATE% %TIME%

cd ..
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' postinstall-common.bat >%OSGEO4W_ROOT%\etc\postinstall\\%PACKAGENAME%-common.bat
if errorlevel 1 (echo creation of common postinstall failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' postinstall-desktop.bat >%OSGEO4W_ROOT%\etc\postinstall\%PACKAGENAME%.bat
if errorlevel 1 (echo creation of desktop postinstall failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' preremove-desktop.bat >%OSGEO4W_ROOT%\etc\preremove\%PACKAGENAME%.bat
if errorlevel 1 (echo creation of desktop preremove failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' qgis.bat.tmpl >%OSGEO4W_ROOT%\bin\%PACKAGENAME%.bat.tmpl
if errorlevel 1 (echo creation of desktop template failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' designer-qgis.bat.tmpl >%OSGEO4W_ROOT%\bin\designer-%PACKAGENAME%.bat.tmpl
if errorlevel 1 (echo creation of designer template failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' browser.bat.tmpl >%OSGEO4W_ROOT%\bin\%PACKAGENAME%-browser.bat.tmpl
if errorlevel 1 (echo creation of browser template & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' qgis.reg.tmpl >%OSGEO4W_ROOT%\apps\%PACKAGENAME%\bin\qgis.reg.tmpl
if errorlevel 1 (echo creation of registry template & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' postinstall-server.bat >%OSGEO4W_ROOT%\etc\postinstall\%PACKAGENAME%-server.bat
if errorlevel 1 (echo creation of server postinstall failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' preremove-server.bat >%OSGEO4W_ROOT%\etc\preremove\%PACKAGENAME%-server.bat
if not exist %OSGEO4W_ROOT%\httpd.d mkdir %OSGEO4W_ROOT%\httpd.d
if errorlevel 1 (echo creation of server preremove failed & goto error)
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' httpd.conf.tmpl >%OSGEO4W_ROOT%\httpd.d\httpd_%PACKAGENAME%.conf.tmpl

touch exclude

for %%i in ("" "-common" "-devel") do (
  if not exist %ARCH%\release\qgis\%PACKAGENAME%%%i mkdir %ARCH%\release\qgis\%PACKAGENAME%%%i
)

tar -C %OSGEO4W_ROOT% -cjf %ARCH%/release/qgis/%PACKAGENAME%-common/%PACKAGENAME%-common-%VERSION%-%PACKAGE%.tar.bz2 ^
  --exclude-from exclude ^
  --exclude "*.pyc" ^
  "apps/%PACKAGENAME%/bin/qgispython.dll" ^
  "apps/%PACKAGENAME%/bin/qgis_analysis.dll" ^
  "apps/%PACKAGENAME%/bin/qgis_networkanalysis.dll" ^
  "apps/%PACKAGENAME%/bin/qgis_core.dll" ^
  "apps/%PACKAGENAME%/bin/qgis_gui.dll" ^
  "apps/%PACKAGENAME%/doc/" ^
  "apps/%PACKAGENAME%/plugins/delimitedtextprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/gdalprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/gpxprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/memoryprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/mssqlprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/ogrprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/owsprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/postgresprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/spatialiteprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/wcsprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/wfsprovider.dll" ^
  "apps/%PACKAGENAME%/plugins/wmsprovider.dll" ^
  "apps/%PACKAGENAME%/resources/qgis.db" ^
  "apps/%PACKAGENAME%/resources/spatialite.db" ^
  "apps/%PACKAGENAME%/resources/srs.db" ^
  "apps/%PACKAGENAME%/resources/symbology-ng-style.db" ^
  "apps/%PACKAGENAME%/resources/cpt-city-qgis-min/" ^
  "apps/%PACKAGENAME%/svg/" ^
  "apps/%PACKAGENAME%/crssync.exe" ^
  "etc/postinstall/%PACKAGENAME%-common.bat"
if errorlevel 1 (echo tar common failed & goto error)

move %PKGDIR%\bin\qgis.exe %OSGEO4W_ROOT%\bin\%PACKAGENAME%-bin.exe
if errorlevel 1 (echo move of desktop executable failed & goto error)
move %PKGDIR%\bin\qbrowser.exe %OSGEO4W_ROOT%\bin\%PACKAGENAME%-browser-bin.exe
if errorlevel 1 (echo move of browser executable failed & goto error)

if not exist %PKGDIR%\qtplugins\sqldrivers mkdir %PKGDIR%\qtplugins\sqldrivers
move %OSGEO4W_ROOT%\apps\qt4\plugins\sqldrivers\qsqlspatialite.dll %PKGDIR%\qtplugins\sqldrivers
if errorlevel 1 (echo move of spatialite sqldriver failed & goto error)

if not exist %PKGDIR%\qtplugins\designer mkdir %PKGDIR%\qtplugins\designer
move %OSGEO4W_ROOT%\apps\qt4\plugins\designer\qgis_customwidgets.dll %PKGDIR%\qtplugins\designer
if errorlevel 1 (echo move of customwidgets failed & goto error)

if not exist %PKGDIR%\python\PyQt4\uic\widget-plugins mkdir %PKGDIR%\python\PyQt4\uic\widget-plugins
move %OSGEO4W_ROOT%\apps\Python27\Lib\site-packages\PyQt4\uic\widget-plugins\qgis_customwidgets.py %PKGDIR%\python\PyQt4\uic\widget-plugins
if errorlevel 1 (echo move of customwidgets binding failed & goto error)

if not exist %ARCH%\release\qgis\%PACKAGENAME% mkdir %ARCH%\release\qgis\%PACKAGENAME%
tar -C %OSGEO4W_ROOT% -cjf %ARCH%/release/qgis/%PACKAGENAME%/%PACKAGENAME%-%VERSION%-%PACKAGE%.tar.bz2 ^
  --exclude-from exclude ^
  --exclude "*.pyc" ^
  "bin/%PACKAGENAME%-browser-bin.exe" ^
  "bin/%PACKAGENAME%-bin.exe" ^
  "apps/%PACKAGENAME%/bin/qgis.reg.tmpl" ^
  "apps/%PACKAGENAME%/i18n/" ^
  "apps/%PACKAGENAME%/icons/" ^
  "apps/%PACKAGENAME%/images/" ^
  "apps/%PACKAGENAME%/plugins/coordinatecaptureplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/dxf2shpconverterplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/evis.dll" ^
  "apps/%PACKAGENAME%/plugins/georefplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/gpsimporterplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/heatmapplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/interpolationplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/offlineeditingplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/oracleplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/rasterterrainplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/roadgraphplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/spatialqueryplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/spitplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/topolplugin.dll" ^
  "apps/%PACKAGENAME%/plugins/zonalstatisticsplugin.dll" ^
  "apps/%PACKAGENAME%/qgis_help.exe" ^
  "apps/%PACKAGENAME%/qtplugins/sqldrivers/qsqlspatialite.dll" ^
  "apps/%PACKAGENAME%/qtplugins/designer/" ^
  "apps/%PACKAGENAME%/python/" ^
  "apps/%PACKAGENAME%/resources/customization.xml" ^
  "bin/%PACKAGENAME%.bat.tmpl" ^
  "bin/%PACKAGENAME%-browser.bat.tmpl" ^
  "etc/postinstall/%PACKAGENAME%.bat" ^
  "etc/preremove/%PACKAGENAME%.bat"
if errorlevel 1 (echo tar desktop failed & goto error)

tar -C %OSGEO4W_ROOT% -cjf %ARCH%/release/qgis/%PACKAGENAME%-devel/%PACKAGENAME%-devel-%VERSION%-%PACKAGE%.tar.bz2 ^
  --exclude-from exclude ^
  --exclude "*.pyc" ^
  "apps/%PACKAGENAME%/FindQGIS.cmake" ^
  "apps/%PACKAGENAME%/include/" ^
  "apps/%PACKAGENAME%/lib/"
if errorlevel 1 (echo tar devel failed & goto error)

goto end

:usage
echo usage: %0 version package packagename arch
echo sample: %0 2.0.1 3 qgis x86
exit

:error
echo BUILD ERROR %ERRORLEVEL%: %DATE% %TIME%
for %%i in ("" "-common" "-server" "-devel") do (
  if exist %ARCH%\release\qgis\%PACKAGENAME%%%i\%PACKAGENAME%%%i-%VERSION%-%PACKAGE%.tar.bz2 del %ARCH%\release\qgis\%PACKAGENAME%%%i\%PACKAGENAME%%%i-%VERSION%-%PACKAGE%.tar.bz2
)

:end
echo FINISHED: %DATE% %TIME% >>%LOG% 2>&1
