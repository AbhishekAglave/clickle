#!/bin/sh
# Regenerates icon/AppIcon.icns from make-icon.swift. Only needed after changing the icon design.
set -e
cd "$(dirname "$0")"

swift make-icon.swift icon-1024.png

rm -rf AppIcon.iconset
mkdir AppIcon.iconset
for s in 16 32 128 256 512; do
	sips -z $s $s icon-1024.png --out "AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
	sips -z $((s * 2)) $((s * 2)) icon-1024.png --out "AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns AppIcon.iconset -o AppIcon.icns
rm -rf AppIcon.iconset
echo "Built icon/AppIcon.icns"
