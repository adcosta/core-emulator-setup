#!/usr/bin/env bash
set -euo pipefail

: "${CORE_DIR:=/opt/core}"
: "${PROTOC_DIR:=/opt/protoc}"
: "${EMANE_DIR:=/opt/emane}"
: "${PREFIX:=/usr/local}"
: "${OSPF_DIR:=/opt/ospf-mdr}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ATENCAO: Executar como root (sudo $0)"; exit 1
fi

rm -rf "${CORE_DIR}" 
rm -rf "${PROTOC_DIR}" 
rm -rf "${EMANE_DIR}"
rm -rf "${OSPF_DIR}"

rm -rf ${PREFIX}/bin/core-cleanup
rm -rf ${PREFIX}/bin/core-cli
rm -rf ${PREFIX}/bin/core-daemon
rm -rf ${PREFIX}/bin/core-gui
rm -rf ${PREFIX}/bin/core-player
rm -rf ${PREFIX}/bin/core-python
rm -rf ${PREFIX}/bin/core-route-monitor
rm -rf ${PREFIX}/bin/core-service-update
rm -rf ${PREFIX}/bin/netns
rm -rf ${PREFIX}/bin/vcmd
rm -rf ${PREFIX}/bin/vnoded
rm -rf ${PREFIX}/bin/vtysh

rm -rf ${PREFIX}/etc/quagga

rm -rf ${PREFIX}/sbin/babeld
rm -rf ${PREFIX}/sbin/bgpd
rm -rf ${PREFIX}/sbin/ospf6d
rm -rf ${PREFIX}/sbin/ospfclient
rm -rf ${PREFIX}/sbin/ospfd
rm -rf ${PREFIX}/sbin/ripd
rm -rf ${PREFIX}/sbin/ripngd
rm -rf ${PREFIX}/sbin/watchquagga
rm -rf ${PREFIX}/sbin/xpimd
rm -rf ${PREFIX}/sbin/zebra

echo "Tudo removido..."
