#!/usr/bin/env bash
# Installs the pinned mkcert version into .tools/bin/. mkcert publishes no
# checksums: the SHA-256 of each official v1.4.4 binary is pinned below.
# Does nothing if this version is already installed. cert@install runs it.
#
# @usage make cert@mkcert
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

MKCERT_VERSION=1.4.4
BIN_DIR=.tools/bin
RELEASES=https://github.com/FiloSottile/mkcert/releases/download

case "$(uname -s)" in
  Linux)                os=linux   exe=mkcert ;;
  Darwin)               os=darwin  exe=mkcert ;;
  MINGW*|MSYS*|CYGWIN*) os=windows exe=mkcert.exe ;;
  *) die "cert@mkcert : système non pris en charge ($(uname -s))" ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) die "cert@mkcert : processeur non pris en charge ($(uname -m))" ;;
esac

asset="mkcert-v${MKCERT_VERSION}-${os}-${arch}"
[ "$os" = windows ] && asset="$asset.exe"

case "$asset" in
  mkcert-v1.4.4-linux-amd64)       sha256=6d31c65b03972c6dc4a14ab429f2928300518b26503f58723e532d1b0a3bbb52 ;;
  mkcert-v1.4.4-linux-arm64)       sha256=b98f2cc69fd9147fe4d405d859c57504571adec0d3611c3eefd04107c7ac00d0 ;;
  mkcert-v1.4.4-darwin-amd64)      sha256=a32dfab51f1845d51e810db8e47dcf0e6b51ae3422426514bf5a2b8302e97d4e ;;
  mkcert-v1.4.4-darwin-arm64)      sha256=c8af0df44bce04359794dad8ea28d750437411d632748049d08644ffb66a60c6 ;;
  mkcert-v1.4.4-windows-amd64.exe) sha256=d2660b50a9ed59eada480750561c96abc2ed4c9a38c6a24d93e30e0977631398 ;;
  mkcert-v1.4.4-windows-arm64.exe) sha256=793747256c562622d40127c8080df26add2fb44c50906ce9db63b42a5280582e ;;
  *) die "cert@mkcert : pas d'empreinte connue pour $asset" ;;
esac

if [ -x "$BIN_DIR/$exe" ] \
  && [ "$("$BIN_DIR/$exe" -version 2>/dev/null)" = "v$MKCERT_VERSION" ]; then
  info "mkcert $MKCERT_VERSION déjà installé ($BIN_DIR/$exe)."
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run curl -sSfL -o "$tmp/$exe" "$RELEASES/v$MKCERT_VERSION/$asset"

[ "$(sha256sum "$tmp/$exe" | cut -d' ' -f1)" = "$sha256" ] \
  || die "cert@mkcert : empreinte SHA-256 invalide pour $asset, installation annulée"

mkdir -p "$BIN_DIR"
mv -f "$tmp/$exe" "$BIN_DIR/$exe"
chmod +x "$BIN_DIR/$exe"
info "mkcert $MKCERT_VERSION installé dans $BIN_DIR/ (empreinte vérifiée)."
