const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Para Android, el teléfono debe alcanzar el backend por la red local.
  // Cambia esta IP si el equipo se conecta a otra red.
  defaultValue: 'http://192.168.0.105:8000/api',
);
