# ESI Maya22 Linux Control

## Descripción
Control por línea de comandos para la interfaz de audio USB ESI Maya22.

## Compilación
```sh
sudo apt-get install build-essential libhidapi-dev
./build.sh
```

## Estructura
- `maya22-control.c` — Código fuente único (C, compilado como C++11)
- `build.sh` — Script de compilación
- `doc/` — Capturas USB y documentación técnica

## Binario
Se genera `maya22-control` en la raíz.
