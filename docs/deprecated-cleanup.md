# Deprecated Syntax Cleanup

Estado resumido de limpieza de sintaxis legacy en Avenys/Mire.

## Hecho (3.8.2)

- `none` eliminado como keyword de entrada.
- `mu` queda como único literal/tipo unitario oficial.
- `trait` y `code` ya no se parsean como sintaxis de usuario.
- `?` queda reservado y ahora produce error léxico explícito.
- Eliminadas variantes legacy internas del AST y pases asociados:
  - `Statement::Code`
  - `Statement::Class`
  - `Statement::Trait`
  - `Statement::AddLib`
  - `Statement::Dmire*`

## Pendiente (siguiente fase)

- Modularización de `parser` y `typeck` para cerrar deuda estructural restante.
- Optimización incremental por reachability real (import graph selectivo).

## Validación

- Build completo: OK.
- Suite de tests (`unit + language_regressions`): OK.
