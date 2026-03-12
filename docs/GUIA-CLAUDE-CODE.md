# Guía: Usar Claude Code con UPTP Control

---

## Paso 1: Instalar Claude Code

```bash
# Requiere Node.js >= 18
npm install -g @anthropic-ai/claude-code
```

Verificar que funcione:
```bash
claude --version
```

---

## Paso 2: Clonar tu repo y copiar los archivos de configuración

```bash
# Clonar el repo
git clone https://github.com/elsiosanchez/uptp-control.git
cd uptp-control
```

Copiá los siguientes archivos descargados a tu repo:

```
uptp-control/
├── CLAUDE.md                              ← Contexto del proyecto
├── docs/
│   ├── PLAN.md                            ← Plan de construcción por fases
│   ├── FIRESTORE_SCHEMA.md                ← Esquema de Firestore
│   └── ARCHITECTURE.md                    ← Diagrama de arquitectura
└── .claude/
    ├── commands/                           ← Slash commands
    │   ├── build-phase.md                 ← /build-phase
    │   ├── status.md                      ← /status
    │   ├── test-module.md                 ← /test-module
    │   └── commit.md                      ← /commit
    ├── agents/
    │   └── flutter-builder.md             ← Agente Flutter
    └── skills/
        └── flutter-firebase/
            └── SKILL.md                   ← Patrones Flutter+Firebase
```

---

## Paso 3: Iniciar Claude Code

```bash
cd uptp-control
claude
```

Claude va a leer automáticamente tu `CLAUDE.md` y ya tendrá todo el contexto del proyecto.

---

## Paso 4: Construir la App fase por fase

### Opción A: Usar el comando /build-phase (recomendado)

Simplemente escribí en Claude Code:

```
/build-phase
```

Esto va a:
1. Leer `docs/PLAN.md`
2. Encontrar la siguiente fase pendiente
3. Ejecutar todas las tareas de esa fase
4. Marcar las tareas como completadas

Repetí `/build-phase` para avanzar fase por fase.

### Opción B: Pedirle directamente

```
Implementa la Fase 1 del plan en docs/PLAN.md
```

### Opción C: Tarea específica

```
Crea el modelo de Sección siguiendo el esquema en docs/FIRESTORE_SCHEMA.md
```

---

## Paso 5: Verificar el progreso

```
/status
```

Te muestra cuántas tareas van completadas por fase y el avance total.

---

## Paso 6: Verificar un módulo

```
/test-module secciones
```

Verifica que el modelo, service, provider y screens del módulo estén correctos.

---

## Paso 7: Hacer commit

```
/commit
```

Genera automáticamente un mensaje de commit descriptivo y hace el push.

---

## Paso 8: Usar el agente Flutter Builder

Para tareas complejas que requieren múltiples archivos, usá el agente:

```
@flutter-builder Implementa el módulo completo de notas con registro masivo
```

El agente tiene contexto especializado de Flutter + Firebase y sigue las convenciones del proyecto.

---

## Flujo de Trabajo Recomendado

```
1. claude                          # Iniciar sesión
2. /status                         # Ver dónde quedamos
3. /build-phase                    # Construir siguiente fase
4. /test-module [nombre]           # Verificar lo construido
5. /commit                         # Guardar cambios
6. Repetir desde paso 2
```

---

## Comandos Disponibles

| Comando | Qué hace |
|---|---|
| `/build-phase` | Ejecuta la siguiente fase pendiente del plan |
| `/status` | Muestra progreso del proyecto |
| `/test-module [nombre]` | Verifica un módulo (secciones, materias, etc.) |
| `/commit` | Commit automático con mensaje descriptivo |

---

## Tips

- **Contexto limpio:** Si la conversación se pone larga, escribí `/clear` para limpiar el contexto. Claude va a re-leer CLAUDE.md automáticamente.
- **Ser específico:** En vez de "arregla los errores", decí "ejecuta flutter analyze y corrige los errores que encuentres".
- **Iterar:** Si algo no quedó bien, decile qué cambiar. No empezás de cero.
- **Git frecuente:** Usá `/commit` después de cada fase para tener checkpoints.

---

## Solución de Problemas

### Claude Code no reconoce los comandos
Verificá que los archivos `.claude/commands/*.md` existan en la raíz del proyecto.

### El agente no sigue las convenciones
Revisá que `CLAUDE.md` esté en la raíz del proyecto (no dentro de una subcarpeta).

### Flutter no compila
Pedile a Claude:
```
Ejecuta flutter analyze y corrige todos los errores
```
