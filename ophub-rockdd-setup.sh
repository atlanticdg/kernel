#!/bin/bash
# ============================================================
# ophub 内核编译补丁脚本 - 为 rk3399-rockdd 添加自定义 DTS
# 在 ophub/kernel 的内核编译工作流中调用此脚本
# ============================================================

set -e

KERNEL_DIR="${1:-/builder/linux}"
BOARD="rk3399-rockdd"
DTS_DIR="${KERNEL_DIR}/arch/arm64/boot/dts/rockchip"
MAKEFILE="${DTS_DIR}/Makefile"

echo "=== 添加 rk3399-rockdd DTS 到内核源码 ==="

# 1. 创建 DTS 文件（从 GitHub 下载或使用内联内容）
if [ ! -f "${DTS_DIR}/rk3399-rockdd.dts" ]; then
    echo "下载 rk3399-rockdd.dts ..."
    wget -q -O "${DTS_DIR}/rk3399-rockdd.dts" \
      "https://raw.githubusercontent.com/atlanticdg/u-boot-rock/main/dts/upstream/src/arm64/rockchip/rk3399-rockdd.dts"

    # 内核 DTS 需要 #include "rk3399-opp.dtsi"（内核中有此文件）
    # U-Boot upstream 不需要，但内核需要
    if ! grep -q "rk3399-opp.dtsi" "${DTS_DIR}/rk3399-rockdd.dts"; then
        sed -i '/#include "rk3399.dtsi"/a #include "rk3399-opp.dtsi"' \
          "${DTS_DIR}/rk3399-rockdd.dts"
    fi
    echo "DTS 文件已创建"
else
    echo "DTS 文件已存在，跳过"
fi

# 2. 在内核 Makefile 中注册 DTS
if ! grep -q "rk3399-rockdd.dtb" "${MAKEFILE}"; then
    echo "注册 DTS 到 Makefile ..."
    # 找到 rk3399 开头的 dtb 行，在其后添加
    sed -i '/dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3399-rock-pi-4a.dtb/a\dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3399-rockdd.dtb' \
      "${MAKEFILE}"
    echo "Makefile 已更新"
else
    echo "Makefile 已包含 rockdd，跳过"
fi

# 3. 验证
echo ""
echo "=== 验证 ==="
echo "DTS 文件:"
ls -la "${DTS_DIR}/rk3399-rockdd.dts"
echo ""
echo "Makefile 注册:"
grep "rockdd" "${MAKEFILE}"
echo ""
echo "=== DTS 补丁完成 ==="
