# todo: Move to build.rs

# Compile the Rust code and produce an ar archive.
printf "=> Compiling Rust code...\n"
cargo lipo --allow-run-on-non-macos || exit 1
printf "=> Finished compiling Rust code.\n"

# Move to the output directory.
cd target/aarch64-apple-ios/debug
unlink ./libcleo.dylib

# Convert the ar archive to a dylib.
printf "=> Converting to .dylib... "
{/home/squ1dd13/Documents/Projects/iOS-Toolchain/alternative/ios-arm64e-clang-toolchain/bin/clang -fpic -shared -Wl,-all_load ./libcleo.a -o ./libcleo.dylib -B/home/squ1dd13/Documents/Projects/iOS-Toolchain/alternative/ios-arm64e-clang-toolchain/bin -isysroot /home/squ1dd13/Documents/Projects/iOS-Toolchain/SDK/iPhoneOS.sdk -target arm64-apple-darwin -I/home/squ1dd13/Documents/Projects/iOS-Toolchain/SDK/iPhoneOS.sdk/usr/include -I/home/squ1dd13/Documents/Projects/iOS-Toolchain/SDK/iPhoneOS.sdk/usr/include/c++/4.2.1 -arch arm64 -framework CoreFoundation -framework Security 2>&1 || exit 1 } | grep -v "hides a non-existent symbol"
printf "done.\n"

# Fakesign the dylib.
printf "=> Fakesigning .dylib... "
ldid -S ./libcleo.dylib || exit 1
printf "done.\n"

if [[ $* == *--package* ]]; then
    # Build the .deb structure.
    rm -r ./deb-archive
    mkdir -p ./deb-archive/Library/MobileSubstrate/DynamicLibraries
    mkdir ./deb-archive/DEBIAN

    # Copy in the files.
    cp "../../../deb/control" "./deb-archive/DEBIAN/control"
    cp "../../../deb/CLEO.plist" "./deb-archive/Library/MobileSubstrate/DynamicLibraries/CLEO.plist"
    cp "./libcleo.dylib" "./deb-archive/Library/MobileSubstrate/DynamicLibraries/CLEO.dylib"

    # Create a .deb archive.
    unlink ../../../deb/CLEO.deb
    dpkg-deb -Z gzip -b ./deb-archive ../../../deb/CLEO.deb

    scp "../../../deb/CLEO.deb" root@$1:/User/Downloads/CLEO.deb
    ssh root@$1 'exec $SHELL -l -c "dpkg -i /User/Downloads/CLEO.deb && (killall -9 gta3sa || echo \"GTA:SA not running\")"'
else
    # Send the dylib to the device.
    printf "=> Installing... "
    (scp ./libcleo.dylib root@$1:/Library/MobileSubstrate/DynamicLibraries/CLEO.dylib >/dev/null) || exit 1
    printf "done.\n"
fi
