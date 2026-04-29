# Contributing to TryDockCmd

Thank you for contributing. This project (TryDockCmd) focuses on reliable, Windows-first operations for Tryton on Docker.

## Contribution Areas

- Bug fixes in Batch orchestration (`tcd.bat`, `scripts/*.bat`).
- Improvements in setup automation (`python/auto_full_setup.py`).
- Documentation alignment (`README.md`, `GUIDE.md`, `QUICKSTART.md`, `README_summary.md`).
- Diagnostics, backup/restore, and operational safety enhancements.

## Reporting Bugs

Please include:

1. Windows version and Docker Desktop version.
2. Relevant `.env` values (mask passwords/secrets).
3. Last log lines from `/log`.
4. Exact menu option and script executed.
5. Reproduction steps.

## Pull Request Rules

1. Keep changes scoped and reviewable.
2. Preserve compatibility with Windows CMD/Batch.
3. Do not hardcode credentials, hostnames, or private paths.
4. If UI text changes, update language files in `/lang` (`es-ES.txt`, `en-US.txt`).
5. Keep docs accurate to real behavior; avoid unsupported claims.

## Code Expectations

- Prefer incremental, defensive changes.
- Keep script flow explicit (`ERRORLEVEL`, controlled exits).
- Maintain current architecture: `tcd.bat` as entry point, `scripts/` as modular operations.
- For Python updates: Preserve action modes (`FULL`, `GEO`, `LANG`, `ACC`,`TAX`) and log compatibility.

## Validation Before PR

Run at minimum:

1. `python -m py_compile python\auto_full_setup.py`
2. Basic script smoke checks through menu options 1, 2, 3, 5.
3. If setup logic changed, test container execution path that uses:
   `/tmp/auto_full_setup.py` and `/tmp/trytond_setup.conf`.

## Branch and Commit Convention

- Branch examples:
  `fix/log-path-consistency`, `docs/readme-alignment`, `feat/install-audit`.
- Commit messages: Use short, technical, outcome-oriented phrasing.

## Security Notes

- Never commit real credentials from `.env`.
- Do not include sensitive logs in PR descriptions.

## License

By contributing, you agree your contributions are licensed under MIT.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.25 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)
