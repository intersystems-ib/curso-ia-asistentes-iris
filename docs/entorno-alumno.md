# Conectar con el entorno del curso

## Máquina Linux preparada: VS Code Remote SSH

El instructor facilita el host SSH, usuario, ruta del repo y método de acceso.
No necesitas una copia de la clave SSH dentro de este repositorio.

1. Instala Remote - SSH en tu VS Code local.
2. Ejecuta **Remote-SSH: Connect to Host...** e introduce `usuario@host-asignado`.
3. Abre la carpeta del repositorio en esa máquina con **File → Open Folder**.
4. En Extensions, busca `@recommended` e instala las recomendaciones del
   repositorio. VS Code indicará cuáles instalar en el entorno remoto.
5. Abre la terminal integrada. Python, notebooks y comandos Docker se ejecutan
   allí, junto al contenedor `iris-aihub`. Selecciona el kernel `.venv` remoto.

En este modo IRIS normalmente está en `localhost`, porque la conexión sale de
la máquina Linux. La dirección pública de SSH y el host de IRIS pueden ser distintos.
Si esta exportación usa otro host, ajusta la conexión descrita más abajo.
No ejecutes `docker compose up --build` si el instructor ya ha preparado IRIS.

## Leer los labs

Abre el `README.md` de cada lab en vista previa con **Markdown: Open Preview**.
El archivo `.vscode/extensions.json` incluye Python, Jupyter, InterSystems
ObjectScript, Remote SSH y Markdown Preview Enhanced como recomendaciones.
La extensión de vista previa es opcional si el visor integrado ya muestra los
diagramas Mermaid. Estas recomendaciones no instalan extensiones automáticamente.

## Conexión ObjectScript y Python

La conexión de esta copia usa `http`, host `localhost`, puerto web `52773` y namespace `USER`.
En `.vscode/settings.json`, cambia `intersystems.servers.curso-iris.webServer.host`
para usar otro host. Allí también puedes cambiar puerto, esquema HTTP/HTTPS y usuario.
`objectscript.conn` apunta a ese perfil. VS Code pedirá la contraseña. No está guardada
en los archivos compartidos.

Python usa otra configuración: copia `.env.example` a `.env`. Incluye
`IRIS_PASSWORD=SYS`, la contraseña de fábrica del Docker de prácticas.
Si el instructor facilita otras credenciales, actualízalas en `.env`.
Si cambias de host, actualiza también
`IRIS_HOST` en `.env`. El puerto `IRIS_PORT` es el nativo de IRIS, no el puerto web.
Las variables exportadas en una terminal tienen prioridad sobre `.env`.
Los bloques con `localhost` y `SYS` de los labs son ejemplos del Docker local.
No sustituyas con ellos una conexión remota que ya hayas configurado.

Una conexión directa desde tu portátil a IRIS sólo cambia dónde se conecta el
editor o Python. No hace que los comandos `docker exec` de los labs se ejecuten
en el servidor: para esos comandos utiliza SSH o una ventana Remote SSH.

## Generación con OpenRouter

El instructor entrega la clave por separado. Guárdala como `OPENROUTER_API_KEY`
en el `.env` del equipo donde se ejecuta Python. No la añadas al repositorio.
El contenedor que ejecuta los agentes nativos también debe recibirla al crearse.
Si el instructor ya lo configuró, no necesitas recrearlo por tu cuenta.

## Si preparas el contenedor desde cero

Esta edición utiliza IRIS 2027.1 AI.109 EAP. La imagen base no se descarga automáticamente
de un registro público: el instructor debe proporcionarla o indicar cómo obtenerla.
La referencia de imagen de esta copia está en `.env.example` (`IRIS_IMAGE`).
Una vez disponible la imagen, sigue el Lab 00. La contraseña de fábrica del
Docker de prácticas es `SYS`. Una máquina asignada puede tener otras credenciales.

Referencias: [Remote SSH](https://code.visualstudio.com/docs/remote/ssh) y
[Server Manager](https://github.com/intersystems-community/intersystems-servermanager).
