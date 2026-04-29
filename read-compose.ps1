# ===============================================================================
# PROGRAM:   read-compose.ps1
# PROJECT:   Tryton Docker Manager
# AUTHOR:    [https://www.telepieza.com - Gemini (Google AI)]
# COLLABORATOR: Gemini (Google AI)
# VERSION:   1.1.25
# DATE:      29/04/2026
# LICENSE:   MIT License
# DESCRIPTION: Tryton Docker Manager (powershell)
# ==============================================================================
$ErrorActionPreference = "Stop"
try {
  $cfg = docker compose config --format json | ConvertFrom-Json
}  catch {
   throw "Error reading file compose.yml"
}
# Función para separar Imagen y Versión
function Get-ImageParts {
    param($fullImage)
    # Expresión regular para separar la última parte después del ':' (el tag)
    if ($fullImage -match '^(.*):([^:]+)$') {
        return @{ "Name" = $matches[1]; "Tag" = $matches[2] }
    }
    return @{ "Name" = $fullImage; "Tag" = "latest" }
}
$serverImage = ""
if ($cfg.services.server.image) {
   $serverImage = $cfg.services.server.image
   Write-Output "SERVER_IMAGE=$serverImage"
   Write-Output "SERVER_IMAGE=$($cfg.services.server.image)"
   $server = Get-ImageParts -fullImage $cfg.services.server.image
   Write-Output "SERVER_IMAGE_NAME=$($server.Name)"
   Write-Output "SERVER_IMAGE_VERSION=$($server.Tag)"
   # Puertos y portocolos del server (contenedor)
   if ($cfg.services.server.ports -and $cfg.services.server.ports.Count -gt 0) {
      $targetPort = $cfg.services.server.ports[0].target       # Interna (Docker)
      $publishedPort = $cfg.services.server.ports[0].published # Publica (Host)
      $protocolPort = $cfg.services.server.ports[0].protocol   # Protocolo
      Write-Output "SERVER_PORT_TARGET=$targetPort"
      Write-Output "SERVER_PORT_PUBLISHED=$publishedPort"
      Write-Output "SERVER_PORT_PROTOCOL=$protocolPort"
   } else {
      Write-Output "SERVER_PORT_TARGET=8000"
      Write-Output "SERVER_PORT_PUBLISHED=8000"
      Write-Output "SERVER_PORT_PROTOCOL=tcp"
   }
   # Imagen de cron y version
   Write-Output "CRON_IMAGE=$($cfg.services.cron.image)"
   $cron = Get-ImageParts -fullImage $cfg.services.cron.image
   Write-Output "CRON_IMAGE_NAME=$($cron.Name)"
   Write-Output "CRON_IMAGE_VERSION=$($cron.Tag)"
   # Imagen de postgres y version
   Write-Output "POSTGRES_IMAGE=$($cfg.services.postgres.image)"
   $postgres = Get-ImageParts -fullImage $cfg.services.postgres.image
   Write-Output "POSTGRES_IMAGE_NAME=$($postgres.Name)"
   Write-Output "POSTGRES_IMAGE_VERSION=$($postgres.Tag)"
}

exit 0