# Proyecto: [nombre del asistente]

Usa esta plantilla como punto de partida para el proyecto final. Cualquier tipo
de solución es válido: un notebook, una herramienta de terminal, RAG Python,
un agente AI Hub en IRIS, MCP, una interfaz pequeña o incluso otro framework
externo. Elige lo que te ayude a probar una idea, conserva el dominio docente y
explica los controles que aplicas. No subas `.env` ni ningún secreto.

Antes de entregar, revisa los [criterios para tu proyecto](../../docs/criterios-proyecto.md).
Debe poder verse qué querías probar, qué hiciste, qué ocurrió y qué aprendiste.
No hace falta una solución perfecta, pero sí una exploración concreta que
puedas contar.

## 1. Problema y personas usuarias

- **Problema que resolvemos:** [una frase concreta]
- **Para quién:** [perfil y necesidad]
- **Pregunta o tarea principal:** [ejemplo realista]

## 2. Fuentes y evidencia

- **Datos que usa:** [documentos Markdown y/o tablas demo]
- **Cómo recupera o consulta evidencia:** [chunking, SQL, herramientas…]
- **Cómo muestra procedencia:** [citas, filas, enlaces…]
- **Cómo evalúo que funciona:** [casos versionados y resultado esperado]

## 3. Arquitectura

```text
[entrada] -> [recuperación o herramientas] -> [IRIS / AI Hub] -> [salida]
```

Explica aquí las piezas elegidas y por qué. Indica qué queda en memoria, qué se persiste en IRIS y cuándo se llama a un modelo externo.

## 4. Contrato de entrada y salida

**Entrada**

```json
{"question": "[pregunta de ejemplo]"}
```

**Salida**

```json
{"answer": "[respuesta]", "citations": ["[fuente o fila]"]}
```

## 5. Límites y seguridad

- **Fuera de alcance:** [qué no responde o no hace]
- **Abstención:** [cuándo prefiere no responder]
- **Permisos:** [solo lectura, allow-list, ToolSet…]
- **Secretos:** se cargan desde `.env`, nunca desde código ni Git.

## 6. Cómo ejecutar

```bash
# [pasos mínimos, reproducibles y sin secretos]
```

## 7. Demostración

Prepara tres minutos: problema, una pregunta que funciona con evidencia visible, un límite que se rechaza correctamente y una idea de mejora.
