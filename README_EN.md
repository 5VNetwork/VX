# VX Proxy Client

<div>

[![English](https://img.shields.io/badge/Language-English-blue)](README_EN.md)
[![中文](https://img.shields.io/badge/语言-中文-red)](README.md)

</div>

<img src="assets/dev/icon.png" alt="Vproxy Icon" width="50"/>

## Overview

VX (formerly known as Vproxy) is a cross-platform proxy client built on top of
[vx-core](https://github.com/5vnetwork/vx-core)

## Features

- **Multi-Protocol Support**
- **Easy-to-Use**
- **Powerful Routing Policy**
- **Realtime Logging**
- **No DNS Leaking in TUN mode**
- **Subscription Management**
- **Automaticly Select Node**
- **VPS Monitor**
- **VX-core Panel**
- **Chain Proxy**
- **As HTTP/SOCKS Server**
- **SYNC and Backup**
- **DNS Policy**
- **Traffic Statistics**
- **Free Trial**
- **Customer Support**

> **Note**: Most features are free, but some are available to paid users only.

## Deep Linking (For airport owners)

### Format 1: Base64 Encoded Subscription URL

```
vx://add/sub://<base64_encoded_url>?remarks=<subscription_name>
```

**Example:**

```
vx://add/sub://aHR0cHM6Ly9leGFtcGxlLmNvbS9hYmNk?remarks=%E6%9C%BA%E5%9C%BA%0A
```

### Format 2: Direct URL with Parameters

```
vx://install-config?url=<subscription_url>&name=<subscription_name>
```

**Example:**

```
vx://install-config?url=https%3A%2F%2Fexample.com%2Fabcd&name=%E6%9C%BA%E5%9C%BA%0A
```

- `url`: The subscription URL (URL-encoded)
- `name`: The name of the subscription (URL-encoded)

Both formats will add a subscription named "My Proxy" to the client.

## Installation

### From Official Website

Visit [vx.5vnetwork.com](https://vx.5vnetwork.com) to download the latest
version for your platform.
