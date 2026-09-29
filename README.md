# Samán Deportivo

Sistema web y móvil (PWA) de gestión de clubes deportivos para la comunidad de la Universidad Metropolitana (UNIMET).

Los estudiantes consultan las disciplinas y se inscriben en tiempo real, los entrenadores registran la asistencia desde el teléfono y la administración gestiona deportes, cupos y horarios desde un solo lugar.

> Proyecto de la asignatura **Sistemas de Información** (Sección 1, trimestre 2026-2027-1), Facultad de Ingeniería, UNIMET. Profesor: Franklin J. Sandoval S.

## Funcionalidades principales

| Rol | Qué puede hacer |
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
| 1. Objetivo del ciclo de vida | Concepción | En curso |
| 2. Arquitectura del ciclo de vida | Elaboración | Pendiente |
| 3. Capacidad operativa inicial | Construcción | Pendiente |
| 4. Lanzamiento del producto | Transición | Pendiente |

## Estructura del repositorio

```
saman-deportivo/
├── docs/        Documentación del proyecto por hito (Visión, casos de uso, diagramas UML)
├── design/      Enlaces y recursos del prototipo en Figma e identidad visual
├── app/         Código fuente de la aplicación Flutter (se agrega en el Hito 2)
├── README.md
├── CONTRIBUTING.md
└── .gitignore
```

## Documentación

- [Hito 1: Documento de Visión y Casos de Uso (PDF)](docs/Hito1_Vision_y_Casos_de_Uso.pdf)
- [Diagramas UML](docs/)
- [Prototipo y diseño](design/)

## Cómo ejecutar el proyecto

> Esta sección se completa en el Hito 2, cuando se agregue la aplicación Flutter.

Requisitos previstos: Flutter SDK (canal estable), una cuenta de Firebase y Firebase CLI.

```bash
git clone https://github.com/juaneslinarez-byte/saman-deportivo.git
cd saman-deportivo/app
flutter pub get
flutter run -d chrome
```

## Equipo

- Juan Linarez
- Luis Bravo
- Antonio Yibirin
- Sebastian Guillen
- Juan Olivera
- Rocco Garcia

## Cómo colaborar

Revisa [CONTRIBUTING.md](CONTRIBUTING.md) para conocer el flujo de ramas, el formato de los commits y cómo abrir un pull request.
