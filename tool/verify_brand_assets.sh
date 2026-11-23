#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Launcher/logo validation failed: $1" >&2
  exit 1
}

verify_sha() {
  local expected="$1"
  local file="$2"
  [[ -f "$file" ]] || fail "Missing file: $file"
  local actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || fail "Wrong image in $file (expected $expected, got $actual)"
}

manifest="android/app/src/main/AndroidManifest.xml"
grep -Fq 'android:icon="@mipmap/ic_launcher_v2"' "$manifest" || fail "Manifest icon resource is not ic_launcher_v2"
grep -Fq 'android:roundIcon="@mipmap/ic_launcher_v2_round"' "$manifest" || fail "Manifest round icon resource is not ic_launcher_v2_round"

verify_sha "38051ab7e358583cfead72fa464e36d6cd25fa1c5e242f55667e984135eb74f6" "assets/images/islamic_app_logo.webp"
verify_sha "62b7201390c31ec915adff6dd4851319f3c8da06d5f55fc683cf3ec2a6c69739" "android/app/src/main/res/drawable-nodpi/ic_launcher_v2_foreground.webp"

declare -A icon_hashes=(
  [mdpi]="65033fc6e25dd6e6a2f398d07db4ec0a9441c0ec31b6ac2bec3a338c2d85fc5f"
  [hdpi]="fa79a0b3987581574cdb01cdc555fc0c7d5966b5118b518bc15a8401fd96eb12"
  [xhdpi]="4340d06afec05a72b013d801d403362774464e7e84b5a36c05c657efc33ffdc9"
  [xxhdpi]="35f08666f50bf4e544f5cf5c950ac08dc51f1737f9d089ade3dfca50a654e549"
  [xxxhdpi]="2e098c7f3e96567b7e54e23c01a66cfc8748b322d2c8468bf17bd0acce732722"
)

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  expected="${icon_hashes[$density]}"
  verify_sha "$expected" "android/app/src/main/res/mipmap-$density/ic_launcher_v2.webp"
  verify_sha "$expected" "android/app/src/main/res/mipmap-$density/ic_launcher_v2_round.webp"
done

adaptive="android/app/src/main/res/mipmap-anydpi-v26"
[[ -f "$adaptive/ic_launcher_v2.xml" ]] || fail "Missing adaptive launcher icon XML"
[[ -f "$adaptive/ic_launcher_v2_round.xml" ]] || fail "Missing round adaptive launcher icon XML"
grep -Fq '@drawable/ic_launcher_v2_foreground' "$adaptive/ic_launcher_v2.xml" || fail "Adaptive icon does not use the expected foreground"
grep -Fq '@color/ic_launcher_v2_background' "$adaptive/ic_launcher_v2.xml" || fail "Adaptive icon does not use the expected background"
grep -Fq '#003C36' "android/app/src/main/res/values/ic_launcher_v2_background.xml" || fail "Adaptive icon background does not match the master logo palette"

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  [[ ! -f "android/app/src/main/res/drawable-$density/ic_launcher_v2_foreground.webp" ]] || fail "Old density foreground still overrides drawable-nodpi: $density"
done

grep -Fq "assets/images/islamic_app_logo.webp" "lib/shared/widgets/islamic_logo_widget.dart" || fail "In-app logo widget does not use the master logo asset"
grep -Fq "version: 1.0.3+4" "pubspec.yaml" || fail "App version was not incremented for logo update"

echo "Brand assets verified: master logo, five launcher densities, adaptive icon, manifest, and version."
