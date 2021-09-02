#!/bin/sh

SOURCE="x264-master"
FAT="fat-x264"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

ARCHS="arm64 armv7"

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-shared"

CWD=`pwd`
for ARCH in $ARCHS
do
    echo "building $ARCH..."
    mkdir -p "$SCRATCH/$ARCH"
    cd "$SCRATCH/$ARCH"

    CC="xcrun -sdk iphoneos clang"
    if [ "$ARCH" = "arm64" ]
	then
		AS="gas-preprocessor.pl -arch aarch64 -- $CC"
        HOST=aarch64-apple-darwin
	else
		AS="gas-preprocessor.pl -arch arm -- $CC"
        HOST=arm-apple-darwin
	fi

    export AS
    export CC
    TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        --host=$HOST \
        --extra-cflags="-arch $ARCH -mios-version-min=9.0 -fembed-bitcode" \
        --extra-asflags="-arch $ARCH -mios-version-min=9.0 -fembed-bitcode" \
        --extra-ldflags="-arch $ARCH -mios-version-min=9.0 -fembed-bitcode" \
        --prefix="$THIN/$ARCH"

    make -j8 
    make install
    # if [ "$ARCH" = "arm64" ]
    # then
    #     export AS="gas-preprocessor.pl -arch aarch64 -- xcrun -sdk iphoneos clang"
    #     export CC="xcrun -sdk iphoneos clang"
        # TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        #     --enable-static \
        #     --enable-pic \
        #     --disable-shared \
        #     --host=aarch64-apple-darwin \
        #     --extra-cflags="-arch arm64 -mios-version-min=9.0 -fembed-bitcode" \
        #     --extra-asflags="-arch arm64 -mios-version-min=9.0 -fembed-bitcode" \
        #     --extra-ldflags="-arch arm64 -mios-version-min=9.0 -fembed-bitcode" \
        #     --prefix="$THIN/$ARCH"
    #     make -j8 
    #     make install
    # else
    #     export AS="gas-preprocessor.pl -arch arm -- xcrun -sdk iphoneos clang"
    #     export CC="xcrun -sdk iphoneos clang"
    #     TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
    #         --enable-static \
    #         --enable-pic \
    #         --disable-shared \
    #         --host=arm-apple-darwin \
    #         --extra-cflags="-arch armv7 -mios-version-min=9.0  -fembed-bitcode" \
    #         --extra-asflags="-arch armv7 -mios-version-min=9.0  -fembed-bitcode" \
    #         --extra-ldflags="-arch armv7 -mios-version-min=9.0  -fembed-bitcode" \
    #         --prefix="$THIN/$ARCH" 
    #     make -j8 
    #     make install
    # fi
    cd $CWD
done

echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`
cd $THIN/$1/lib
for LIB in *.a
do
    cd $CWD
    echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
    lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
done

cd $CWD
cp -rf $THIN/$1/include $FAT

echo Done
