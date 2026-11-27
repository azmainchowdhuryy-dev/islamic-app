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
grep -Fq 'android:icon="@mipmap/ic_launcher_v3"' "$manifest" || fail "Manifest icon resource is not ic_launcher_v3"
grep -Fq 'android:roundIcon="@mipmap/ic_launcher_v3_round"' "$manifest" || fail "Manifest round icon resource is not ic_launcher_v3_round"

# This SHA-256 is derived from the original circular navy mosque logo uploaded by the user.
verify_sha "dca2ce0e3e3949be8e04a9f9c645804add33c87cf64770bae6532b91e850cece" "assets/images/islamic_app_logo.webp"
verify_sha "1a3c9570453f1795b4554b3438bff6828c6831ebf5ff5fb58f9eb03c37cc9963" "android/app/src/main/res/drawable-nodpi/ic_launcher_v3_foreground.webp"

declare -A icon_hashes=(
  [mdpi]="3a7f61778b1e5806caeec261775ed6791458e360a60c4da48bd54dbb76cff560"
  [hdpi]="f0e5e171c5218415c97f30eed70769166b4c45ca342e60f163b7a96819943a9d"
  [xhdpi]="a23955d505679ad2bdfafe1f0291aed9c2493fa5d401adb817821094224d4802"
  [xxhdpi]="cae7598d9b6fd9533349f835276e03fa902566fada14560c304b2f98733674a8"
  [xxxhdpi]="60e2ae15715dc1e5bae243350d0904cec953fc5e28ee2ab4c5bb80e69411f6f4"
)

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  expected="${icon_hashes[$density]}"
  verify_sha "$expected" "android/app/src/main/res/mipmap-$density/ic_launcher_v3.webp"
  verify_sha "$expected" "android/app/src/main/res/mipmap-$density/ic_launcher_v3_round.webp"
done

adaptive="android/app/src/main/res/mipmap-anydpi-v26"
[[ -f "$adaptive/ic_launcher_v3.xml" ]] || fail "Missing adaptive launcher icon XML"
[[ -f "$adaptive/ic_launcher_v3_round.xml" ]] || fail "Missing round adaptive launcher icon XML"
grep -Fq '@drawable/ic_launcher_v3_foreground' "$adaptive/ic_launcher_v3.xml" || fail "Adaptive icon does not use the original-logo foreground"
grep -Fq '@color/ic_launcher_v3_background' "$adaptive/ic_launcher_v3.xml" || fail "Adaptive icon does not use the original-logo background"
grep -Fq '#071836' "android/app/src/main/res/values/ic_launcher_v3_background.xml" || fail "Adaptive icon background is not navy"

grep -Fq "assets/images/islamic_app_logo.webp" "lib/shared/widgets/islamic_logo_widget.dart" || fail "In-app logo widget does not use the original logo asset"
grep -Fq "version: 1.0.6+7" "pubspec.yaml" || fail "App version was not incremented for original-logo update"

echo "Brand assets verified: original circular navy logo, five launcher densities, adaptive and round icons, manifest, and app version."
