# ⚙️ Documentación Técnica: `auto_full_setup.py` - El Corazón de TryDockCmd

## 1. Introducción: La Joya de la Corona

El script `auto_full_setup.py` es el motor inteligente detrás de **TryDockCmd**, actuando como un "usuario virtual" experto que automatiza la configuración completa de un entorno Tryton ERP. Su misión es transformar una infraestructura Docker vacía en un sistema contable profesional y plenamente operativo en cuestión de minutos, eliminando la intervención manual y garantizando la consistencia.

Inspirado en la necesidad de replicar configuraciones complejas de forma fiable, este script encapsula años de experiencia en despliegues de Tryton, similar a cómo el script de Argentina ha sido fundamental para la comunidad. Sin esta automatización, la puesta en marcha de Tryton sería un proceso tedioso y propenso a errores.

## 2. Filosofía de Diseño y Principios Clave

`auto_full_setup.py` se adhiere a principios de ingeniería de software robustos para asegurar su fiabilidad y adaptabilidad:

*   **Sincronización de Contexto (`User.get_preferences(True, {})`)**: Resuelve el problema del "Cold Start" en bases de datos nuevas. Al inicializar las preferencias del usuario, el script asegura que el entorno de Tryton esté en un estado conocido y funcional antes de aplicar configuraciones, evitando errores comunes de contexto.
*   **Idempotencia Real**: Cada operación realizada por el script verifica lógicamente la existencia de registros o configuraciones antes de crearlos. Esto permite que el script se ejecute múltiples veces de forma segura sin duplicar datos ni causar conflictos, facilitando la depuración y las re-ejecuciones.
*   **Proteus como Notario Digital**: En lugar de inyectar SQL directamente, `auto_full_setup.py` utiliza la API de Proteus. Esto garantiza que cada cambio se realice a través de la lógica de negocio de Tryton, validando las reglas contables y asegurando que la base de datos resultante sea legalmente coherente y técnicamente íntegra.
*   **Compatibilidad Multi-Versión**: El script está diseñado para adaptarse a las particularidades de las versiones de Tryton, desde la **7.0 (LTS)** hasta la **8.0**, y está preparado para futuras versiones como la 8.2.

## 3. Fases de Ejecución: Un Manual Paso a Paso

El script `auto_full_setup.py` orquesta una serie de fases críticas para la configuración de Tryton. A continuación, se detalla cada fase, sus acciones y las consideraciones de versión.

### 3.1. FASE ACC (Accounting - Contabilidad)

Esta fase se encarga de establecer la estructura contable fundamental de la empresa.

*   **Creación de Empresa y Moneda**:
    *   El script crea la entidad de empresa (`company.company`) y la vincula a la moneda principal (EUR por defecto).
    *   Se asegura de que el usuario administrador esté asociado a esta empresa.
    *   **Llamada a Proteus**: `Company.create()`, `Party.create()`, `User.write()`.
*   **Generación de Ejercicios Fiscales y Períodos**:
    *   Crea automáticamente **5 ejercicios fiscales** (2026-2030) y **60 períodos contables** asociados.
    *   Genera las secuencias de facturación necesarias.
    *   **Consideraciones de Versión (Tryton 7.6+)**: Se solucionó un bug de integración de ejercicios contables a partir de la versión 7.6 para asegurar su correcta creación.
    *   **Llamada a Proteus**: `FiscalYear.create()`, `Period.create()`, `Sequence.create()`.
*   **Configuración del Plan Contable (Localización ES)**:
    *   Carga automáticamente las 776 cuentas del Plan Contable Nacional (`account_es`) para la localización española.
    *   **Consideraciones de Versión (Tryton < 8.0 vs. Tryton 8.0+)**:
        *   **Tryton < 8.0**: El script gestiona módulos de localización independientes como `account_es`.
        *   **Tryton 8.0+**: Tryton integró muchos módulos de localización en el núcleo (`account`). El script reconoce esta integración y utiliza "módulos ancla" como `account_statement_sepa` o `party_siret` para detectar y configurar correctamente los planes contables integrados.
        *   Se optimizó Proteus para priorizar el módulo `account_es` inyectado manualmente, permitiendo el uso de plantillas Pymes/Normal con cuentas imputables en entornos Tryton 8.
    *   **Llamada a Proteus**: `Account.create()`, `AccountType.create()`, `AccountTax.create()`.

### 3.2. FASE TAX (Fiscalidad)

Esta fase configura los impuestos y su vinculación con la contabilidad.

*   **Configuración de Tipos de Impuestos**:
    *   Inyecta y configura automáticamente **64 tipos de impuestos** (ej. IVA 21%, 10%, 4%) para la localización española.
    *   Vincula estos impuestos con los diarios y secuencias contables correspondientes.
    *   **Consideraciones de Versión (Tryton 8.0+)**:
        *   **Bug Solucionado (v1.1.36)**: Se corrigió un bug crítico en la integración de impuestos de IVA a partir de la versión 8.0. En versiones anteriores (7.0-7.4), el filtro de vista para cuentas utilizaba el campo `type`, mientras que en 7.6-7.8 y 8.0+ se utiliza el campo `kind`. El script ahora maneja esta diferencia, asegurando la compatibilidad.
        *   Se corrigió el error `KeyError: 'kind'` en versiones < 8.0, utilizando `type` para filtrar cuentas imputables y `kind` para >= 8.0.
        *   Se aseguró que Proteus seleccione cuentas contables que no sean de tipo "Vista" para evitar errores de validación.
    *   **Llamada a Proteus**: `Tax.create()`, `TaxRule.create()`.

### 3.3. FASE EXT/MOD (Módulos Externos y Dependencias)

Esta fase, introducida y mejorada en la versión **1.1.30**, gestiona la instalación de módulos y dependencias que no forman parte de la imagen oficial de Tryton.

*   **Gestión de Dependencias Críticas**:
    *   Instala automáticamente librerías Python esenciales dentro del contenedor Tryton:
        *   **SignXML**: Motor de firma digital (estándar XML Signature y XAdES), obligatorio para Facturae y Verifactu.
        *   **pyOpenSSL**: Para gestión de certificados digitales (X.509) y conexiones seguras (SSL/TLS).
        *   **XMLSIG**: Para la integridad de objetos XML en comunicaciones con la administración.
        *   **Jinja2**: Motor de plantillas para generar dinámicamente mensajes XML.
    *   **Llamada a Proteus**: No directamente, sino a través de comandos de sistema (`pip install`, etc.) ejecutados dentro del contenedor.
*   **Flujos de Negocio Españoles (Facturae, Verifactu, SII)**:
    *   Automatiza la instalación de módulos específicos para el cumplimiento normativo español.
    *   **Lógica de Anclaje Contable (Validación de PREFIX)**: El script analiza el archivo `setup.py` del módulo `account_es` para detectar si la base contable es de NaN-tic (`PREFIX.*'nantic'`).
        *   Si es NaN-tic, descarga los paquetes desde su GitHub oficial.
        *   Si no, asume una instalación **COMMUNITY** y busca en Heptapod o en la ruta local de TryDockCmd (`modules/es/{version}/`).
    *   **Estrategia Multi-Proveedor y Resolución de Versiones**: Sigue un orden de prioridad (Heptapod > Local > GitHub) y verifica la existencia y compatibilidad de los módulos antes de la descarga.
    *   **Inyección Pura (Pure Modules)**: Para módulos con `setup.py` problemáticos o incompatibles con versiones modernas de `pip`, el script clona el repositorio en una carpeta temporal del host e inyecta los archivos directamente en el volumen de Tryton, ejecutando luego `python3 setup.py install` dentro del contenedor.
    *   **Auditoría de Versiones**: Registra el nombre del módulo, proveedor, rama/tag y el **Hash (ID)** del commit en `log/modules_git_audit.log` para una trazabilidad completa.
    *   **Llamada a Proteus**: Utiliza `trytond-admin` para la activación inicial (`-u`, `--activate-dependencies`), actualización de lista (`--update-modules-list`) y actualización global con traducciones (`--all`, `-l`).

### 3.4. FASE GEO (Geografía)

Esta fase se encarga de la importación de datos geográficos.

*   **Carga de Países, Subdivisiones y Códigos Postales**:
    *   Importa masivamente datos geográficos (países, subdivisiones y códigos postales) utilizando la base de datos GeoNames para España, Francia y Alemania.
    *   **Consideraciones de Versión**: Se modificó `auto_full_setup.py` en la versión **1.1.26** para incluir `process_env["PYTHONWARNINGS"] = "ignore:RequestsDependencyWarning"` y evitar warnings al incorporar códigos postales.
    *   **Llamada a Proteus**: No directamente, sino a través de scripts de Tryton como `/trytond/modules/country/scripts/import_countries.py` e `/trytond/modules/country/scripts/import_postal_codes.py`.

### 3.5. FASE LANG (Lenguajes)

Esta fase activa los idiomas y sus traducciones.

*   **Activación de Idiomas y Traducciones**:
    *   Activa los idiomas configurados en el archivo `.env` (ej. `es`, `fr`, `de`).
    *   Asocia el idioma al usuario administrador y refresca las traducciones en todos los módulos activados.
    *   **Optimización de Traducciones (v1.1.30)**: Se mejoró la carga de idiomas mediante el parámetro `-l` en la fase final de activación.
    *   **Llamada a Proteus**: `Language.create()`, `User.write()`, `trytond-admin --all -l`.

## 4. Beneficios para Técnicos y Proyectos Futuros

La existencia de `auto_full_setup.py` como un script robusto y bien documentado ofrece ventajas significativas:

*   **Reducción Drástica del Tiempo de Despliegue**: Lo que antes tomaba horas o días de configuración manual, ahora se completa en minutos.
*   **Consistencia y Fiabilidad**: Al automatizar el proceso, se eliminan los errores humanos y se garantiza que cada despliegue sea idéntico y cumpla con las reglas de negocio de Tryton.
*   **Facilidad de Replicación**: Permite a los técnicos replicar entornos de desarrollo, pruebas o producción con un esfuerzo mínimo.
*   **Base para la Innovación**: Al liberar a los técnicos de tareas repetitivas, pueden centrarse en el desarrollo de nuevas funcionalidades y la integración con otras herramientas.
*   **Conocimiento Centralizado**: El script actúa como una "receta" ejecutable de cómo configurar Tryton, sirviendo como una valiosa fuente de conocimiento para el equipo.
*   **Preparado para el Futuro**: Su diseño modular y la atención a la compatibilidad de versiones lo hacen una herramienta duradera y adaptable a las próximas evoluciones de Tryton.

## 5. Conclusión

`auto_full_setup.py` no es solo un script; es una manifestación de la filosofía de automatización y fiabilidad de TryDockCmd. Su capacidad para manejar la complejidad de Tryton a través de Proteus y adaptarse a las diferentes versiones lo convierte en un activo invaluable para cualquier proyecto que busque eficiencia y precisión en sus despliegues de ERP.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT
- **Versión del proyecto:** v1.1.36 Estable

---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
```