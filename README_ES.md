# TryDockCmd

Kit de automatización orientado a producción para desplegar y operar Tryton ERP con Docker en Windows.

TryDockCmd proporciona un flujo controlado por menú para ciclo de vida de infraestructura, instalación de módulos, diagnóstico, backup y recuperación.  
Combina orquestación Batch (`tcd.bat`) con automatización Python/Proteus (`python/auto_full_setup.py`) para reducir tareas manuales post-instalación.

## Por qué este proyecto

- Estandariza la operación de Tryton sobre Docker para perfiles técnicos.
- Reduce errores manuales mediante validaciones y flujos guiados.
- Mejora la operatividad con trazabilidad, chequeos de estado y recuperación.
- Soporta entornos separados de producción (`tryton`) y demo (`tryton_demo`).

## Capacidades principales

- Gestión de ciclo de vida Docker: `checkdocker`, `startup`, `startdown`, `status`.
- Pipeline guiado de instalación: Descubrimiento de imágenes/contenedores, lectura de compose, inicialización.
- Automatización post-instalación de Tryton con Proteus: Empresa, Idiomas, Contabilidad, Ejercicios fiscales.
- Importación geográfica: Países y códigos postales por ISO seleccionado (`es`, `fr`, `de`).
- Diagnóstico forense:  Filtrado de errores, trazas y reportes de comparación de módulos.
- Protección de datos: Flujos de backup y restore desde menú.

## Alcance funcional (incluido)

- Orquestación Windows-first con CMD/Batch.
- Stack Docker Compose de tres servicios: `server`, `cron`, `postgres`.
- Interfaz del gestor multiidioma mediante `/lang`: `es-ES`, `en-US`.
- Automatización de idiomas/módulos Tryton: `TRYTON_LANGUAGE=es|fr|de`.
- Automatización Python por acción: `FULL`, `GEO`, `LANG`, `ACC`, `TAX`.
- Inyección en caliente de archivos hacia el contenedor activo: `/tmp/auto_full_setup.py`, `/tmp/trytond_setup.conf`.

## Fuera de alcance (no incluido)

- Orquestación cloud (Kubernetes, DB gestionadas).
- Controladores nativos Linux/macOS (el plano de control actual es Batch).
- Instalación automática de dependencias fuera de prerrequisitos de Docker Desktop.
- Migración ERP genérica fuera de los flujos de backup/restore existentes.

## Arquitectura

### Punto de entrada

- `tcd.bat` orquesta pre-flight, carga de entorno, enrutado de menú y logging.

### Componentes de runtime

- `compose.yml`: Define `server`, `cron`, `postgres`.
- `scripts/*.bat`: Operaciones modulares.
- `python/auto_full_setup.py`: Automatización de negocio/configuración con Proteus.
- `config/trytond.conf`: Identidad de negocio y configuración consumida por la automatización.
- `.env`:
  credenciales, versiones e idioma.

## Operaciones del menú principal

El menú de operaciones está organizado como ciclo de ejecución:

- `0` Realiza instalación/Bootstrap inicial cuando el entorno aún no está preparado.
- `1` a `3` Cubren operación diaria (estado, arranque, parada).
- `4` y `5` Se enfocan en observabilidad (logs y auditoría de errores).
- `6` y `7` Cubren protección de datos (backup y restore).
- `8` y `9` Son flujos de setup para producción/demo (módulos y base de datos).
- `10` Valida conectividad y abre el cliente web cuando los chequeos son correctos.

| Opción | Script | Propósito |
|---|---|---|
| 0 | `install.bat` | Instalación/Bootstrap completo |
| 1 | `status.bat` | Estado y verificaciones |
| 2 | `startup.bat` | Arranque de servicios |
| 3 | `startdown.bat` | Parada controlada de servicios |
| 4 | `logger.bat` | Visualización de logs |
| 5 | `errors.bat` | Auditoría centrada en errores |
| 6 | `backup.bat` | Backup |
| 7 | `restore.bat` | Restore |
| 8 | `install_tryton.bat` | Flujo de módulos en BD productiva |
| 9 | `install_demo.bat` | Flujo de demo/módulos en BD demo |
| 10 | `client.bat` | Verificación de conectividad y lanzamiento |

## Motor Proteus (`auto_full_setup.py`)

El motor se ejecuta dentro del contenedor Tryton y soporta:

- `FULL`: Ejecuta el setup completo (sync de módulos, geodata, flujo de idiomas, configuración empresa/contable, ejercicios y secuencias).
- `GEO`:  Ejecuta solo importación de paises/codigos postales para ISO seleccionado (`es`, `fr`, `de`).
- `LANG`: Ejecuta solo activación de idiomas/traducciones y flujo de upgrade.
- `ACC`:  Ejecuta solo configuracion de empresa/contabilidad/fiscal (plan contable, ejercicios, periodos y secuencias).
- `TAX`:  Ejecuta configuración de empresa/impuestos.
- 
Tareas implementadas:

- Reintentos de conexión y Bootstrap Tryton/DB.
- Sincronización de módulos y limpieza de asistentes.
- Resolución/creación de empresa desde `trytond.conf`/entorno.
- Activación de idiomas y asignación de idioma a admin.
- Vinculación contable por localización.
- Ejercicios fiscales (2026 al 2030), periodos y secuencias.
- Países, subdivisiones y códigos postales.

## Configuración

### `.env` (valores mínimos)

```bash
DB_PASSWORD=tu_password_db
PASSWORD=tu_password_admin_tryton
VERSION=7.8      # Indicate Tryton version. View Tryton versions url: https://downloads.tryton.org/
EMAIL=admin@dominio.com
LANGUAGE=es-ES
TRYTON_LANGUAGE=es
```

### `config/trytond.conf` (perfil de empresa)

```ini
[database]
uri = postgresql://postgres:tu_password_db@tryton-postgres-1:5432/

[company]
name = Mi Empresa
currency = EUR
journal_name = Diario General
journal_code = GEN            
vat_rates = 21,10,4 

```

## Requisitos

- Docker Desktop para Windows.
- PowerShell 5.1+.
- Permisos de escritura en:
  `log`, `tmp`, `backup`, `sql`.

## Inicio rápido

1. Configurar `.env`.
2. Configurar `config/trytond.conf`.
3. Ejecutar `tcd.bat`.
4. Usar opción `0` para primera instalación.
5. Acceder a Tryton en `http://localhost:8000`.

## Fortalezas operativas

- Modularidad de scripts: Operaciones aisladas y reutilizables.
- Pre-flight defensivo: Valida entorno, ficheros, versiones y estado Docker antes de ejecutar.
- Trazabilidad: Logs centralizados y extracción dirigida de errores.
- Extensibilidad controlada: Motor Python invocable por acción sin relanzar todo el setup.
- Preparación para recuperación: Backup/Restore integrado en el flujo del operador.

### 📄 Licencia

Este proyecto está licenciado bajo la licencia MIT.
Tryton-Docker-Manager: Facilita y protege la gestión de Tryton ERP.

---

- __Autor:__ [https://www.telepieza.com]
- __Colaborador:__ Gemini (Google AI)
- __Plataforma:__ Windows (CMD/Batch)
- __Motor:__ Docker & Docker Compose
- __Licencia:__ MIT
- __Versión del proyecto:__ v1.1.25 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
