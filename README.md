# core-emulator-setup

Simple scripts to setup CORE Emulator on Linux (Ubuntu)

## Install

Make sure you are using Ubuntu 20.04 version and run install script:

```bash
sudo ./install_core_emane.sh
```

## Uninstall

If something goes wrong during install, while intallation script 
can deal with another install attempt, it is maybe easier to simply
renmove everything and try again:

```bash
sudo ./install_core_emane.sh
```

## Run daemon and GUI

Ways to run core-daemon (required to use core-gui)

1. Automatically run the core-daemon service at system startup:

```bash
  systemctl enable core-daemon.service
  systemctl daemon-reload
```

2. Manually running core-daemon when necessary:

```bash
  systemctl stop core-daemon
  systemctl start core-daemon
  systemctl status core-daemon
```

3. Manually running core-daemon in a bash (perhaps the most appropriate):

```bash
  sudo core-daemon
```

Once core-daemon is running, you can start the GUI interface

```bash
  sudo core-gui
```

## Links

- [CORE Documentation](https://coreemu.github.io/core/index.html)

- [coreemucore Common Open Research
  Emulator](https://github.com/coreemu/core)

- [Common Open Research Emulator
  (CORE)](https://www.nrl.navy.mil/Our-Work/Areas-of-Research/Information-Technology/NCS/CORE/)

- [Developers Guide - CORE
  Documentation](https://coreemu.github.io/core/devguide.html)

- [XubunCORE 7.5 Xubuntu 20.04 LTS + CORE
  7.5.2](https://marco.uminho.pt/ferramentas/CORE/)

- [eivarin Dockerized-Coreemu Dockerized image of Coreemu with X11
  Forwarding capabilities for native like
  UI](https://github.com/eivarin/Dockerized-Coreemu)


