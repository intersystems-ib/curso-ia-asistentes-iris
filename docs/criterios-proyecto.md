# Criterios para tu proyecto final

Tu proyecto es un espacio para probar, preguntar y aprender: no hace falta que llegues con una idea cerrada ni que aciertes a la primera. Se valora que puedas explicar una exploración útil y demostrable, no que añadas más capas de las necesarias.

Puedes explorar una hipótesis pequeña, encontrar un límite y enseñarlo con honestidad. Un intento que explica qué falló, cómo lo comprobaste y qué harías después aporta mucho más que una demo aparentemente perfecta pero opaca.

No hay un formato ni una tecnología obligatorios. Puede ser un notebook, una herramienta de terminal, un RAG Python, una solución directamente en IRIS con AI Hub, un servidor MCP, una pequeña interfaz o un framework externo. Elige lo que mejor te ayude a explorar tu idea y explica por qué lo has elegido. Usar IRIS no da puntos por sí mismo: es una opción más, no un requisito.

## Alcance y dedicación

El proyecto es individual y se trabaja durante la semana posterior a las dos sesiones de demostración. La dedicación orientativa es de **cuatro horas**. Elige una pregunta que puedas explorar en ese tiempo. Basta con ampliar o investigar una sola pieza del curso.

No necesitas reproducir todos los laboratorios antes de empezar. Puedes volver al ejemplo que te ayude a probar tu idea y trabajar desde ahí. Las ideas para explorar que aparecen en los labs son opcionales. Puedes inspirarte en una de ellas o proponer otra, sin tener que completarlas todas.

Como orientación, puedes dedicar una hora a elegir la pregunta y reproducir el ejemplo de partida, hora y media a experimentar, una hora a conservar evidencia y documentar lo observado, y media hora a preparar la presentación.

## Algunas ideas para empezar

Estas propuestas son ejemplos, no una lista de tareas:

- **Recuperación documental:** comparar las fuentes y el contexto de una misma pregunta antes y después de cambiar el tamaño de chunk o el umbral. ¿Mejora algo? ¿Empeora otro caso?
- **Herramientas de un agente:** explorar una herramienta pequeña de lectura, su entrada y su resultado, y comprobar qué permite o deniega la política.
- **MCP:** plantear otra consulta sobre pedidos o productos, conservar los eventos y comprobar qué herramientas utiliza realmente el cliente.

Puedes usar los datos sintéticos del curso. Si prefieres otro caso, usa datos que puedas compartir y evita información personal o confidencial.

## Qué entregar

Para que podamos evaluar tu proyecto, prepara una idea concreta y algún artefacto que permita seguirla: un notebook, código, una herramienta de terminal, capturas o una pequeña demo. Tendrás que contar qué querías probar, qué ocurrió y qué aprendiste. No hace falta que todo funcione. Sí hace falta haberlo trabajado y poder explicarlo.

La entrega debe incluir:

- **El material del experimento:** archivos o un enlace accesible al instructor. No es obligatorio crear un repositorio público ni una interfaz.
- **Una explicación breve:** pregunta, qué probaste, resultado, evidencia y límite o aprendizaje. Puedes usar la [plantilla de proyecto](../plantillas-proyecto/proyecto-asistente/README.md).
- **Cómo seguir la prueba:** pasos de ejecución y requisitos si hay código. Si entregas capturas o registros, indica la entrada, las condiciones de la prueba y qué muestran.

El instructor comunicará la fecha y el canal de entrega. No incluyas `.env`, claves, archivos de acceso ni datos privados. Si hace falta describir la configuración, usa nombres de variables o un `.env.example` sin secretos.

Si el experimento no llega a funcionar, conserva el error o resultado observado, explica qué intentaste y cuál sería la siguiente prueba. No hace falta sustituirlo por una demo que oculte el problema.

## Cómo presentar tu proyecto

Como ejemplo orientativo, cada alumno podría disponer de **cinco minutos**: **tres de exposición y dos de dudas**. El instructor confirmará la duración y el orden de los turnos según el número de participantes.

Los tres minutos de exposición podrían repartirse así:

| Tiempo orientativo | Qué contar |
| --- | --- |
| 30 segundos | Qué pregunta querías explorar y por qué. |
| 90 segundos | Qué probaste y una evidencia visible del resultado. |
| 60 segundos | Qué límite encontraste, qué aprendiste y qué probarías después. |

La evidencia puede ser una salida, una cita, una comparación, una llamada de herramienta o un error investigado. No necesitas preparar slides ni ejecutar una demo en directo. Puedes mostrar un resultado guardado e identificar cómo lo obtuviste.

## Criterios de evaluación

La puntuación total es de 100 puntos:

| Criterio | Puntos | Qué buscamos |
| --- | ---: | --- |
| Problema, dominio y propuesta | 20 | Se entiende qué problema intenta resolver, para quién, con qué datos o dominio y qué espera conseguir. |
| Exploración reproducible | 20 | Hay una forma razonable de seguir lo que se ha probado: instrucciones, notebook, código, ejemplos o decisiones anotadas. `.env.example` sin secretos si hace falta. |
| Evidencia, pruebas y resultado | 25 | Se muestran preguntas, entradas, resultados o pruebas que permitan comprobar qué ocurrió. Puede incluir citas, filas, capturas, casos fallidos o métricas sencillas. |
| Límites y reflexión | 20 | Explica qué no hace, qué salió mal o resultó difícil, por qué puede haber ocurrido y qué probaría a continuación. Si aplica, incluye seguridad y protección de secretos. |
| Cómo lo cuenta al grupo | 15 | La demostración o explicación tiene un hilo claro: idea, prueba, resultado y aprendizaje. Se valora compartir dudas y hallazgos, no sólo éxitos. |

## Cómo sacar partido a tu proyecto

- Empieza por una pregunta concreta y una primera prueba observable antes de añadir más cosas.
- Prueba variantes sin miedo: cambiar una pregunta, un chunk o un límite es parte del trabajo, no un error que haya que ocultar.
- Guarda uno o dos casos que no salieron como esperabas. Explicarlos durante la demo demuestra que sabes comprobar el comportamiento del asistente.
- Si tu experimento no llega a funcionar, cuenta qué intentaste, qué observaste y cuál sería tu siguiente prueba. Eso también es una entrega valiosa.
- Pide ayuda pronto si te bloqueas. Compartir una duda o un hallazgo puede desbloquear a otra persona. Durante la semana puedes consultar al instructor por correo con tu pregunta, lo que has probado y el resultado, sin secretos.

## Cómo interpretar tu puntuación

- **85–100:** exploración muy bien explicada, con una prueba visible y reflexiones útiles para el grupo.
- **70–84:** la idea y el recorrido se entienden. Faltan pulir evidencias, límites o la forma de contarlo.
- **50–69:** hay una exploración interesante, pero cuesta saber exactamente qué se intentó o qué se aprendió.
- **Menos de 50:** todavía no hay información suficiente para seguir el experimento o conversar sobre sus resultados.

No se penaliza elegir una solución pequeña ni reconocer una limitación. De hecho, un asistente que se abstiene bien, muestra su evidencia y explica qué mejoraría suele ser más valioso que uno espectacular pero opaco.
