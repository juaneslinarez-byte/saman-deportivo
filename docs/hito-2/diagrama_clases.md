# Diagrama de clases con Pago

Modelo del dominio actualizado a partir del código de `app/lib/modelos/`. Parte de la Figura 3 del Hito 1 y agrega la clase **Pago** con su relación con el Estudiante.

```mermaid
classDiagram
    class Persona {
        <<abstract>>
        -id: String
        -nombre: String
        -apellido: String
        -cedula: String
        -correo: String
        -habilitado: bool
        +nombreCompleto() String
    }
    class Estudiante {
        -carnet: String
        -carrera: String
        -solvente: bool
    }
    class Entrenador {
        -especialidad: String
    }
    class Administrador {
        -cargo: String
    }
    class Deporte {
        -id: String
        -nombre: String
        -descripcion: String
        -lugar: String
        -cupoMaximo: int
        -cuposDisponibles: int
        -visible: bool
        +hayCupo() bool
        +inscritos() int
    }
    class Sesion {
        -id: String
        -dia: DiaSemana
        -horaInicio: String
        -horaFin: String
        -lugar: String
    }
    class Inscripcion {
        -id: String
        -fecha: DateTime
        -estado: EstadoInscripcion
        +estaActiva() bool
    }
    class Asistencia {
        -id: String
        -fecha: DateTime
        -presente: bool
    }
    class Pago {
        -id: String
        -monto: double
        -fecha: DateTime
        -referencia: String
        -estado: EstadoPago
    }
    class EstadoPago {
        <<enumeration>>
        pendiente
        aprobado
        rechazado
    }
    class EstadoInscripcion {
        <<enumeration>>
        activa
        cancelada
    }
    class DiaSemana {
        <<enumeration>>
        lunes
        martes
        miercoles
        jueves
        viernes
        sabado
        domingo
    }

    Persona <|-- Estudiante
    Persona <|-- Entrenador
    Persona <|-- Administrador
    Estudiante "1" --> "0..*" Inscripcion : realiza
    Estudiante "1" --> "0..*" Pago : realiza
    Inscripcion "0..*" --> "1" Deporte : pertenece a
    Entrenador "0..1" --> "0..*" Deporte : dirige
    Deporte "1" *-- "1..*" Sesion : se compone de
    Inscripcion "1" --> "0..*" Asistencia : tiene
    Asistencia "0..*" --> "1" Sesion : corresponde a
```

## Decisiones de modelado

- **Pago:** guarda el monto, la fecha, el código de operación (`referencia`) que devuelve la pasarela y el estado. No guarda datos de tarjeta.
- **Estados del pago:** nace `pendiente`. Al aprobarlo el administrador pasa a `aprobado` y el estudiante a `solvente = true` (RF-SIS-07). Un pago `rechazado` no cambia la solvencia.
- **Relación Estudiante - Pago:** un estudiante puede tener varios pagos (por ejemplo, uno rechazado y uno posterior aprobado), y cada pago pertenece a un solo estudiante.
- **Entrenador - Deporte:** un deporte tiene como máximo un entrenador, porque se crea sin entrenador hasta que el administrador lo asigna (CU-09).

## Cambios respecto a la Figura 3 del Hito 1

| Elemento | Hito 1 | Código actual |
|---|---|---|
| Pago y EstadoPago | No existían | Se agregan, con relación a Estudiante |
| Persona | `iniciarSesion()` | Se agrega `habilitado`. El inicio de sesión pasa a `AuthRepository` |
| Deporte | `activo: bool` | `visible: bool`, y el entrenador se referencia con `idEntrenador` (nulo hasta asignarlo) |
| Operaciones de negocio | `inscribirse()`, `cancelar()`, `gestionarDeporte()`, etc. | Pasan a los repositorios (`InscripcionRepository`, `DeporteRepository`, etc.) |
| Fechas | `Date` | `DateTime` |
