# Pruebas

## Objetivo
Este documento centraliza los casos de prueba manuales y automatizados del proyecto "Control de Activos" para garantizar la calidad de los flujos críticos y los estados de la aplicación.

## Alcance
- Login / autenticación
- Gestión de activos
- Solicitud de préstamos
- Devoluciones y novedades
- Creación de mantenimiento automático
- Estados de UI (loading, empty, error)
- Persistencia local y sincronización con Firestore
- Reglas de negocio de usuarios y préstamos

## Entorno de pruebas
- Flutter
- Firebase (proyecto: `loan-managment-app-7bf91`)
- SQL local: `sqflite` / `sqflite_common_ffi`
- Plataformas objetivo:
  - Android
  - Web
  - Desktop (Windows)

## Pruebas automatizadas existentes

### Archivos de pruebas
- `test/unit/business_rules_test.dart`
- `test/widget/ui_states_test.dart`

### Cómo ejecutar
```bash
git checkout <rama-de-pruebas>
flutter test
```

### Cobertura actual
- `test/unit/business_rules_test.dart`
  - Validación de autorización de usuarios
  - Reglas de permiso para solicitar y aprobar préstamos
  - Reglas de negocio sobre estado de préstamos rechazados
- `test/widget/ui_states_test.dart`
  - Estado vacío en lista de activos
  - Pantalla de acceso bloqueado para usuarios `blocked`
  - Pantalla de aprobación pendiente para usuarios `pendingApproval`
  - Dashboard con opciones según rol de usuario
  - Badge de sincronización pendiente en UI

## Casos de prueba manuales

| ID | Título | Prioridad | Resultado esperado | Estado |
|---|---|---|---|---|
| TP-001 | Login válido | Alta | Redirige a home y muestra activos | Pendiente |
| TP-002 | Login inválido | Alta | Muestra mensaje de error; no avanza | Pendiente |
| TP-003 | Listar activos disponibles | Alta | Lista assets con estado Disponible | Pendiente |
| TP-004 | Solicitar préstamo (activo disponible) | Alta | Crea préstamo; activo pasa a Prestado | Pendiente |
| TP-005 | Bloquear solicitud de activo no disponible | Alta | No crea préstamo; muestra aviso | Pendiente |
| TP-006 | Límite de préstamos por usuario | Alta | Bloquea tercer préstamo; muestra aviso | Pendiente |
| TP-007 | Devolución sin novedad | Alta | Activo vuelve a Disponible | Pendiente |
| TP-008 | Devolución con novedad | Alta | Crea mantenimiento; activo queda En mantenimiento | Pendiente |
| TP-009 | Sincronización offline → online | Media | Los datos pendientes se sincronizan al reconectar | Pendiente |
| TP-010 | Préstamo vencido marcado visualmente | Media | Préstamo vence con estilo diferenciado | Pendiente |
| TP-011 | Reglas Firestore: escritura denegada | Alta | Firestore deniega operaciones no autorizadas | Pendiente |
| TP-012 | Accesibilidad básica | Baja | Elementos principales etiquetados y navegables | Pendiente |

## Notas importantes
- El proyecto ya incorpora soporte de estados de carga/empty/error en la UI.
- Existe lógica de persistencia local y sincronización básica, pero la cobertura de pruebas de sync offline/online aún debe confirmarse.
- En web, la base local `sqflite` no está disponible y puede presentar limitaciones si se intenta usar modo offline.

## Información del proyecto (específica)

- **Nombre del paquete:** `final_exam` (ver `pubspec.yaml`)
- **Versión:** `1.0.0+1` (según `pubspec.yaml`)
- **SDK Dart mínima:** `>=3.11.5` (según `pubspec.yaml`)
- **Firebase:** configurado para el proyecto `loan-managment-app-7bf91` (`lib/firebase_options.dart`)
- **Archivos clave:**
  - Punto de entrada: [lib/main.dart](lib/main.dart#L1)
  - Config Firebase: [lib/firebase_options.dart](lib/firebase_options.dart#L1)
  - Inicialización DB escritorio: [lib/data/db_init.dart](lib/data/db_init.dart#L1)
  - Helper local: [lib/data/local_db_helper.dart](lib/data/local_db_helper.dart#L1)
  - Servicios de datos: [lib/data/crud_service.dart](lib/data/crud_service.dart#L1), [lib/data/firestore_service.dart](lib/data/firestore_service.dart#L1)

## Dependencias relevantes

- `firebase_core`, `firebase_auth`, `cloud_firestore` — integración con Firebase
- `sqflite`, `sqflite_common_ffi` — persistencia local (móvil/desktop)
- `uuid`, `path`, `crypto` — utilidades varias

## Ejecutar las pruebas

1. Instala dependencias (una vez):

```bash
flutter pub get
```

2. Ejecutar toda la suite de pruebas:

```bash
flutter test
```

3. Ejecutar tests unitarios específicos:

```bash
flutter test test/unit/business_rules_test.dart
```

4. Ejecutar tests de widgets:

```bash
flutter test test/widget/ui_states_test.dart
```

## Observaciones finales
- Las pruebas existentes cubren reglas de negocio y estados UI, pero no validan escenarios de sincronización en red intermitente ni la integración completa con Firestore en staging.
- Recomiendo ejecutar `flutter test` antes de la presentación y, si es posible, añadir un test de integración que simule operaciones offline → online para cubrir `BUG-001`.

## Recomendaciones
- Ejecutar `flutter test` tras cada cambio crítico.
- Registrar en esta tabla el estado real de cada caso (`OK`, `Falló`, `Pendiente`).
- Abrir issues para cualquier bug reproducible y enlazarlos con este documento.
