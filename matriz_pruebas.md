
# Matriz de Pruebas

## Objetivo
Definir y detallar los casos de prueba para validar las funcionalidades clave de la aplicación "Control de Activos", sus reglas de negocio y la sincronización entre la base local y Firestore.

## Alcance
- Login / autenticación
- Gestión y visualización de activos
- Solicitud, aprobación y vencimiento de préstamos
- Devoluciones y registro de novedades
- Creación automática de mantenimiento por novedad
- Sincronización local ↔ Firestore (offline/online)
- Reglas de negocio críticas (p. ej. límite de préstamos por usuario)

## Entorno de pruebas
- Flutter (mobile / web / desktop)
- Firebase (proyecto: `loan-managment-app-7bf91`)
- Base local: `sqflite` / `sqflite_common_ffi`
- Herramientas recomendadas: VS Code / Android Studio, emuladores, cuentas de prueba en Firebase

## Criterios de aceptación
- Las pantallas críticas cargan sin errores y responden en tiempos razonables.
- Flujos principales (login, solicitar préstamo, devolver) completan sin errores y persisten el estado correcto.
- Reglas de negocio se aplican consistentemente en UI y backend local/Firestore.

## Formato de los casos de prueba
- ID: identificador único (TP-XXX)
- Título: breve descripción
- Prioridad: Alta / Media / Baja
- Precondiciones: datos o estado necesarios antes del test
- Pasos: pasos concretos para ejecutar
- Datos: ejemplos de entrada (usuario, asset id, fechas)
- Resultado esperado: comportamiento exacto que valida el test
- Estado: Pendiente / OK / Falló
- Responsable: persona asignada (opcional)

## Casos de prueba detallados

| ID | Título | Prioridad | Precondiciones | Pasos | Datos | Resultado esperado | Estado | Responsable |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| TP-001 | Login válido | Alta | Cuenta válida en Firebase Auth | 1. Abrir app 2. Ingresar email/clave 3. Pulsar Login | email: tester@example.com | Redirige a HomePage; sesión iniciada | Pendiente | QA |
| TP-002 | Login inválido (credenciales) | Alta | Ninguna | 1. Abrir app 2. Credenciales inválidas 3. Pulsar Login | email: bad@x.com | Mostrar error de autenticación; no avanzar | Pendiente | QA |
| TP-003 | Listar activos disponibles | Alta | Al menos 1 asset con status=Disponible en Firestore | 1. Login 2. Ir a pantalla Activos | - | Lista muestra assets con estado Disponible | Pendiente | QA |
| TP-004 | Solicitar préstamo (activo disponible) | Alta | Usuario con <2 préstamos activos; asset status=Disponible | 1. Seleccionar asset 2. Solicitar préstamo 3. Confirmar | userId: u123, assetId: a123 | Crear préstamo; asset pasa a Prestado; registro en local y en Firestore | Pendiente | QA |
| TP-005 | Bloqueo de solicitud (activo no disponible) | Alta | Asset status=Prestado/Vencido/En mantenimiento/Dado de baja | Intentar solicitar préstamo sobre asset no disponible | assetId: a999 | UI muestra mensaje y no crea préstamo | Pendiente | QA |
| TP-006 | Límite de préstamos por usuario | Alta | Usuario con 2 préstamos activos | Intentar crear tercer préstamo | userId: u_limit | App bloquea solicitud y muestra aviso | Pendiente | QA |
| TP-007 | Devolución sin novedad | Alta | Préstamo activo | 1. Ingresar devolución 2. No reportar novedad | loanId: l123 | Préstamo cerrado; asset vuelve a Disponible | Pendiente | QA |
| TP-008 | Devolución con novedad → crear mantenimiento | Alta | Préstamo activo | 1. Registrar devolución con novedad 2. Confirmar | loanId: l124, novedad: "daño" | Se crea registro Mantenimiento; asset queda En mantenimiento | Pendiente | QA |
| TP-009 | Sincronización offline → online | Media | Modo offline disponible (desconectar red) | 1. Crear préstamo offline 2. Volver online 3. Forzar sync | local record | Registro se sube a Firestore; IDs y estados coinciden | Pendiente | QA |
| TP-010 | Préstamo vencido marcado visualmente | Media | Préstamo con fecha de fin pasada | 1. Abrir lista de préstamos 2. Observar estilo | loanId vencido | Préstamo aparece como Vencido con estilo diferenciado | Pendiente | QA |
| TP-011 | Reglas Firestore: escritura denegada para usuarios no autorizados | Alta | Reglas de Firestore aplicadas en staging | Intentar escritura no permitida | usuario sin permisos | Firestore deniega operación | Pendiente | Dev |
| TP-012 | Accesibilidad (lectores de pantalla) | Baja | - | Navegar pantallas con lector de pantalla | - | Elementos principales accesibles y etiquetados | Pendiente | QA |

## Ejecución y reporte
- Ejecutar pruebas manuales siguiendo las filas de la tabla.
- Registrar resultados en la columna `Estado` y usar issues para fallos reproducibles.
- Para pruebas automáticas, añadir tests en `test/` y ejecutar `flutter test`.

## Pruebas Unitarias
- Objetivo: validar lógica aislada de servicios, controladores y modelos.
- Ubicación: `test/`.
- Ejemplos de pruebas unitarias:
  - Autenticación con `AuthService`.
  - Cálculo de estados de préstamos y vencimientos.
  - Validaciones de formularios en `lib/validators/form_validators.dart`.
  - Operaciones de datos en `lib/data/local_db_helper.dart` y `lib/data/crud_service.dart`.
- Criterios: cada unidad debe pasar en menos de 1 segundo y no depender de Firebase ni UI.

## Pruebas de Widgets
- Objetivo: validar la UI y la interacción entre widgets individuales.
- Ubicación: `test/widget_test.dart` o archivos dentro de `test/widget_tests/`.
- Ejemplos de pruebas de widgets:
  - Renderizar `LoginPage` y validar botones/inputs.
  - Validación de la lista de activos en `ActivosPage`.
  - Verificar navegación de login a home.
  - Mostrar mensajes de error cuando falla una operación.
- Criterios: los widgets deben renderizarse correctamente y responder a interacciones básicas.

## Pruebas de Integración
- Objetivo: validar los flujos completos de la aplicación con múltiples pantallas y/o servicios.
- Ubicación recomendada: `integration_test/`.
- Ejemplos de pruebas de integración:
  - Login completo → navega a home → solicitar préstamo → verificar cambio de estado.
  - Devolución con novedad → confirmación → creación de mantenimiento.
  - Envío de datos offline y sincronización al reconectar.
- Criterios: el flujo completo debe ejecutarse sin errores y mantener estados consistentes entre UI y datos.


