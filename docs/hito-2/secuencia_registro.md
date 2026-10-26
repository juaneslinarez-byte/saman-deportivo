# Diagrama de secuencia: Registro de usuario

**Requisitos:** RF-EST-01, RNF-02, RNF-06 · **Relación con casos de uso:** el registro del estudiante es la precondición de CU-01 Iniciar sesión.

Muestra cómo un estudiante crea su cuenta y su perfil. Los entrenadores y administradores no se registran solos: los crea el administrador (CU-09).

```mermaid
sequenceDiagram
    autonumber
    actor E as Estudiante
    participant V as Vista
    participant VM as ViewModel
    participant AR as AuthRepository
    participant UR as UsuarioRepository
    participant FA as Firebase Auth
    participant FS as Firestore

    E->>V: Completa el formulario de registro
    V->>VM: registrar(datos)
    VM->>VM: Valida los campos y el correo institucional
    alt Datos inválidos o correo no institucional
        VM-->>V: Error de validación
        V-->>E: Muestra el mensaje y no deja continuar
    else Datos válidos
        VM->>AR: registrar(correo, contrasena)
        AR->>FA: Crear la cuenta
        alt Correo ya registrado u otro error
            FA-->>AR: Error
            AR-->>VM: ErrorAutenticacion(mensaje)
            VM-->>V: Muestra el error
            V-->>E: Mensaje claro y vuelve al formulario
        else Cuenta creada
            FA-->>AR: idUsuario
            AR-->>VM: idUsuario
            VM->>UR: crear(Estudiante con solvente = false)
            UR->>FS: Guardar el perfil con el mismo id de la cuenta
            FS-->>UR: Perfil guardado
            UR-->>VM: Listo
            VM-->>V: Registro exitoso
            V-->>E: Muestra el inicio del estudiante
        end
    end
```

## Notas

- Los métodos `registrar` y `crear` salen de las interfaces `AuthRepository` y `UsuarioRepository`. Los nombres de los métodos del ViewModel son propuestos, porque esa capa todavía no está implementada.
- Un estudiante nuevo nace con `solvente = false`: debe pagar (CU-12) antes de poder inscribirse (CU-03).
- Punto por definir en el ViewModel: si la cuenta se crea pero falla el guardado del perfil, queda una cuenta sin perfil.
- Este flujo se puede probar sin Firebase con `FakeAuthRepository` y `FakeUsuarioRepository` (`app/test/fakes/`).
