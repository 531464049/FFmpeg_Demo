#!/bin/sh

CONFIGURE_FLAGS="--enable-static --with-pic=yes --disable-shared"

ARCHS="arm64 armv7"

# directories
SOURCE="fdk-aac-2.0.2"
FAT="fdk-aac-ios"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

COMPILE="y"
LIPO="y"

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			HOST="--host=x86_64-apple-darwin"
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ $ARCH = arm64 ]
		    then
		        HOST="--host=aarch64-apple-darwin"
                    else
		        HOST="--host=arm-apple-darwin"
	            fi
		    CFLAGS="$CFLAGS -fembed-bitcode"
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -Wno-error=unused-command-line-argument-hard-error-in-future"
		AS="gas-preprocessor.pl $CC"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		$CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
		    $HOST \
		    CC="$CC" \
		    CXX="$CC" \
		    CPP="$CC -E" \
                    AS="$AS" \
		    CFLAGS="$CFLAGS" \
		    LDFLAGS="$LDFLAGS" \
		    CPPFLAGS="$CFLAGS" \
		    --prefix="$THIN/$ARCH" || exit 1

		make -j8 install || exit 1
		cd $CWD
	done
fi

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