# 📜 Changelog - TryDockCmd

All notable changes to this project will be documented in this file. The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

**[Versión en Español disponible aquí](changelog_es.md)**

---

## [1.1.1] - 2026-04-29

### Added
- **Modules:** The account_eu module was removed in version 8 due to issues with the --update command.
- **Proteus Integration:** The language is now included for the company and admin user when creating tables in Tryton.

### Changed
- **Optimization:** Blanks were removed when reading the tritond.conf file in each option.

### Fixed
**Command Standardization:** Solventig variable and logic issues were corrected in some programs.

## [1.1.0] - 2026-04-28

### Added
- **Module Modularity:** Implementation of `base_modules.bat` to centralize module selection logic (F1-F8).
- **Dynamic Version Detection:** Support for differentiating Python paths between Tryton 7.0 (3.11) and 8.0 (3.13).
- **Localization Filtering:** Hot-detection system for language modules (ES, FR, DE) through file validation within the container.
- **Installation Reports:** Inclusion of `install_reports.bat` to audit XML integrity and module statuses post-deployment.
- **Proteus Integration:** Accounting Wizard automation and creation of fiscal years (2026-2030) via `auto_full_setup.py`.

### Changed
- **Installation Orchestration:** Refactoring of `install.bat` to improve container startup resilience using recursive retries between `status.bat` and `startup.bat`.
- **UI Optimization:** Improved visualization of progress bars and timers in `global_routines.bat`.
- **Performance:** Reduced static wait times through active Docker engine status checks.

### Fixed
- **Command Standardization:** Fixed all internal calls to explicitly include the `.bat` extension, avoiding ambiguities in the Windows CMD processor.
- **Environment Validation:** Improved `startcontrol.bat` to ensure no sub-script runs without the global variable context from `tcd.bat`.

---

## [1.0.0] - 2026-03-23

### Added
- **Initial Release:** Complete management framework for Tryton ERP on Docker.
- **i18n Engine:** Native multi-language support for the manager (es-ES, en-US).
- **YAML Intelligence:** Bridge with PowerShell (`read-compose.ps1`) for dynamic port and version parsing from `compose.yml`.
- **Security Architecture:** Implementation of `startdocker.bat` with automatic Docker Desktop location via URI protocols and shortcuts.
- **Data Management:** Base scripts for Backup and Restore with MD5 integrity validation.
- **Auditing:** Initial error detection engine (`errors.bat`) with critical pattern filtering (FATAL, EXCEPTION).

---

### Labels Guide
*   `Added`: For new features.
*   `Changed`: For changes in existing functionalities.
*   `Deprecated`: For features that will be removed in future versions.
*   `Removed`: For removed features.
*   `Fixed`: For bug fixes.
*   `Security`: In case of vulnerabilities.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.0 Stable

---

##### Optimized & Documented with the help of Gemini (Google AI)
  