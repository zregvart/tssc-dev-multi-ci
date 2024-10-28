

echo "Copy scripts"  
cp -r /work/rhtap /out/rhtap 
mkdir -p /out/binaries
for binary in yq cosign ec syft
do
    echo "binary $binary"
    cp /usr/bin/$binary /out/binaries/$binary
    chmod +x /out/binaries/$binary
done