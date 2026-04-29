# 📜 Changelog - TryDockCmd

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato se basa en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.1.25] - 2026-04-29

### Added
- **Inyección Dinámica de Módulos (V8):** Implementada la capacidad de inyectar módulos personalizados (ej. `account_es`, `account_es_sii`) desde la carpeta `TryDockCmd/modules/` al contenedor de Tryton 8 si no existen previamente. Esto permite extender la funcionalidad de la V8 con módulos de versiones anteriores o externos.
- **Validación de Inyección Total:** Se confirma que la inyección de las carpetas completas de `account_es` y `account_es_sii` (versión 7.8) proporciona a Proteus todas las plantillas de cuentas imputables y tasas de IVA necesarias para un entorno funcional en Tryton 8.
- **Estabilidad Cross-Version:** Validación completa de compatibilidad entre las ramas 7.8 y 8.0. Se unifican todos los scripts del sistema bajo el mismo número de versión para garantizar la integridad del despliegue.
**Reportes de instalación:** Se incluye el documento ModulesTrytonV8.md, indicando todos los módulos que contiene tryton en la version 8 en su imagen de docker.
- **Módulos:** Se quita el módulo account_eu en version 8, por dar problema en el --update
- **Integración Proteus:** Se incluye el idioma en la empresa y usuario admin al crear las tablas en tryton.

### Fixed
- **Auditoría Dual V7/V8:** Se corrigen las rutas de búsqueda en `_pick_account_for_taxes` para evitar el error `KeyError: kind` en la rama 7.8, asegurando que la fase TAX se complete con éxito en ambas versiones.
- **Compatibilidad Proteus V7:** Se corrige el error `KeyError: 'kind'` al detectar automáticamente la arquitectura del modelo de cuentas. En versiones < 8.0 se utiliza el campo `type` para filtrar cuentas imputables, mientras que en >= 8.0 se mantiene el uso de `kind`.
- **Interpolación Compose:** Se corrige la sintaxis de variables en `compose.yml` para evitar errores de parseo y se establece la versión 7.0 como fallback seguro.
- **Estrategia Híbrida V8:** Refinamiento del buscador de cuentas de impuestos para priorizar el PGC (Pymes/Normal) inyectado manualmente sobre el plan universal del núcleo de Tryton 8.
- **Localización Híbrida V8:** Se optimiza Proteus para priorizar el módulo `account_es` inyectado manualmente, permitiendo el uso de plantillas Pymes/Normal con cuentas imputables en entornos Tryton 8.
- **Resiliencia Fiscal V8:** Se corrige el error de validación de dominio en la creación de impuestos al asegurar que Proteus seleccione cuentas contables que no sean de tipo "Vista". Se añade soporte de búsqueda por nombre para cuentas a cobrar/pagar en el Plan Universal.
- **Plantillas Universales V8:** Se integran los nombres exactos detectados en los XML del core (`account_chart.xml`) para España, Francia y Alemania, permitiendo la creación automática del plan contable en Tryton 8 sin módulos externos.
- **Localización Francesa V8:** Se ajusta el módulo ancla para Francia a `party_siret` en Tryton 8.0, asegurando la detección correcta del plan contable integrado.
- **Localización Integrada V8:** Se confirma la integración de planes contables en el core de `account`. Se ajusta `auto_full_setup.py` para detectar plantillas mediante nombres genéricos localizados.
- **Compatibilidad Tryton 8:** Actualizado `auto_full_setup.py` para usar `account_statement_sepa` como módulo ancla para la localización española, dado que `account_es` está integrado en el núcleo en la versión 8.
- **Integración Proteus:** Añadida validación de existencia para plantillas de plan contable en `auto_full_setup.py` para evitar fallos silenciosos en la creación de cuentas.
 Corregido el `chart_mapping` en `auto_full_setup.py` para asegurar la correcta creación de cuentas contables y tasas de impuestos en Tryton 8.
**Estandarización de Comandos:** Se solucionan varios problemas de variables globales en TryDockCmd.

### Changed
- **Optimización de Logs:** Se modifica `auto_full_setup.py` para listar únicamente las plantillas de cuentas raíz en lugar de todas las cuentas del sistema, mejorando la legibilidad del log de instalación y facilitando el diagnóstico de localizaciones disponibles.
- **Filtro de Localización V8:** Se restringe la configuración contable y fiscal para España únicamente cuando el módulo `account_es` está presente y activo. Esto evita que en Tryton 8 se intenten usar las plantillas universales del núcleo, las cuales carecen de cuentas imputables.
- **Resiliencia:** `auto_full_setup.py` ya no detiene la ejecución ante fallos en acciones individuales, permitiendo que todas las tareas se intenten y se registren para auditoría.
- **Diagnóstico:** Se ha añadido el volcado al log de todas las plantillas de cuentas raíz disponibles en `setup_accounts` para facilitar la resolución de problemas de localización.
-**Optimización:** Se eliminan los blancos al leer el fichero tritond.conf, en cada una de las opciones.

---


## [1.1.0] - 2026-04-28

### Added
- **Modularidad de Módulos:** Implementación de `base_modules.bat` para centralizar la lógica de selección de módulos (F1-F8).
- **Detección Dinámica de Versión:** Soporte para diferenciar rutas de Python entre Tryton 7.X (3.11) y 8.X (3.13).
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
  