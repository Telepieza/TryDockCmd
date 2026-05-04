# Guia de TryDockCmd

Guia operativa para desplegar y administrar Tryton ERP sobre Docker en Windows.

Video guia en youtube: https://youtu.be/4i9TWQKoBeQ

## 1. Requisitos previos

- Docker Desktop instalado y arrancado.
- PowerShell 5.1+ disponible.
- Permisos de escritura en:
  `log`, `tmp`, `backup`, `sql`.

## 2. Configuración obligatoria

### 2.1 `.env`

Valores mínimos:

```bash
DB_PASSWORD=your_db_password
PASSWORD=your_tryton_admin_password
VERSION=7.8        # Indicar Tryton version. Ver todas las versiones Tryton url: https://downloads.tryton.org/
EMAIL=admin@example.com
LANGUAGE=es-ES
TRYTON_LANGUAGE=es
```

### 2.2 `config/trytond.conf`

```ini
[database]
uri = postgresql://postgres:your_db_password@tryton-postgres-1:5432/

[company]
name = My Company
currency = EUR
journal_name = Diario General
journal_code = GEN            
vat_rates = 21,10,4 

```

## 3. Flujo de arranque

1. Ejecuta `tcd.bat`.
2. El pre-flight valida archivos, entorno, metadatos compose y estado docker.
3. Si no detecta stack, usa la opción `0` para instalar.

## 4. Menu principal

| Opcion | Script | Descripción |
|---|---|---|
| 0 | `install.bat` | Instalación/Bootstrap completo |
| 1 | `status.bat` | Estado y verificaciones |
| 2 | `startup.bat` | Arranque de servicios |
| 3 | `startdown.bat` | Parada de servicios |
| 4 | `logger.bat` | Visualización de logs |
| 5 | `errors.bat` | Auditoria centrada en errores |
| 6 | `backup.bat` | Backup |
| 7 | `restore.bat` | Restore |
| 8 | `install_tryton.bat` | Flujo de módulos en BD producción |
| 9 | `install_demo.bat` | Flujo demo/módulos en BD demo |
| 10 | `client.bat` | Verificación de conectividad + navegador |

## 5. Motor de setup Python/Proteus

`python/auto_full_setup.py` se ejecuta dentro del contenedor Tryton y soporta:

- `FULL`: Ejecuta la secuencia completa (sync de módulos, importación geodata, activación de idiomas, configuración de empresa/contabilidad, ejercicios y secuencias).
- `GEO`: Importa/actualiza países y códigos postales para el ISO seleccionado (`es`, `fr`, `de`), sin ejecutar configuración contable.
- `LANG`: Activa idiomas traducibles y ejecuta el flujo de upgrade de traducciones/módulos, sin crear estructura fiscal/contable.
- `ACC`: Ejecuta configuración de empresa/contabilidad (contexto de empresa, enlace de plan, ejercicios, periodos y secuencias), sin importar geodata.
- `TAX`: Ejecuta configuración de empresa/impuestos.

Tareas principales:

- Sincronización de módulos y limpieza de asistentes.
- Configuración de empresa y moneda.
- Activación de idiomas.
- Mapeo contable por localización.
- Ejercicios fiscales, periodos y secuencias.
- Países, subdivisiones y códigos postales.

## 6. Resolución de incidencias

### Docker no disponible

- Verifica que Docker Desktop este totalmente iniciado.
- Reintenta opción `2` o reinicia desde el menú.

### Conflicto de puertos (8000 / 5432)

- Comprobar con:
  `netstat -ano | findstr :8000`
  `netstat -ano | findstr :5432`

### Desajuste de idioma/setup

- Revisa `LANGUAGE` y `TRYTON_LANGUAGE` en `.env`.
- Verifica que existan `lang/es-ES.txt` y `lang/en-US.txt`.

### Problemas restore/autenticación

- Comprueba que la password actual en `.env` coincide con la usada al inicializar el volumen.
- Si no coincide, resetea/actualiza credenciales DB según tu política de datos.

## 7. Recomendaciones operativas

- Ejecuta backup antes de actualizaciones de módulos importantes.
- Mantener docs y scripts alineados en el mismo PR.
- Prioriza cambios pequeños y testeadles  en Batch y Python.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.25 Estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
