# GUI Integration Guide — ESI Maya22 Control

This document describes how to integrate the `maya22-control` CLI tool into a
graphical application (Qt, GTK, Electron, web, etc.).

## Architecture

```
┌─────────────┐   subprocess/exec    ┌──────────────────┐
│  GUI App     │ ──────────────────>  │  maya22-control  │
│  (Python/Qt) │  <────────────────  │  (C binary)      │
└─────────────┘   stdout (JSON)      └──────────────────┘
                                            │
                                     ┌──────┴──────┐
                                     │  ESI Maya22  │
                                     │  (USB HID)   │
                                     └─────────────┘
```

The GUI never talks to USB directly. It spawns `maya22-control` with the `-j`
(JSON) flag and parses its standard output.

---

## JSON Output Format

All commands return a single JSON object on **stdout**. The exit code is **0**
on success, **non-zero** on error.

### Success (device connected)

```json
{
  "channel": 1,
  "monitor": true,
  "input_left": 86,
  "input_right": 86,
  "output_left": 145,
  "output_right": 145,
  "status": "ok"
}
```

Only keys for the requested operations appear. Always ends with `"status": "ok"`.

### Error (device not found)

```json
{"error": "Unable to open hid device"}
```

No trailing comma — always valid JSON.

---

## Commands Reference

### `-j` (always include for JSON output)

Add `-j` to every invocation.

### `-d` — Set all defaults

```
$ maya22-control -j -d
{
  "channel": 8,
  "monitor": false,
  "input_left": 86,
  "input_right": 86,
  "output_left": 145,
  "output_right": 145,
  "status": "ok"
}
```

### `-c <name>` — Set input channel

| Name     | Value | Description           |
|----------|-------|-----------------------|
| `mic`    | 0x01  | Microphone            |
| `hiz`    | 0x02  | High-Z (instrument)   |
| `line`   | 0x04  | Line input            |
| `mic_hiz`| 0x08  | Mic + Hi-Z            |
| `mute`   | 0xc2  | Mute input            |

```
$ maya22-control -j -c mic
{
  "channel": 1,
  "status": "ok"
}
```

### `-M` / `-m` — Monitor on/off

```
$ maya22-control -j -M
{
  "monitor": true,
  "status": "ok"
}

$ maya22-control -j -m
{
  "monitor": false,
  "status": "ok"
}
```

### `-l` / `-r` — Input volume (0–127)

```
$ maya22-control -j -l 100 -r 80
{
  "input_left": 100,
  "input_right": 80,
  "status": "ok"
}
```

### `-L` / `-R` — Output volume (0–145)

```
$ maya22-control -j -L 127 -R 100
{
  "output_left": 127,
  "output_right": 100,
  "status": "ok"
}
```

### `-i` / `-I` — Enable/Disable all outputs

```
$ maya22-control -j -i
{"status": "ok"}

$ maya22-control -j -I
{"status": "ok"}
```

### Combining commands

Multiple flags can be combined in a single call:

```
$ maya22-control -j -c line -l 127 -r 127 -M
{
  "channel": 4,
  "input_left": 127,
  "input_right": 127,
  "monitor": true,
  "status": "ok"
}
```

### `-e` — Enumerate devices

**Note:** `-e` does **not** support JSON output yet. Output is plain text:

```
$ maya22-control -e
2573:0017 - /dev/hidraw0 ESI12345
    vendor: ESI Audiotechnik GmbH
    product: MAYA22 USB
```

---

## Exit Codes

| Code | Meaning         |
|------|-----------------|
| 0    | Success         |
| -1   | hid_init failed |

Error messages are printed to **stdout** (not stderr) in JSON format.

---

## Integration Examples

### Python (PyQt / PySide)

```python
import subprocess
import json

BINARY = "/usr/local/bin/maya22-control"

def send_command(*args):
    cmd = [BINARY, "-j"] + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    if "error" in data:
        raise RuntimeError(data["error"])
    return data

# Usage
send_command("-c", "mic")
send_command("-l", "100", "-r", "80")
status = send_command("-d")
print(status["input_left"])  # → 86
```

### Qt (C++)

```cpp
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>

QJsonObject maya22(const QStringList &args) {
    QProcess p;
    p.start("/usr/local/bin/maya22-control",
            QStringList{"-j"} + args);
    p.waitForFinished(3000);
    QJsonDocument doc = QJsonDocument::fromJson(p.readAllStandardOutput());
    QJsonObject obj = doc.object();
    if (obj.contains("error"))
        throw std::runtime_error(obj["error"].toString().toStdString());
    return obj;
}

// Usage
auto r = maya22({"c", "mic"});
int channel = r["channel"].toInt();
```

### Node.js / Electron

```javascript
const { execFileSync } = require('child_process');

function maya22(...args) {
  const out = execFileSync('/usr/local/bin/maya22-control', ['-j', ...args]);
  const data = JSON.parse(out.toString());
  if (data.error) throw new Error(data.error);
  return data;
}

// Usage
maya22('-c', 'line');
maya22('-l', '100', '-r', '80');
```

### Rust

```rust
use std::process::Command;

fn maya22(args: &[&str]) -> Result<serde_json::Value, Box<dyn std::error::Error>> {
    let out = Command::new("/usr/local/bin/maya22-control")
        .arg("-j")
        .args(args)
        .output()?;
    let data: serde_json::Value = serde_json::from_slice(&out.stdout)?;
    if let Some(err) = data.get("error") {
        return Err(err.as_str().unwrap().into());
    }
    Ok(data)
}
```

---

## Installation Checklist for GUI Users

```sh
# 1. Install dependencies
sudo apt-get install build-essential libhidapi-dev

# 2. Build and install
git clone <repo-url>
cd esi-maya22-linux
make
sudo make install

# 3. Connect the device and verify
maya22-control -j -d
```

`make install` also creates the udev rule so **no root** is needed at runtime.

---

## Notes

- The binary is **single-threaded** and fast (~10 ms per call). It is safe to
  call from GUI event loops.
- For volume sliders, call the tool on **release** (not every tick) to avoid
  unnecessary USB traffic.
- The `-d` flag is useful at app startup to synchronise the GUI with the
  hardware defaults.
