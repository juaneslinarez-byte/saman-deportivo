# Samán Deportivo

Sistema web y móvil de gestión de los clubes deportivos de la **Universidad Metropolitana (UNIMET)**. Los estudiantes consultan disciplinas y cupos en tiempo real, se inscriben, pagan su solvencia y reservan eventos; los entrenadores toman asistencia; y la coordinación administra disciplinas, horarios, usuarios, pagos y eventos.

**Aplicación publicada:** https://proyecto-saman-deportivo.web.app (se puede instalar en el teléfono como PWA)

Proyecto de la asignatura Sistemas de Información (Trimestre 2026-2027-1), Grupo 4. Metodología OpenUP.

## Funcionalidades

| Actor | Qué puede hacer |
|---|---|
| Estudiante | Registrarse con su correo institucional, buscar disciplinas por nombre, cupos, día y horario, inscribirse y cancelar, pagar la solvencia con PayPal, reservar y pagar eventos, ver su asistencia y dejar reseñas. |
| Entrenador | Ver sus disciplinas y su nómina, tomar y corregir la asistencia con un calendario de clases y consultar el historial. |
| Administrador | Panel con cifras en tiempo real; crear, editar, publicar y eliminar disciplinas; asignar varios entrenadores; gestionar sesiones y cupos; inscribir y sacar estudiantes; moderar reseñas; habilitar usuarios y convertirlos en entrenadores; aprobar pagos; publicar eventos y aprobar o rechazar reservas. |

## Tecnologías

- **Flutter 3.47.7** (web) y Dart ^3.13.5
- **Firebase:** Authentication, Cloud Firestore y Hosting
- **provider** para MVVM e inyección de dependencias
- **PayPal JavaScript SDK** en modo sandbox para los pagos
- **GitHub Actions** para verificar cada pull request

## Arquitectura

MVVM con los patrones **Repository** (interfaz + implementación de Firebase), **Observer** (Streams de Firestore y `ChangeNotifier`) y **Simple Factory** (`Persona.fromMap`).

```
app/lib/
├── core/          rutas, tema, colores, validadores, formatos, catálogos, PayPal
├── modelos/       Persona → Estudiante / Entrenador / Administrador, Deporte, Sesion,
│                  Inscripcion, Asistencia, Pago, Resena, Evento, Reserva
├── repositorios/  interfaces y su implementación *_firebase.dart
├── viewmodels/    estado y reglas de cada pantalla
└── vistas/        pantallas por actor (auth, estudiante, entrenador, administrador, comun)
```

Las reglas de seguridad están en [`app/firestore.rules`](app/firestore.rules): cada inscripción o reserva mueve el cupo en la misma operación (`getAfter`), nadie puede registrarse como administrador ni declararse solvente, y solo el administrador aprueba pagos.

## Instalación

Requisitos: Flutter 3.47.7 con soporte web, Google Chrome y, para publicar, Node.js con Firebase CLI (`npm install -g firebase-tools`).

```bash
git clone https://github.com/juaneslinarez-byte/saman-deportivo.git
cd saman-deportivo/app
flutter pub get
flutter run -d chrome
```

La app usa el proyecto de Firebase ya configurado en `lib/firebase_options.dart`; no hace falta ningún archivo de credenciales. Para usar otro proyecto: `flutterfire configure --project=<id> --platforms=web`.

## Pruebas

```bash
cd app
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter test        # 96 pruebas: modelos, reglas de negocio, ViewModels y vistas
```

El flujo **Verificar aplicación** de GitHub Actions corre estos pasos y `flutter build web` en cada PR y en cada push a `develop` y `main`.

## Despliegue

```bash
cd app
flutter build web --release
firebase deploy --only hosting --project proyecto-saman-deportivo
firebase deploy --only firestore:rules --project proyecto-saman-deportivo
```

Versión de pruebas sin tocar producción: `firebase hosting:channel:deploy pruebas --expires 14d`.

## Pagos con PayPal

La solvencia ($20) y los eventos con precio se pagan con el botón oficial de PayPal en **modo sandbox** (cuentas de prueba, sin dinero real). El Client ID está en `app/lib/core/paypal.dart`; el Secret nunca está en la app. El pago queda en revisión y el administrador lo aprueba después de verificar la referencia en PayPal.

## Flujo de trabajo

Ramas `feature/…` o `fix/…` desde `develop`, PR hacia `develop` con commits `feat:` o `fix:` en español e integración con squash cuando la verificación está en verde. `develop` pasa a `main` en cada liberación.

## Documentación

El Manual de Usuario y el Manual Técnico e instalación se entregan con el Hito 4.

## Equipo (Grupo 4)

Juan Linarez (líder) · Luis Bravo · Antonio Yibirin · Sebastián Guillén · Juan Olivera · Rocco García

Profesor: Franklin J. Sandoval S.
