# Acceder al entorno AWS del curso

Esta guía sirve para alumnos e instructor. Al terminar tendrás VS Code conectado
a tu máquina, el repo abierto y tu clave OpenRouter configurada.

El instructor prepara Ubuntu, Docker, IRIS, el repo y el entorno Python.
En tu portátil necesitas VS Code, la extensión Remote - SSH y un cliente SSH.
No necesitas una cuenta AWS, AWS CLI, Docker ni Python en el portátil.

## 1. Reunir los datos de acceso

El instructor te entregará por separado:

| Dato | Para qué sirve |
| --- | --- |
| IP pública o nombre del servidor | Identificar tu máquina |
| Usuario SSH, normalmente `ubuntu` | Entrar en Ubuntu |
| Fichero `.pem` individual | Autenticar la conexión SSH |
| API key individual de OpenRouter | Generar respuestas en los labs |
| Credenciales de IRIS | Conectar las extensiones y abrir el Portal |

La carpeta del curso es `/home/ubuntu/curso-ia-asistentes-iris`.
Los ejemplos usan `IP_DE_TU_MAQUINA` como marcador. Sustitúyelo por el dato
recibido. No escribas claves reales en documentos, chats compartidos o notebooks.

## 2. Preparar el portátil

Instala [Visual Studio Code](https://code.visualstudio.com/) y la extensión
[Remote - SSH de Microsoft](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh).

Guarda el `.pem` recibido en una carpeta de tu portátil, fuera del repo.
Puedes utilizar la carpeta donde lo has descargado. Conserva su nombre y
anota la ruta completa. No lo copies a la EC2 ni lo borres después de conectar.

## 3. Añadir la conexión desde VS Code

1. Abre la paleta de comandos con `Cmd+Shift+P` en macOS o `Ctrl+Shift+P`
   en Windows y Linux.
2. Ejecuta **Remote-SSH: Add New SSH Host...**.
3. Introduce el comando de conexión, sustituyendo la ruta del `.pem` y la IP.

Ejemplo en macOS o Linux:

```bash
ssh -i "/RUTA/COMPLETA/A/TU/CLAVE.pem" ubuntu@IP_DE_TU_MAQUINA
```

Ejemplo en Windows:

```text
ssh -i "C:/Users/TU_USUARIO/Downloads/CLAVE.pem" ubuntu@IP_DE_TU_MAQUINA
```

Las comillas permiten utilizar rutas con espacios. Si el instructor te ha dado
otro usuario, sustituye `ubuntu`.

Cuando aparezca **Select SSH configuration file to update**, elige el archivo
de tu usuario. Normalmente es la primera opción:

| Sistema | Opción que debes elegir |
| --- | --- |
| macOS | `/Users/TU_USUARIO/.ssh/config` |
| Linux | `/home/TU_USUARIO/.ssh/config` |
| Windows | `C:\Users\TU_USUARIO\.ssh\config` |

VS Code guarda la conexión automáticamente y conserva las que ya tengas.
No necesitas abrir ni editar ese archivo. En macOS y Linux, no selecciones
el archivo del sistema `/etc/ssh/ssh_config`.

## 4. Conectar VS Code y abrir el curso

1. Pulsa **Connect** en el aviso de conexión añadida. También puedes abrir la
   paleta y ejecutar **Remote-SSH: Connect to Host...**.
2. Elige la IP o el nombre de la conexión que acabas de añadir. Si pregunta
   por el sistema remoto, selecciona **Linux**.
3. En la primera conexión, confirma con el instructor la huella del servidor
   antes de aceptarla. Si aparece un error de permisos del `.pem`, consulta
   [Permisos de la clave](#permisos-de-la-clave).
4. Espera a que termine la preparación de VS Code Server. La primera vez puede tardar.
5. Comprueba que la esquina inferior izquierda muestra **SSH:** seguido de tu servidor.
6. Usa **File → Open Folder...** y abre `/home/ubuntu/curso-ia-asistentes-iris`.
7. Abre **Terminal → New Terminal**.

En esa terminal, comprueba dónde estás trabajando:

```bash
whoami
pwd
```

Debes ver `ubuntu` y `/home/ubuntu/curso-ia-asistentes-iris`.
A partir de aquí, los comandos se ejecutan en esta terminal remota, salvo que
la guía indique expresamente que corresponden al portátil.

El repo público ya debe estar preparado en la máquina. Si la carpeta no existe,
avisa al instructor antes de clonar o instalar nada.

## 5. Seleccionar las extensiones y el entorno Python

En **Extensions**, busca `@recommended`. Instala Python, Jupyter e InterSystems
ObjectScript en el servidor **SSH:** conectado cuando VS Code ofrezca esa opción. Remote - SSH
se instala en el portátil. Las recomendaciones no se instalan automáticamente.

Abre la paleta, ejecuta **Python: Select Interpreter** y selecciona:

```text
/home/ubuntu/curso-ia-asistentes-iris/.venv/bin/python
```

Si no aparece, usa la opción para introducir la ruta del intérprete.
En cada notebook, pulsa **Select Kernel** y elige ese mismo entorno Python.

Para trabajar desde la terminal remota:

```bash
cd /home/ubuntu/curso-ia-asistentes-iris
source .venv/bin/activate
python --version
docker compose ps
```

Si falta `.venv` o Docker da un error de permisos, avisa al instructor.
No vuelvas a crear el entorno ni reinstales las dependencias si ya están preparados.
Si IRIS está detenido, arráncalo con:

```bash
docker compose up -d iris-aihub
```

## 6. Configurar tu API key de OpenRouter

En la terminal remota, crea `.env` sólo si todavía no existe y limita sus permisos:

```bash
test -f .env || cp .env.example .env
chmod 600 .env
```

Abre el archivo `.env` desde el explorador de VS Code remoto. Introduce tu clave
en `OPENROUTER_API_KEY` y conserva el modelo del curso:

```dotenv
OPENROUTER_API_KEY=PEGA_AQUI_TU_CLAVE
OPENROUTER_MODEL=openai/gpt-oss-20b
```

Sustituye el marcador por la clave real, guarda el archivo y conserva las demás
variables que haya preparado el instructor. No publiques `.env` en Git.

La conexión Python a IRIS utiliza normalmente `IRIS_HOST=localhost` y
`IRIS_PORT=1972`. Usa las credenciales IRIS facilitadas. La IP pública sirve
para SSH. Python y las extensiones remotas se conectan a IRIS desde la EC2.

Para que el contenedor de AI Hub reciba la clave nueva, ejecuta en la terminal
remota de tu máquina individual:

```bash
docker compose up -d --force-recreate iris-aihub
```

Este comando interrumpe brevemente IRIS y recrea el contenedor con las variables
actuales. Los datos de `irisdata` se conservan. Hazlo al configurar la clave o
cuando cambies esas variables. Reiniciar el contenedor con `restart` no basta.
No borres `irisdata`.

Si ya tenías un notebook abierto, reinicia su kernel. Reinicia también las
aplicaciones Python que estuvieran en marcha. Las variables exportadas en una
terminal tienen prioridad sobre `.env`.

Puedes verificar que Python encuentra una clave sin mostrarla. Con `.venv`
activo y desde la carpeta del curso:

```bash
python -c 'from dotenv import load_dotenv; import os; load_dotenv(".env"); print("Clave configurada:", bool(os.getenv("OPENROUTER_API_KEY")))'
```

Un resultado `True` confirma que hay un valor, no que la clave sea válida o
tenga saldo. La prueba real de generación se hará cuando lo indique el lab o
el instructor y consume créditos. Más detalle en [OpenRouter](openrouter.md).

## 7. Abrir el Portal de IRIS y otras aplicaciones

Desde la ventana remota de VS Code:

1. Abre la pestaña **Ports**. Si no aparece, ejecuta **Ports: Focus on Ports View**.
2. Pulsa **Forward a Port** e introduce `52773`.
3. Pulsa **Open in Browser** en la fila del puerto.
4. Abre la ruta `/csp/sys/UtilHome.csp` en esa dirección para entrar al Portal.
5. Utiliza las credenciales IRIS facilitadas por el instructor.

Si el puerto local también es `52773`, la dirección del Portal será:

```text
http://localhost:52773/csp/sys/UtilHome.csp
```

Si VS Code asigna otro puerto local, usa el que muestre en **Forwarded Address**.
El navegador se ejecuta en tu portátil y llega a IRIS mediante el túnel SSH.
No necesitas abrir puertos adicionales en AWS ni instalar un navegador en EC2.

| Aplicación | Puerto remoto a reenviar |
| --- | --- |
| Portal de IRIS | `52773` |
| FastAPI opcional | `8000` |
| Gradio opcional | `7860` |

FastAPI y Gradio sólo estarán disponibles después de arrancarlos en sus labs.
Los notebooks usan el kernel remoto de VS Code y no necesitan un puerto Jupyter
público. La conexión ObjectScript remota usa el host y credenciales facilitados,
normalmente `localhost:52773` y namespace `USER`.

## 8. Comprobar que puedes empezar

- La ventana de VS Code indica **SSH:** seguido de tu servidor.
- La carpeta abierta es `/home/ubuntu/curso-ia-asistentes-iris`.
- Los notebooks y la terminal usan `.venv`.
- `docker compose ps` muestra `iris-aihub` en ejecución.
- Tu clave OpenRouter está guardada en el `.env` remoto.
- Puedes abrir el Portal mediante el puerto reenviado.

Continúa con la sección [Comprobación del Lab 00](../labs/00-setup/README.md#comprobación).
Si el instructor ya cargó los datos demo, no hace falta volver a cargarlos.
La comprobación inicial no llama al modelo ni consume créditos de OpenRouter.

## Retomar el trabajo otro día

Conecta con **Remote-SSH: Connect to Host...** y elige tu servidor. Abre la misma carpeta
y activa `.venv` si usas una terminal nueva. Reenvía los puertos si hace falta.
Reutiliza `.env` y los datos existentes. No recrees el contenedor en cada sesión.

Cerrar VS Code no apaga la EC2. El instructor gestiona el encendido y apagado
de las máquinas. Si cambia la IP pública, repite **Add New SSH Host...** con la
IP nueva y el mismo `.pem`, y selecciona esa conexión al entrar.

## Problemas habituales

| Mensaje o síntoma | Qué comprobar |
| --- | --- |
| `Connection timed out` | IP actual, máquina encendida, conexión de red y acceso TCP 22. Avisa al instructor si hay restricción por IP |
| `Permission denied (publickey)` | Usuario `ubuntu`, `.pem` asignado y ruta introducida al añadir la conexión |
| `UNPROTECTED PRIVATE KEY FILE` | Sigue el apartado Permisos de la clave |
| Huella SSH distinta de una conexión anterior | Confirma con el instructor si se ha sustituido la máquina antes de modificar `known_hosts` |
| Python no encuentra un paquete | Intérprete y kernel de `.venv` en la ventana remota |
| Docker no está disponible o no permite ejecutar comandos | Avisa al instructor para revisar instalación y grupo del usuario |
| Portal no responde | Contenedor en ejecución y puerto remoto `52773` reenviado. Usa el puerto local mostrado por VS Code |
| OpenRouter rechaza la generación | Clave individual, saldo, modelo permitido y recreación del contenedor después de editar `.env` |

Al pedir ayuda, comparte el mensaje de error sin tu clave OpenRouter ni el
contenido del `.pem`. Los detalles de conexión y reenvío de puertos están en
la [documentación de VS Code Remote SSH](https://code.visualstudio.com/docs/remote/ssh).

### Permisos de la clave

Si SSH rechaza el `.pem` por tener permisos demasiado abiertos:

**En macOS o Linux**, abre una terminal de tu portátil y ejecuta, con la ruta
real del archivo:

```bash
chmod 400 "/RUTA/COMPLETA/A/TU/CLAVE.pem"
```

**En Windows**, abre las propiedades del `.pem` en el Explorador y entra en
**Seguridad → Opciones avanzadas**. Restringe el acceso al archivo a tu cuenta.
Si hereda permisos de otros usuarios o grupos, deshabilita la herencia y retira
esos permisos. Si las políticas corporativas lo impiden, solicita ayuda al soporte.

Después vuelve a conectar desde VS Code.

Si el error indica que no encuentra `ssh`, comprueba `ssh -V` en la terminal
del portátil. En Windows, instala **OpenSSH Client** desde las características
opcionales del sistema si falta, o solicita ayuda al soporte.
