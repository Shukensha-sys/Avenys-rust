# Mire CLI

CLI simplificada para priorizar integración backend (Avenys/Owl).

## Comandos soportados

- `mire run [file] [options] [-- args]`
- `mire build [file] [options]`
- `mire check [file] [options]`
- `mire debug [file] [options]`

## Perfiles y optimización

- Por defecto: `--debug` + `-O0`
- `--release`: perfil release (si no se define `-O`, usa `-O3`)
- `-O`, `--opt-level`: `0|1|2|3|s|z`

## Opciones comunes

- `-o`, `--output <path>`
- `--cache-max-units <N>`
- `--analysis-cache`
- `--no-analysis-cache`
- `--warn-all`
- `-W <Wxxxx>`
- `--deny <Wxxxx>`

## Debug

- `--tokens` / `-t`
- `--ast` / `-p`
- `--run` / `-r`
- `--ir`

## Notas

- Si no pasas archivo, se intenta resolver `entry` desde `project.toml` u `owl.toml`.
- `run` soporta separación de argumentos con `--`.
