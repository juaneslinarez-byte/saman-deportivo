# Diagrama de secuencia: Inicio de sesión

**Caso de uso:** CU-01 Iniciar sesión · **Requisitos:** RF-EST-01, RF-SIS-05, RNF-02

Muestra cómo un usuario (estudiante, entrenador o administrador) inicia sesión y entra a la vista de su rol.

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario
    participant V as Vista
    participant VM as ViewModel
    participant AR as AuthRepository
    participant UR as UsuarioRepository
    participant FA as Firebase Auth
    participant FS as Firestore

    U->>V: Escribe su correo y su contraseña
    V->>VM: iniciarSesion(correo, contrasena)
    VM->>AR: iniciarSesion(correo, contrasena)
    AR->>FA: Verificar las credenciales
    alt Credenciales incorrectas
        FA-->>AR: Error
        AR-->>VM: ErrorAutenticacion(mensaje)
        VM-->>V: Muestra el error
        V-->>U: Mensaje y vuelve al formulario
    else Credenciales correctas
        FA-->>AR: idUsuario
        AR-->>VM: idUsuario
        VM->>UR: obtener(idUsuario)
        UR->>FS: Leer el perfil
        FS-->>UR: Datos del perfil
        UR-->>VM: Persona (Estudiante, Entrenador o Administrador)
        alt Perfil inexistente o usuario deshabilitado
            VM->>AR: cerrarSesion()
            VM-->>V: Acceso no permitido
            V-->>U: Informa que no puede ingresar
        else Usuario habilitado
            VM-->>V: Persona con su actor
            V-->>U: Muestra el inicio de su rol
        end
    end
    opt Olvidó la contraseña
        U->>V: Pide recuperar la contraseña
        V->>VM: recuperarContrasena(correo)
        VM->>AR: enviarCorreoRecuperacion(correo)
        AR->>FA: Enviar el enlace de restablecimiento
    end
```

## Notas

- Corresponde a las excepciones de CU-01: 4' credenciales incorrectas y 4'' contraseña olvidada. La excepción 3' (correo no institucional) se valida en el formulario antes del paso 2.
- `Persona.fromMap` crea la subclase correcta según el campo `actor`; con ese dato la Vista decide qué pantalla de inicio mostrar (RF-SIS-05).
- Un usuario con `habilitado = false` no puede iniciar sesión: el ViewModel cierra la sesión recién abierta.
- Los nombres de los métodos del ViewModel son propuestos. Los de los repositorios salen de las interfaces.
