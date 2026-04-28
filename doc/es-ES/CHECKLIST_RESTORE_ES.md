# Checklist de Restore

Objetivo: Asegurar una restauración limpia, determinista y segura.

## Antes del Restore
- Confirmar que el ZIP corresponde al proyecto correcto.
- Validar integridad del ZIP y ficheros requeridos:
  - `*_dumpall.sql`, `trytond/` o `trytond_persist.tar` para opciones 1-2
  - `DB_NAME_schema.sql`, `DB_NAME_data.sql` o `DB_NAME_full_db.sql` para opciones 3-5
- Verificar `DB_NAME` y opcional `DB_NAME_DEMO`.
- Confirmar que `DIR_TMP` es escribible (extracción temporal).
- Asegurar que no hay cargas criticas en los contenedores.

## Durante el Restore
- Opción 1: Imágenes + BD + ficheros
  - Contenedores detenidos antes de cargar imagenes.
  - Imágenes cargadas sin error.
- Opción 2: BD + ficheros (sin imágenes)
  - Contenedores iniciados para restaurar BD.
- Opción 3/4/5: Estructura/Datos/Base completa
  - BD creada o validada según el modo.
  - `psql` o `pg_restore` sin errores.
  - Si existe `trytond_persist.tar`, asegurar descompresión interna con `tar -xf`.

## Después del Restore
- Reiniciar servicios y confirmar estado saludable.
- Validar acceso a Tryton y operaciones básicas.
- Confirmar consistencia de datos (registros, modulos).
- Revisar logs de errores.
- Guardar logs junto con metadata del backup.

## Reglas de Seguridad
- Nunca restaurar en el entorno equivocado.
- Usar siempre un ZIP verificado.
- Si falla un comando, detener y analizar antes de repetir.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
