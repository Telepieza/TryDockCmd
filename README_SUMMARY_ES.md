# TryDockCmd - Resumen

TryDockCmd is an operations layer for Tryton ERP in Docker, on the Windows operating system.

## Que ofrece

- Control por menú mediante `tcd.bat`.
- Scripts de ciclo de vida Docker para iniciar/parar/estado/instalar.
- Automatización post-instalación con Proteus (`python/auto_full_setup.py`).
- Interfaz del gestor con idiomas `es-ES` y `en-US`.
- Separación de entornos `tryton` (producción) y `tryton_demo` (demo).
- Diagnostico, backup y restore integrados.

## Modos del motor de setup

- `FULL`: flujo completo
- `GEO`:  solo importación geodata (Países, provincias, códigos postales)
- `LANG`: solo flujo de idiomas
- `ACC`:  solo contabilidad/empresa/fiscal
- `TAX`:  solo contabilidad/empresa/impuestos

## Puntos técnicos

- Arquitectura modular en `scripts/`.
- Validaciones pre-flight antes de acciones críticas.
- Automatizacion en contenedor con inyección controlada de:
  `/tmp/auto_full_setup.py`, `/tmp/trytond_setup.conf`.
- Logs de setup disponibles en:
  `/tmp/trytond_proteus.txt`.

## Requisitos

- Docker Desktop
- PowerShell 5.1+
- `.env` y `config/trytond.conf` validos

## Inicio

1. Configurar `.env` y `config/trytond.conf`.
2. Ejecutar `tcd.bat`.
3. Usar opción `0` en primera instalación.
4. Acceder a Tryton con opción `10`.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.0.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
