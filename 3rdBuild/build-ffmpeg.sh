#!/bin/sh

# directories
FF_VERSION="4.3.1"
#FF_VERSION="snapshot-git"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
FAT="FFmpeg-iOS"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

CONFIGURE_FLAGS="--enable-gpl --disable-shared --disable-stripping --disable-ffmpeg --disable-ffplay  --disable-ffprobe --disable-avdevice --disable-indevs --disable-filters --disable-devices --disable-parsers --disable-postproc --disable-debug --disable-asm --disable-yasm --disable-doc --disable-bsfs --disable-muxers --disable-demuxers --disable-ffplay --disable-ffprobe  --disable-indevs --disable-outdevs --enable-cross-compile --enable-filter=aresample --enable-bsf=aac_adtstoasc --enable-small --enable-dct --enable-dwt --enable-lsp --enable-mdct --enable-rdft --enable-fft --enable-static --enable-version3 --enable-nonfree --disable-encoders --enable-encoder=pcm_s16le --enable-encoder=aac --enable-encoder=mp2 --disable-decoders --enable-decoder=aac --enable-decoder=mp3 --enable-decoder=h264 --enable-decoder=pcm_s16le --disable-parsers --enable-parser=aac --enable-parser=mpeg4video --enable-parser=mpegvideo --enable-parser=mpegaudio --enable-parser=aac --disable-muxers --enable-muxer=flv --enable-muxer=mp4 --enable-muxer=wav --enable-muxer=adts --disable-demuxers --enable-demuxer=flv --enable-demuxer=mpegvideo --enable-demuxer=mpegtsraw --enable-demuxer=mpegts --enable-demuxer=mpegps --enable-demuxer=h264 --enable-demuxer=y4m --enable-demuxer=wav --enable-demuxer=aac --enable-demuxer=hls --enable-demuxer=mov --enable-demuxer=m4v --disable-protocols --enable-protocol=rtmp --enable-protocol=http --enable-protocol=file "
# CONFIGURE_FLAGS="--disable-shared \
# --enable-static \
# --disable-stripping \
# --disable-ffmpeg \
# --disable-ffplay \
# --disable-ffprobe \
# --disable-avdevice \
# --disable-devices \
# --disable-indevs \
# --disable-outdevs \
# --disable-debug \
# --disable-asm \
# --disable-yasm \
# --disable-doc \
# --enable-small \
# --enable-dct \
# --enable-dwt \
# --enable-lsp \
# --enable-mdct \
# --enable-rdft \
# --enable-fft \
# --enable-version3 \
# --enable-nonfree \
# --disable-filters \
# --disable-postproc \
# --disable-bsfs \
# --enable-bsf=aac_adtstoasc \
# --enable-bsf=h264_mp4toannexb \
# --disable-encoders \
# --enable-encoder=rawvideo \
# --enable-encoder=pcm_s16le \
# --enable-encoder=aac \
# --enable-encoder=libvo_aacenc \
# --disable-decoders \
# --enable-decoder=aac \
# --enable-decoder=mp3 \
# --enable-decoder=pcm_s16le \
# --disable-parsers \
# --enable-parser=aac \
# --disable-muxers \
# --enable-muxer=flv \
# --enable-muxer=mp4 \
# --enable-muxer=wav \
# --enable-muxer=adts \
# --enable-muxer=rawvideo
# --disable-demuxers \
# --enable-demuxer=flv \
# --enable-demuxer=mp4 \
# --enable-demuxer=wav \
# --enable-demuxer=aac \
# --disable-protocols \
# --enable-protocol=rtmp \
# --enable-protocol=file \
# --enable-cross-compile
# "


ARCHS="arm64 armv7"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="9.0"


if [ "$COMPILE" ]
then
	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		
		CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		CC="xcrun -sdk iphoneos clang"

		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="gas-preprocessor.pl -- $CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make clean
		make -j8
		make install
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
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo Done


