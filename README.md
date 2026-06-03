# Control de Activos y Préstamos Institucionales

Aplicación Flutter para administrar activos institucionales y controlar préstamos, devoluciones, vencimientos y mantenimiento.

**Estado del proyecto**: aplicación multiplataforma (Android / iOS / Web / Desktop) construida con Flutter.

**Título de la app (UI):** "Control de Activos"

**Resumen rápido**
- **Proyecto:** final_exam (nombre del paquete)
- **App title:** Control de Activos (definido en `lib/main.dart`)
- **Firebase:** configurado para el proyecto `loan-managment-app-7bf91` en `lib/firebase_options.dart`

**Características principales**
- Gestión de activos y sus estados (disponible, prestado, vencido, en mantenimiento, dado de baja).
- Solicitud y aprobación de préstamos.
- Registro de devoluciones y creación de mantenimientos cuando hay novedades.
- Almacenamiento local sincronizado con Firestore cuando hay conexión (usa `sqflite` para modo offline/desktop).
- Autenticación con Firebase Auth.

**Requisitos**
- Flutter SDK compatible con Dart >= 3.11.5
- Android SDK / Xcode para correr en dispositivos móviles
- Si ejecutas en Desktop (Windows/Linux/macOS) se usa `sqflite_common_ffi` (ya inicializado en `lib/main.dart`).
- Cuenta de Firebase y, si deseas, `flutterfire` CLI para reconfigurar el proyecto Firebase.

**Instalación (desarrollo)**
1. Clona el repositorio:

```
git clone <repo-url>
cd loan_management_app
```

2. Instala dependencias:

```
flutter pub get
```

3. (Opcional) Si vas a usar la versión de escritorio, asegúrate de tener las dependencias nativas instaladas. El proyecto ya inicializa la DB para desktop en `lib/main.dart`.

4. Ejecuta la app en el dispositivo deseado:

```
flutter run -d <device-id>
```

Ejemplo web:
```
flutter run -d chrome
```

**Configurar Firebase**
- El proyecto incluye `lib/firebase_options.dart` generado por FlutterFire CLI para el proyecto Firebase `loan-managment-app-7bf91`.
- Si quieres usar tu propio proyecto Firebase, genera una nueva configuración con FlutterFire CLI:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

- Reemplaza `lib/firebase_options.dart` con la salida generada o edita los valores según tu proyecto. Los paquetes `google-services.json` y demás deben colocarse en `android/app/` y los archivos de iOS en sus carpetas correspondientes (si aplica).

**Base de datos local**
- La app usa `sqflite` y `sqflite_common_ffi` para persistencia local en plataformas móviles y desktop.
- Inicialización de la DB de escritorio en: [lib/data/db_init.dart](lib/data/db_init.dart#L1)
- Helper local en: [lib/data/local_db_helper.dart](lib/data/local_db_helper.dart#L1)

**Estructura del proyecto (resumen)**
- `lib/main.dart` — Punto de entrada de la app. [lib/main.dart](lib/main.dart#L1)
- `lib/firebase_options.dart` — Configuración de Firebase (generada). [lib/firebase_options.dart](lib/firebase_options.dart#L1)
- `lib/controllers/` — Lógica de controladores (prestamos, devoluciones, mantenimiento, etc.). Ejemplos:
	- [lib/controllers/prestamos_controller.dart](lib/controllers/prestamos_controller.dart#L1)
	- [lib/controllers/devoluciones_controller.dart](lib/controllers/devoluciones_controller.dart#L1)
- `lib/data/` — Servicios de datos y persistencia (Firestore, SQLite, Auth). Ejemplos:
	- [lib/data/auth_service.dart](lib/data/auth_service.dart#L1)
	- [lib/data/firestore_service.dart](lib/data/firestore_service.dart#L1)
	- [lib/data/crud_service.dart](lib/data/crud_service.dart#L1)
- `lib/models/` — Modelos de dominio (asset, loan, user, maintenance, history). Ejemplos:
	- [lib/models/asset.dart](lib/models/asset.dart#L1)
	- [lib/models/loan.dart](lib/models/loan.dart#L1)
- `lib/pages/` — Pantallas de la aplicación (login, home, préstamos, devoluciones, historial). Ejemplos:
	- [lib/pages/login_page.dart](lib/pages/login_page.dart#L1)
	- [lib/pages/prestamos_page.dart](lib/pages/prestamos_page.dart#L1)
	- [lib/pages/devoluciones_page.dart](lib/pages/devoluciones_page.dart#L1)
- `lib/widgets/` — Componentes UI reutilizables (cards, diálogos).

**Entidades mínimas**
- Usuario
- Activo
- Préstamo
- Devolución
- Mantenimiento
- Historial

**Roles mínimos**
- Solicitante
- Encargado de inventario
- Administrador

**Estados mínimos de un activo**
- Disponible
- Prestado
- Vencido
- Devuelto
- En mantenimiento
- Dado de baja

**Reglas de negocio (resumen)**
- No se puede solicitar préstamo de un activo que esté prestado, vencido, en mantenimiento o dado de baja.
- Un usuario no puede tener más de dos préstamos activos.
- Una devolución con novedad debe crear automáticamente un registro de mantenimiento.
- Un préstamo vencido debe aparecer con un estado visual diferente.
- Un activo devuelto vuelve a disponible solo si no tiene novedad.
- Solo el encargado de inventario puede confirmar la devolución.

**Flujo principal esperado**
1. Login → consultar activos disponibles → seleccionar activo → solicitar préstamo → validar préstamo pendiente o activo.

**Pruebas**
- Ejecutar tests unitarios/ widget tests:

```
flutter test
```

**Depuración y desarrollo**
- Logs y depuración se pueden realizar desde las herramientas de Flutter/IDE (Android Studio, VS Code).

**Contribuir**
- Abre un issue describiendo el bug o feature.
- Crea una rama con nombre `feature/descripcion` o `fix/descripcion` y envía un PR con pruebas y descripción clara.

**Notas y mejoras pendientes**
- Añadir documentación de API (endpoints Firestore y colecciones).
- Agregar más tests automatizados.
- Mejorar manejo de errores y reconexión/sincronización offline.

Si quieres, puedo:
- Añadir badges (build / tests / license).
- Generar documentación más detallada por carpeta.
- Crear un archivo `CONTRIBUTING.md` y `LICENSE`.

---

README generado y estructurado por el equipo de desarrollo.

**Documentación de pruebas**

La documentación centralizada de pruebas se encuentra en: [pruebas.md](pruebas.md)

