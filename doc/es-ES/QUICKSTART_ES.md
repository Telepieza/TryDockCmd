# Inicio Rapido - TryDockCmd

## 1. Configurar

Editar `.env`:

```bash
DB_PASSWORD=your_db_password
PASSWORD=your_tryton_admin_password
VERSION=7.8        # Indicar Tryton version. Ver todas las versiones Tryton url: https://downloads.tryton.org/
EMAIL=admin@example.com
LANGUAGE=es-ES
TRYTON_LANGUAGE=es
```

Editar `config/trytond.conf`:

```ini
[database]
uri = postgresql://postgres:your_db_password@tryton-postgres-1:5432/

[company]
name = Mi Empresa
currency = EUR
journal_name = Diario General
journal_code = GEN            
vat_rates = 21,10,4 

```

## 2. Lanzar

Ejecutar:

```cmd
tcd.bat
```

## 3. Instalar

- En la primera ejecución, se activa de forma automática la opción `0`.
- El sistema prepara servicios Docker y ejecuta la automatización de setup.

## 4. Acceder

- Usar opción `10` (lanzamiento/verificación cliente).
- Abrir `http://localhost:8000`.
- Entrar con `admin` y la password definida en `.env`.

## 5. Operaciones diarias

- Opción `0`: instalación ERP tryton.
- Opción `1`: estado y chequeos.
- Opción `2`: arrancar servicios.
- Opción `3`: parar servicios.
- Opción `5`: auditoria de errores.
- Opción `6`: backup.
- Opción `7`: restore.

## 6. Notas

- Producción y demo se gestionan por separado (`tryton`, `tryton_demo`).
- El motor de setup soporta acciones `FULL`, `GEO`, `LANG`, `ACC`, `TAX`.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.25 Estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
