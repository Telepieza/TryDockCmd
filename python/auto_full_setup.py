# ===============================================================================
# PROGRAM:   auto_full_setup.py
# PROJECT:   Tryton Docker Manager
# VERSION:   1.0.0
# DATE:      01/03/2026
# LICENSE:   MIT License
# DESCRIPTION: Enlace TryDockCmd con proteus
# ==============================================================================
import os
import logging
from datetime import date
import time
import sys
import configparser
import subprocess
from decimal import Decimal
import proteus
# Añadimos p_config como alias para que coincida con la subrutina
from proteus import config as p_config, Model, Wizard 
from trytond.config import config as trytond_config
from trytond.pool import Pool

# -------------------------------------------------
# CONFIGURACIÓN DE LOGGING (Tu original mejorada)
# -------------------------------------------------
# Ruta fija por compatibilidad con scripts .bat (docker cp desde /tmp)
# Permite override opcional con SETUP_LOG_PATH.
log_path = os.environ.get("SETUP_LOG_PATH", "/tmp/trytond_proteus.txt")
os.makedirs(os.path.dirname(log_path), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_path),
        logging.StreamHandler(sys.stdout)
    ]
)

# -------------------------------------------------
# DICCIONARIOS DE MENSAJES (Tus originales intactos)
# -------------------------------------------------
RAW_LANG = os.environ.get('APP_LANGUAGE', 'es-ES').lower()
APP_LANG = RAW_LANG.split('-')[0] if '-' in RAW_LANG else RAW_LANG
MESSAGES = {
    'es': {
        'start': "--- CONEXIÓN EXITOSA ---",
        'wait': "Intento {}/10: Esperando a Postgres. {}",
        'scan': "--- ESCANEANDO MÓDULOS Y ASISTENTES ---",
        'comp_phase': "--- GESTIÓN DE EMPRESA ({}) ---",
        'comp_found': "Empresa detectada: {}",
        'comp_create': "Creando empresa '{}'...",
        'lang_phase': "--- CONFIGURACIÓN DE IDIOMAS Y TRADUCCIONES ---",
        'lang_act': "Activando idioma: {}",
        'lang_error': "Error en fase: {}",
        'fisc_year': "Ejercicio {} creado.",
        'acc_link': "Cuentas vinculadas para {}.",
        'success': "=== SETUP COMPLETADO EXITOSAMENTE ===",
        'conf_file': "Datos obtenidos del archivo: {}",
        'conf_warn': "Sin entorno ni .conf. Usando valores de emergencia.",
        'conf_active': "CONFIGURACIÓN ACTIVA -> Empresa: {} | Moneda: {}",
        'ctx_upd': "Contexto actualizado para {}. Moneda: {}",
        'admin_es': "Perfil Admin set en Español.",
        'error': "ERROR EN EL SETUP: {}",
        'read_error': "Error en lectura de configuración: {}",
        'acc_error': "Error en el plan contable {}: {}",
        'conf_phase': "--- FASE DE CONFIGURACIÓN ---",
        'end_phase': "--- FASE {} FINALIZADA ---",
        'geo_techn': "Info técnica (Geodata) {}",
        'geo_start': "Motor Geodata: Importando Países y Códigos Postales para {}",
        'geo_step1': "Paso 1/2: Importando Países (Scripts oficiales)...",
        'geo_step2': "Paso 2/2: Importando Códigos Postales ({}). Proceso lento (Esperar) ...",
        'geo_skip1': "Los países ya están importados. Saltamos al siguiente proceso 1/2.",
        'geo_skip2': "Ya existen códigos postales para {}. Se omite el paso 2/2.",
        'geo_error': "Error durante la ejecución: {}",
        'seq_move': "Asientos {}",
        'geo_error1': "Error en script oficial (Código {})",
        'currency_not_found': "Moneda no encontrada: {}",
        'company_not_created': "El asistente no creó la empresa: {}",
        'admin_lang_skip': "Actualización de idioma admin omitida: {}",
        'invoice_seq_missing': "No hay secuencias de factura para el ejercicio.",
        'unsupported_action': "Acción no soportada: {}",
        'journal_created': "Diario contable {} creado.",
        'vat_skipped_no_module': "IVA España omitido: módulo account_es no activo.",
        'vat_skipped_no_account': "No se pudo crear IVA: no hay cuentas contables disponibles.",
        'vat_skipped_bad_type': "No se pudo crear {}: tipo de impuesto no compatible.",
        'vat_skipped_bad_rate': "No se pudo crear {}: campo de porcentaje no compatible.",
        'vat_created': "IVA España creado para account_es: {}.",
        'vat_already_present': "IVA España ya existente, no recreado: {}."
    },
    'en': {
        'start': "--- CONNECTION SUCCESSFUL ---",
        'wait': "Attempt {}/10: Waiting for Postgres. {}",
        'scan': "--- SCANNING MODULES AND WIZARDS ---",
        'comp_phase': "--- COMPANY MANAGEMENT ({}) ---",
        'comp_found': "Company detected: {}",
        'comp_create': "Creating company '{}'...",
        'lang_phase': "--- LANGUAGES AND TRANSLATIONS CONFIGURATION ---",
        'lang_act': "Activating language: {}",
        'lang_error': "Phase error: {}",
        'fisc_year': "Fiscal year {} created.",
        'acc_link': "Accounts linked for {}.",
        'success': "=== SETUP COMPLETED SUCCESSFULLY ===",
        'conf_file': "Data obtained from file: {}",
        'conf_warn': "No environment or .conf found. Using emergency values.",
        'conf_active': "ACTIVE CONFIGURATION -> Company: {} | Currency: {}",
        'ctx_upd': "Context updated for {}. Currency: {}",
        'admin_es': "Admin profile set to Spanish.",
        'error': "SETUP ERROR: {}",
        'read_error': "Configuration reading error: {}",
        'acc_error': "Error in accounting plan {}: {}",
        'conf_phase': "--- CONFIGURATION PHASE ---",
        'end_phase': "--- PHASE {} COMPLETED ---",
        'geo_techn': "Technical information (Geodata) {}",
        'geo_start': "Geodata Engine: Importing Countries & Postal Codes for {}",
        'geo_step1': "Step 1/2: Importing Countries (Official scripts)...",
        'geo_step2': "Step 2/2: Importing Postal Codes ({}). Slow process (Wait) ...",
        'geo_skip1': "Countries already seem to be loaded. Skipping Step 1/2.",
        'geo_skip2': "Postal codes already exist for {}. Skipping Step 2/2.",
        'geo_error': "Error during execution {}",
        'seq_move': "Account Moves {}",
        'geo_error1': "Error in official script (Code {})",
        'currency_not_found': "Currency not found: {}",
        'company_not_created': "Company wizard did not create company: {}",
        'admin_lang_skip': "Admin language update skipped: {}",
        'invoice_seq_missing': "No invoice sequence links available for fiscal year.",
        'unsupported_action': "Unsupported action: {}",
        'journal_created': "Accounting journal {} created.",
        'vat_skipped_no_module': "Spanish VAT skipped: account_es module is not active.",
        'vat_skipped_no_account': "Could not create VAT: no accounting accounts available.",
        'vat_skipped_bad_type': "Could not create {}: incompatible tax type.",
        'vat_skipped_bad_rate': "Could not create {}: incompatible percentage field.",
        'vat_created': "Spanish VAT created for account_es: {}.",
        'vat_already_present': "Spanish VAT already exists, not recreated: {}."
    },
    'fr': {
        'start': "--- CONNEXION RÉUSSIE ---",
        'wait': "Tentative {}/10: Attente de Postgres. {}",
        'scan': "--- ANALYSE DES MODULES ET ASSISTANTS ---",
        'comp_phase': "--- GESTION DE L'ENTREPRISE ({}) ---",
        'comp_found': "Entreprise détectée: {}",
        'comp_create': "Création de l'entreprise '{}'...",
        'lang_phase': "--- CONFIGURATION DES LANGUES ET TRADUCTIONS ---",
        'lang_act': "Activation de la langue: {}",
        'lang_error': "Erreur de phase: {}",
        'fisc_year': "Exercice comptable {} créé.",
        'acc_link': "Comptes liés pour {}.",
        'success': "=== CONFIGURATION TERMINÉE AVEC SUCCÈS ===",
        'conf_file': "Données obtenues du fichier: {}",
        'conf_warn': "Pas d'environnement ni de .conf. Utilisation de valeurs d'urgence.",
        'conf_active': "CONFIGURATION ACTIVE -> Entreprise: {} | Devise: {}",
        'ctx_upd': "Contexte mis à jour pour {}. Devise: {}",
        'admin_es': "Profil Admin configuré en Espagnol.",
        'error': "ERREUR DE CONFIGURATION: {}",
        'read_error': "Erreur de lecture de la configuration: {}",
        'acc_error': "Erreur dans le plan comptable {}: {}",
        'conf_phase': "--- PHASE DE CONFIGURATION ---",
        'end_phase': "--- PHASE {} TERMINÉE ---",
        'geo_techn': "Informations techniques (géodonnées) {}",
        'geo_start': "Moteur Geodata: Importation des Pays et Codes Postaux pour {}",
        'geo_step1': "Étape 1/2: Importation des Pays (Scripts officiels)...",
        'geo_step2': "Étape 2/2: Importation des Codes Postaux ({}).Processus lent (Patienter) ...",
        'geo_skip1': "Les pays semblent déjà être chargés. Saut de l'étape 1/2.",
        'geo_skip2': "Les codes postaux existent déjà pour {}. Saut de l'étape 2/2.",
        'geo_error': "Erreur lors de l'exécution {}",
        'seq_move': "Écritures comptables {}",
        'geo_error1': "Erreur dans le script officiel (Code {})",
        'currency_not_found': "Devise introuvable : {}",
        'company_not_created': "L'assistant n'a pas créé l'entreprise : {}",
        'admin_lang_skip': "Mise à jour de la langue admin ignorée : {}",
        'invoice_seq_missing': "Aucun lien de séquence de facture disponible pour l'exercice.",
        'unsupported_action': "Action non prise en charge : {}",
        'journal_created': "Journal comptable {} créé.",
        'vat_skipped_no_module': "TVA Espagne ignorée : le module account_es n'est pas actif.",
        'vat_skipped_no_account': "Impossible de créer la TVA : aucun compte comptable disponible.",
        'vat_skipped_bad_type': "Impossible de créer {} : type de taxe incompatible.",
        'vat_skipped_bad_rate': "Impossible de créer {} : champ de pourcentage incompatible.",
        'vat_created': "TVA Espagne créée pour account_es : {}.",
        'vat_already_present': "TVA Espagne déjà existante, non recréée : {}."
    },
    'de': {
        'start': "--- VERBINDUNG ERFOLGREICH ---",
        'wait': "Versuch {}/10: Warten auf Postgres. {}",
        'scan': "--- SCANNEN VON MODULEN UND ASSISTENTEN ---",
        'comp_phase': "--- UNTERNEHMENSVERWALTUNG ({}) ---",
        'comp_found': "Unternehmen erkannt: {}",
        'comp_create': "Unternehmen '{}' wird erstellt...",
        'lang_phase': "--- SPRACH- UND ÜBERSETZUNGSKONFIGURATION ---",
        'lang_act': "Sprache aktivieren: {}",
        'lang_error': "Phasenfehler: {}",
        'fisc_year': "Geschäftsjahr {} erstellt.",
        'acc_link': "Konten verknüpft für {}.",
        'success': "=== SETUP ERFOLGREICH ABGESCHLOSSEN ===",
        'conf_file': "Daten aus Datei erhalten: {}",
        'conf_warn': "Keine Umgebung oder .conf gefunden. Notfallwerte werden verwendet.",
        'conf_active': "AKTIVE KONFIGURATION -> Unternehmen: {} | Währung: {}",
        'ctx_upd': "Kontext aktualisiert für {}. Währung: {}",
        'admin_es': "Admin-Profil auf Spanisch gesetzt.",
        'error': "SETUP-FEHLER: {}",
        'read_error': "Fehler beim Lesen der Konfiguration: {}",
        'acc_error': "Fehler im Kontenplan {}: {}",
        'conf_phase': "--- KONFIGURATIONSPHASE ---",
        'end_phase': "--- PHASE {} ABGESCHLOSSEN ---",
        'geo_techn': "Technische Informationen (Geodaten) {}",
        'geo_start': "Geodata-Engine: Importieren von Ländern und Postleitzahlen für {}",
        'geo_step1': "Schritt 1/2: Länder importieren (Offizielle Skripte)...",
        'geo_step2': "Schritt 2/2: Postleitzahlen importieren ({}).Es dauert etwas (Bitte warten)...",
        'geo_skip1': "Länder scheinen bereits geladen zu sein. Schritt 1/2 wird übersprungen.",
        'geo_skip2': "Postleitzahlen existieren bereits für {}. Schritt 2/2 wird übersprungen.",
        'geo_error': "Fehler bei der Ausführung {}",
        'seq_move': "Buchungssätze {}",
        'geo_error1': "Fehler im offiziellen Skript (Code {})",
        'currency_not_found': "Währung nicht gefunden: {}",
        'company_not_created': "Der Assistent hat das Unternehmen nicht erstellt: {}",
        'admin_lang_skip': "Admin-Sprachaktualisierung übersprungen: {}",
        'invoice_seq_missing': "Keine Rechnungssequenz-Verknüpfungen für das Geschäftsjahr verfügbar.",
        'unsupported_action': "Nicht unterstützte Aktion: {}",
        'journal_created': "Buchungsjournal {} erstellt.",
        'vat_skipped_no_module': "Spanische MwSt. übersprungen: Modul account_es ist nicht aktiv.",
        'vat_skipped_no_account': "MwSt. konnte nicht erstellt werden: keine Buchhaltungskonten verfügbar.",
        'vat_skipped_bad_type': "{} konnte nicht erstellt werden: inkompatibler Steuertyp.",
        'vat_skipped_bad_rate': "{} konnte nicht erstellt werden: inkompatibles Prozentfeld.",
        'vat_created': "Spanische MwSt. für account_es erstellt: {}.",
        'vat_already_present': "Spanische MwSt. bereits vorhanden, nicht neu erstellt: {}."
    }
}

# Obtenemos el idioma del entorno (ej: 'es-ES' -> 'es')
requested_lang = os.getenv('APP_LANGUAGE', 'en')[:2].lower()
msg = MESSAGES.get(requested_lang, MESSAGES['en'])

# -------------------------------------------------
# NUEVA FUNCIÓN: IMPORTACIÓN DE GEODATA (Inyectada)
# -------------------------------------------------
def run_geodata_import(database, config_file, iso_code):
    logging.info(msg['geo_start'].format(iso_code))
    base_mod = os.environ.get('TRYTON_BASE_MODULE', '/usr/local/lib/python3.11/dist-packages/trytond/modules')
    scripts_path = f"{base_mod}/country/scripts"
    iso_up = iso_code.upper()
    try:
        # 1. COMPROBACIÓN DE PAÍSES
        Country = Model.get('country.country')
        countries_exist = False
        try:
            if len(Country.find([], limit=201)) > 200:
                countries_exist = True
        except Exception:
            pass 
        if countries_exist:
            logging.info(msg['geo_skip1'])
        else:
            logging.info(msg['geo_step1'])
            result = subprocess.run(
                [sys.executable, f"{scripts_path}/import_countries.py", "-d", database, "-c", config_file],
                capture_output=True, text=True, check=True
            )
            if result.stderr:
                logging.debug(result.stderr.strip())
            # Refresco del Pool usando el alias p_config
            p_config.get_config().pool.init()

        # 2. COMPROBACIÓN DE CÓDIGOS POSTALES (Carga perezosa)
        zips_exist = False
        try:
            Zip = Model.get('country.zip')
            if Zip.find([('country.code', '=', iso_up)], limit=1):
                zips_exist = True
        except (KeyError, Exception):
            zips_exist = False

        if zips_exist:
            logging.info(msg['geo_skip2'].format(iso_up))
        else:
            logging.info(msg['geo_step2'].format(iso_up))
            # Ejecutamos con salida en vivo para facilitar diagnóstico de cargas grandes.
            subprocess.run(
                [sys.executable, f"{scripts_path}/import_postal_codes.py", "-d", database, "-c", config_file, iso_up],
                stdout=sys.stdout,
                stderr=sys.stderr,
                text=True,
                check=True
            )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(msg['geo_error1'].format(e.returncode)) from e
    except Exception as e:
        logging.debug(msg['geo_techn'].format(str(e)))
        raise
                        
# -------------------------------------------------
# FUNCIONES ORIGINALES (Tal cual me las pasaste)
# -------------------------------------------------

def get_company_config(conf_path='/config/trytond.conf'):
    logging.info(msg['conf_phase'])
    config = configparser.ConfigParser()
    env_name = os.environ.get('COMPANY_NAME')
    env_currency = os.environ.get('COMPANY_CURRENCY')
    env_journal_name = os.environ.get('COMPANY_JOURNAL_NAME')
    env_journal_code = os.environ.get('COMPANY_JOURNAL_CODE')
    env_vat_rates = os.environ.get('COMPANY_VAT_RATES')
    data = {
        'name': env_name or '',
        'currency': env_currency or '',
        'journal_name': env_journal_name or '',
        'journal_code': env_journal_code or '',
        'vat_rates': env_vat_rates or '',
    }
    if (not data['name'] or not data['currency']
            or not data['journal_name'] or not data['journal_code'] or not data['vat_rates']):
        try:
            if os.path.exists(conf_path):
                config.read(conf_path)
                if 'company' in config:
                    if not data['name']: data['name'] = config['company'].get('name', 'Telepieza')
                    if not data['currency']: data['currency'] = config['company'].get('currency', 'EUR')
                    if not data['journal_name']: data['journal_name'] = config['company'].get('journal_name', 'Diario General')
                    if not data['journal_code']: data['journal_code'] = config['company'].get('journal_code', 'GEN')
                    if not data['vat_rates']: data['vat_rates'] = config['company'].get('vat_rates', '21,10,4')
                    logging.info(msg['conf_file'].format(conf_path))
            else:
                if not data['name']: data['name'] = 'Telepieza'
                if not data['currency']: data['currency'] = 'EUR'
                if not data['journal_name']: data['journal_name'] = 'Diario General'
                if not data['journal_code']: data['journal_code'] = 'GEN'
                if not data['vat_rates']: data['vat_rates'] = '21,10,4'
                logging.warning(msg['conf_warn'])
        except Exception as e:
            logging.error(msg['read_error'].format(e))
    # Normaliza entradas potencialmente sucias desde entorno/.conf (espacios, comillas o comentarios inline).
    data['currency'] = normalize_currency_code(data.get('currency'))
    data['name'] = (data.get('name') or 'Telepieza').strip()
    data['journal_name'] = (data.get('journal_name') or 'Diario General').strip()
    data['journal_code'] = normalize_conf_value(data.get('journal_code') or 'GEN').upper()[:10]
    data['vat_rates'] = parse_vat_rates(data.get('vat_rates'))
    logging.info(msg['conf_active'].format(data['name'], data['currency']))       
    return data

def normalize_currency_code(value):
    cleaned = (value or '').strip()
    cleaned = normalize_conf_value(cleaned)
    return (cleaned or 'EUR').upper()

def normalize_conf_value(value):
    cleaned = (value or '').strip()
    if len(cleaned) >= 2 and cleaned[0] == cleaned[-1] and cleaned[0] in ("'", '"'):
        cleaned = cleaned[1:-1].strip()
    for marker in ('#', ';'):
        if marker in cleaned:
            cleaned = cleaned.split(marker, 1)[0].strip()
    return cleaned

def parse_vat_rates(raw_value):
    cleaned = normalize_conf_value(raw_value)
    if not cleaned:
        return ['21', '10', '4']
    parsed = []
    for part in cleaned.split(','):
        token = part.strip().replace('%', '').replace(' ', '')
        if not token:
            continue
        if token.isdigit() and token not in parsed:
            parsed.append(token)
    return parsed or ['21', '10', '4']

def parse_actions(raw_action):
    action_text = (raw_action or 'FULL').strip()
    if not action_text:
        return {'FULL'}
    normalized = action_text.replace('[', '').replace(']', '').replace("'", '').replace('"', '')
    tokens = [part.strip().upper() for part in normalized.replace(';', ',').split(',') if part.strip()]
    if not tokens:
        tokens = [action_text.upper()]
    return set(tokens)

def ensure_currency_available(currency_code, db_name=None, config_file=None):
    Currency = Model.get('currency.currency')
    normalized = normalize_currency_code(currency_code)
    currencies = Currency.find([('code', '=', normalized)])
    if currencies:
        return currencies[0]
    if db_name and config_file:
        base_mod = os.environ.get('TRYTON_BASE_MODULE', '/usr/local/lib/python3.11/dist-packages/trytond/modules')
        import_script = f"{base_mod}/currency/scripts/import_currencies.py"
        if os.path.exists(import_script):
            try:
                result = subprocess.run(
                    [sys.executable, import_script, "-d", db_name, "-c", config_file],
                    capture_output=True, text=True, check=True
                )
                if result.stderr:
                    logging.debug(result.stderr.strip())
                p_config.get_config().pool.init()
                Currency = Model.get('currency.currency')
                currencies = Currency.find([('code', '=', normalized)])
                if currencies:
                    return currencies[0]
            except Exception as e:
                logging.debug(msg['geo_techn'].format(str(e)))
    raise ValueError(msg['currency_not_found'].format(normalized))

def get_company_language(lang_code):
    Lang = Model.get('ir.lang')
    normalized = (lang_code or APP_LANG or 'en').lower()
    short_code = normalized[:2]
    found = Lang.find([('code', '=', short_code)], limit=1)
    if found:
        return found[0]
    found = Lang.find([('code', '=', 'en')], limit=1)
    return found[0] if found else None

def connect_and_init(db_name, config_file):
    trytond_config.update_etc(config_file)
    for attempt in range(1, 11):
        try:
            p_config.set_trytond(db_name, config_file=config_file)
            pool = Pool(db_name)
            pool.init()
            logging.info(msg['start'])
            return True
        except Exception as e:
            # Opción segura: Pasamos el intento y el error convertido a string
            # Asegúrate de que tu mensaje 'wait' tenga al menos dos {} o {0} {1}
            logging.warning(msg['wait'].format(attempt, str(e)))
            time.sleep(5)
            attempt += 1
    return False

def sync_and_clean_modules():
    logging.info(msg['scan'])
    Module = Model.get('ir.module')
    ConfigWizardItem = Model.get('ir.module.config_wizard.item')
    try: Wizard('ir.module.activate_upgrade').execute('upgrade')
    except: pass
    items = ConfigWizardItem.find([('state', '!=', 'done')])
    for item in items:
        item.state = 'done'
        item.save()
    return [m.name for m in Module.find([('state', '=', 'activated')])]

def setup_or_get_company(company_name, currency_code, db_name, config_file, target_lang):
    # 1. Aseguramos que Proteus tiene el contexto de preferencias cargado
    User = Model.get('res.user')
    p_config.get_config()._context = User.get_preferences(True, {})

    Party = Model.get('party.party')
    Company = Model.get('company.company')
    Currency = Model.get('currency.currency')

    # Intentar buscar si ya existe
    existing_companies = Company.find([('party.name', '=', company_name)])
    if existing_companies:
        logging.info(f"Empresa {company_name} ya existe.")
        return existing_companies[0]

    logging.info(f"Creando empresa: {company_name}")
    
    # 2. Asegurar moneda
    usd_list = Currency.find([('code', '=', currency_code)])
    if not usd_list:
        currency = Currency(name=currency_code, code=currency_code, symbol=currency_code)
        currency.save()
    else:
        currency = usd_list[0]

    # 3. EL WIZARD (Copiando exactamente el flujo de la demo)
    company_config = Wizard('company.company.config')
    company_config.execute('company')
    
    # Crear el Party ANTES de asignarlo
    party = Party(name=company_name)
    party.save() # Si esto falla aquí, usa el bloque 'with cfg.set_context(company=None):' que pusimos antes
    
    company_form = company_config.form
    company_form.party = party
    company_form.currency = currency
    company_config.execute('add')

    # 4. RECARGAR CONTEXTO (Vital para que el resto del script sepa que ya hay empresa)
    p_config.get_config()._context = User.get_preferences(True, {})
    
    new_company, = Company.find([('party.name', '=', company_name)])
    return new_company


def activate_languages(dependencies):
    logging.info(msg['lang_phase'])
    Lang = Model.get('ir.lang')
    Module = Model.get('ir.module')
    for code, module_name in dependencies.items():
        if Module.find([('name', '=', module_name), ('state', '=', 'activated')]):
            lang_found = Lang.find([('code', '=', code)])
            if lang_found:
                lang = lang_found[0]
                if not lang.translatable:
                    logging.info(msg['lang_act'].format(code))
                    lang.translatable = True
                    lang.save()
                active_mods = Module.find([('state', '=', 'activated')])
                for mod in active_mods: mod.click('upgrade')
                Wizard('ir.module.activate_upgrade').execute('upgrade')
    try:
        admin = Model.get('res.user')(1)
        es_lang = Lang.find([('code', '=', 'es')])
        if es_lang:
            admin.language = es_lang[0]
            admin.save()
            logging.info(msg['admin_es'])
    except Exception as e:
        logging.debug(msg['admin_lang_skip'].format(str(e)))

def get_sequence_type_id(module, name, fallback_id):
    ModelData = Model.get('ir.model.data')
    try:
        data = ModelData.find([('module', '=', module), ('name', '=', name)])
        if data: return data[0].db_id
    except: pass
    return fallback_id

def create_fiscalyear(year, company):
    FiscalYear = Model.get('account.fiscalyear')
    Period = Model.get('account.period')
    SequenceStrict = Model.get('ir.sequence.strict')
    SequenceType = Model.get('ir.sequence.type') 
    def _create_periods(fy):
        Wizard('account.fiscalyear.create_periods', [fy]).execute('create_periods')
    existing = FiscalYear.find([('name', '=', str(year)), ('company', '=', company.id)])
    if existing:
        fy = existing[0]
        has_periods = bool(Period.find([('fiscalyear', '=', fy.id)], limit=1))
        if not has_periods:
            _create_periods(fy)
            logging.info(msg['fisc_year'].format(year))
        return fy
    fy = FiscalYear(name=str(year), company=company)
    fy.start_date = date(year, 1, 1)
    fy.end_date = date(year, 12, 31)
    st_move = SequenceType(get_sequence_type_id('account', 'sequence_type_account_move', 11))
    move_name = msg['seq_move'].format(year)
    move_seq = SequenceStrict(name=move_name, sequence_type=st_move, company=company, padding=6)
    move_seq.save()
    fy.move_sequence = move_seq
    st_inv = SequenceType(get_sequence_type_id('account_invoice', 'sequence_type_account_invoice', 13))
    def _make_seq(n):
        s = SequenceStrict(name=f"{n} {year}", sequence_type=st_inv, company=company, padding=6)
        s.save()
        return s
    if not fy.invoice_sequences:
        raise RuntimeError(msg['invoice_seq_missing'])
    inv_seq_link = fy.invoice_sequences[0]
    inv_seq_link.company = company
    inv_seq_link.out_invoice_sequence = _make_seq("INV")
    inv_seq_link.out_credit_note_sequence = _make_seq("CRN")
    inv_seq_link.in_invoice_sequence = _make_seq("SUP_INV")
    inv_seq_link.in_credit_note_sequence = _make_seq("SUP_CRN")
    fy.save()
    _create_periods(fy)
    logging.info(msg['fisc_year'].format(year))
    return fy

def setup_accounts(company, dependencies):
    AccountTemplate = Model.get('account.account.template')
    Account = Model.get('account.account')
    Module = Model.get('ir.module')
    Party = Model.get('party.party')
    mapping = {
        'es': {'name': '%Pymes%', 'receivable': '4300', 'payable': '4000'},
        'fr': {'name': '%Plan comptable général%', 'receivable': '411', 'payable': '401'},
        'de': {'name': '%SKR03%', 'receivable': '10000', 'payable': '70000'}
    }
    for code, mod_name in dependencies.items():
        if not Module.find([('name', '=', mod_name), ('state', '=', 'activated')]): continue
        conf = mapping[code]
        try:
            templates = AccountTemplate.find([('parent', '=', None), ('name', 'ilike', conf['name'])])
            if not templates: continue
            create_chart = Wizard('account.create_chart')
            create_chart.execute('account')
            create_chart.form.account_template = templates[0]
            create_chart.form.company = company
            try: create_chart.execute('create_account')
            except: pass
            rec = Account.find([('code', '=', conf['receivable']), ('company', '=', company.id)])
            pay = Account.find([('code', '=', conf['payable']), ('company', '=', company.id)])
            if rec and pay:
                for p in Party.find([]):
                    try:
                        p.account_receivable = rec[0]
                        p.account_payable = pay[0]
                        p.save()
                    except: pass
                logging.info(msg['acc_link'].format(code))
        except Exception as e:
            logging.error(msg['acc_error'].format(code,str(e)))

def _safe_set(record, field_name, value):
    try:
        setattr(record, field_name, value)
        return True
    except Exception:
        return False

def _safe_set_first(record, field_name, values):
    for value in values:
        if _safe_set(record, field_name, value):
            return value
    return None

def _safe_set_any_field(record, field_names, values):
    for field_name in field_names:
        applied = _safe_set_first(record, field_name, values)
        if applied is not None:
            return field_name, applied
    return None, None

def is_module_activated(module_name):
    Module = Model.get('ir.module')
    return bool(Module.find([('name', '=', module_name), ('state', '=', 'activated')], limit=1))

def ensure_general_journal(company, company_conf):
    if not is_module_activated('account'):
        return
    Journal = Model.get('account.journal')
    journal_code = company_conf.get('journal_code') or 'GEN'
    journal_name = company_conf.get('journal_name') or 'Diario General'
    existing = Journal.find([('code', '=', journal_code)], limit=1)
    if existing:
        return
    journal = Journal()
    journal.name = journal_name
    journal.code = journal_code
    _safe_set(journal, 'type', 'general')
    _safe_set(journal, 'company', company)
    journal.save()
    logging.info(msg['journal_created'].format(journal_code))

def _pick_account_for_taxes(company):
    Account = Model.get('account.account')
    account = Account.find([('company', '=', company.id), ('code', '=', '47700000')], limit=1)
    if account:
        return account[0]
    account = Account.find([('company', '=', company.id), ('code', '=', '477')], limit=1)
    if account:
        return account[0]
    account = Account.find([('company', '=', company.id), ('code', 'like', '477%')], limit=1)
    if account:
        return account[0]
    account = Account.find([('company', '=', company.id), ('code', 'like', '470%')], limit=1)
    if account:
        return account[0]
    account = Account.find([('company', '=', company.id), ('code', 'like', '7%')], limit=1)
    if account:
        return account[0]
    account = Account.find([('company', '=', company.id), ('code', 'like', '6%')], limit=1)
    return account[0] if account else None

def ensure_spanish_vat_taxes(company, company_conf):
    if not is_module_activated('account_es'):
        logging.info(msg['vat_skipped_no_module'])
        return
    Tax = Model.get('account.tax')
    base_account = _pick_account_for_taxes(company)
    if not base_account:
        logging.warning(msg['vat_skipped_no_account'])
        return

    vat_rates = company_conf.get('vat_rates') or ['21', '10', '4']
    created = []
    already_present = []
    for amount in vat_rates:
        tax_name = f"IVA {amount}%"
        existing_tax = Tax.find([
            ('company', '=', company.id),
            ('name', '=', tax_name),
        ], limit=1)
        if existing_tax:
            already_present.append(amount)
            continue
        tax = Tax()
        tax.name = tax_name
        _safe_set(tax, 'description', tax_name)
        tax_type = _safe_set_first(tax, 'type', ['percentage', 'percent'])
        if not tax_type:
            logging.warning(msg['vat_skipped_bad_type'].format(tax_name))
            continue
        # En Tryton suele ser fracción (0.21), no 21. Probamos varios campos según versión.
        rate_fraction = Decimal(amount) / Decimal('100')
        rate_field, _ = _safe_set_any_field(
            tax,
            ['rate', 'percentage', 'percent'],
            [rate_fraction, float(rate_fraction), str(rate_fraction), amount]
        )
        if not rate_field:
            logging.warning(msg['vat_skipped_bad_rate'].format(tax_name))
            continue
        _safe_set(tax, 'company', company)
        _safe_set(tax, 'account', base_account)
        _safe_set(tax, 'refund_account', base_account)
        _safe_set(tax, 'invoice_account', base_account)
        _safe_set(tax, 'credit_note_account', base_account)
        tax.save()
        created.append(amount)
    if created:
        logging.info(msg['vat_created'].format("/".join(created)))
    if already_present:
        logging.info(msg['vat_already_present'].format("/".join(already_present)))

# -------------------------------------------------
# EJECUCIÓN PRINCIPAL DINÁMICA
# -------------------------------------------------
def run_setup():
    # Parámetros desde el .bat: DB_NAME CONF_PATH LANG ACTION
    DB_NAME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('DB_NAME', 'tryton')
    CONF_FILE = sys.argv[2] if len(sys.argv) > 2 else '/etc/trytond.conf'
    TARGET_LANG = (sys.argv[3] if len(sys.argv) > 3 else APP_LANG).lower()
    ACTION = (sys.argv[4] if len(sys.argv) > 4 else 'FULL')
    actions = parse_actions(ACTION)

    if not connect_and_init(DB_NAME, CONF_FILE): sys.exit(10)
    
    # Definimos el mapeo de módulos para reutilizar en LANG y ACC
    chart_mapping = {'es': 'account_es', 'fr': 'account_fr', 'de': 'account_de_skr03'}
    
    # 1. PRIMERO: Sincronizar módulos para que 'country' esté disponible en el Pool
    # Esto asegura que Model.get('country.zip') no falle
    try:
        sync_and_clean_modules()
    except Exception as e:
        logging.warning(msg['error'].format(str(e)))
        logging.shutdown()
        sys.exit(15)

    # ACCIÓN: GEODATA (Solo países y postales)
    if 'FULL' in actions or 'GEO' in actions:
        try:
            run_geodata_import(DB_NAME, CONF_FILE, TARGET_LANG)
        except RuntimeError as e:
            logging.error(msg['geo_error'].format(str(e)))
            logging.shutdown()
            sys.exit(20) # <--- Código específico para GEO
        except Exception as e:
            # Captura cualquier otro error inesperado (fallo de red, disco lleno, etc.)
            logging.error(msg['geo_error'].format(str(e)))
            logging.shutdown()
            sys.exit(21)
        
    # ACCIÓN: LANG (Traducciones e Idiomas)
    if 'FULL' in actions or 'LANG' in actions:
        try:
            activate_languages(chart_mapping)
        except Exception as e:
             logging.error(msg['lang_error'].format(str(e)))
             logging.shutdown()
             sys.exit(30) # <--- Código específico para LANG

    # ACCIÓN: ACC (Solo contabilidad y empresa) o FULL
    if 'FULL' in actions or 'ACC' in actions:
        try:
            conf_data = get_company_config(CONF_FILE)
            sync_and_clean_modules()
            company = setup_or_get_company(conf_data['name'], conf_data['currency'], DB_NAME, CONF_FILE, TARGET_LANG)
            setup_accounts(company, chart_mapping)
            ensure_general_journal(company, conf_data)
            for year in range(2026, 2031):
                create_fiscalyear(year, company)
        except Exception as e:
            logging.exception(msg['error'].format(str(e)))
            logging.shutdown()
            sys.exit(40) # <--- Código específico para ACC

    # ACCIÓN: TAX (IVA España) o FULL
    if 'FULL' in actions or 'TAX' in actions:
        try:
            conf_data = get_company_config(CONF_FILE)
            sync_and_clean_modules()
            company = setup_or_get_company(conf_data['name'], conf_data['currency'], DB_NAME, CONF_FILE, TARGET_LANG)
            ensure_spanish_vat_taxes(company, conf_data)
        except Exception as e:
            logging.exception(msg['error'].format(str(e)))
            logging.shutdown()
            sys.exit(50) # <--- Código específico para TAX

    valid_actions = {'FULL', 'GEO', 'LANG', 'ACC', 'TAX'}
    invalid_actions = sorted([item for item in actions if item not in valid_actions])
    if invalid_actions:
        logging.error(msg['unsupported_action'].format(", ".join(invalid_actions)))
        logging.shutdown()
        sys.exit(11)
    logging.info(msg['success'])
    logging.info(msg['end_phase'].format(", ".join(sorted(actions))))
    logging.shutdown()
    sys.exit(0)
if __name__ == "__main__":
    run_setup()
