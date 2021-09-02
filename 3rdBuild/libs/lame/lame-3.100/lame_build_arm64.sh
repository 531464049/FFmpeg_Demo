./configure \
--disable-shared \
--disable-frontend \
--host=arm-apple-darwin \
--prefix= "./thin/arm64" \
CC="xcrun -sdk iphoneos clang -arch arm64" \
CFLAGS="-arch arm64 -fembed-bitcode -miphoneos-version-min=9.0" \
LDFLAGS="-arch arm64 -fembed-bitcode -miphoneos-version-min=9.0" 
make clean
make -j8
make install