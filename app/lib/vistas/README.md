# vistas

Pantallas de la aplicación (capa **Vista** del patrón MVVM), organizadas por actor:

| Carpeta | Contenido |
| --- | --- |
| `auth/` | Inicio de sesión, registro y recuperación de contraseña |
| `perfil/` | Perfil del usuario, común a los tres actores |
| `estudiante/` | Catálogo de disciplinas, inscripciones y asistencia del estudiante |
| `entrenador/` | Nómina de inscritos y registro de asistencia |
| `administrador/` | Gestión de deportes, entrenadores, cupos, sesiones y pagos |

Una vista solo muestra datos y recibe las acciones del usuario. Toda la lógica va en su ViewModel y nunca importa Firebase.
