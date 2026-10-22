# Samán Deportivo

Sistema web y móvil (PWA) de gestión de clubes deportivos para la comunidad de la Universidad Metropolitana (UNIMET).

Los estudiantes consultan las disciplinas y se inscriben en tiempo real, los entrenadores registran la asistencia desde el teléfono y la administración gestiona deportes, cupos y horarios desde un solo lugar.

> Proyecto de la asignatura **Sistemas de Información** (Sección 1, trimestre 2026-2027-1), Facultad de Ingeniería, UNIMET. Profesor: Franklin J. Sandoval S.

## Funcionalidades principales

| Actor | Qué puede hacer |
| --- | --- |
| Estudiante | Buscar disciplinas con filtros por día, horario y cupo; inscribirse (con validación de solvencia) y cancelar; ver su historial de asistencia. |
| Entrenador | Consultar la nómina de inscritos y registrar la asistencia por sesión. |
| Administrador | Crear y gestionar deportes, asignar entrenadores y configurar cupos y sesiones. |

El sistema controla los cupos con transacciones, de modo que dos inscripciones simultáneas nunca superan el cupo disponible.

## Tecnologías

- **Frontend:** [Flutter](https://flutter.dev) (Dart), compilado para web como PWA.
- **Backend:** [Firebase](https://firebase.google.com): Authentication, Cloud Firestore y Hosting.
- **Diseño:** Figma (prototipo de UI/UX).
- **Control de versiones:** Git y GitHub.

## Metodología

El proyecto sigue **OpenUP**, con cuatro fases cerradas por un hito:

| Hito | Fase | Estado |
| --- | --- | --- |
| 1. Objetivo del ciclo de vida | Concepción | Completado |
| 2. Arquitectura del ciclo de vida | Elaboración | En curso |
| 3. Capacidad operativa inicial | Construcción | Pendiente |
| 4. Lanzamiento del producto | Transición | Pendiente |

## Estructura del repositorio

```
saman-deportivo/
├── docs/        Documentación del proyecto por hito (Visión, casos de uso, diagramas UML)
├── design/      Enlaces y recursos del prototipo en Figma e identidad visual
├── app/         Código fuente de la aplicación Flutter
├── .github/     Verificación automática de cada pull request (GitHub Actions)
├── README.md
├── CONTRIBUTING.md
└── .gitignore
```

## Arquitectura de la aplicación

La aplicación sigue el patrón **MVVM** (Modelo-Vista-ViewModel). El código de `app/lib/` se organiza en estas carpetas:

```
app/lib/
├── vistas/        Pantallas, por actor: auth, perfil, estudiante, entrenador, administrador
├── viewmodels/    Estado y acciones de cada pantalla
├── repositorios/  Acceso a los datos (patrón Repositorio): interfaces e implementaciones con Firebase
├── modelos/       Entidades del dominio: Persona, Estudiante, Entrenador, Administrador, Deporte, Sesion, Inscripcion, Asistencia y Pago
├── core/          Tema visual, rutas, validadores y widgets compartidos
└── main.dart
```

Las dependencias van en un solo sentido: las vistas usan los ViewModels, los ViewModels usan los repositorios y los modelos, y **solo los repositorios usan Firebase**. Cada carpeta tiene un README con sus reglas.

## Documentación

- [Hito 1: Documento de Visión y Casos de Uso (PDF)](docs/Hito1_Vision_y_Casos_de_Uso.pdf)
- [Diagramas UML](docs/)
- [Prototipo y diseño](design/)

## Cómo ejecutar el proyecto

Requisitos: Flutter 3.47.7 (canal estable) y Google Chrome. La conexión con Firebase se agrega en el Hito 2.

```bash
git clone https://github.com/juaneslinarez-byte/saman-deportivo.git
cd saman-deportivo/app
flutter pub get
flutter run -d chrome
```

## Equipo

| Integrante | Rol |
| --- | --- |
| Sebastian Guillen | Líder de proyecto |
| Juan Linarez | Arquitecto de software |
| Rocco Garcia | Diseñador UX/UI |
| Luis Bravo | Desarrollador Frontend (Flutter) |
| Antonio Yibirin | Desarrollador Backend (Firebase) |
| Juan Olivera | Analista y pruebas |

## Cómo colaborar

Revisa [CONTRIBUTING.md](CONTRIBUTING.md) para conocer el flujo de ramas, el formato de los commits y cómo abrir un pull request.

Cada pull request pasa por una verificación automática que revisa el formato, ejecuta `flutter analyze` y las pruebas, y compila la versión web. Antes de subir cambios, ejecuta lo mismo en tu computadora:

```bash
cd app
dart format lib
flutter analyze
```
