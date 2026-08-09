# UniFi Controller NG (LoxBerry-Plugin)

Betreibt die [UniFi Network Application](https://www.ui.com/) (den Nachfolger des
eingestellten *UniFi Controller*) samt der benötigten MongoDB in Docker auf
[LoxBerry](https://www.loxberry.de) und bindet sie in die LoxBerry-Weboberfläche ein.

Ein neu geschriebenes, **V4-natives** Plugin (LoxBerry Design System, LoxBerry-PHP-
Bibliotheken). Nur 64-Bit.

## Voraussetzungen

- **64-Bit-LoxBerry** (Raspberry Pi 3/4/5 im 64-Bit-Modus oder x86, LoxBerry 4.0+).
  Durchgesetzt über das Feld `ARCHITECTURE` in `plugin.cfg` (`aarch64,x86_64`) - die
  Pluginverwaltung verweigert die Installation auf 32-Bit-Systemen, weil UniFi
  Network Application und MongoDB nur als 64-Bit-Abbilder erscheinen.
  Läuft nachweislich auch auf einem Raspberry Pi 3B+ (Cortex-A53, ARMv8-A) - siehe
  den Hinweis zur MongoDB-Version weiter unten.
- Ein laufender **Docker Engine** mit dem `docker compose`-v2-Plugin, erreichbar für
  den Benutzer `loxberry` (`/var/run/docker.sock`).
- Etwa **1-2 GB freier Arbeitsspeicher** (Java-Anwendung + MongoDB).

## Funktionen

- UniFi Network Application + MongoDB als zwei Docker-Container.
- Versionsumschalter, Dienststatus, Live-Diagnose.
- Automatisch erzeugtes MongoDB-Kennwort (kein Geheimnis im Repository).
- Datenbank-Diagnose auf der Hauptseite: erkennt eine Neustartschleife des
  Datenbank-Containers direkt und benennt die Ursache im Klartext, statt sie in den
  rohen Container-Logs zu verstecken.

## Bekannter Stolperstein: MongoDB und ältere ARM-Boards

Ab Fassung 4.4.19 (und jede 5.0 oder neuer) verlangt das offizielle MongoDB-Abbild
einen Prozessor mit **ARMv8.2-A**. Ältere 64-Bit-Boards wie der Raspberry Pi 3
(Cortex-A53) oder Pi 4 (Cortex-A72) haben nur ARMv8-A - die Datenbank bricht dort bei
jedem Start sofort mit „Illegal instruction" ab, und die UniFi-Oberfläche bleibt
dauerhaft unerreichbar, ohne dass der Grund offensichtlich wäre.

Dieses Plugin bindet deshalb bewusst `mongo:4.4.18` statt der wandernden Tag `4.4` -
eine Fassung, die auf der gesamten unterstützten Geräteflotte läuft, vom Pi 3 bis zum
Pi 5 (neuere Prozessoren beherrschen den älteren Befehlssatz immer mit). Eine
prozessorabhängige Auswahl einer neueren MongoDB-Fassung gibt es bewusst nicht: das
hielte das Fehlerbild je nach Hardware unterschiedlich, für einen Zugewinn, der sich
auf Sicherheitspatches innerhalb der 4.4-Reihe beschränkt.

## Credits

Dieses Plugin baut auf dem ursprünglichen
[LoxBerry-Plugin-Unfi-Controller](https://github.com/romanlum/LoxBerry-Plugin-Unfi-Controller)
von **Roman Lumetsberger** auf. Danke für die Vorarbeit, auf der hier aufgesetzt wird!

## Lizenz

Lizenziert unter der [MIT](LICENSE)-Lizenz.
