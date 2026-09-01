# Conversor automático de PDF a Markdown para Claude

Este proyecto automatiza la conversión de archivos PDF a Markdown (`.md`) en Windows utilizando [MarkItDown](https://github.com/microsoft/markitdown), de Microsoft, y PowerShell.

El objetivo es disponer de una carpeta de entrada en la que se puedan depositar PDFs y obtener automáticamente una versión en Markdown lista para trabajar con Claude u otros modelos de lenguaje.

## ¿Por qué convertir PDF a Markdown?

Cuando un modelo procesa directamente un PDF puede tener que interpretar no solo el texto, sino también la estructura visual del documento, las páginas, imágenes, tablas y otros elementos.

Para documentos principalmente textuales —guiones, novelas, artículos, documentación técnica, informes, etc.— puede ser más eficiente convertir previamente el contenido a Markdown.

El flujo es:

```text
PDF
 ↓
MarkItDown
 ↓
Markdown UTF-8
 ↓
Claude
```

Esto puede reducir información innecesaria en el contexto cuando no se necesita analizar la maquetación, gráficos o imágenes del PDF.

> Importante: no existe un porcentaje fijo de ahorro de tokens. Depende del documento. Si necesitas que Claude interprete fotografías, diagramas, gráficos, tablas complejas o la disposición visual de las páginas, es preferible utilizar el PDF original.

\---

## Estructura de carpetas

El script utiliza esta estructura:

```text
C:\\ClaudePDF
│
├── IN
│     └── documento.pdf
│
├── OUT
│     └── documento.md
│
├── ERROR
│     └── PDFs que no pudieron convertirse correctamente
│
└── convertir\_pdfs.ps1
```

### `IN`

Carpeta vigilada por el script.

Cualquier archivo PDF colocado aquí se intentará convertir automáticamente.

### `OUT`

Contiene los archivos Markdown generados correctamente.

Ejemplo:

```text
C:\\ClaudePDF\\IN\\guion.pdf
```

genera:

```text
C:\\ClaudePDF\\OUT\\guion.md
```

### `ERROR`

Si MarkItDown falla o genera un archivo vacío o prácticamente vacío, el PDF se mueve a esta carpeta para poder revisarlo manualmente.

\---

# Requisitos

## 1\. Windows

El script está diseñado para Windows y utiliza PowerShell.

PowerShell viene incluido en las versiones modernas de Windows.

Comprobar:

```powershell
powershell --version
```

En algunas versiones también puede utilizarse:

```powershell
$PSVersionTable.PSVersion
```

\---

## 2\. Python

MarkItDown requiere una versión moderna de Python.

En este ejemplo se utiliza Python 3.13.

Comprobar las versiones instaladas:

```cmd
py -0p
```

Ejemplo:

```text
-V:3.14 \*
-V:3.13
```

Comprobar Python 3.13:

```cmd
py -3.13 --version
```

\---

## 3\. Git

Git es necesario si se quiere instalar MarkItDown directamente desde su repositorio.

Comprobar:

```cmd
git --version
```

Git para Windows:

https://git-scm.com/

\---

## 4\. MarkItDown

MarkItDown es una herramienta open source de Microsoft para convertir distintos formatos de archivo a Markdown.

Repositorio oficial:

https://github.com/microsoft/markitdown

### Instalación sencilla

```cmd
py -3.13 -m pip install "markitdown\[all]"
```

### Instalación desde el repositorio

Clonar:

```cmd
git clone https://github.com/microsoft/markitdown.git
```

Entrar en la carpeta:

```cmd
cd markitdown
```

Instalar:

```cmd
py -3.13 -m pip install -e "packages/markitdown\[all]"
```

Comprobar:

```cmd
markitdown --help
```

\---

# Uso manual de MarkItDown

Antes de automatizar el proceso conviene comprobar que MarkItDown funciona correctamente.

Conversión directa:

```cmd
markitdown "C:\\ruta\\documento.pdf" -o "C:\\ruta\\documento.md"
```

También puede utilizarse la redirección estándar:

```cmd
markitdown "C:\\ruta\\documento.pdf" > "C:\\ruta\\documento.md"
```

Para automatizaciones en Windows se recomienda `-o`, ya que MarkItDown gestiona directamente el archivo de salida.

\---

```

\---

# Ejecutar el conversor

Desde CMD:

```cmd
powershell -ExecutionPolicy Bypass -File C:\\ClaudePDF\\convertir\_pdfs.ps1
```

O desde PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File C:\\ClaudePDF\\convertir\_pdfs.ps1
```

El script permanecerá ejecutándose y comprobará la carpeta de entrada cada 3 segundos.

Para detenerlo:

```text
Ctrl + C
```

\---

# Funcionamiento

Cada tres segundos el script busca archivos:

```text
\*.pdf
```

dentro de:

```text
C:\\ClaudePDF\\IN
```

Para cada PDF:

1. Obtiene el nombre del archivo.
2. Calcula el nombre correspondiente del `.md`.
3. Comprueba que todavía no exista en `OUT`.
4. Ejecuta MarkItDown:

```powershell
markitdown "archivo.pdf" -o "archivo.md"
```

5. Comprueba el código de salida de MarkItDown.
6. Comprueba que el `.md` exista.
7. Fuerza la codificación UTF-8 con BOM.
8. Comprueba que el resultado tenga contenido.
9. Si todo es correcto, conserva el Markdown en `OUT`.
10. Si falla, elimina cualquier salida defectuosa y mueve el PDF a `ERROR`.

\---

# Codificación y acentos

Los archivos Markdown se guardan explícitamente en:

```text
UTF-8 con BOM
```

Esto mejora la compatibilidad con software de Windows y evita problemas frecuentes como:

```text
canciÃ³n
MÃ¡laga
tambiÃ©n
```

en lugar de:

```text
canción
Málaga
también
```

Se conservan correctamente caracteres como:

```text
á é í ó ú
Á É Í Ó Ú
ñ Ñ
ü Ü
¿ ¡
```

\---

# Utilización con Claude

Una vez generado el Markdown:

```text
C:\\ClaudePDF\\OUT\\documento.md
```

se puede adjuntar directamente a Claude.

Para documentos eminentemente textuales, el flujo recomendado es:

```text
PDF original
   ↓
MarkItDown
   ↓
Markdown limpio
   ↓
Claude
```

En cambio, si el análisis requiere información visual:

```text
fotografías
diagramas
gráficos
tablas complejas
maquetación
posición de elementos
```

conviene proporcionar el PDF original.

\---

# Tokens y PDFs

Los PDFs pueden resultar más costosos en contexto que una representación puramente textual porque los sistemas multimodales pueden procesar tanto el texto como la representación visual de las páginas.

Anthropic documenta que el procesamiento de PDFs puede combinar:

* extracción de texto;
* análisis visual de cada página.

Por ello, convertir previamente un documento principalmente textual a Markdown puede reducir el material que el modelo necesita procesar.

No debe interpretarse como un ahorro fijo o garantizado de tokens.

El ahorro depende de factores como:

* número de páginas;
* densidad del texto;
* cantidad de imágenes;
* tablas;
* gráficos;
* complejidad de la maquetación;
* cantidad real de información conservada en Markdown.

## Cuándo utilizar Markdown

Adecuado para:

* guiones;
* novelas;
* relatos;
* artículos;
* documentación técnica;
* informes textuales;
* manuales;
* documentación de software;
* textos académicos.

## Cuándo conservar el PDF

Preferible para:

* cómics;
* documentos escaneados;
* planos;
* presentaciones visuales;
* informes con gráficos;
* PDFs con diagramas;
* documentos en los que la posición de los elementos tenga significado.

\---

# PDFs escaneados

MarkItDown puede no extraer correctamente PDFs que realmente contienen imágenes escaneadas en lugar de texto.

Una prueba sencilla consiste en abrir el PDF e intentar seleccionar una palabra con el ratón.

Si no se puede seleccionar texto, probablemente sea necesario aplicar OCR antes de convertirlo.

\---

# FFmpeg

Durante la instalación de `markitdown\[all]` puede aparecer una advertencia relacionada con FFmpeg:

```text
Couldn't find ffmpeg or avconv
```

Esto normalmente no afecta a la conversión de PDFs.

FFmpeg es principalmente relevante para determinadas funciones relacionadas con audio y vídeo.

Puede instalarse en Windows mediante:

```cmd
winget install Gyan.FFmpeg
```

Después:

```cmd
ffmpeg -version
```

\---

# Solución de problemas

## `markitdown` no se reconoce como comando

Comprobar:

```cmd
where markitdown
```

Si se instaló con Python 3.13, normalmente estará en una ruta similar a:

```text
C:\\Users\\USUARIO\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\
```

Esa carpeta debe estar incluida en `PATH`.

\---

## `pip` apunta a una versión antigua de Python

Comprobar:

```cmd
where pip
```

y:

```cmd
py -0p
```

Es preferible ejecutar pip indicando explícitamente la versión:

```cmd
py -3.13 -m pip
```

en lugar de:

```cmd
pip
```

\---

## El `.md` sale vacío

Probar manualmente:

```cmd
markitdown "C:\\ruta\\archivo.pdf"
```

Si tampoco aparece contenido, probablemente el problema esté en ese PDF.

Posibles causas:

* PDF escaneado;
* texto representado como imágenes;
* protección;
* estructura PDF no estándar;
* fuentes incrustadas de forma problemática;
* archivo parcialmente corrupto.

\---

# Posibles mejoras

El script puede ampliarse fácilmente para:

* mover los PDFs convertidos a una carpeta `PROCESADOS`;
* guardar un archivo de log;
* procesar `.docx`, `.pptx` o `.xlsx`;
* realizar OCR automáticamente;
* arrancar automáticamente con Windows;
* ejecutarse como tarea programada;
* integrar MarkItDown mediante MCP;
* vigilar varias carpetas;
* registrar tiempo y tamaño de cada conversión.

\---

# Licencias

Este script PowerShell se puede utilizar, modificar y adaptar libremente.

MarkItDown es un proyecto de Microsoft. Consulta su repositorio oficial para conocer su licencia y condiciones:

https://github.com/microsoft/markitdown

\---

# Créditos

Automatización construida sobre:

**MarkItDown — Microsoft**

https://github.com/microsoft/markitdown

