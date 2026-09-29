# Guía de colaboración

Estas reglas mantienen el historial ordenado y permiten que el profesor vea el aporte de cada integrante.

## Ramas

| Rama | Uso |
| --- | --- |
| `main` | Versión estable. Solo recibe cambios revisados, al cierre de cada hito. |
| `develop` | Integración del trabajo en curso. |
| `feature/<nombre>` | Una funcionalidad o tarea, por ejemplo `feature/login` o `feature/catalogo-deportes`. |
| `docs/<nombre>` | Cambios de documentación, por ejemplo `docs/hito-2`. |
| `fix/<nombre>` | Corrección de un error. |

Flujo: se crea la rama desde `develop`, se trabaja en ella y se abre un pull request hacia `develop`. Al cerrar cada hito, `develop` se integra en `main` y se marca con una etiqueta (`hito-1`, `hito-2`, …).

## Commits

Mensajes cortos, en español y en imperativo, con un prefijo que indique el tipo de cambio:

| Prefijo | Cuándo usarlo | Ejemplo |
| --- | --- | --- |
| `feat:` | Nueva funcionalidad | `feat: agregar filtro por horario en el catálogo` |
| `fix:` | Corrección de un error | `fix: impedir inscripción sin cupo disponible` |
| `docs:` | Documentación | `docs: agregar diagrama de clases del Hito 1` |
| `style:` | Formato o estilos, sin cambiar lógica | `style: ajustar colores del tema` |
| `refactor:` | Reorganizar código sin cambiar su comportamiento | `refactor: separar servicio de inscripciones` |
| `test:` | Pruebas | `test: agregar pruebas del control de cupos` |
| `chore:` | Configuración y mantenimiento | `chore: configurar Firebase Hosting` |

## Pull requests

1. Describe qué cambia y qué requisito o caso de uso cubre (por ejemplo, `CU-03`, `RF-EST-04`).
2. Pide la revisión de al menos otro integrante.
3. Integra solo cuando la revisión esté aprobada y la app compile.

## Buenas prácticas

- Haz `git pull` antes de empezar a trabajar.
- No subas claves ni archivos de configuración privados de Firebase.
- Mantén los commits pequeños y enfocados en una sola tarea.
