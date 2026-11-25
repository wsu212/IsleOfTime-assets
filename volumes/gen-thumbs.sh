#!/bin/bash
# 掃描 volumes/ 下所有全尺寸 PNG，為缺少 256x256 縮圖的檔案補上 thumb/<name>.png
# 用法：./gen-thumbs.sh
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p thumb

made=0
for f in *.png; do
    [ -e "$f" ] || continue          # 沒有 png 時跳過
    if [ ! -e "thumb/$f" ]; then
        sips -z 256 256 "$f" --out "thumb/$f" >/dev/null 2>&1
        echo "✓ thumb/$f"
        made=$((made + 1))
    fi
done

if [ "$made" -eq 0 ]; then
    echo "全部對齊，無缺。"
else
    echo "已補 $made 張 thumb。"
fi
