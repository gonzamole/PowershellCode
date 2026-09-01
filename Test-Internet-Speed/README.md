# Monitor de velocidad de Internet con PowerShell

Este proyecto contiene un script de PowerShell que mide automáticamente la velocidad de una conexión a Internet mediante la herramienta oficial **Speedtest CLI de Ookla**.

El script ejecuta una prueba cada **5 minutos**, muestra el resultado en la consola y guarda un historial en el archivo `speedtest_log.csv`.

## Qué hace el script

Al iniciarse, el script:

1. Limpia la consola de PowerShell.
2. Comprueba que `Speedtest.exe` está instalado y disponible en el `PATH` de Windows.
3. Muestra la ubicación y la versión de Speedtest CLI detectada.
4. Crea el archivo `speedtest_log.csv` si todavía no existe.
5. Ejecuta una prueba de velocidad cada 5 minutos.
6. Muestra en pantalla la descarga, la subida, el ping y el servidor utilizado.
7. Añade cada medición al archivo CSV.
8. Si se produce un error, lo muestra y también lo registra en el CSV.
9. Continúa funcionando hasta que el usuario lo detiene con `Ctrl+C`.

## Datos registrados

Cada prueba guarda la siguiente información:

| Campo | Descripción |
| --- | --- |
| `Fecha` | Fecha de la medición en formato `AAAA-MM-DD`. |
| `Hora` | Hora de la medición en formato `HH:mm:ss`. |
| `Descarga_Mbps` | Velocidad de descarga en megabits por segundo. |
| `Subida_Mbps` | Velocidad de subida en megabits por segundo. |
| `Ping_ms` | Latencia de la conexión en milisegundos. |
| `Servidor` | Nombre y localidad del servidor de Ookla utilizado. |
| `Resultado` | Indica `OK` o contiene la descripción del error. |

Ejemplo:

```csv
Fecha,Hora,Descarga_Mbps,Subida_Mbps,Ping_ms,Servidor,Resultado
2026-09-01,18:30:00,624.32,587.41,12.4,Madrid (Madrid),OK
```

## Requisitos

- Windows 10 o Windows 11.
- PowerShell 5.1 o PowerShell 7.
- Conexión a Internet.
- Speedtest CLI oficial de Ookla.
- `winget`, si se utiliza el método de instalación recomendado.

> El script está preparado para la CLI oficial de Ookla. Una herramienta diferente, como el paquete de Python `speedtest-cli`, puede devolver datos incompatibles.

## Instalar Speedtest CLI

Abre PowerShell y ejecuta:

```powershell
winget install --id Ookla.Speedtest.CLI --exact
```

Para realizar la instalación sin preguntas adicionales:

```powershell
winget install --id Ookla.Speedtest.CLI --exact --accept-package-agreements --accept-source-agreements
```

Después de instalarlo, cierra PowerShell, vuelve a abrirlo y comprueba que el comando está disponible:

```powershell
speedtest --version
```

También puede descargarse manualmente desde la [página oficial de Speedtest CLI](https://www.speedtest.net/apps/cli).

## Cómo ejecutar el script

1. Guarda el archivo `.ps1` en una carpeta.
2. Abre PowerShell en esa carpeta.
3. Ejecuta el script. Sustituye `Monitor-Speedtest.ps1` por el nombre real del archivo:

```powershell
.\Monitor-Speedtest.ps1
```

El programa mostrará un resultado parecido a este:

```text
[2026-09-01 18:30:00] Ejecutando test de velocidad...
  Descarga : 624.32 Mbps
  Subida   : 587.41 Mbps
  Ping     : 12.4 ms
  Servidor : Madrid (Madrid)
```

Para detener la monitorización, pulsa:

```text
Ctrl+C
```

## Archivo de resultados

El archivo `speedtest_log.csv` se guarda, normalmente, en la misma carpeta que el script. Si el código se pega directamente en una consola en vez de ejecutarse desde un archivo, se utiliza la carpeta de trabajo actual.

El CSV se puede abrir con Excel, LibreOffice Calc o cualquier editor de texto. Los resultados anteriores no se eliminan: cada nueva medición se añade al final.

## Cambiar la frecuencia de las mediciones

El intervalo se configura al principio del script:

```powershell
$IntervaloMinutos = 5
```

Por ejemplo, para ejecutar una prueba cada 15 minutos:

```powershell
$IntervaloMinutos = 15
```

Conviene no utilizar intervalos demasiado cortos, ya que cada prueba consume datos y ancho de banda.

## Indicar manualmente la ubicación de Speedtest

De forma predeterminada, el script busca este ejecutable:

```powershell
$SpeedtestExe = "Speedtest.exe"
```

Si no está incluido en el `PATH`, se puede escribir su ruta completa:

```powershell
$SpeedtestExe = "C:\Herramientas\speedtest.exe"
```

## Permiso de ejecución de PowerShell

Si Windows impide ejecutar el archivo `.ps1`, se puede permitir únicamente durante la sesión actual:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

A continuación, vuelve a ejecutar el script. Este cambio desaparece al cerrar esa ventana de PowerShell.

## Tratamiento de los datos

Speedtest devuelve las velocidades como bytes por segundo. El script las convierte a megabits por segundo mediante esta operación:

```text
Mbps = bytes por segundo × 8 / 1 MB
```

La descarga y la subida se redondean a dos decimales, mientras que el ping se redondea a uno.

Los parámetros `--accept-license` y `--accept-gdpr` aceptan automáticamente las condiciones de Ookla para impedir que la primera medición quede esperando una respuesta interactiva.

## Solución de problemas

### No se encontró `Speedtest.exe`

Instala la CLI oficial y vuelve a abrir PowerShell:

```powershell
winget install --id Ookla.Speedtest.CLI --exact
```

También puedes indicar la ruta completa del ejecutable en `$SpeedtestExe`.

### La salida de Speedtest no es JSON válido

Normalmente significa que:

- se ha instalado otra herramienta llamada `speedtest`;
- Speedtest ha devuelto un mensaje de error;
- la conexión está bloqueada por un cortafuegos, proxy o antivirus.

Comprueba manualmente la salida con:

```powershell
speedtest --format=json --accept-license --accept-gdpr
```

### El CSV no aparece donde se esperaba

Consulta la ruta mostrada al arrancar el programa:

```text
Log guardado en: ...\speedtest_log.csv
```

### Una prueba falla temporalmente

El script registra el error y continúa. Transcurrido el intervalo configurado, vuelve a intentarlo automáticamente.

## Funcionamiento interno

El script está dividido en tres partes principales:

- `Test-SpeedtestInstalado`: localiza el ejecutable y consulta su versión.
- `Initialize-Log`: crea el archivo CSV y su cabecera cuando es necesario.
- `Invoke-SpeedTest`: ejecuta la prueba, interpreta el JSON, calcula los Mbps y guarda el resultado.

El bucle `while ($true)` mantiene la monitorización activa y `Start-Sleep` espera el número de minutos configurado entre pruebas.

## Consideraciones

- Cada medición utiliza una cantidad apreciable de datos, especialmente con conexiones rápidas.
- La prueba puede ocupar gran parte del ancho de banda mientras se está ejecutando.
- Los resultados dependen del servidor elegido, la congestión de la red, el uso de Wi-Fi o cable y la actividad de otros dispositivos.
- El archivo CSV crece progresivamente mientras el script continúa en uso.

## Licencia

Puedes añadir aquí la licencia que quieras aplicar al script, por ejemplo MIT. Speedtest CLI pertenece a Ookla y está sujeto a sus propias condiciones de uso.
