# Checklist de Backup

Objetivo: Asegurar que el backup sea completo, consistente y restaurable.

## Antes del Backup
- Confirmar que estas en el proyecto y entorno correctos.
- Verificar que `docker compose` y los contenedores estan saludables.
- Comprobar espacio libre en el volumen de backup (ZIP + carpeta temporal).
- Confirmar nombres de BD (`DB_NAME`, opcional `DB_NAME_DEMO`).
- Confirmar que `DIR_BACKUP` y `DIR_TMP` existen y tienen permisos.

## Durante el Backup
- Opción 1 o 2: El ZIP debe contener
  - `*_dumpall.sql`
  - carpeta `trytond/`
  - `img_postgres.tar` y `img_tryton.tar` (solo opción 1)
  - `compose.yml` si se copia
- Opción 3/4/5: Deben existir SQL por BD
  - `DB_NAME_schema.sql` o `DB_NAME_data.sql` o `DB_NAME_full_db.sql`
  - Opcional `DB_NAME_DEMO_*` si existe demo
- Revisar errores en logs de pg_dump/pg_dumpall.

## Después del Backup
- Verificar que el ZIP existe y su tamaño es razonable (> 1KB).
- Si la carpeta de backup sigue, confirmar si debe eliminarse.
- Abrir el ZIP y validar ficheros requeridos.
- Guardar el ZIP en lugar seguro (idealmente fuera del host).
- Registrar fecha, proyecto y opción usada.

## Compatibilidad con Restore
- Restore completo (opciones 1-2) requiere `*_dumpall.sql` y `trytond/` en el ZIP.
- Restore estructura/datos/base completa requiere los SQL con el nombre correcto.
- Si existe demo y su fichero, se restaurará también.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.0.0 estable

---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)

