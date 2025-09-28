#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Script de instalacao para Ubuntu 22.04 (Jammy) — CORE + EMANE
# Adaptado a partir da Dockerfile
# ============================================================

# ---------- Configuração ----------
: "${PREFIX:=/usr/local}"
: "${BASE_DIR:=/opt}"
: "${BASE_SRC_DIR:=/usr/local/src}"
: "${VENV_PATH:=/opt/core/venv}"               # venv do CORE
: "${CORE_DIR:=/opt/core}"
: "${CORE_REPO:=https://github.com/coreemu/core}"
: "${BRANCH:=master}"                          # branch do CORE (ex.: master)
: "${PROTOC_DIR:=/opt/protoc}"
: "${PROTOC_VERSION:=3.19.6}"                  # igual ao da Dockerfile
: "${EMANE_DIR:=/opt/emane}"
: "${EMANE_REPO:=https://github.com/adjacentlink/emane}"  # best-effort
: "${NONINTERACTIVE:=1}"

if [[ "${NONINTERACTIVE}" == "1" ]]; then
  export DEBIAN_FRONTEND=noninteractive
fi

# ---------- Verificações básicas ----------
. /etc/lsb-release

echo "----------------------------------------------------------"
echo "     DISTRIB_ID: ${DISTRIB_ID:-?}"
echo "DISTRIB_RELEASE: ${DISTRIB_RELEASE:-?}"

# testar se estamos na versao certa
if [[ "${DISTRIB_ID:-}" != "Ubuntu" || "${DISTRIB_RELEASE:-}" != "22.04" ]]; then
  echo "ATENCAO: Este script foi desenvolvido para Ubuntu 22.04 (Jammy). "
fi

# Detectar arquitetura com dpkg
dpkg_arch="$(dpkg --print-architecture)"
case "$dpkg_arch" in
  amd64) EMANE_ARCH="x86_64"; PROTOC_ZIP_ARCH="x86_64" ;;
  arm64) EMANE_ARCH="aarch_64"; PROTOC_ZIP_ARCH="aarch_64" ;;  # protoc usa "aarch_64" em alguns releases antigos
  *)     EMANE_ARCH="$dpkg_arch"; PROTOC_ZIP_ARCH="$dpkg_arch" ;;
esac

# Tentar adivinhar nome do zip (Ex: protoc-3.19.6-linux-x86_64.zip)
PROTOC_ZIP="protoc-${PROTOC_VERSION}-linux-${PROTOC_ZIP_ARCH}.zip"
PROTOC_URL="https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}"

echo "         PREFIX: ${PREFIX}"
echo "       BASE_DIR: ${BASE_DIR}"
echo "   BASE_SRC_DIR: ${BASE_SRC_DIR}"
echo "      VENV_PATH: ${VENV_PATH}"
echo "       CORE_DIR: ${CORE_DIR}"
echo "      CORE_REPO: ${CORE_REPO}"
echo "         BRANCH: ${BRANCH}"
echo " PROTOC_VERSION: ${PROTOC_VERSION}"
echo "    PROTOC_ARCH: ${PROTOC_ZIP_ARCH}"
echo "     PROTOC_ZIP: ${PROTOC_ZIP}"
echo "     PROTOC_URL: ${PROTOC_URL}"
echo "     PROTOC_DIR: ${PROTOC_DIR}"
echo "      EMANE_DIR: ${EMANE_DIR}"
echo "     EMANE_REPO: ${EMANE_REPO}"
echo "     EMANE_ARCH: ${EMANE_ARCH}"

echo "----------------------------------------------------------"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ATENCAO: Executar como root (sudo $0)"; exit 1
fi
# ---------- Diretórios ----------
mkdir -p "${BASE_SRC_DIR}" "${BASE_DIR}" 
chmod 755 "${BASE_DIR}"

# ---------- Pacotes de sistema (espelhando a Dockerfile) ----------
echo "[1/7] Instalar todos os pacotes de software do Ubuntu necessarios..."
sudo apt update
sudo apt install -y --no-install-recommends \
  build-essential gcc g++ make pkg-config autoconf automake libtool cmake \
  gawk git vim bash xterm dbus-x11 netsurf-gtk links2 \
  sntp ntp wget curl lynx net-tools traceroute tcptraceroute \
  ipcalc socat hping3 httpie whois ngrep \
  tcpdump wireshark tshark iperf iperf3 ethtool nftables iproute2 iputils-ping \
  mtr-tiny nmap netcat-openbsd arping iftop nload dillo \
  openssh-server openssh-client openssh-sftp-server \
  vsftpd atftp atftpd apache2 mini-httpd openvpn \
  isc-dhcp-server isc-dhcp-client \
  bind9 bind9-utils dnsutils inetutils-telnet \
  ca-certificates sudo tzdata software-properties-common unzip \
  protobuf-compiler libpcre3-dev libprotobuf-dev libxml2-dev \
  libpcap0.8 libpcap0.8-dev libreadline-dev \
  libsqlite3-0 libsqlite3-dev libssl-dev libev-dev uuid-dev \
  python3-dev python3-pip python3-venv python3-tk \
  libtk-img tk imagemagick python3-pythonmagick \
  libnl-3-dev libnl-route-3-dev libnl-genl-3-dev \
  libnl-nf-3-dev libnl-cli-3-dev \
  openvswitch-switch python3-openvswitch mininet

# (opcional) manter imagem/host mais limpo
apt-get autoremove -y
apt-get clean -y


# ---------- Clonar e instalar CORE ----------
echo "[2/7] Clonar o repositorio CORE (${BRANCH}) e instalar..."
if [[ -d ${CORE_DIR} ]]; then
  echo "  -- Diretoria ${CORE_DIR} já existe: atualizar..."
  cd ${CORE_DIR}
  if [[ ! -d "${CORE_DIR}/.git" ]]; then
    git init
    git remote add origin "${CORE_REPO}"
    git fetch --depth 1 origin ${BRANCH}
    git checkout -t origin/"${BRANCH}" 
  else
    git fetch --depth 1 origin "${BRANCH}"
    git checkout "${BRANCH}"
  fi
  git pull
else
  mkdir -p ${CORE_DIR}
  echo "  -- Clonar o repositorio CORE..."
  git clone --depth 1 --branch "${BRANCH}" "${CORE_REPO}" ${CORE_DIR}
  cd ${CORE_DIR}
fi

# ---------- Criar venv do CORE ----------
echo "[3/7] Criar virtual environment python em ${VENV_PATH}..."
# 3. Criar venv se não existir
if [[ ! -d "${VENV_PATH}" ]]; then
    echo "  -- Criar ${VENV_PATH}..."
    python3 -m venv "${VENV_PATH}"
    # pip mais recente e wheel
    "${VENV_PATH}/bin/pip" install --upgrade pip setuptools wheel
fi
"${VENV_PATH}/bin/python" -m pip install --upgrade pip wheel setuptools
"${VENV_PATH}/bin/python" -m pip install --upgrade invoke poetry
# eventualmente podem-se instalar mais pacotes python no venv 

echo "[3.1] Correr setup.sh do CORE..."
cd ${CORE_DIR}
chmod +x ./setup.sh
./setup.sh

echo "[3.2] Instalar CORE em ${PREFIX}... e testar... "
"${VENV_PATH}/bin/inv" install -v -p "${PREFIX}"
"${VENV_PATH}/bin/python" -c "import core,sys; print('OK ->', core.__file__, '\nPython:', sys.executable)"

# ---------- Protobuf 'protoc' (binário) ----------
echo "[4/7] Obter protoc ${PROTOC_VERSION}..."
cd "${BASE_DIR}"
mkdir -p "${PROTOC_DIR}"

set +e
curl -fsSL -o "/opt/${PROTOC_ZIP}" "${PROTOC_URL}"
curl_rc=$?
set -e
if [[ $curl_rc -ne 0 ]]; then
  echo "AVISO: Falhou download de ${PROTOC_URL}. Vou tentar instalar via apt (protobuf-compiler), mas pode ser versão diferente."
else
  unzip -o "/opt/${PROTOC_ZIP}" -d "${PROTOC_DIR}"
  chmod -R a+rX "${PROTOC_DIR}"
fi

# ---------- Clonar e instalar EMANE ----------
echo "[5/7] Clonar e construir EMANE (repo: ${EMANE_REPO})..."
if [[ -d ${EMANE_DIR} ]]; then
  echo "  -- Diretoria ${EMANE_DIR} já existe: atualizando..."
  cd ${EMANE_DIR}
  if [[ ! -d "${EMANE_DIR}/.git" ]]; then
    git init
    git remote add origin "${EMANE_REPO}"
    git fetch origin ${BRANCH}
    git checkout -t origin/"${BRANCH}" 
  else
    git fetch origin "${BRANCH}"
    git checkout "${BRANCH}"
  fi
  git pull
else
  mkdir -p ${EMANE_DIR}
  echo "  -- Clonando o repositorio EMANE..."
  git clone "${EMANE_REPO}" ${EMANE_DIR}
  cd ${EMANE_DIR}
fi

# Build and install EMANE 
cd ${EMANE_DIR}
echo "  -- compilando o EMANE..."
./autogen.sh
./configure --prefix=/usr
make -j"$(nproc)"
echo "  -- instalando o EMANE..."
make install

# Bindings Python do EMANE (pelo padrão do upstream)
cd ${EMANE_DIR}/src/python
echo "  -- instalando python EMANE..."
make clean || true
PATH="${PROTOC_DIR}/bin:${PATH}" make
"${VENV_PATH}/bin/python" -m pip install .
:
# ---------- Limpezas ----------
cd ${BASE_DIR}
echo "[6/7] Limpezas…"
rm -rf "/opt/${PROTOC_ZIP}" || true
# Se quiseres manter o protoc, comenta a linha abaixo
# rm -rf "${PROTOC_DIR}" || true

# ---------- Serviço / arranque ----------
echo "[7/7] Pronto. Podes iniciar o core-daemon assim:"
echo "sudo ${VENV_PATH}/bin/core-daemon"
echo
cat >/etc/systemd/system/core-daemon.service <<'UNIT'
[Unit]
Description=CORE network emulator daemon
After=network-online.target

[Service]
Type=simple
ExecStart=/opt/core/venv/bin/core-daemon
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
UNIT

echo "Formas de correr o core-daemon (obrigatório para usar core-gui)"
echo
echo "1. Execução automática do serviço core-daemom, no arranque do sistema:"
echo
echo "  systemctl enable core-daemon.service"
echo "  systemctl daemon-reload"
echo
echo "2. Execução manual do core-daemon, quando necessário:"
echo 
echo "  systemctl stop core-daemon"
echo "  systemctl start core-daemon"
echo "  systemctl status core-daemon"
echo
echo "3. Execção manual do core-daemon numa bash (talvez o mais adequado):"
echo
echo "  sudo core-daemon"
echo
echo "Estando o core-daemon em execução, pode iniciar o interface GUI"
echo 
echo "  sudo core-gui"
echo
echo "Done."

