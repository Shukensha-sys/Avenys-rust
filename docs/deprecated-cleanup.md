# Deprecated Syntax Cleanup

Estado resumido de limpieza de sintaxis legacy en Avenys/Mire.

## Hecho (3.8.1)

- `none` eliminado como keyword de entrada.
- `mu` queda como único literal/tipo unitario oficial.
- `trait` y `code` ya no se parsean como sintaxis de usuario.
- `?` queda reservado y ahora produce error léxico explícito.

## Pendiente (interno)

Estas rutas legacy siguen en el AST/passes internos por compatibilidad técnica temporal y deben retirarse en una fase dedicada:

- `Statement::Code`
- `Statement::Class`
- `Statement::Trait`
- `Statement::AddLib`
- `Statement::Dmire*`

## Criterio de cierre

- Remover variantes legacy del AST.
- Remover arms muertos en typeck/borrowck/semantic/incremental/backend.
- Mantener 100% de tests de regresión en verde.
