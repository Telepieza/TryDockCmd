# Guía Avanzada de Instalación de Módulos Externos y Dependencias (v1.1.30)

Esta guía detalla el funcionamiento del sistema de extensión de Tryton mediante el gestor **TryDockCmd**, centrándose en la instalación de paquetes de sistema, dependencias Python y módulos de la comunidad o partners.

## 1. Filosofía del Sistema

A partir de la versión 1.1.30, TryDockCmd utiliza un motor híbrido para la gestión de módulos que no vienen incluidos en la imagen oficial de Docker. El sistema se divide en dos capas:
1. **Interfaz (`install_modules.bat`)**: Menú interactivo para seleccionar qué instalar.
2. **Motor (`install_external.bat`)**: Lógica inteligente que resuelve dependencias, busca en repositorios remotos o locales e inyecta el código en el contenedor.

## 2. El Menú de Instalación (Opción 8 del tcd.bat)

El menú de **Instalación de paquetes y módulos** ofrece las siguientes secciones críticas:

### 2.1 Preparación (Opciones 1 y 2)
- **Backup (Opción 1)**: Es **obligatorio** realizar una copia de seguridad antes de proceder. La inyección de módulos modifica la estructura de archivos del contenedor y la base de datos.
- **Git y Mercurial (Opción 2)**: Instala `git` y `hg` (Mercurial) dentro del contenedor. Es el paso previo necesario para que el motor pueda descargar código en tiempo real.

### 2.2 Dependencias Python (Opciones 3 a 6)
La instalación de dependencias es un paso crítico, ya que dota al contenedor de Tryton de las capacidades criptográficas y lógicas necesarias para la administración electrónica avanzada:

1. **SignXML (Opción 3)**: Es el motor de firma digital. Implementa el estándar XML Signature y el perfil **XAdES** (*XML Advanced Electronic Signatures*). Es **obligatoria** para Facturae y Verifactu; sin ella, el ERP no puede realizar el sellado digital que otorga validez legal a los documentos.
2. **pyOpenSSL (Opción 4)**: Proporciona una interfaz para la librería OpenSSL. Es vital para la gestión de certificados digitales (X.509) y la apertura de túneles seguros (SSL/TLS) para que el ERP pueda identificarse y "hablar" con los servidores de la AEAT.
3. **XMLSIG (Opción 5)**: Implementación del estándar del W3C para la integridad de objetos XML. Se utiliza en los flujos de comunicación con la administración para asegurar que el contenido del mensaje no ha sido alterado tras su firma.
4. **Jinja2 (Opción 6)**: Potente motor de plantillas. Se utiliza para generar dinámicamente los cuerpos de los mensajes XML, permitiendo que la lógica de negocio de Tryton se traduzca fielmente al formato técnico exigido por la normativa.

### 2.3 Flujos de Negocio (Opciones 7 a 9)
Permite la instalación automatizada de:

- **Facturae (Opción 7)**: La factura electrónica (también conocida popularmente como factura-e o Facturae) es un documento digital con la misma validez legal y fiscal que una factura tradicional en papel. Sustituye el formato físico por un fichero informático (generalmente en formato XML) que garantiza la autenticidad e integridad de la operación.
    *   **En España (Facturae)**: Es el estándar oficial y el formato electrónico específico (basado en XML) utilizado para enviar facturas a organismos públicos a través del punto general de entrada.
    *   **Validez**: Tienen el mismo valor legal que una factura en papel.
    *   **Uso**: Es obligatorio su uso para proveedores que trabajan con el Estado, Comunidades Autónomas y Ayuntamientos. La futura **Ley Crea y Crece** extenderá esta obligatoriedad a las transacciones entre empresas (B2B).
    *   **Herramienta oficial**: El Gobierno proporciona un software descargable para generar, firmar y gestionar este tipo de facturas. Para más información y descargas, visita el Portal Oficial de Facturae.
    *   **Implementación en TryDockCmd**: El sistema inyecta el módulo `account_es_facturae` y sus dependencias, permitiendo la generación de facturas en formato XML con firma XAdES, asegurando el cumplimiento de la normativa.

- **Verifactu (Opción 8)**: Es el flujo de mayor relevancia técnica y legal actual en España, diseñado para dar respuesta a la **Ley Antifraude**.
    * **¿A quién afecta?**: Afecta a todos los autónomos, profesionales y empresas en España obligados a expedir facturas.
    * **Obligatoriedad**: Su función es garantizar la integridad, conservación y trazabilidad de los registros. El sistema inyecta la lógica de **hashes encadenados** y permite que las facturas incluyan el código QR y la leyenda oficial "VERI*FACTU".
    * **Fecha clave**: A partir del **1 de enero de 2027**, será obligatorio por ley que todo software de facturación esté adaptado a este sistema de remisión inmediata de datos a la AEAT.

- **SII (Opción 9)**: El Suministro Inmediato de Información. Es el sistema para la llevanza de los libros registro del IVA a través de la sede electrónica de la AEAT. Este flujo es vital para empresas en el régimen de devolución mensual (REDEME) o aquellas con una facturación superior a 6M€, automatizando el envío en un plazo de 4 días.

> **Nota**: El sistema detecta automáticamente si debe instalar la versión para Tryton 7.0,7.2,7.4,7.6,7.8,8.0 según tu configuración en `.env`. Se aconseja que la instalación se realice con la 7.0, siendo la versión LTS más estable.

## 3. El Motor de Inyección (`install_external`)

Cuando seleccionas un módulo (Facturae,Verifactu o SII), el motor realiza los siguientes pasos:

### 3.1 Resolución de Dependencias
El script no solo instala el módulo solicitado, sino que analiza recursivamente el archivo `tryton.cfg` y busca todas las dependencias necesarias para cada módulo (`account_es_aeat`, `certificate_manager`, etc.).

### 3.2 Lógica de Anclaje Contable (Validación de PREFIX)
Para evitar conflictos críticos en la contabilidad española, el motor analiza el archivo `setup.py` del módulo `account_es` ya instalado:

- **Si detecta `PREFIX.*'nantic'`**: El sistema identifica que la base es de NaN-tic e instalará los paquetes desde su GitHub oficial: `https://github.com/NaN-tic/trytond-{module_name}.git`.
- **Si NO detecta el prefijo**: El sistema asume una instalación **COMMUNITY** e intentará descargar desde Heptapod. Si falla, buscará en la ruta local **TRYDOCKCMD** (`modules/es/{version}/`).

> **Importante**: Si el sistema detecta que la contabilidad base no es de NANTIC, bloqueará automáticamente a NANTIC como proveedor para prevenir la mezcla de modelos contables incompatibles.

### 3.3 Estrategia Multi-Proveedor y Resolución de Versiones
El motor sigue una secuencia de búsqueda estricta para garantizar estabilidad y compatibilidad. Por cada módulo y sus dependencias, se realiza el siguiente proceso:

1.  **Verificación de Existencia**:
    *   Primero comprueba si el módulo ya está **activado en la base de datos de Tryton**.
    *   Si no está activado, comprueba si existe físicamente en el contenedor o si es importable como paquete Python.
    *   Si el módulo ya existe o está activado, se marca como `NATIVO` y se omite su descarga.

2.  **Búsqueda por Proveedor (Orden de Prioridad)**:
    *   **COMMUNITY (Heptapod)**:
        *   Intenta clonar la **rama** que coincide con la versión LTS de Tryton (ej. `7.0`).
        *   Si no existe, intenta con la rama `default` o busca el **tag** más alto compatible.
        *   **Auditoría**: Registra el nombre, proveedor, rama/tag y el **Hash (ID)** del commit en `log/modules_git_audit.log`.

    *   **TRYDOCKCMD (Local)**:
        *   Busca en la carpeta local `modules/` del host según el idioma y versión.
        *   Si se encuentra, inyecta los archivos directamente en el volumen de Tryton.

    *   **NANTIC (GitHub)**:
        *   Traduce el nombre del módulo al nombre del repositorio oficial de NaN-tic.
        *   Aplica lógica de ramas (versión completa, LTS o ramas por defecto).
        *   **Instalación Estándar**: Usa `pip install` directamente desde GitHub.
        *   **Instalación "Pura"**: Para módulos con `setup.py` problemáticos, usa la técnica de Inyección Pura para asegurar la integridad de los archivos.

3.  **Análisis de Dependencias (`tryton.cfg`)**:
    *   Una vez localizado un módulo, el motor extrae su archivo de configuración y añade las dependencias declaradas en la sección `[depends]` a la cola de procesamiento.

4.  **Validación de Compatibilidad**:
    *   Se compara la versión mayor del módulo con la versión instalada de Tryton para evitar fallos de arquitectura.

### 3.4 Activación de Módulos en Tryton
Una vez inyectados todos los archivos, el sistema activa los módulos en la base de datos siguiendo este ciclo:

1.  **Activación Inicial**: Ejecuta `trytond-admin` con los flags `-u` y `--activate-dependencies` para procesar el módulo solicitado.
2.  **Actualización de Lista**: Ejecuta `--update-modules-list` para que Tryton reconozca los nuevos módulos inyectados en el sistema de archivos.
3.  **Actualización Global y Traducciones**: Ejecuta un comando `--all` forzando la carga de datos XML y aplicando el parámetro `-l` para refrescar las traducciones al idioma configurado.

### 3.5 Reinicio de Contenedores
Para garantizar que los cambios surtan efecto y se limpien las cachés internas, el motor realiza un reinicio completo de los servicios de Tryton (`trytond` y `trytond-cron`).

### 3.6 Inyección Pura y Módulos "Puros"
Para evitar errores comunes de compatibilidad con versiones modernas de `pip` (como el antiguo error `use_2to3`), el motor utiliza una técnica de **Inyección Pura**:
- Clona el repositorio en una carpeta temporal del host.
- Inyecta los archivos directamente en el volumen de Tryton.
- Ejecuta `python3 setup.py install` dentro del contenedor para registrar los *entry-points* necesarios.

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

## 7. Resumen del Flujo Lógico (Para Vídeo Resumen)

Para el estilo **Pizarra**, el vídeo debe seguir esta secuencia lógica:
1.  **Cimientos**: Verificación de Docker y Git (Prerrequisitos).
2.  **Inteligencia de Datos**: El motor analiza el ADN contable (PREFIX) para decidir el proveedor.
3.  **Inyección y Dependencias**: Carga de SignXML y lógicas criptográficas.
4.  **Cumplimiento Legal**: Activación de Facturae (Ley Crea y Crece) y Verifactu (Ley Antifraude).
5.  **Trazabilidad**: Generación del log de auditoría con Hashes de Git.

## 8. Guía para Presentadores de IA (NotebookLM)

Al generar el vídeo, indica a los presentadores que se centren en:
*   **Seguridad:** Resaltar que el proceso es reversible y auditable mediante el log de auditoría.
*   **Automatización:** Mencionar que la inyección de dependencias como `SignXML` elimina la necesidad de configurar librerías manualmente.
*   **Fechas Críticas:** Enfatizar la fecha del **1 de enero de 2027** para Verifactu, posicionando a TryDockCmd como la solución lista para el futuro.
*   **Resiliencia:** Explicar la "Inyección Pura" como la solución definitiva para módulos con instaladores antiguos.

----

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.30 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)