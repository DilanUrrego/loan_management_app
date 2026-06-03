# Bugs Backlog

Este documento recoge los bugs reales detectados en el proyecto con base en la documentación, la implementación actual y la cobertura de pruebas disponible.

## 1. Errores abiertos

Lista de bugs conocidos que aún no están en desarrollo.

| ID | Fecha | Módulo | Descripción | Prioridad | Responsable | Notas |
|---|---|---|---|---|---|---|
| BUG-001 | 2026-06-03 | Sincronización | Sincronización offline/online incompleta y sin pruebas en red intermitente | Alta | — | `docs/release_checklist.md` y `docs/rc_statement.md` indican validación pendiente |
| BUG-002 | 2026-06-03 | Permisos / Firebase | Flujo de permiso denegado no está completamente manejado en la UI | Alta | — | `docs/release_checklist.md` señala que no hay flujo completo implementado |
| BUG-003 | 2026-06-03 | Web / Local DB | `lib/data/local_db_helper.dart` lanza `UnsupportedError` en web por falta de SQLite | Media | — | El README menciona `sqflite`/offline, pero la web no tiene fallback local |
| BUG-004 | 2026-06-03 | Datos | Timeout de sincronización a Firestore fijo en 3s puede fallar con red lenta | Media | — | `lib/data/crud_service.dart` usa `.timeout(const Duration(seconds: 3))` |
| BUG-005 | 2026-06-03 | Pruebas | Pruebas automatizadas presentes pero cobertura limitada a UI/roles; falta validación de sincronización y flujo completo | Media | — | `test/unit/business_rules_test.dart` y `test/widget/ui_states_test.dart` cubren lógica de autorización y estados UI |

## 2. En progreso

Bugs que ya están siendo investigados o corregidos.

| ID | Fecha | Módulo | Descripción | Estado | Responsable | Avance |
|---|---|---|---|---|---|---|
| BUG-006 | 2026-06-03 | Autenticación | Login offline-first no validado en web/escritorio | En progreso | — | Revisar flujo en `lib/data/auth_service.dart` |

## 3. Corregidos / Verificados

Bugs que ya se corrigieron y fueron validados.

| ID | Fecha cierre | Módulo | Descripción | Solución aplicada | Versión |
|---|---|---|---|---|---|
| BUG-000 | 2026-06-02 | UI | Estados de carga/empty/error implementados en UI | Validado en review | 1.0.0 |

## 4. Prioridades sugeridas

- Alta: bloquea el flujo principal o causa pérdida de datos.
- Media: afecta funcionalidad importante, pero existe solución temporal.
- Baja: issue cosmético o que no impacta el uso crítico.

## 5. Cómo usar este backlog

1. Añade un nuevo bug en la sección "Errores abiertos".
2. Asigna prioridad y responsable.
3. Cuando se inicie la corrección, mueve el registro a "En progreso".
4. Una vez validado, mueve el registro a "Corregidos / Verificados".

