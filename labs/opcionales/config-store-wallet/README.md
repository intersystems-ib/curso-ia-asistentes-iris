# Ampliación: Config Store y Wallet

Esta ampliación parte del Lab 04. Conserva el agente de soporte, sus instrucciones, sus herramientas y su política. Cambia únicamente de dónde obtiene el proveedor, el modelo y la credencial.

## Qué son Config Store y Wallet

**Config Store** es el almacén de configuraciones de IRIS. Permite guardar un conjunto de parámetros con un nombre, validarlos según el tipo de configuración y controlar quién puede consultarlos o modificarlos. En este lab guardaremos el proveedor OpenRouter, el modelo y una referencia a su credencial bajo el nombre `AI.LLM.learning-support`. La aplicación utiliza ese nombre para recuperar la configuración. Puedes consultar la [referencia de la API `%ConfigStore.Configuration`](https://docs.intersystems.com/iris20262/csp/documatic/%25CSP.Documatic.cls?LIBRARY=%25SYS&CLASSNAME=%25ConfigStore.Configuration).

**Wallet**, o **Secure Wallet**, es el almacén de secretos de IRIS. Un secreto es un dato sensible que necesita una aplicación, como una contraseña o una clave de API. Wallet organiza los secretos en colecciones y controla su acceso mediante recursos de seguridad de IRIS. En este lab, la colección `LearningAISecrets` contendrá el secreto `OpenRouter`, con la clave en el campo `api_key`. La documentación de IRIS lo explica en [Secure Wallet](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ROARS_secrets_mgmt).

Ambos componentes se complementan: Config Store guarda los parámetros y la referencia al secreto, mientras que Wallet guarda la clave. La referencia `secret://LearningAISecrets.OpenRouter#api_key` identifica qué campo del secreto debe utilizarse, sin incluir su valor en la configuración.

| Elemento del ejercicio | Qué contiene |
| --- | --- |
| Configuración `AI.LLM.learning-support` | Proveedor, modelo y referencia a la clave. |
| Secreto `LearningAISecrets.OpenRouter` | La clave de OpenRouter en el campo `api_key`. |
| Agente `ConfiguredSupport` | El nombre de la configuración en `PROVIDERCONFIG`. |

Al llamar a `%Init()`, AI Hub lee la configuración y resuelve la referencia a Wallet para crear el proveedor. Las instrucciones del agente siguen en `XData INSTRUCTIONS`. Config Store y Wallet gestionan los parámetros de conexión y las credenciales.

El recorrido principal sigue usando `.env`. Aquí copiamos su clave a Wallet una vez para practicar, sin escribirla en el código ni mostrarla en la terminal. En una aplicación desplegada, un administrador puede aprovisionar el secreto por separado. Este ejercicio no elimina ni modifica tu `.env`.

## Preparación

Usa el contenedor del curso, IRIS `2027.1.0AI.109.0`, con `OPENROUTER_API_KEY` disponible. Abre una terminal ObjectScript con permisos de administración para crear los recursos, la colección y la configuración. El usuario docente tiene permisos amplios. Esta práctica no demuestra aislamiento entre usuarios.

Los nombres de abajo son exclusivos de esta ampliación. Si ya existen, reutiliza la preparación anterior. No borres una colección existente para repetir el lab. Ejecuta las líneas por partes. Después de cada operación, `DisplayError` debe quedar sin errores. Si aparece alguno, detente y corrígelo antes de continuar.

## 1. Crear los recursos

En `%SYS`:

```objectscript
Set $Namespace = "%SYS"
Set sc = ##class(Security.Resources).Create("LearningAIUse")
Do $System.Status.DisplayError(sc)
Set sc = ##class(Security.Resources).Create("LearningAIEdit")
Do $System.Status.DisplayError(sc)
Set $Namespace = "USER"
```

`LearningAIUse:USE` permite usar la credencial. `LearningAIEdit:USE` permite administrar la colección. Los recursos deben asignarse mediante roles cuando uses usuarios sin privilegios administrativos. Config Store tiene además sus propios permisos de lectura y edición.

## 2. Guardar la clave en Wallet

```objectscript
Set sc = ##class(%Wallet.Collection).Create("LearningAISecrets", {"UseResource":"LearningAIUse", "EditResource":"LearningAIEdit"})
Do $System.Status.DisplayError(sc)

Set key = $System.Util.GetEnviron("OPENROUTER_API_KEY")
Write "Clave disponible: ", (key '= ""), !
```

Continúa sólo si muestra `1`. No imprimas `key`.

```objectscript
Set secret = {"Usage":"CUSTOM", "Secret":{"api_key":(key)}}
Set sc = ##class(%Wallet.KeyValue).Create("LearningAISecrets.OpenRouter", secret)
Kill key, secret
Do $System.Status.DisplayError(sc)
```

## 3. Crear la configuración

En `USER`, registra los descriptores de configuración y crea la entrada del LLM:

```objectscript
Do ##class(%ConfigStore.DescriptorManager).RebuildRegistry()
Set model = $System.Util.GetEnviron("OPENROUTER_MODEL")
If model = "" Set model = "openai/gpt-oss-20b"
Set details = {"model_provider":"openrouter", "model":(model), "api_key":"secret://LearningAISecrets.OpenRouter#api_key", "site_name":"Curso AI Hub", "site_url":"http://localhost:52773"}
Set sc = ##class(%ConfigStore.Configuration).Create("AI", "LLM", "", "learning-support", details, "Soporte del curso", "OpenRouter con Wallet", "LearningAIUse:USE", "LearningAIEdit:USE")
Do $System.Status.DisplayError(sc)
```

En esta build, el descriptor de OpenRouter exige también `site_name` y `site_url`. Son metadatos de identificación de la aplicación.

Comprueba la referencia sin resolver el secreto. El cuarto argumento de `GetDetails` es `resolveSecrets`, aquí vale `0`:

```objectscript
Set sc = ##class(%ConfigStore.Configuration).GetDetails("AI.LLM.learning-support", .details, 1, 0)
Do $System.Status.DisplayError(sc)
Write details.%Get("model_provider"), !, details.%Get("model"), !, details.%Get("api_key"), !
```

La última línea debe ser `secret://LearningAISecrets.OpenRouter#api_key`. No uses `resolveSecrets=1` para inspeccionar o imprimir la configuración.

## 4. Inicializar el agente

Abre [ConfiguredSupport.cls](../../../src/Learning/Agent/ConfiguredSupport.cls). Hereda de `Support` y declara:

```objectscript
Parameter PROVIDERCONFIG = "@{config:AI.LLM.learning-support}";
```

También vacía `PROVIDER`, `MODEL` y `APIKEY`, heredados de `Basic`, para que no sobrescriban los valores guardados. `Basic.%OnInit()` conserva el modelo de Config Store cuando hay `PROVIDERCONFIG`.

```objectscript
Set agent = ##class(Learning.Agent.ConfiguredSupport).%New()
Set sc = agent.%Init()
Do $System.Status.DisplayError(sc)
Write agent.Model, !
Write agent.ToolManager.GetToolStatuses().%ToJSON(), !
```

Hasta aquí no has llamado al modelo. `%Init()` resuelve la referencia a Wallet internamente para construir el proveedor. No añadas trazas del proveedor ni imprimas su configuración resuelta.

Para generar una respuesta real, con consumo de OpenRouter:

```objectscript
Set session = agent.CreateSession({"max_iterations":10}) // Máx. iteraciones por pregunta (varias llamadas a herramientas por iteración).
Set response = agent.Chat(session, "¿Dónde está ORD-002?")
Do ##class(Learning.Helper).PrintResponse(response.Content)
```

Compara con el Lab 04. Deben mantenerse las cuatro herramientas de lectura, las instrucciones comunes y el flujo `GetOrder` → `GetShipment`.

## Limpieza opcional

Si has terminado y estos objetos se crearon sólo para esta práctica, elimina primero la configuración y después el secreto. Comprueba cada resultado:

```objectscript
Set sc = ##class(%ConfigStore.Configuration).Delete("AI.LLM.learning-support")
Do $System.Status.DisplayError(sc)
Set sc = ##class(%Wallet.Secret).Delete("LearningAISecrets.OpenRouter")
Do $System.Status.DisplayError(sc)
Set sc = ##class(%Wallet.Collection).Delete("LearningAISecrets")
Do $System.Status.DisplayError(sc)
```

Eliminar la colección elimina también sus secretos. Hazlo sólo si sigue siendo exclusiva de esta práctica. Los recursos pueden conservarse para repetirla. Después de la limpieza, `ConfiguredSupport.%Init()` debe fallar por configuración ausente. Los agentes del recorrido principal siguen usando el entorno.

## Referencias

- [Secure Wallet: gestión de secretos en IRIS](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ROARS_secrets_mgmt).
- [Referencia de `%ConfigStore.Configuration`](https://docs.intersystems.com/iris20262/csp/documatic/%25CSP.Documatic.cls?LIBRARY=%25SYS&CLASSNAME=%25ConfigStore.Configuration).
- [Guía ObjectScript de AI Hub](https://github.com/intersystems-community/ai-hub-eap/blob/master/ObjectScript_SDK_Guide.md#configuration-variables).
- [Config Store y Wallet](https://github.com/intersystems-community/ai-hub-eap/blob/master/Config_Store_Guide.md).

Las APIs de esta práctica se contrastaron con la build del curso. Los ejemplos upstream pueden utilizar firmas de otras versiones EAP.
