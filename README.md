# Frontend Hotel

Aplicación Flutter Web para administrar habitaciones, huéspedes, reservas y consumos.

## Estructura

- `lib/main.dart`: punto de entrada mínimo.
- `lib/app.dart`: tema amarillo elegante y configuración global.
- `lib/config/`: URL de la API.
- `lib/services/`: consumo autenticado de Laravel.
- `lib/models/`: definición de módulos y campos.
- `lib/screens/`: inicio de sesión, panel y pantallas de CRUD.
- `lib/widgets/`: formularios y detalles reutilizables.

## Ejecutar

Con el backend iniciado en `http://localhost:8000`, ejecute:

```bash
flutter pub get
flutter run -d chrome --web-hostname=localhost --web-port=3001 --dart-define=API_BASE_URL=http://localhost:8000/api
```

Usuarios de demostración:

- `Admin` / `Hola123`
- `Recepcion` / `Hola123`

La app no completa automáticamente las credenciales: deben ingresarse en el inicio de sesión.
