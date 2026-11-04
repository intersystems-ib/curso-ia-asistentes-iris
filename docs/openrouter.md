# OpenRouter en todo el curso

Los Labs Python, los notebooks, LangChain, la UI y los agentes nativos de AI Hub
usan OpenRouter. El modelo inicial es GPT-OSS 20B. Los embeddings siguen siendo
locales: configurar el modelo de generación no cambia la recuperación.

## Configuración

Copia `.env.example` a `.env` si todavía no tienes configuración local. Define:

```dotenv
OPENROUTER_API_KEY=tu_clave_local
OPENROUTER_MODEL=openai/gpt-oss-20b
```

La clave debe tener saldo y permiso para ese identificador en los guardrails
que hayas configurado. No publiques `.env` ni pegues claves en notebooks.
Si omites el modelo o lo dejas vacío, se usa `openai/gpt-oss-20b`.

`OPENROUTER_MODEL` es común a todo el curso. Para comparar modelos, cambia
únicamente su identificador completo en esta variable y permite ese modelo
en tu guardrail.

Python lee `.env` al ejecutar los ejemplos. Reinicia la aplicación web o el
kernel del notebook si ya estaban abiertos. Las variables exportadas en la
terminal prevalecen sobre `.env`.

Docker recibe la configuración al crear el contenedor:

```bash
docker compose up -d --build --force-recreate iris-aihub
```

Un reinicio simple no incorpora cambios de variables. Crea también un agente
y una sesión nuevos después de cambiar el modelo.

Si conservas `irisdata` de una versión anterior, reconstruir la imagen no
actualiza por sí solo sus clases. Importa el código actualizado en USER:

```objectscript
Set sc = $System.OBJ.LoadDir("/app/src", "ck", , 1)
Do $System.Status.DisplayError(sc)
```

## Cómo se conecta cada ejemplo

- **Python y UI:** `OpenRouterAnswerGenerator` envía mensajes de chat a
  `https://openrouter.ai/api/v1`, con la clave y modelo configurados.
- **LangChain:** el conector compatible `ChatOpenAI` recibe explícitamente
  ese endpoint y la clave de OpenRouter.
- **AI Hub:** `Learning.Agent.Basic` crea el proveedor nativo `openrouter`
  y utiliza el mismo modelo que Python.

El paquete Python `openai`, `langchain-openai` y la clase `ChatOpenAI` conservan
sus nombres técnicos porque implementan el protocolo compatible. No implican
una conexión a otro servicio ni requieren otra clave. Del mismo modo,
`openai/gpt-oss-20b` es el identificador de catálogo de OpenRouter.

Referencia de la integración compatible:
[guía oficial de OpenRouter](https://openrouter.ai/docs/quickstart).

## Comprobación rápida

El Lab 01 permite probar generación sin IRIS:

```bash
python labs/01-python-rag-basico/rag_basico.py --generate
```

Para comprobar herramientas con el agente de soporte, abre la terminal:

```bash
docker compose exec iris-aihub iris session IRIS -U USER
```

Con los datos del Lab 00 cargados:

```objectscript
Set sc = ##class(Learning.Agent.Support).Create(.agent)
Do $System.Status.DisplayError(sc)
Write agent.Model, !
Set session = agent.CreateSession()
Set response = agent.Chat(session, "¿Dónde está ORD-002?")
Write response.Content, !
Write session.GetStats().%ToJSON(), !
Write session.GetContext().%ToJSON(), !
```

Comprueba que GetOrder devuelve DHL-1002 y que GetShipment utiliza ese tracking.
Una respuesta fluida no sustituye a comprobar herramientas y evidencia.
