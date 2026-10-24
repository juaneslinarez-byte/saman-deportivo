# Modelo de datos en Cloud Firestore

Proyecto de Firebase: `proyecto-saman-deportivo` (plan Spark).

Las colecciones y sus campos siguen el diagrama de clases y los modelos de `app/lib/modelos/`. Cada modelo se guarda con `toMap()` y se lee con `fromMap(id, datos)`, así que **los nombres de los campos deben coincidir exactamente** con los de esta tabla. Si hace falta un campo nuevo, se agrega primero en el modelo y en este documento.

Convenciones:

- Nombres de colecciones en plural y en minúsculas.
- Nombres de campos en `camelCase`, sin espacios ni tildes.
- Las referencias a otro documento se guardan como el id de ese documento, con el prefijo `id` (por ejemplo, `idDeporte`).
- Los valores fijos (actor, estado, día) se guardan como texto en minúsculas.

## `usuarios/{uid}`

El id del documento es el mismo `uid` de la cuenta en Firebase Authentication. El perfil se crea al registrarse.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `actor` | string | `estudiante`, `entrenador` o `administrador` |
| `nombre` | string | |
| `apellido` | string | |
| `cedula` | string | |
| `correo` | string | Correo institucional |
| `habilitado` | boolean | Un usuario deshabilitado no puede iniciar sesión (RF-SIS-08) |

Campos adicionales según el actor:

| Actor | Campo | Tipo | Descripción |
| --- | --- | --- | --- |
| estudiante | `carnet` | string | |
| estudiante | `carrera` | string | |
| estudiante | `solvente` | boolean | Lo cambia el administrador al revisar los pagos (RF-SIS-07) |
| entrenador | `especialidad` | string | |
| administrador | `cargo` | string | |

## `deportes/{id}`

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `nombre` | string | |
| `descripcion` | string | |
| `lugar` | string | |
| `cupoMaximo` | int | |
| `cuposDisponibles` | int | Se descuenta y se devuelve en una transacción al inscribir y cancelar (RNF-07) |
| `idEntrenador` | string o null | Id del entrenador en `usuarios`; null mientras no tenga uno asignado |
| `visible` | boolean | Si aparece en el catálogo |

## `sesiones/{id}`

Horario semanal de un deporte. Un deporte puede tener varias sesiones.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idDeporte` | string | |
| `dia` | string | `lunes`, `martes`, `miercoles`, `jueves`, `viernes`, `sabado` o `domingo` |
| `horaInicio` | string | Formato de 24 horas, por ejemplo `16:00` |
| `horaFin` | string | |
| `lugar` | string | |

## `inscripciones/{id}`

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idEstudiante` | string | Id del estudiante en `usuarios` |
| `idDeporte` | string | |
| `fecha` | timestamp | |
| `estado` | string | `activa` o `cancelada`. Al cancelar no se borra el documento |

## `asistencias/{id}`

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idInscripcion` | string | |
| `idSesion` | string | |
| `fecha` | timestamp | Día de la sesión |
| `presente` | boolean | |

## `pagos/{id}`

Pagos de solvencia hechos con la pasarela de pagos.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idEstudiante` | string | |
| `monto` | double | |
| `fecha` | timestamp | |
| `referencia` | string | Código de la operación que devuelve la pasarela |
| `estado` | string | `pendiente`, `aprobado` o `rechazado` |

## Datos de ejemplo cargados

- `deportes/futbol`: Fútbol, cupo de 25, visible, sin entrenador asignado.
- `sesiones/futbol-martes`: martes de 16:00 a 18:00 en la cancha de fútbol.

## Acceso esperado (base para las reglas de seguridad)

| Colección | Lectura | Escritura |
| --- | --- | --- |
| `usuarios` | El propio usuario y el administrador | El propio usuario edita su perfil, pero no `actor`, `solvente` ni `habilitado`; el administrador edita todo |
| `deportes`, `sesiones` | Cualquier usuario con sesión iniciada | Solo el administrador |
| `inscripciones` | El estudiante, el entrenador del deporte y el administrador | El estudiante crea y cancela las suyas |
| `asistencias` | El estudiante, el entrenador del deporte y el administrador | El entrenador del deporte |
| `pagos` | El estudiante dueño y el administrador | El estudiante crea los suyos; el administrador aprueba o rechaza |

No se usa Cloud Storage: no está disponible en el plan Spark.
