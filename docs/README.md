# Documentación

Artefactos del proyecto organizados por hito de OpenUP.

## Hito 1: Concepción

| Archivo | Contenido |
| --- | --- |
| [Hito1_Vision_y_Casos_de_Uso.pdf](Hito1_Vision_y_Casos_de_Uso.pdf) | Documento de Visión, especificación de casos de uso y modelado UML |
| [arquitectura.png](arquitectura.png) | Arquitectura seleccionada: Flutter + Firebase |
| [diagrama_casos_de_uso.png](diagrama_casos_de_uso.png) | Diagrama de casos de uso |
| [diagrama_de_clases.png](diagrama_de_clases.png) | Diagrama de clases |
| [diagrama_secuencia_inscribirse.png](diagrama_secuencia_inscribirse.png) | Diagrama de secuencia de CU-03 Inscribirse |

## Hito 2: Elaboración

| Archivo | Contenido |
| --- | --- |
| [modelo-de-datos.md](modelo-de-datos.md) | Colecciones de Cloud Firestore, sus campos y el acceso esperado de cada actor |
| [hito-2/arquitectura.png](hito-2/arquitectura.png) | Arquitectura MVVM de la aplicación sobre Firebase |
| [hito-2/paquetes.png](hito-2/paquetes.png) | Diagrama de paquetes por capas |
| [hito-2/patron_repositorio.png](hito-2/patron_repositorio.png) | Patrón Repositorio |
| [hito-2/patron_observador.png](hito-2/patron_observador.png) | Patrón Observador |
| [hito-2/patron_fabrica.png](hito-2/patron_fabrica.png) | Patrón Fábrica simple (Persona.fromMap) |
| [hito-2/diagrama_clases.md](hito-2/diagrama_clases.md) | Diagrama de clases con Pago ([imagen](hito-2/diagrama_clases.png)) |
| [hito-2/secuencia_inicio_sesion.md](hito-2/secuencia_inicio_sesion.md) | Secuencia de CU-01 Iniciar sesión ([imagen](hito-2/secuencia_inicio_sesion.png)) |
| [hito-2/secuencia_registro.md](hito-2/secuencia_registro.md) | Secuencia del registro de un estudiante ([imagen](hito-2/secuencia_registro.png)) |
| [hito-2/secuencia_inscripcion.md](hito-2/secuencia_inscripcion.md) | Secuencia de CU-03 Inscribirse ([imagen](hito-2/secuencia_inscripcion.png)) |
| [hito-2/secuencia_pago.md](hito-2/secuencia_pago.md) | Secuencia de CU-12 y CU-16: pago de solvencia y revisión ([imagen](hito-2/secuencia_pago.png)) |

Los archivos .dot, .puml y .md (Mermaid) de cada diagrama están junto a su imagen en [hito-2/](hito-2/).

Módulo de autenticación (registro, inicio y cierre de sesión, recuperación de contraseña y perfil), en el código de la aplicación:

| Parte | Ubicación |
| --- | --- |
| Repositorios con Firebase | [auth_repository_firebase.dart](../app/lib/repositorios/auth_repository_firebase.dart) y [usuario_repository_firebase.dart](../app/lib/repositorios/usuario_repository_firebase.dart) |
| ViewModels | [app/lib/viewmodels/](../app/lib/viewmodels/) |
| Pantallas | [app/lib/vistas/auth/](../app/lib/vistas/auth/) y [app/lib/vistas/perfil/](../app/lib/vistas/perfil/) |
| Tema, rutas y validadores | [app/lib/core/](../app/lib/core/) |
| Reglas de seguridad de Firestore | [app/firestore.rules](../app/firestore.rules), publicadas en el proyecto `proyecto-saman-deportivo` |
| Pruebas | [app/test/](../app/test/): 77 pruebas que se ejecutan en cada pull request |

## Hito 3: Construcción

Pendiente: plan de pruebas y módulos principales.

## Hito 4: Transición

Pendiente: manual de usuario y manual técnico.
