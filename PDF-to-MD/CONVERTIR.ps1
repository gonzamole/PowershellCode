$inputFolder  = "C:\ClaudePDF\IN"
$outputFolder = "C:\ClaudePDF\OUT"
$errorFolder  = "C:\ClaudePDF\ERROR"

# Crear carpetas si no existen
New-Item -ItemType Directory -Force -Path $inputFolder  | Out-Null
New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null
New-Item -ItemType Directory -Force -Path $errorFolder  | Out-Null

Write-Host "========================================="
Write-Host "  Conversor automático PDF -> Markdown"
Write-Host "========================================="
Write-Host ""
Write-Host "Entrada : $inputFolder"
Write-Host "Salida  : $outputFolder"
Write-Host "Errores : $errorFolder"
Write-Host ""
Write-Host "Pulsa Ctrl+C para detener."
Write-Host ""

while ($true) {

    Get-ChildItem -Path $inputFolder -Filter "*.pdf" -File | ForEach-Object {

        $pdf      = $_.FullName
        $fileName = $_.Name
        $baseName = $_.BaseName
        $md       = Join-Path $outputFolder ($baseName + ".md")

        # Solo procesa si todavía no existe el Markdown
        if (-not (Test-Path $md)) {

            Write-Host "-----------------------------------------"
            Write-Host "Convirtiendo:"
            Write-Host $pdf
            Write-Host ""

            # Ejecutar MarkItDown
            & markitdown "$pdf" -o "$md"

            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0 -and (Test-Path $md)) {

                try {

                    # Leer el Markdown como UTF-8
                    $texto = [System.IO.File]::ReadAllText(
                        $md,
                        [System.Text.Encoding]::UTF8
                    )

                    # Guardarlo explícitamente como UTF-8 con BOM
                    $utf8Bom = New-Object System.Text.UTF8Encoding($true)

                    [System.IO.File]::WriteAllText(
                        $md,
                        $texto,
                        $utf8Bom
                    )

                    $size = (Get-Item $md).Length

                    # Considerar sospechoso un Markdown demasiado pequeño
                    if ($size -gt 20) {

                        Write-Host "OK"
                        Write-Host "Markdown creado:"
                        Write-Host $md
                        Write-Host "Tamaño: $size bytes"
                        Write-Host ""

                    }
                    else {

                        Write-Host "ERROR: El Markdown está vacío o casi vacío."
                        Write-Host ""

                        Remove-Item $md -ErrorAction SilentlyContinue

                        $errorDestination = Join-Path $errorFolder $fileName

                        Move-Item `
                            -Path $pdf `
                            -Destination $errorDestination `
                            -Force

                        Write-Host "PDF movido a:"
                        Write-Host $errorDestination
                    }

                }
                catch {

                    Write-Host "ERROR procesando la codificación UTF-8:"
                    Write-Host $_.Exception.Message

                    Remove-Item $md -ErrorAction SilentlyContinue

                    $errorDestination = Join-Path $errorFolder $fileName

                    Move-Item `
                        -Path $pdf `
                        -Destination $errorDestination `
                        -Force
                }

            }
            else {

                Write-Host "ERROR: MarkItDown no pudo convertir el PDF."
                Write-Host "Código de salida: $exitCode"
                Write-Host ""

                if (Test-Path $md) {
                    Remove-Item $md -ErrorAction SilentlyContinue
                }

                $errorDestination = Join-Path $errorFolder $fileName

                Move-Item `
                    -Path $pdf `
                    -Destination $errorDestination `
                    -Force

                Write-Host "PDF movido a:"
                Write-Host $errorDestination
            }
        }
    }

    Start-Sleep -Seconds 3
}