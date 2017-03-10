#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

pacman -Sy && pacman --noconfirm --needed -S mingw-w64-x86_64-jsoncpp mingw-w64-x86_64-cmake mingw-w64-x86_64-python3
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install tools!${NC}"
    exit 1
fi

git checkout origin/opencv3
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to checkout opencv3 branch!${NC}"
    exit 1
fi

if [ ! -d "opencv" ]; then
	opencv_ver=3.2.0
	git clone --depth=1 git://github.com/opencv/opencv -b ${opencv_ver} &&
	git clone --depth=1 git://github.com/opencv/opencv_contrib opencv/contrib -b ${opencv_ver}
	rc=$?
	if [ $rc != 0 ]; then
		echo -e "${RED}Failed to download opencv ${opencv_ver}!${NC}"
		exit 1
	fi
fi

vs_cfg="Visual Studio 14 2015 Win64"

if [ ! -d "opencv/build" ]; then
	mkdir -p opencv/build
	cd opencv/build
	cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DOPENCV_EXTRA_MODULES_PATH=../contrib/modules  -G "${vs_cfg}" ..
	rc=$?
	if [ $rc != 0 ]; then
		echo -e "${RED}Failed to generate build files for opencv ${opencv_ver}!${NC}"
		exit 1
	fi
else
    cd opencv/build
fi
Platform=x64 MSBuild.exe OpenCV.sln -t:build -p:Configuration=Release
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to build opencv ${opencv_ver}!${NC}"
    exit 1
fi
cd ../..

if [ !-d "build" ]; then
	mkdir -p build
	cd build
	cmake -DOpenCV_DIR=opencv/build -G "${vs_cfg}" ..
	rc=$?
	if [ $rc != 0 ]; then
		echo -e "${RED}Failed to generate build files for bgslibrary!${NC}"
		exit 1
	fi
else
    cd build
fi
Platform=x64 MSBuild.exe bgs.sln -t:build -p:Configuration=Release
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to build bgslibrary!${NC}"
    exit 1
fi

cd ..
cp opencv/3rdparty/ffmpeg/opencv_ffmpeg.dll build/Release/opencv_ffmpeg320.dll &&
cp opencv/3rdparty/ffmpeg/opencv_ffmpeg_64.dll build/Release/opencv_ffmpeg320_64.dll
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to copy opencv DLLs!${NC}"
    exit 1
fi