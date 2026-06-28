# ESI Maya22 Linux Control

## Descripción
Control por línea de comandos para la interfaz de audio USB ESI Maya22.

## Compilación
```sh
sudo apt-get install build-essential libhidapi-dev
make
```

## Estructura
- `maya22-control.c` — Código fuente único (C, compilado como C++11)
- `Makefile` — Compilación e instalación
- `build.sh` — Script de compilación alternativo
- `doc/` — Capturas USB y documentación técnica

## Binario
Se genera `maya22-control` en la raíz.

## Uso
```
maya22-control -h
  -e          - Enumerate available devices
  -i          - Enable all outputs
  -I          - Disable all outputs
  -d          - Set default values
  -c <name>   - Set input channel (mic, hiz, line, mic_hiz, mute)
  -M          - Input monitoring on
  -m          - Input monitoring off
  -l <0-127>  - Input left volume
  -r <0-127>  - Input right volume
  -L <0-145>  - Output left volume
  -R <0-145>  - Output right volume
  -j          - JSON output
```

## Errores conocidos corregidos
- `-c mute` usaba valor `0xc1` incorrecto (corregido a `0xc2`)
- `getopt()` casteado a `signed char` causaba overflow en ARM
- `do_enable_outputs` inicializado como `true` hacía que `-I` habilitase antes de deshabilitar
- Variable `input_mute` declarada pero no usada
- Parseo de `-c` con `optarg[0]` frágil (reemplazado por `strcmp`)
