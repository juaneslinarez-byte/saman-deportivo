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
| entrenador | `aniosExperiencia` | int | Años de experiencia; 0 si no se indicó |
| administrador | `cargo` | string | |

## `deportes/{id}`

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `codigo` | string | Código corto del deporte, por ejemplo `FUT-01` |
| `nombre` | string | |
| `descripcion` | string | |
| `lugar` | string | |
| `cupoMaximo` | int | |
| `cuposDisponibles` | int | Se descuenta y se devuelve en la misma escritura en lote que crea o cancela la inscripción (RNF-07); las reglas verifican que cambie exactamente en 1 |
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

## `inscripciones/{idEstudiante}_{idDeporte}`

El id del documento se arma con `Inscripcion.idPara(idEstudiante, idDeporte)`, por ejemplo `EYPv6..._futbol`. Así un estudiante no puede tener dos inscripciones en el mismo deporte: si cancela y se vuelve a inscribir, se reactiva el mismo documento.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idEstudiante` | string | Id del estudiante en `usuarios` |
| `nombreEstudiante` | string | Nombre y apellido del estudiante, copiados de su perfil para mostrar la nómina sin leer cada perfil |
| `carnetEstudiante` | string | Carnet del estudiante, copiado de su perfil |
| `idDeporte` | string | |
| `fecha` | timestamp | |
| `estado` | string | `activa` o `cancelada`. Al cancelar no se borra el documento |

## `asistencias/{idInscripcion}_{idSesion}_{AAAAMMDD}`

El id del documento se arma con `Asistencia.idPara(idInscripcion, idSesion, fecha)`, por ejemplo `u1_futbol_futbol-martes_20261103`. Registrar dos veces la asistencia del mismo día sobrescribe el registro en vez de duplicarlo.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `idInscripcion` | string | |
| `idEstudiante` | string | Copiado de la inscripción, para que el estudiante consulte su historial (RF-EST-06) |
| `idDeporte` | string | Copiado de la inscripción, para el historial del deporte (RF-ENT-04) y para que las reglas verifiquen al entrenador |
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

- `deportes/futbol`: Fútbol, cupo de 25, visible, sin entrenador asignado. Todavía no tiene `codigo`; la app lo lee como texto vacío hasta que el administrador lo asigne.
- `sesiones/futbol-martes`: martes de 16:00 a 18:00 en la cancha de fútbol.

## Acceso esperado (base para las reglas de seguridad)

| Colección | Lectura | Escritura |
| --- | --- | --- |
| `usuarios` | El propio usuario, los entrenadores (para ver solvencia y estado de sus inscritos, RF-ENT-05) y el administrador | El propio usuario edita su perfil, pero no `actor`, `solvente` ni `habilitado`; el administrador edita todo, incluso convertir a un estudiante registrado en entrenador (RF-ADM-08) |
| `deportes` | Cualquier usuario con sesión iniciada | El administrador; el estudiante solo puede mover `cuposDisponibles` en 1 junto con su inscripción o cancelación |
| `sesiones` | Cualquier usuario con sesión iniciada | Solo el administrador (RF-ADM-03) |
| `inscripciones` | El estudiante dueño, los entrenadores y el administrador | El estudiante solvente y habilitado crea la suya si hay cupo, y la cancela o reactiva; nadie la borra |
| `asistencias` | El estudiante dueño, los entrenadores y el administrador | El entrenador asignado al deporte registra y corrige; el administrador también |
| `pagos` | El estudiante dueño y el administrador | El estudiante crea los suyos en `pendiente`; solo el administrador los pasa a `aprobado` o `rechazado`; nadie los borra |

Cualquier otra colección queda cerrada. Las reglas están en `app/firestore.rules`.

No se usa Cloud Storage: no está disponible en el plan Spark.
