#!/bin/bash
MODULE_NAME="leafwiki"
VERSION="0.10.2-custom"
BUILD_DIR="releases_dist"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 待编译的平台列表：OS/ARCH
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "windows/amd64"
    "darwin/amd64"
    "darwin/arm64"
)

echo "开始编译全套 Releases 版本: $VERSION..."

for PLATFORM in "${PLATFORMS[@]}"; do
    IFS="/" read -r -a arr <<< "$PLATFORM"
    GOOS="${arr[0]}"
    GOARCH="${arr[1]}"

    OUTPUT_NAME="${MODULE_NAME}-${VERSION}-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="${OUTPUT_NAME}.exe"
    fi

    echo "正在编译 -> OS: $GOOS, ARCH: $GOARCH..."

    # 执行 Go 编译 (根据 leafwiki 实际入口调整路径，通常是 main.go 所在目录)
    # CGO_ENABLED=0 确保静态链接，避免目标机器缺少 glibc 报错
    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" -o "${BUILD_DIR}/${OUTPUT_NAME}" ./cmd/leafwiki

    # 顺便打包成 tar.gz 或 zip
    cd $BUILD_DIR
    if [ "$GOOS" = "windows" ]; then
        zip "${OUTPUT_NAME}.zip" "${OUTPUT_NAME}" && rm "${OUTPUT_NAME}"
    else
        tar -czf "${OUTPUT_NAME}.tar.gz" "${OUTPUT_NAME}" && rm "${OUTPUT_NAME}"
    fi
    cd ..
done

echo "所有平台编译完成，文件保存在 ./${BUILD_DIR} 目录中。"
