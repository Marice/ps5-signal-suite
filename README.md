# Signal suite

A payload repository for [Payload Manager](https://github.com/itsPLK/ps5-payload-manager) (pldmgr) with three PS5
payloads that work together:

| Payload | What it does |
| --- | --- |
| [ps5-exporter](https://github.com/Marice/ps5-exporter) | The console's temperatures, power, fan, clocks, CPU load, frame rate and running game as Prometheus metrics on port 9100. |
| [ps5-homeassistant](https://github.com/Marice/ps5-homeassistant) | The PS5 as a device in Home Assistant over MQTT. It reads its values from ps5-exporter and uses ps5-signal for beeps and the light. |
| [ps5-signal](https://github.com/Marice/ps5-signal) | Beeps and the console's light for you and for homebrew. |

Start them in this order, a few seconds apart: ps5-exporter, ps5-homeassistant, ps5-signal.

## Using it

[PayLoader](https://github.com/Marice/ps5-payloader) adds this repository to pldmgr by itself and can install the
whole suite with one press. In pldmgr's web page you can add it by hand (Settings, repositories):

```
https://raw.githubusercontent.com/Marice/ps5-signal-suite/main/payloads.json
```

pldmgr shows extra repositories only while "multiple sources" is on in its settings.

Every entry points to the payload's GitHub release and carries its SHA-256, so pldmgr checks each download.

## Updating

After a release of one of the payloads:

```bash
tools/update.sh   # needs gh (logged in) and python3; rewrites payloads.json from the latest releases
git commit -am "chore: <payload> <version>" && git push
```

## Licence

GPL-3.0-or-later, like the payloads.
