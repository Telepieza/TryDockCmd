# Backup Checklist

Purpose: Ensure the backup is complete, consistent, and safe to restore.

## Before Backup
- Confirm you are in the correct project and environment.
- Verify `docker compose` and containers are healthy.
- Check free disk space on backup volume (target zip + temp folder).
- Confirm database names (`DB_NAME`, optional `DB_NAME_DEMO`) are correct.
- Confirm `DIR_BACKUP` and `DIR_TMP` exist and are writable.

## During Backup
- Option 1 or 2: Ensure ZIP contains
  - `*_dumpall.sql`
  - `trytond/` folder
  - `img_postgres.tar` and `img_tryton.tar` (option 1 only)
  - `compose.yml` if copied
- Option 3/4/5: Ensure SQL files exist for each DB
  - `DB_NAME_schema.sql` or `DB_NAME_data.sql` or `DB_NAME_full_db.sql`
  - Optional `DB_NAME_DEMO_*` file if demo DB exists
- Check for any errors logged by pg_dump/pg_dumpall.

## After Backup
- Verify ZIP file exists and size is reasonable (> 1KB).
- If backup folder exists, confirm it was cleaned after zipping (if expected).
- Open ZIP and validate required files are present.
- Store ZIP in secure location (off-host if possible).
- Record backup date, project, and option used.

## Restore Compatibility Notes
- Full restore (options 1-2) expects `*_dumpall.sql` and `trytond/` inside the ZIP.
- Schema/Data/Full DB restore expects the matching SQL files by name.
- If demo DB is backed up, restore will attempt it when its file exists.
  
---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)

