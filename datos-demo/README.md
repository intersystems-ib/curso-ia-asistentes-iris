# Datos demo

Todos los datos de este directorio son sintéticos y están diseñados para el
curso. No contienen información personal real ni deben sustituirse por datos
de clientes en un entorno de aprendizaje.

## Modelo

Los datos transaccionales —clientes, productos, pedidos y envíos— se definen
en `src/Learning/Data/DemoData.cls` y se cargan en las tablas `Learning_Data.*`
de IRIS mediante `Learning.Bootstrap.LoadDemoData()`. IRIS es la fuente de
verdad de esos datos. Los laboratorios Python los consultarán directamente con
el controlador DB-API, sin mantener una copia CSV.

Los documentos de `knowledge/` son la fuente de verdad para políticas. No se
usan para conocer el estado actual de un pedido: esa pregunta se resuelve con
los datos estructurados y una herramienta de lectura.

Los ficheros de `evaluation/` se usarán en los laboratorios de evaluación y no
se pasan al modelo como contexto.
