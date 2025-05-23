# AMBEd / XLXd / YSFReflector docker images


## Compatability


| Services        | Image Tags            | Architectures           | Base Image         |
| :-------------- | :-------------------- | :-----------------------| :----------------- |
| AMBEd           | [latest & test](https://hub.docker.com/r/cbodden/ambed-docker/tags)         | x86_64, ARM64/v8        | Ubuntu Latest      |
| XLXd            | [latest & test](https://hub.docker.com/r/cbodden/xlxd-docker/tags)         | x86_64, ARM64/v8        | Alpine Latest      |
| YSFReflector    | [latest & test](https://hub.docker.com/r/cbodden/ysfreflector-docker/tags)         | x86_64, ARM64/v8        | Alpine Latest      |


AMBEd FTDI testing done with:
- 2 x DVSI AMBE3000
- 1 x DVMEGA DVstick 33
```
Starting AMBEd 1.3.5

Initializing vocodecs:
s6-rc: info: service legacy-services successfully started
Detected 3 USB-FTDI devices

Description : ThumbDV	 Serial : D30CDTY5
Description : ThumbDV	 Serial : D30CBZH8
Description : FT230X Basic UART	 Serial : DK0EN6FB

Opening ThumbDV:D30CDTY5 device
ReadDeviceVersion : AMBE3000R V120.E100.XXXX.C106.G514.R009.B0010411.C0020208

Opening ThumbDV:D30CBZH8 device
ReadDeviceVersion : AMBE3000R V120.E100.XXXX.C106.G514.R009.B0010411.C0020208

Codec interfaces initialized successfully : 2 channels available

Initializing controller

AMBEd started and listening on 172.31.0.2
```


## General

### XLXd YSF Default Settings
- Autolink enabled: 1
- Autolink module: A
- port: 42000
- Default RX/TX freq: 438.000.000

### YSFReflector Default Settings
- port: 42000
- port: 80 (for the ysf dashboard)

### Versions
- AMBEd: 1.2.5
- XLXd: 2.5.3
- FTDI: 1.4.33
- S6 Overlay: 3.2.0.2
- Ubuntu: Latest
- YSFReflector: 20210824
- YSFReflector-Dashboard: 20210331-2


## Usage


## License

XLXd && AMBEd:
- Copyright (C) 2016 Jean-Luc Deltombe LX3JL and Luc Engelmann LX1IQ

YSFReflector:
- Copyright (C) Jonathan Naylor G4KLX

All other work:
- Copyright (C) 2023 cbodden

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.

