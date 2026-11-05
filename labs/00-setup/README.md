# Lab 00 — Preparar el entorno

## Objetivo

Arrancar IRIS AI Hub, comprobar que la build prevista está disponible y cargar el dominio sintético de soporte. Aquí se prepara el entorno común una sola vez. Los demás labs lo reutilizan. Este laboratorio no necesita una clave OpenRouter.

## Elige tu punto de partida

- **Máquina preparada por el instructor:** abre el repositorio en la máquina asignada siguiendo la [guía de acceso del alumno](../../docs/guia-acceso-aws-alumno.md). Usa las credenciales y el entorno Python facilitados. Si falta `.env`, créalo desde `.env.example` y ajusta la conexión indicada por el instructor. Pasa a [Comprobación](#comprobación). Prepara sólo lo que falte según ese resultado.
- **Instalación en tu equipo:** sigue la preparación, el entorno Python y la carga de datos que aparecen a continuación. Necesitas Docker y la imagen EAP indicada por el instructor disponible localmente.

Todos los comandos de terminal del curso parten de la raíz del repositorio. Con acceso remoto, se ejecutan en la terminal de la máquina asignada.

## Leer los labs en VS Code

La copia pública incluye `.vscode/extensions.json` con las extensiones recomendadas. Abre Extensions y busca `@recommended` para verlas. VS Code puede sugerirlas al abrir la carpeta, pero no las instala automáticamente.

Para leer un README, usa **Markdown: Open Preview** desde la paleta de comandos. Markdown Preview Enhanced figura como recomendación opcional para la lectura. Si la vista previa integrada ya muestra los diagramas Mermaid, puedes usarla sin instalar esa extensión. Con Remote SSH, VS Code indica si cada extensión debe instalarse localmente o en la máquina remota.

## Preparación

1. Abre la carpeta del repositorio en Visual Studio Code. Instala las extensiones recomendadas cuando VS Code las sugiera: **Python**, **Jupyter** e **InterSystems ObjectScript**.
2. Si todavía no existe `.env`, copia `.env.example` como `.env`. Conserva tu configuración si ya lo habías creado. Los ejemplos Python leerán este archivo. En Docker local, la conexión predeterminada es `localhost:1972`, namespace `USER`, usuario `superuser` y contraseña `SYS`.
3. Para generar respuestas, configura OpenRouter una vez siguiendo [su guía](../../docs/guia-acceso-aws-alumno.md#4-añade-tu-clave-y-arranca-iris). Puedes dejar la clave vacía por ahora. Si ya la tienes, configúrala antes de crear el contenedor.
4. Arranca el entorno:

   ```bash
   docker compose up --build -d
   ```

## Entorno Python para los Labs 01–03

Si el instructor ya preparó `.venv` y las dependencias base, utiliza ese entorno. Para una instalación nueva, déjalos preparados ahora. El entorno virtual aísla las dependencias del curso para no mezclarlas con las instalaciones Python que ya tengas en tu equipo. Desde la raíz del repositorio:

```bash
python3.13 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

El ejemplo selecciona Python 3.13 explícitamente. Si usas 3.11 o 3.12, ajusta el ejecutable a esa versión. En Windows puedes crear el entorno con `py -3.13 -m venv .venv`. Comprueba con `python --version` la versión activa. `python3` puede apuntar a una versión distinta de la prevista para el curso.

En PowerShell para Windows, el comando de activación es `.venv\Scripts\Activate.ps1`. Cuando abras una terminal nueva para un lab Python, repite sólo `source .venv/bin/activate`. Usa Python 3.11, 3.12 o 3.13. Para ejecutar un notebook en VS Code, selecciona `.venv` en el selector de kernel de la esquina superior derecha.

No vuelvas a crear `.venv` ni a instalar `requirements.txt` al cambiar de lab. Las ampliaciones indican sus dependencias adicionales cuando las necesitan.

## Abrir una terminal ObjectScript

Con IRIS en marcha, en VS Code puedes usar **ObjectScript: Launch Lite Terminal**. Como alternativa, si trabajas con Docker en esa máquina, abre una terminal (**Terminal → Nueva terminal**) y ejecuta:

```bash
docker compose exec iris-aihub iris session IRIS -U USER
```

Este comando abre la terminal de IRIS en el namespace `USER`. Cuando un lab pida una terminal ObjectScript, reutiliza esta sesión o abre otra del mismo modo.

## Carga explícita de datos

En una instalación nueva, cuando aparezca el prompt `USER>`, carga el dominio demo:

```objectscript
Do ##class(Learning.Bootstrap).LoadDemoData()
```

Los datos de clientes, productos, pedidos y envíos quedan persistidos en IRIS. Si el instructor ya los cargó, pasa a la comprobación. La carga es idempotente: puede repetirse sin crear duplicados, pero no es necesaria en cada lab.

## Comprobación

Desde una [terminal ObjectScript en USER](#abrir-una-terminal-objectscript), verifica el entorno sin modificarlo:

```objectscript
Do ##class(Learning.Test.Smoke).Run()
```

La salida confirma que están disponibles AI Hub, las clases del dominio y los datos demo. Esta comprobación no carga ni modifica registros.

Para continuar con los Labs 01–03, comprueba también que puedes seleccionar `.venv` como kernel de un notebook. El Management Portal es una comprobación visual opcional.

## Retomar el curso en otra sesión

Activa `.venv` si abres una terminal nueva para Python, o selecciónalo como kernel del notebook. Para ObjectScript, abre una sesión en `USER`. Si usas Docker local y el contenedor está detenido, arráncalo con `docker compose up -d iris-aihub`. Reutiliza `.env` y los datos persistidos.

Recrear el contenedor sólo es necesario al cambiar su configuración, por ejemplo las variables de OpenRouter. Consulta [la guía](../../docs/guia-acceso-aws-alumno.md#4-añade-tu-clave-y-arranca-iris). En una máquina administrada por el instructor, sigue sus indicaciones para cualquier cambio de configuración.

## Qué observar

La carga y la comprobación son acciones distintas: la primera prepara datos persistentes. La segunda sólo valida el estado del entorno. Más adelante las herramientas y el RAG consultarán estas fuentes sin que tengas que crear datos manualmente.

## Fallo esperado

Si el contenedor no recibe una clave OpenRouter, el diagnóstico la marca como no disponible, pero la prueba local sigue pasando. La clave no se imprime nunca. Si ejecutas la prueba antes de la carga, falla indicando el comando de inicialización que debes ejecutar.

## Siguiente paso

Continúa con el RAG Python básico para convertir documentos de políticas en una fuente consultable.
