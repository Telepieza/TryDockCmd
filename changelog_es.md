# 📜 Changelog - TryDockCmd

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato se basa en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.1.1] - 2026-04-29

### Added
- **Módulos:** Se quita el módulo account_eu en version 8, por dar problema en el --update
- **Integración Proteus:** Se incluye el idioma en la empresa y usuario admin al crear las tablas en tryton.

### Changed
-**Optimización:** Se eliminan los blancos al leer el fichero tritond.conf, en cada una de las opciones.

### Fixed
**Estandarización de Comandos:** Se corrigieron varios problemas de variables y logica en algunos programas.

## [1.1.0] - 2026-04-28

### Added
- **Modularidad de Módulos:** Implementación de `base_modules.bat` para centralizar la lógica de selección de módulos (F1-F8).
- **Detección Dinámica de Versión:** Soporte para diferenciar rutas de Python entre Tryton 7.0 (3.11) y 8.0 (3.13).
- **Filtrado de Localización:** Sistema de detección en caliente de módulos de lenguaje (ES, FR, DE) mediante validación de archivos en el contenedor.
- **Reportes de Instalación:** Inclusión de `install_reports.bat` para auditar la integridad de archivos XML y estados de módulos tras el despliegue.
- **Integración Proteus:** Automatización de Wizards contables y creación de ejercicios fiscales (2026-2030) mediante `auto_full_setup.py`.

### Changed
- **Orquestación de Instalación:** Refactorización de `install.bat` para mejorar la resiliencia en el arranque de contenedores mediante reintentos recursivos entre `status.bat` y `startup.bat`.
- **Optimización de UI:** Mejora en la visualización de barras de progreso y temporizadores en `global_routines.bat`.
- **Rendimiento:** Reducción de tiempos de espera estáticos por comprobaciones activas de estado del motor Docker.

### Fixed
- **Estandarización de Comandos:** Se corrigieron todas las llamadas internas para incluir explícitamente la extensión `.bat`, evitando ambigüedades en el procesador CMD de Windows.
- **Validación de Entorno:** Mejora en `startcontrol.bat` para asegurar que ningún sub-script se ejecute sin el contexto global de variables de `tcd.bat`.

---

## [1.0.0] - 2026-03-23

### Added
- **Lanzamiento Inicial:** Framework completo de gestión para Tryton ERP en Docker.
- **Motor i18n:** Soporte multi-idioma nativo para el gestor (es-ES, en-US).
- **YAML Intelligence:** Puente con PowerShell (`read-compose.ps1`) para lectura dinámica de puertos y versiones desde `compose.yml`.
- **Arquitectura de Seguridad:** Implementación de `startdocker.bat` con localización automática de Docker Desktop mediante protocolos URI y accesos directos.
- **Gestión de Datos:** Scripts base de Backup y Restore con validación de integridad MD5.
- **Auditoría:** Primer motor de detección de errores (`errors.bat`) con filtrado de patrones críticos (FATAL, EXCEPTION).

---

### Guía de Etiquetas
*   `Added`: Para nuevas funcionalidades.
*   `Changed`: Para cambios en funcionalidades existentes.
*   `Deprecated`: Para funcionalidades que se eliminarán en versiones futuras.
*   `Removed`: Para funcionalidades eliminadas.
*   `Fixed`: Para corrección de errores.
*   `Security`: En caso de vulnerabilidades.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.0 Stable

---

##### Optimized & Documented with the help of Gemini (Google AI)
  