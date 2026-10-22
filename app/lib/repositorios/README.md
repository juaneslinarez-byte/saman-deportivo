# repositorios

Acceso a los datos (patrón **Repositorio**). Es el único paquete de la aplicación que depende de Firebase.

- Cada entidad tiene una interfaz (por ejemplo, `InscripcionRepository`) que define qué se puede hacer con sus datos.
- La implementación con Firebase (`InscripcionRepositoryFirebase`) cumple esa interfaz.
- Para las pruebas se usan versiones falsas que guardan los datos en memoria.
