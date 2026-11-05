# AGENTS

Este archivo agrupa las reglas que yo (Codex) debo respetar al trabajar en este repo. Esta basado en los `.agent/rules` y `.agents/rules` que usabas para Gemini, pero en un formato mas facil de consumir al iniciar chats nuevos.

## 1. Arquitectura y flujo
- Antes de codificar, presento un esquema de clases (entidades, repositorios, providers).
- Defino contratos/abstracciones en Domain antes de implementar la capa Data.
- Mantengo las clases por debajo de 200 lineas salvo justificacion clara.
- La estructura es Clean Architecture: Domain puro, Data con implementaciones/DTO, Presentation con Flutter/Riverpod.
- Stack esperado: Riverpod (generadores si corresponde), GoRouter, Dio (con interceptores), Freezed para modelos inmutables.

## 2. Negocio y producto
- Multi-tenancy completo: cada profesional solo ve sus datos; filtros `providerId` obligatorios en Firestore y en el codigo.
- El ledger aplica deuda por turno, saldo = monto - pagos, pagos FIFO, `liquidated` a saldo 0.
- Notificaciones WhatsApp mensuales para pacientes con deuda (`totalDebt > 0`), guardando log en subcoleccion `communications` con `messageId`, `sentAt`, `status`, `totalDebtAtThatTime`.
- Siempre se verifica si ya se envio un recordatorio en 24h antes de llamar a Meta API.

## 3. Firebase y backend
- Respeto la separacion `/lib`, `/firebase/functions`, `/firebase/firestore_rules`, `/firebase/storage_rules`.
- Pruebo todo en emuladores (`firebase emulators`); en Flutter uso `10.0.2.2`/`localhost` si `use_emulator`.
- Firebase vive en Data. Nunca expongo snapshots/credenciales en Domain: siempre mapeo a entidades puras y convierto excepciones Firebase en `Failure`.
- Cloud Functions en TypeScript, modularizadas y con validacion (`zod` u otra) antes de procesar datos.
- Regla de seguridad: no hardcodear secrets; versionar reglas y desplegarlas via CLI.

## 4. Seguridad, privacidad y suscripciones
- No logueo PII (nombres, telefonos, montos) en produccion.
- No guardo diagnosticos/nota medica, solo concepto del turno.
- Suscripcion: tres estados (`active`, `past_due`, `suspended`); si esta `suspended` se bloquean escrituras pero se permite lectura.
- Cada ingreso valida el estado de suscripcion via Provider antes de habilitar acciones.
- **Pre-commit/deploy:** invocar Security Guardian para analisis OWASP, multi-tenancy leaks, PII exposure, code smells.
- Validar security rules con MCP `firebase_validate_security_rules` antes de deploy.

## 5. UX/ UI/ animaciones
- Material 3: uso `NavigationBar`, `FilledButton`, `Card`; colores/spacing via `Theme` y constantes (escala 8px).
- Mobile-first, adaptabilidad con `LayoutBuilder`/`MediaQuery`; dialogos coherentes en distintos tamanos.
- Limito `build()` a 60-80 lineas; mas de 3 niveles de nesting implica extraer widgets (idealmente en `presentation/widgets/`).
- Prefiero widgets tontos; logica en providers/convertidores y `onTap` solo delega a controladores.
- No hardcodeo colores o spacing; si un widget se repite, lo extraigo como componente.
- Uso animaciones con proposito (200-400ms) mediante widgets implicitos, `RepaintBoundary` si es necesario, y respeto `prefers-reduced-motion`.
- Para cargas uso `skeletonizer`; estados de error/empty deben ser amigables y con CTA; chequear conectividad (`connectivity_plus`) antes de acciones claves.
- Riverpod `AsyncValue` se maneja con `.when(data:..., error:..., loading:...)`.
- Feedback con `HapticFeedback.lightImpact()` en acciones exitosas y transiciones suaves (`flutter_animate`).

## 6. WhatsApp & fiabilidad
- Cada mensaje debe incluir variables obligatorias (`{{monto_total}}`, `{{nombre_paciente}}`).
- Se apunta a "check-before-write": siempre verificar el ultimo envio y evitar duplicados antes de disparar la API.

## 7. TDD y testing
- Aplico el ciclo rojo/verde/refactor. **El ciclo es innegociable: ningun agente de implementacion arranca sin tests RED previos.**
- Tests obligatorios para caminos negativos (401, 404, 500, JSON mal formado, sin conexion, cancelaciones).
- Unit tests para casos de uso/repositorios; uso `mocktail` o `mockito`.
- No uso `try/catch` genericos en la UI; la capa Data convierte excepciones en `Failure` y la UI reacciona a `AsyncError`.
- **Un bug fix SIEMPRE empieza con un test que reproduce el bug (RED) antes de tocar codigo.**
- **Un refactor SIEMPRE empieza verificando cobertura existente. Si no hay, TDD Writer la crea primero.**

## 8. Ecosistema de herramientas (uso obligatorio — no proactivo, OBLIGATORIO)

### ⚠️ Regla crítica de delegacion

NUNCA escribir codigo directamente sin delegar al agente correspondiente. La tabla de abajo es un contrato, no una sugerencia.

TDD Writer y Documentation Keeper son OBLIGATORIOS en toda tarea que produzca codigo. Solo pueden omitirse en los casos listados en "Excepciones acotadas" del orchestrator.

### Agentes (`.claude/agents/`) — triggers y excepciones

| Agente | Trigger obligatorio | Puede omitirse cuando |
|--------|--------------------|-----------------------|
| 📋 Spec Agent | **Gate 0 para features no triviales** — antes de Planner y TDD | Feature trivial (cambio estetico, copy, config), fix de bug sin nuevo contrato, refactor sin cambio de comportamiento, solo lectura |
| 🔥 Firebase Data Layer | Cualquier toque a Cloud Functions, DataSources, Firestore | Nunca si hay cambios en esas areas |
| 🏗️ Flutter Feature Builder | Feature end-to-end nueva | Solo si la feature es exclusivamente backend o UI |
| 🎨 UI Composer | Cualquier creacion o modificacion de widgets/screens | Solo lectura / investigacion |
| 🧪 TDD Writer | **SIEMPRE antes de implementar y despues de implementar** | Solo lectura, config pura, typo/copy sin logica |
| 🛡️ Security Guardian | **SIEMPRE si hubo cambios de codigo** | Solo lectura / investigacion |
| 📚 Documentation Keeper | **SIEMPRE si hubo cambios de codigo** (ver excepciones) | Solo lectura, config pura, typo sin impacto en contratos, cambios solo en tests |

### Checklist de cierre obligatorio

Despues de cada tarea que produzca codigo, DEBO declarar:
- Que agentes invoque (con resultado).
- Que agentes omiti (con motivo explicito).
- Si 🧪 o 📚 fueron omitidos sin excepcion valida, declararlo como error de proceso.

### Subagents (`.agent/subagents.toml`)
7 agentes registrados: ui-atomic-composer, ui-states-polisher, ui-motion-engineer, testing-tdd-enforcer, firebase-boundary-guardian, security-guardian, documentation-keeper.

### MCP Servers
- **Firebase MCP**: Firestore CRUD, functions logs, security rules validation
- **Mercado Pago MCP**: docs, notifications, quality checks, webhooks

### Skills instaladas
- `find-skills` (vercel-labs/skills) — descubrir skills
- `api-documentation` (supercent-io) — docs de API
- `documentation-writer` (github/awesome-copilot) — documentacion general
- `firebase-basics` (firebase/agent-skills) — patterns Firebase
- `firebase-auth-basics` (firebase/agent-skills) — patterns Auth

## 9. Documentacion
- Documentation Keeper DEBE invocarse post-feature y al modificar Domain. No es opcional.
- Toda entidad de Domain, repo abstracto y provider publico DEBE tener dartdoc.
- Toda Cloud Function nueva o modificada DEBE tener API doc y entrada en CHANGELOG.
- CHANGELOG.md con formato Keep a Changelog. Cualquier feature, fix o cambio de comportamiento DEBE tener entrada.

## 10. Logistica
- Si queres alertarme de una regla extra "siempre activa", actualiza este `AGENTS.md`.
