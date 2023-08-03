# Workstation

Resources and guides related to using [Fedora Silverblue](https://fedoraproject.org/silverblue/) as your main
workstation.

## Download image

Fedora Silverblue 38
```shell
RELEASE="38"
ARCH="x86_64"
BASE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${RELEASE}/Silverblue/${ARCH}/iso"
FILENAME=$(curl -sfL ${BASE_URL} | grep -oP --color=none 'href="Fedora-Silverblue-ostree.*.iso"' | sed 's/href=//g;s/"//g')
URL="${BASE_URL}/${FILENAME}"
curl -fL "${URL}" -O
```

Fedora Server 38
```shell
RELEASE="38"
ARCH="x86_64"
BASE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${RELEASE}/Server/${ARCH}/iso"
FILENAME=$(curl -sfL ${BASE_URL} | grep -oP --color=none 'href="Fedora-Server-dvd.*.iso"' | sed 's/href=//g;s/"//g')
URL="${BASE_URL}/${FILENAME}"
curl -fL "${URL}" -O
```

Fedora CoreOS 38
```shell
BUILD="38.20230709.3.0"
ARCH="x86_64"
URL="https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${BUILD}/${ARCH}/fedora-coreos-${BUILD}-live.${ARCH}.iso"
curl -fL "${URL}" -O
```
More about Fedora CoreOS [here](fcos.md).

## Burn the image to an USB disk

```shell
INPUT="${HOME}/data/fedora-coreos-38.20230709.3.0-live.x86_64.iso"
OUTPUT="/dev/disk7"
sudo dd if="${INPUT}" of="${OUTPUT}" status=progress bs=1M
```
