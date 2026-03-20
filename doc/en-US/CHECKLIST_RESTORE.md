# Restore Checklist

Purpose: Ensure the restore is clean, deterministic, and safe.

## Before Restore
- Confirm backup ZIP is from the correct project.
- Validate ZIP integrity and required files:
  - `*_dumpall.sql` and `trytond/` for options 1-2
  - `DB_NAME_schema.sql`, `DB_NAME_data.sql`, or `DB_NAME_full_db.sql` for options 3-5
- Verify `DB_NAME` and optional `DB_NAME_DEMO` are correct.
- Confirm `DIR_TMP` is writable (temporary extraction).
- Ensure containers are not running critical workloads.

## During Restore
- Option 1: Images + DB + files
  - Containers are stopped before loading images.
  - Images load without error.
- Option 2: DB + files (no images)
  - Containers started for DB restore.
- Option 3/4/5: Schema/Data/Full DB
  - DB is created or validated as needed.
  - `psql` or `pg_restore` completes without errors.

## After Restore
- Restart services and confirm containers are healthy.
- Validate Tryton login and basic operations.
- Confirm data consistency (sample records, modules).
- Check logs for errors during restore.
- Store restore logs with backup metadata.

## Safety Rules
- Never restore into the wrong environment.
- Always use a known?good ZIP.
- If any command fails, stop and investigate before retrying.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.0.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
