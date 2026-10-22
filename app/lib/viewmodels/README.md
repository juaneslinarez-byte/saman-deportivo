# viewmodels

Capa **ViewModel** del patrón MVVM: una clase por pantalla o grupo de pantallas (por ejemplo, `AuthViewModel` o `CatalogoViewModel`).

- Guarda el estado de la pantalla (cargando, error, datos) y ejecuta sus acciones.
- Extiende `ChangeNotifier` y avisa a la vista con `notifyListeners()` cuando cambia algo.
- Usa los repositorios a través de sus interfaces; nunca usa Firebase directamente.
