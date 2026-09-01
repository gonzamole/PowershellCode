<#
.SYNOPSIS
    Mide la velocidad de descarga y subida de Internet cada 5 minutos y
    guarda los resultados en un fichero CSV, mostrando también un resumen
    por consola.

.DESCRIPCION
    Usa la CLI oficial de Speedtest (Ookla). Si no está instalada, el script
    lo indica y da instrucciones de instalación.

.NOTAS
    Requiere: Speedtest CLI de Ookla (speedtest.exe)
    Instalación rápida con winget:
        winget install Ookla.Speedtest.CLI
    O descarga manual desde: https://www.speedtest.net/apps/cli
#>

# ----------------------- CONFIGURACIÓN -----------------------
Clear-host
$IntervaloMinutos = 5

# $PSScriptRoot puede venir vacío si el script no se ejecuta como fichero
# (p.ej. pegado directamente en la consola). Si pasa, usamos la carpeta actual.
$CarpetaBase = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$RutaLog = Join-Path $CarpetaBase "speedtest_log.csv"

$SpeedtestExe = "Speedtest.exe"   # Cambia esto si tienes la ruta completa, p.ej. "C:\Herramientas\speedtest.exe"

# ----------------------- COMPROBACIÓN INICIAL -----------------------
function Test-SpeedtestInstalado {
    $existe = Get-Command $SpeedtestExe -ErrorAction SilentlyContinue
    if (-not $existe) {
        Write-Host "No se encontró '$SpeedtestExe' en el PATH." -ForegroundColor Red
        Write-Host "Instálalo con: winget install Ookla.Speedtest.CLI" -ForegroundColor Yellow
        Write-Host "O descárgalo de: https://www.speedtest.net/apps/cli" -ForegroundColor Yellow
        return $false
    }

    Write-Host "Se encontró speedtest en: $($existe.Source)" -ForegroundColor DarkGray
    try {
        $version = & $SpeedtestExe --version 2>&1 | Out-String
        Write-Host "Versión detectada:`n$($version.Trim())" -ForegroundColor DarkGray
    }
    catch {
        Write-Host "No se pudo obtener la versión (no es necesariamente un problema)." -ForegroundColor DarkGray
    }

    return $true
}

# ----------------------- CREAR CABECERA DEL LOG -----------------------
function Initialize-Log {
    if (-not (Test-Path $RutaLog)) {
        "Fecha,Hora,Descarga_Mbps,Subida_Mbps,Ping_ms,Servidor,Resultado" |
            Out-File -FilePath $RutaLog -Encoding UTF8
    }
}

# ----------------------- EJECUTAR UNA MEDICIÓN -----------------------
function Invoke-SpeedTest {
    $ahora = Get-Date
    $fecha = $ahora.ToString("yyyy-MM-dd")
    $hora  = $ahora.ToString("HH:mm:ss")

    Write-Host "`n[$fecha $hora] Ejecutando test de velocidad..." -ForegroundColor Cyan

    try {
        # --accept-license y --accept-gdpr evitan que la primera ejecución se quede
        # esperando confirmación interactiva.
        # Capturamos también stderr (2>&1) para poder mostrar el error real si algo falla,
        # en vez de ocultarlo.
        $salidaCompleta = & $SpeedtestExe --format=json --accept-license --accept-gdpr 2>&1
        $textoSalida = ($salidaCompleta | Out-String).Trim()

        if (-not $textoSalida) {
            throw "El comando no devolvió ninguna salida (ni datos ni error)."
        }

        try {
            $datos = $textoSalida | ConvertFrom-Json
        }
        catch {
            # La salida no era JSON válido: seguramente es un mensaje de error
            # o de otra versión de 'speedtest' (p.ej. speedtest-cli en Python
            # en vez de la CLI oficial de Ookla). Lo mostramos tal cual.
            throw "La salida de speedtest no es JSON válido. Salida recibida: $textoSalida"
        }

        # Los valores vienen en bytes/segundo -> convertimos a Megabits/segundo
        $descargaMbps = [math]::Round(($datos.download.bandwidth * 8 / 1MB), 2)
        $subidaMbps   = [math]::Round(($datos.upload.bandwidth   * 8 / 1MB), 2)
        $pingMs       = [math]::Round($datos.ping.latency, 1)
        $servidor     = "$($datos.server.name) ($($datos.server.location))"

        # Mostrar resumen en consola
        Write-Host "  Descarga : $descargaMbps Mbps" -ForegroundColor Green
        Write-Host "  Subida   : $subidaMbps Mbps"   -ForegroundColor Green
        Write-Host "  Ping     : $pingMs ms"
        Write-Host "  Servidor : $servidor"

        # Guardar en el CSV
        "$fecha,$hora,$descargaMbps,$subidaMbps,$pingMs,$servidor,OK" |
            Out-File -FilePath $RutaLog -Append -Encoding UTF8
    }
    catch {
        Write-Host "  ERROR al medir la velocidad: $($_.Exception.Message)" -ForegroundColor Red
        "$fecha,$hora,,,,,ERROR: $($_.Exception.Message)" |
            Out-File -FilePath $RutaLog -Append -Encoding UTF8
    }
}

# ----------------------- BUCLE PRINCIPAL -----------------------
if (-not (Test-SpeedtestInstalado)) {
    return
}

Initialize-Log

Write-Host "Iniciando monitorización de velocidad de Internet." -ForegroundColor Magenta
Write-Host "Frecuencia: cada $IntervaloMinutos minutos." -ForegroundColor Magenta
Write-Host "Log guardado en: $RutaLog" -ForegroundColor Magenta
Write-Host "Pulsa Ctrl+C para detener.`n" -ForegroundColor Magenta

try {
    while ($true) {
        Invoke-SpeedTest
        Start-Sleep -Seconds ($IntervaloMinutos * 60)
    }
}
finally {
    Write-Host "`nMonitorización detenida." -ForegroundColor Magenta
}