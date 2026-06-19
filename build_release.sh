#!/bin/bash
# 遇到任何命令出错立即停止执行
set -e

MODULE_NAME="leafwiki"
VERSION="0.10.2-custom"
BUILD_DIR="releases_dist"

# ==== 1. 前端自动化打包与资源同步 ====
echo "正在构建前端静态资源..."
cd ui/leafwiki-ui
pnpm install
pnpm build
cd ../..

echo "正在同步前端产物到 Go embed 目录..."
rm -rf internal/http/dist
cp -r ui/leafwiki-ui/dist internal/http/

# ==== 2. 初始化构建目录 ====
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

# 核心注入参数：合并你原本的 -s -w 压缩，并强行开启前端内嵌
LDFLAGS="-s -w -X 'github.com/perber/wiki/internal/http.EmbedFrontend=true' -X 'github.com/perber/wiki/internal/http.Environment=production'"

echo "开始编译全套 满血版 Releases 版本: $VERSION..."

# 获取当前绝对路径，方便打包时准确定位
ROOT_DIR=$(pwd)

# ==== 3. 跨平台循环编译 ====
for PLATFORM in "${PLATFORMS[@]}"; do
    IFS="/" read -r -a arr <<< "$PLATFORM"
    GOOS="${arr[0]}"
    GOARCH="${arr[1]}"

    OUTPUT_NAME="${MODULE_NAME}-${VERSION}-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="${OUTPUT_NAME}.exe"
    fi

    echo "正在编译 -> OS: $GOOS, ARCH: $GOARCH..."

    # 执行 Go 编译，注入 LDFLAGS
    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="${LDFLAGS}" -o "${BUILD_DIR}/${OUTPUT_NAME}" ./cmd/leafwiki

    # 安全地进入构建目录打包，随后返回原目录
    cd "${ROOT_DIR}/${BUILD_DIR}"
    if [ "$GOOS" = "windows" ]; then
        zip -q "${OUTPUT_NAME}.zip" "${OUTPUT_NAME}" && rm "${OUTPUT_NAME}"
    else
        tar -czf "${OUTPUT_NAME}.tar.gz" "${OUTPUT_NAME}" && rm "${OUTPUT_NAME}"
    fi
    cd "${ROOT_DIR}"
done

echo "所有平台编译完成，文件保存在 ./${BUILD_DIR} 目录中。"
