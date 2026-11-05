# Lab 05 — RAG nativo con AI Hub

## Objetivo

En los Labs 01 y 02 construiste el RAG de forma explícita. Aquí dejamos que AI Hub conecte una `KnowledgeBase` con un vector store en IRIS y la añadimos al agente de soporte. El resultado combina dos clases de evidencia:

- datos vivos y estructurados, obtenidos mediante herramientas de sólo lectura.
- políticas Markdown, recuperadas semánticamente desde la base de conocimiento.

```mermaid
flowchart TB
    Question[Pregunta de soporte] --> Agent[Agente AI Hub]

    subgraph iris_runtime[Dentro de IRIS]
        Agent --> Tools[Herramientas de solo lectura]
        Tools --> Data[(Pedidos, productos y envíos)]
        Agent --> KB[KnowledgeBase]
        KB --> Search[search_support_policies]
        Search --> Vector[(Chunks de políticas<br/>+ vector store)]
    end

    Data --> Evidence[Evidencia con origen]
    Vector --> Evidence
    Evidence --> Answer[Respuesta con citas]

    classDef input fill:#E7F0F8,stroke:#2B648E,color:#18344D,stroke-width:1.5px;
    classDef process fill:#EEF3F7,stroke:#617A8A,color:#263E50,stroke-width:1.5px;
    classDef iris fill:#D7EBE8,stroke:#19706C,color:#174743,stroke-width:1.5px;
    class Question,Answer input;
    class Agent,Tools,KB,Search,Evidence process;
    class Data,Vector iris;
    style iris_runtime fill:#F7F9FB,stroke:#9AACBA,color:#18344D,stroke-width:1.5px
```

## Antes de empezar

Necesitas haber comprobado las herramientas y la política del [Lab 04](../04-iris-y-aihub/README.md), con IRIS y los datos demo disponibles. Para conversar, reutiliza la [configuración de OpenRouter](../../docs/guia-acceso-aws-alumno.md#4-añade-tu-clave-y-arranca-iris). No necesitas instalar dependencias Python en `.venv` para este recorrido.

Aquí crearás una base de conocimiento nativa con FastEmbed, distinta de la tabla vectorial Python del Lab 02. [FastEmbed](https://qdrant.github.io/fastembed/) es una librería ligera de Python que ejecuta modelos de embeddings localmente para convertir textos en vectores. En este lab permite comparar la pregunta con las políticas por su significado. Si saltas directamente a este lab, completa los requisitos del Lab 04. No necesitas ejecutar los Labs 01–03.

## Recorrido principal: terminal ObjectScript

Este lab construye una `KnowledgeBase` nativa de AI Hub. Jupyter añadiría una capa Python que no participa en esa operación. Trabajaremos directamente en la terminal de IRIS, separando el momento de crear el índice —que escribe estado persistente— de la conversación posterior.

Los embeddings se crean localmente con FastEmbed. Los documentos no se duplican en ObjectScript: se leen desde `datos-demo/knowledge`, disponible dentro del contenedor en `/app/datos-demo/knowledge` gracias al volumen de Docker Compose.

Desde una terminal de VS Code, en la raíz del proyecto, abre una sesión ObjectScript en `USER`:

```bash
docker compose exec iris-aihub iris session IRIS -U USER
```

## De dónde sale `search_support_policies`

La herramienta que ve el agente combina una `KnowledgeBase` nativa de AI Hub con una clase del curso que devuelve documentos completos. Sigue este recorrido con las clases abiertas:

1. **Crear e indexar la base de conocimiento.** Abre [SupportRAG.cls](../../src/Learning/Knowledge/SupportRAG.cls) y mira `Build()`. Conecta FastEmbed con el vector store de IRIS y crea la `KnowledgeBase` con el nombre `search_support_policies`. Fíjate después en `AddVersionedDocuments()`: lee los Markdown y guarda `metadata.source`, que permitirá identificar el documento al recuperar un fragmento.
2. **Conectar la herramienta al agente.** En la misma clase, sigue `AddToSupportAgent()`: inicializa el agente, construye la base de conocimiento y llama a `PolicyDocuments.AddToAgent()`. Abre [PolicyDocuments.cls](../../src/Learning/Knowledge/PolicyDocuments.cls) y compara su `XData Definition` con `AddToAgent()`. El XML publica `search_support_policies` enlazada al método `Search`. La búsqueda nativa se registra en un `SearchManager` interno, mientras que el agente recibe la herramienta de esta clase. Son dos herramientas con el mismo nombre, en gestores distintos.
3. **Seleccionar una política por tema.** En `PolicyDocuments.Search()`, fíjate en la rama `topic` distinta de `general`. `TopicSource()` traduce el tema a un archivo autorizado y `ReadDocument()` devuelve su texto completo. Esta ruta no hace búsqueda vectorial. Por ejemplo, `topic=garantia` selecciona la política de garantía aunque la descripción del producto mencione «cancelación de ruido».
4. **Buscar por significado cuando no hay un tema concreto.** Sigue la otra rama de `Search()`, con `topic=general`. `SearchManager.ExecuteTool()` ejecuta la búsqueda semántica nativa con `query`. Después, `ExpandHits()` usa la fuente de cada fragmento para leer los primeros **dos documentos distintos**, conservando el orden de relevancia y descartando fuentes no autorizadas.
5. **Entender la evidencia devuelta.** En `ReadDocument()`, observa cómo se construyen `text` y `metadata`: el agente recibe el documento completo, su archivo en `source`, `sourcePath`, `retrievalMode=full_document` y `selection=topic` o `semantic`. Sólo la ruta semántica añade `matchedChunkId`. `sourceUrl=null` indica que la fuente es un archivo local, no un enlace web.

Los documentos son breves (193–305 palabras). Una consulta de garantía debe recuperar su política completa, incluidos los 12 meses de reacondicionados y las exclusiones de cobertura. La duración del catálogo no acredita por sí sola las condiciones de garantía. Ambas variantes del agente reciben esa instrucción.

Esta herramienta se aplica **sólo al agente normal y al agente con skill del Lab 05**. Los Labs 01–03 usan fragmentos y contexto por secciones. El MCP del Lab 06 conserva sus cuatro herramientas. La `KnowledgeBase` obtenida con `Build()` sigue devolviendo fragmentos si se utiliza directamente.

La herramienta sólo permite abrir los seis archivos del corpus versionado. Una consulta general vacía devuelve una lista vacía y una fuente fuera de esa lista no permite acceder a archivos arbitrarios. Puedes comprobar la ampliación sin llamar a un modelo ni escribir en el índice:

```objectscript
Do ##class(Learning.Test.PolicyDocuments).Run()
```

Abre también [ReadOnlySupport.cls](../../src/Learning/Policy/ReadOnlySupport.cls) y busca `search_support_policies` en `%CanExecute()`: la búsqueda se autoriza de forma explícita, igual que las herramientas de pedidos. Todas pasan por el `ToolManager`. Al activar la auditoría en el siguiente bloque, podrás observar sus llamadas. Para ver qué comprueba la prueba anterior, abre [Learning.Test.PolicyDocuments](../../src/Learning/Test/PolicyDocuments.cls) y sigue `Run()`.

## Construye, activa el trace y consulta

Primero creamos el agente y añadimos una auditoría de consola. No es un adorno: AI Hub mostrará cada herramienta que el modelo decide invocar, con sus argumentos y el resultado. Así podemos comprobar el flujo en vez de fiarnos de una respuesta que simplemente suena convincente.

```objectscript
Set sc = ##class(Learning.Knowledge.SupportRAG).AddToSupportAgent(.agent)
Do agent.ToolManager.SetAuditPolicy(##class(%AI.Policy.ConsoleAudit).%New())
Set session = agent.CreateSession({"max_iterations":10}) // Máx. iteraciones por pregunta (varias llamadas a herramientas por iteración).
Set response = agent.Chat(session, "¿Qué cubre la garantía de SKU-AUD-001?")
Do ##class(Learning.Helper).PrintResponse(response.Content)
```

La primera vez crea la tabla e índice de la base de conocimiento con FastEmbed, sin una llamada cloud para los embeddings. Si repites el ejercicio, usa un nombre de tabla nuevo o limpia deliberadamente el vector store de práctica: es una escritura persistente, no una comprobación.

## Sigue el recorrido de la respuesta

Antes de leer la respuesta final, mira el trace que aparece en la terminal. En esta pregunta el agente puede necesitar `GetProduct` para conocer el producto y `search_support_policies` para recuperar la política. Lo importante no es que adivine esas herramientas, sino que veas qué decidió usar realmente y qué evidencia devolvió cada una.

Después, consulta las métricas acumuladas de la sesión:

```objectscript
Set stats = session.GetStats()
Write stats.%ToJSON(), !
```

Busca `total_tool_calls`, los tokens y los tiempos. Si quieres inspeccionar el historial completo —incluidos mensajes y llamadas a herramientas— puedes ver su representación JSON:

```objectscript
Set context = session.GetContext()
Write context.%ToJSON(), !
```

`ConsoleAudit` es perfecto para este lab porque trabajamos directamente en la terminal. No lo uses en el endpoint MCP del Lab 06: escribir en la salida estándar rompería la respuesta JSON-RPC. Allí la alternativa correcta será una política de auditoría persistente en IRIS. Este trace tampoco se guarda: si el caso de uso necesitara trazabilidad real, podríamos crear una política propia basada en `%AI.Policy.Audit` que registrase en una tabla la herramienta, sus argumentos, duración y resultado o error.

## Qué observar en la evidencia

No basta con que la respuesta suene razonable. Pide al agente que cite el documento recuperado y compara esa evidencia con el Markdown original. Si la pregunta no tiene respaldo, debe reconocerlo en vez de rellenar el hueco.

## Ideas para explorar por tu cuenta

Si quieres profundizar, puedes probar una pregunta que necesite las dos fuentes, por ejemplo una devolución de un pedido concreto: **«ORD-003 figura como entregado. ¿Puedo devolverlo y qué plazo tengo?»** Es una propuesta opcional y no forma parte de una entrega obligatoria. La conversación con el modelo consume créditos de OpenRouter.

Puedes observar qué parte procede del pedido en IRIS (su estado) y cuál procede de la política Markdown (condiciones y plazo de devolución). El estado Delivered no incluye una fecha real de entrega: la respuesta debe separar el plazo general de la confirmación de que ese pedido esté dentro del plazo. Los metadatos de los fragmentos identifican archivos locales, no URLs. Se citan por su nombre sin inventar un enlace. Ese límite entre herramienta y RAG es justo lo que conviene poder explicar en producción.

## Ampliación opcional — De agente a skill reutilizable

Hasta ahora has visto de forma explícita la cadena agente → ToolSet → política → herramienta. Es la forma más clara de aprenderla. Cuando ese patrón se repite, AI Hub permite empaquetarlo como una **skill**. En este caso, `Learning.Skill.SupportWorkflow` reúne tres cosas orientadas al modelo:

- instrucciones en Markdown sobre cómo atender soporte.
- el ToolSet `Learning.ToolSet.ReadOnlySupport`.
- metadatos breves (`SUMMARY`) para describir la capacidad.

Es el equivalente ObjectScript de un `SKILL.md`: una unidad reutilizable de instrucciones y herramientas. En AI Hub, el parámetro `SKILLS` registra la capacidad durante `%Init()`. Las instrucciones y herramientas se hacen visibles al modelo cuando invoca `load_skill`. `Learning.Agent.SupportWithSkill` pide expresamente activar `support-workflow` antes de atender la consulta. La alternativa programática es `UseSkill`. No es un subagente, no crea una sesión distinta ni recibe permisos propios.

**¿Qué aporta?** Evita repetir el mismo prompt y la selección de herramientas en cada agente, mantiene reglas como «cita las fuentes recuperadas» en un único sitio y ayuda a organizar un agente con varias capacidades —por ejemplo, soporte, analítica y documentación— sin convertir su prompt principal en un texto enorme. No sustituye a las políticas de seguridad: esas siguen siendo responsabilidad del ToolSet y de `Learning.Policy.ReadOnlySupport`.

```mermaid
flowchart TB
    Agent[Agente] --> Skill[Learning.Skill.SupportWorkflow]
    Skill --> Instructions[INSTRUCTIONS<br/>cómo debe responder]
    Skill --> ToolSet[Learning.ToolSet.ReadOnlySupport]
    ToolSet --> Tools[GetOrder · GetProduct<br/>GetShipment · ListOutOfStock]
    Policy[Learning.Policy.ReadOnlySupport] -. autoriza o deniega .-> Tools
    RAG[KnowledgeBase<br/>search_support_policies] --> Agent

    classDef input fill:#E7F0F8,stroke:#2B648E,color:#18344D,stroke-width:1.5px;
    classDef process fill:#EEF3F7,stroke:#617A8A,color:#263E50,stroke-width:1.5px;
    classDef iris fill:#D7EBE8,stroke:#19706C,color:#174743,stroke-width:1.5px;
    class Agent,Skill,Instructions,ToolSet,Tools process;
    class Policy iris;
    class RAG input;
```

Compara las clases: `Support` declara `TOOLSETS`, mientras que `SupportWithSkill` declara `SKILLS`. Ambas heredan de `Basic` y conservan las reglas comunes. El flujo específico de la variante con skill está en `SupportWorkflow.INSTRUCTIONS`, sin repetirlo en el prompt principal.

Prueba esta ruta como una **alternativa** a la creación anterior, en una sesión nueva de IRIS. No hace falta añadirla al agente que ya tenías. La base de conocimiento se añade después exactamente igual y genera `search_support_policies`:

```objectscript
Set sc = ##class(Learning.Knowledge.SupportRAG).AddToSupportAgentWithSkill(.agent)
Do $System.Status.DisplayError(sc)
Write agent.ToolManager.GetToolStatuses().%ToJSON(), !

Do agent.ToolManager.SetAuditPolicy(##class(%AI.Policy.ConsoleAudit).%New())
Set session = agent.CreateSession({"max_iterations":10})
Set response = agent.Chat(session, "ORD-003 figura como entregado. ¿Puedo devolverlo y qué plazo tengo?")
Do ##class(Learning.Helper).PrintResponse(response.Content)
```

Después de la conversación puedes comprobar la activación:

```objectscript
Write session.ActiveSkills.%ToJSON(), !
```

Debe aparecer `Learning.Skill.SupportWorkflow`. Que las herramientas estén registradas en el catálogo no demuestra por sí solo que se hayan cargado las instrucciones de la skill.

Antes de activar la skill, sus herramientas están registradas internamente pero ocultas al modelo. Al activarla, se hacen visibles las mismas herramientas de pedido, producto y envío. `search_support_policies` se añade por separado con la base de conocimiento. En el trace comprueba que la pregunta combina `GetOrder` con la búsqueda de políticas y que la respuesta cita la evidencia.

Lo que cambia es cómo se empaquetan y se reutilizan las instrucciones y el ToolSet. Se mantienen la búsqueda con ampliación a documentos completos, las fuentes Markdown, la política `Learning.Policy.ReadOnlySupport` y los permisos: la skill no concede acceso adicional. Para comprobarlo, intenta una escritura como en el Lab 04. La política debe seguir denegándola. AI Hub también puede cargar skills desde otros orígenes en escenarios más avanzados, pero aquí la dejamos deliberadamente como una clase interna y fácil de inspeccionar.
