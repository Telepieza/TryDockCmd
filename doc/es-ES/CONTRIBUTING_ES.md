# Contribuir a TryDockCmd

Gracias por contribuir. Este proyecto (TryDockCmd) prioriza operaciones fiables de Tryton sobre Docker en Windows.

## Áreas de contribución

- Correcciones en TryDockCmd Batch (`tcd.bat`, `scripts/*.bat`).
- Mejoras en automatización de setup (`python/auto_full_setup.py`).
- Alineación documental (`README.md`, `GUIDE.md`, `QUICKSTART.md`, `README_summary.md`).
- Mejoras en diagnóstico, backup/restore y seguridad operativa.

## Reporte de bugs

Incluye:

1. Versión de Windows y Docker Desktop.
2. Valores relevantes de `.env` (Parametrización).
3. Últimas líneas de `/log`.
4. Opción de menú y script ejecutado.
5. Pasos de reproducción.

## Reglas para Pull Request

1. Mantener cambios acotados y revisables.
2. Preservar compatibilidad con Windows CMD/Batch.
3. No hardcodear credenciales, hostnames o rutas privadas.
4. Si cambias textos UI, actualiza `/lang` (`es-ES.txt`, `en-US.txt`).
5. Mantener documentación fiel al comportamiento real.

## Expectativas de código

- Preferir cambios incrementales y defensivos.
- Flujo explícito de scripts (`ERRORLEVEL`, salidas controladas).
- Mantener la arquitectura actual:
  `tcd.bat` como entry point y `scripts/` como operaciones modulares.
- En Python: Preservar modos `FULL`, `GEO`, `LANG`, `ACC`, `TAX` y compatibilidad de logs.

## Validacion previa al PR

Como mínimo:

1. `python -m py_compile python\auto_full_setup.py`
2. Smoke checks basicos en menú opciones 1, 2, 3, 5.
3. Si cambias setup, probar ruta en contenedor que usa:
   `/tmp/auto_full_setup.py` y `/tmp/trytond_setup.conf`.

## Convención de ramas y commits

- Ramas ejemplo: `fix/log-path-consistency`, `docs/readme-alignment`, `feat/install-audit`.
- Commits:  Mensaje corto, técnico y orientado a resultado.

## Seguridad

- No subir credenciales reales de `.env`.
- No publicar logs sensibles en PR.

## Licencia

Al contribuir, aceptas que tu contribución queda bajo MIT.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
