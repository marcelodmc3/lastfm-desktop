#!/bin/bash
# Author: Jono Cole <jono@last.fm>
#
# A tool for distributing Mac OSX bundles.
#
# Finds and copies dependant frameworks and local dylibs 
# not installed on stardard systems.
# Also ensures that all binaries have the correct paths 
# installed relative to the bundle's @executable_path

function deposx {
    otool -L $1 | sed -n '/\/opt.*/ s/^[^\/]*\([^(]*\) ([^)]*)/\1/p'
}

function getBundleBin {
    if echo $1|grep -q framework; then
        echo $1/`cat $1/Contents/Info.plist | sed -n '/CFBundleExecutable<\/key>/,/<\/string>/ s/.*<string>\(.*\)<.*/\1/p'|sed s/_debug//`
    else
        echo $1/Contents/MacOS/`cat $1/Contents/Info.plist | sed -n '/CFBundleExecutable<\/key>/,/<\/string>/ s/.*<string>\(.*\)<.*/\1/p'`
    fi
}

function fixFrameworks {
    echo -n F
    if [ -d $1 ]; then
        local bin=`getBundleBin $1`
    else
        local bin=$1
    fi

    # echo Fixing Frameworks for $bin

    libs=`otool -L $bin|sed -n '/\/opt.*/ s/^[^\/]*\([^(]*\) [^(]*([^)]*)/\1/p'`
    
    mkdir -p $bundlePath/Contents/Frameworks

    local lib
    for lib in $libs; do
        #ignore non-frameworks
        if echo $lib | grep -vq framework; then continue; fi

        #examples for /opt/qt/lib/QtXml.framework/Contents/QtXml

        #framework=/opt/qt/qt.git/lib/QtXml.framework
        framework=`echo $lib |sed -n 's/\(\.framework\).*/\1/p'`
        
        #frameworkLib=/Contents/QtXml
        frameworkLib=`echo $lib |sed -n 's/^.*\.framework//p'`

        #frameworkName=QtXml.framework
        frameworkName=`basename $framework`
        
        destFramework=$bundlePath/Contents/Frameworks/$frameworkName
        installFramework=@executable_path/../Frameworks/$frameworkName
        
        if [ `basename $lib` == `basename $bin` ]; then continue; fi

        if [ ! -e $bundlePath/Contents/Frameworks/$frameworkName ]; then 
            #cp -Rf -P /opt/qt/qt.git/lib/QtXml.framework (app name.app)/Contents/Frameworks
            cp -Rf -P $framework $bundlePath/Contents/Frameworks
            #install_name_tool -id /opt/qt/qt.git/lib/QtXml.framework/Contents/QtXml
            install_name_tool -id $installFramework$frameworkLib $destFramework$frameworkLib
        fi
        #install_name_tool -change /opt/qt/qt.git/lib/QtXml.framework/Contents/QtXml @executable_path/../Frameworks/QtXml.framework/Contents/QtXml (bin)
        install_name_tool -change $lib $installFramework$frameworkLib $bin
        fixLocalLibs $destFramework
        fixFrameworks $destFramework
    done
}

function fixLocalLibs {
    echo -n L
    if [ -d $1 ]; then
        local bin=`getBundleBin $1`
    else
        local bin=$1
    fi
    #echo Fixing Local Lib for $bin

    local libs=`otool -L $bin | sed -n '/^[^\/]*$/ s/^[[:space:]]*\(.*\) (com.*/\1/p'`
    local extralibs=`otool -L $bin | sed -n '/\/opt.*/ s/^[^\/]*\([^(]*\) [^(]*([^)]*)/\1/p'|grep -v framework`
    local libs="$libs $extralibs"
    local lib
    local cpPath
    for lib in $libs; do
        #echo for lib $lib in libs
        local libPath=$lib
        if [ ! -e $lib ]; then
            cpPath=`locateLib $lib`
        else
            cpPath=$lib
        fi
        lib=`basename $lib`
        cp -rf $cpPath $bundlePath/Contents/MacOS
        install_name_tool -id @executable_path/$lib $bundlePath/Contents/MacOS/$lib
        install_name_tool -change $libPath @executable_path/$lib $bin
        
        fixFrameworks $bundlePath/Contents/MacOS/$lib
        fixLocalLibs $bundlePath/Contents/MacOS/$lib
    done
}

function locateLib {
    for p in {$rootdir,/opt/local/lib}; do
        if [ -e $p/$1 ]; then
            echo $p/$1
            return 0
        fi
    done
    return 1
}

bundlePath=$1
rootdir=`dirname $1`
binPath=$bundlePath/Contents/MacOS

echo =========== Fix Local Libs ==============
fixLocalLibs $bundlePath
echo

echo =========== Fix Frameworks ==============
fixFrameworks $bundlePath
echo

echo ======= Copying image plugins ===========
mkdir -p $bundlePath/Contents/plugins

plugins="imageformats phonon_backend"

for plugin in $plugins; do
    cp -R -P /Developer/Applications/Qt/plugins/$plugin $bundlePath/Contents/plugins
    for i in $bundlePath/Contents/plugins/$plugin/*; do
        fixFrameworks $i
        echo -n P
    done
    echo
done


qtconf=$bundlePath/Contents/Resources/qt.conf
echo [Paths] > $qtconf
echo Plugins = plugins >> $qtconf