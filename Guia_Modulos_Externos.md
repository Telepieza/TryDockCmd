# Guía de Instalación de Módulos Externos y Dependencias (v1.1.30)

Esta guía detalla el funcionamiento del sistema de extensión de Tryton mediante el gestor **TryDockCmd**, centrándose en la instalación de paquetes de sistema, dependencias Python y módulos de la comunidad o partners.

## 1. Filosofía del Sistema

A partir de la versión 1.1.30, TryDockCmd utiliza un motor híbrido para la gestión de módulos que no vienen incluidos en la imagen oficial de Docker. El sistema se divide en dos capas:
1. **Interfaz (`install_modules.bat`)**: Menú interactivo para seleccionar qué instalar.
2. **Motor (`install_external.bat`)**: Lógica inteligente que resuelve dependencias, busca en repositorios remotos o locales e inyecta el código en el contenedor.

## 2. El Menú de Instalación (Opción 8 del TCD)

El menú de **Instalación de paquetes y módulos** ofrece las siguientes secciones críticas:

### 2.1 Preparación (Opciones 1 y 2)
- **Backup (Opción 1)**: Es **obligatorio** realizar una copia de seguridad antes de proceder. La inyección de módulos modifica la estructura de archivos del contenedor y la base de datos.
- **Git y Mercurial (Opción 2)**: Instala `git` y `hg` (Mercurial) dentro del contenedor. Es el paso previo necesario para que el motor pueda descargar código en tiempo real.

### 2.2 Dependencias Python (Opciones 3 a 6)
La instalación de dependencias varía según el origen del módulo:

1. **SignXML**: Requerido obligatoriamente para los módulos de **NANTIC** y **COMMUNITY** (necesario para la firma XAdES de Facturae y Verifactu).
2. **XMLSIG / pyOpenSSL / Jinja2**: Estas dependencias son específicas y requeridas únicamente por los flujos de trabajo de **NANTIC** para gestionar comunicaciones avanzadas con la AEAT y generación dinámica de documentos.

### 2.3 Flujos de Negocio (Opciones 7 a 9)
Permite la instalación automatizada de:
- **Facturae**: Facturación electrónica española.
- **Verifactu**: Cumplimiento de la nueva normativa antifraude (AEAT).
- **SII**: Suministro Inmediato de Información.

> **Nota**: El sistema detecta automáticamente si debe instalar la versión para Tryton 7.0,7.2,7.4,7.6,7.8,8.0 según tu configuración en `.env`. Se aconseja que la instalación se realice con la 7.0, siendo la versión LTS más estable.

## 3. El Motor de Inyección (`install_external`)

Cuando seleccionas un módulo (Facturae,Verifactu o SII), el motor realiza los siguientes pasos:

### 3.1 Resolución de Dependencias
El script no solo instala el módulo solicitado, sino que analiza recursivamente el archivo `tryton.cfg` y busca todas las dependencias necesarias para cada módulo (`account_es_aeat`, `certificate_manager`, etc.).

### 3.2 Estrategia Multi-Proveedor
El motor sigue una secuencia de búsqueda estricta para garantizar la estabilidad:
1. **COMMUNITY (Heptapod)**: Primero busca en los repositorios oficiales de la comunidad (`https://foss.heptapod.net/tryton-community/modules/`).
2. **TRYDOCKCMD (Local)**: Si no lo encuentra, busca en la carpeta local `modules/` del host.
3. **NANTIC (GitHub)**: Finalmente, busca en el repositorio de NaN-tic (`https://github.com/NaN-tic/`).

### 3.3 Lógica de Anclaje Contable (Validación de PREFIX)
Para evitar conflictos críticos en la contabilidad española, el motor analiza el archivo `setup.py` del módulo `account_es` ya instalado:

- **Si detecta `PREFIX.*'nantic'`**: El sistema identifica que la base es de NaN-tic e instalará los paquetes desde su GitHub oficial: `https://github.com/NaN-tic/trytond-{module_name}.git`.
- **Si NO detecta el prefijo**: El sistema asume una instalación **COMMUNITY** e intentará descargar desde Heptapod. Si falla, buscará en la ruta local **TRYDOCKCMD** (`modules/es/{version}/`).

> **Importante**: Si el sistema detecta que la contabilidad base no es de NANTIC, bloqueará automáticamente a NANTIC como proveedor para prevenir la mezcla de modelos contables incompatibles.

### 3.4 Módulos "Puros" (Pure Modules)
Para evitar errores comunes de compatibilidad con `pip` (como el antiguo `use_2to3`), el motor utiliza una técnica de **Inyección Pura**:
- Clona el repositorio en una carpeta temporal.
- Inyecta los archivos directamente en el volumen de Tryton.
- Ejecuta el `setup.py` dentro del contenedor para registrar los entry-points.

## 4. Compatibilidad con Tryton 8.0

En la versión 8, Tryton ha integrado muchos módulos de localización en el núcleo (`account`). La guía de v1.1.30 contempla esto:
- **Módulos Ancla**: El motor detecta si la localización española es la de NANTIC o la comunitaria para evitar conflictos de "PREFIX".

## 5. Auditoría y Logs

Cada vez que se instala un módulo externo, el sistema genera registros para soporte técnico:
- **Árbol de dependencias**: Se visualiza en pantalla durante la instalación.
- **Log de Auditoría**: `log/modules_git_audit.log`. Contiene el nombre del módulo, el proveedor, la rama descargada y el **Hash (ID)** del commit para garantizar la trazabilidad.
- **Reporte XML**: Al finalizar, se auditan los archivos XML para asegurar que no hay errores de carga.

## 6. Resolución de Problemas

- **Error de Rama**: Si el módulo no existe para tu versión de Tryton (ej. 8.0), el sistema buscará automáticamente la etiqueta más alta disponible o la rama `default`.
- **Conflicto de Localización**: Si intentas instalar módulos de NANTIC sobre una base de datos con localización comunitaria, el sistema lo bloqueará para proteger la integridad de tus cuentas contables.

----

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.30 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)