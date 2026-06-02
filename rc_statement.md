
# RC Statement (Release Candidate)

**Proyecto:** final_exam — Control de Activos

**Versión:** 1.0.0+1 (según `pubspec.yaml`)

**Fecha:** 2026-06-02

## Resumen ejecutivo
Release Candidate que contiene el conjunto mínimo viable de funcionalidades para la gestión de activos y préstamos: autenticación, persistencia local y sincronización con Firestore, flujos de solicitud y devolución, y manejo de mantenimiento por novedades. Esta RC está preparada para validación QA y pruebas en staging.

## Cambios relevantes desde la versión anterior
- Implementación de flujo de devolución con generación automática de `Mantenimiento` cuando se reporta novedad.
- Lógica de negocio para limitar a 2 préstamos activos por usuario.
- Inicialización de base local para escritorio (`sqflite_common_ffi`) y sincronización básica.
- Configuración Firebase incluida en `lib/firebase_options.dart` (proyecto: `loan-managment-app-7bf91`).

## Alcance de la RC
- Login / autenticación (Firebase Auth)
- Listado y detalle de activos
- Solicitud y gestión de préstamos
- Devoluciones y registro de novedades
- Persistencia local y sincronización (sqflite ↔ Firestore)

## Commit range / referencia
- Desde: `<commit-hash-anterior>`
- Hasta: `<commit-hash-actual>`

## Pruebas realizadas (resumen)
- Tests unitarios: agregar aquí resultados de `flutter test` (pendiente ejecutar).
- Pruebas manuales realizadas: login, solicitud de préstamo, devolución con novedad, verificación de cambio de estado.
- Matriz de pruebas asociada: [matriz_pruebas.md](matriz_pruebas.md#L1)

## Criterios mínimos para declarar RC
| Criterio | Estado | Observación |
| --- | --- | --- |
| Login funcional con cuentas de prueba | Pendiente | Validar flujo completo en staging |
| Solicitud de préstamo en activo disponible | Pendiente | Verificar cambio de estado en UI y backend |
| Devolución con novedad crea mantenimiento | Pendiente | Confirmar creación de registro y estado del asset |
| Sincronización offline/online | Pendiente | Probar en entorno con red intermitente |
| Reglas de negocio de límite de préstamos | Pendiente | Usuario no debe tener >2 préstamos activos |
| Builds generados exitosos | Pendiente | APK/AAB/Web deben compilar sin errores |

## Justificación
Esta RC está diseñada para asegurar que las funciones básicas de gestión de activos y préstamos estén completas y verificadas antes de avanzar a producción. Incluye validaciones de autenticación, estados de activos, flujos de préstamo y devolución, así como la sincronización entre la base local y Firestore.

## Plataformas objetivo
- Android
- Web
- Desktop (Windows; Linux requiere reconfiguración de Firebase)

## Riesgos y mitigaciones
- Riesgo: conflictos de sincronización en escenarios con cambios concurrentes.
	- Mitigación: revisar la estrategia de conciliación y añadir logging detallado.
- Riesgo: reglas de Firestore no validadas para producción.
	- Mitigación: validar reglas en entorno staging y ejecutar tests de seguridad.



