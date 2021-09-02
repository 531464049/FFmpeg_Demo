#!/bin/sh

CONFIGURE_FLAGS="--disable-shared --disable-frontend"

ARCHS="arm64 armv7"

# directories
SOURCE="lame-3.100"
FAT="fat-lame"

SCRATCH="scratch-lame"
# must be an absolute path
THIN=`pwd`/"thin-lame"

LIPO="y"

CWD=`pwd`
for ARCH in $ARCHS
do
	echo "building $ARCH..."
	mkdir -p "$SCRATCH/$ARCH"
	cd "$SCRATCH/$ARCH"

	if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
	then
		PLATFORM="iPhoneSimulator"
		if [ "$ARCH" = "x86_64" ]
		then
			SIMULATOR="-mios-simulator-version-min=9.0"
			HOST=x86_64-apple-darwin
		else
			SIMULATOR="-mios-simulator-version-min=9.0"
			HOST=i386-apple-darwin
		fi
	else
		PLATFORM="iPhoneOS"
		SIMULATOR="-miphoneos-version-min=9.0"
		HOST=arm-apple-darwin
	fi

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
	CFLAGS="-arch $ARCH $SIMULATOR -fembed-bitcode"
	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"

	CC=$CC $CWD/$SOURCE/configure \
		$CONFIGURE_FLAGS \
		--host=$HOST \
		--prefix="$THIN/$ARCH" \
		CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
	make clean
	make -j8
	make install
	cd $CWD
done


if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi