import os
import logging
from datetime import date
import time
import sys
import configparser
import subprocess
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
        'unsupported_action': "Acción no soportada: {}"
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
        'unsupported_action': "Unsupported action: {}"
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
        'unsupported_action': "Action non prise en charge : {}"
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
        'unsupported_action': "Nicht unterstützte Aktion: {}"
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
    data = {'name': env_name or '', 'currency': env_currency or ''}
    if not data['name'] or not data['currency']:
        try:
            if os.path.exists(conf_path):
                config.read(conf_path)
                if 'company' in config:
                    if not data['name']: data['name'] = config['company'].get('name', 'Telepieza')
                    if not data['currency']: data['currency'] = config['company'].get('currency', 'EUR')
                    logging.info(msg['conf_file'].format(conf_path))
            else:
                if not data['name']: data['name'] = 'Telepieza'
                if not data['currency']: data['currency'] = 'EUR'
                logging.warning(msg['conf_warn'])
        except Exception as e:
            logging.error(msg['read_error'].format(e))
    logging.info(msg['conf_active'].format(data['name'], data['currency']))       
    return data

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

def setup_or_get_company(company_name, currency_code):
    logging.info(msg['comp_phase'].format(company_name))
    Company = Model.get('company.company')
    Party = Model.get('party.party')
    Currency = Model.get('currency.currency')
    User = Model.get('res.user')
    existing = Company.find([('party.name', '=', company_name)])
    if existing:
        company = existing[0]
        logging.info(msg['comp_found'].format(company.party.name))
    else:
        logging.info(msg['comp_create'].format(company_name))
        currencies = Currency.find([('code', '=', currency_code)])
        if not currencies:
            raise ValueError(msg['currency_not_found'].format(currency_code))
        currency = currencies[0]
        company_config = Wizard('company.company.config')
        company_config.execute('company')
        new_party = Party(name=company_name)
        new_party.save()
        company_config.form.party = new_party
        company_config.form.currency = currency
        company_config.execute('add')
        companies = Company.find([('party.name', '=', company_name)])
        if not companies:
            raise RuntimeError(msg['company_not_created'].format(company_name))
        company = companies[0]
    
    cfg = proteus.config.get_config()
    old_user = cfg.user
    cfg.user = 0 
    new_context = User.get_preferences(True, {'company': company.id})
    cfg.context.update(new_context)
    cfg.user = old_user
    logging.info(msg['ctx_upd'].format(company_name, currency_code))
    return company

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
    SequenceStrict = Model.get('ir.sequence.strict')
    SequenceType = Model.get('ir.sequence.type') 
    existing = FiscalYear.find([('name', '=', str(year)), ('company', '=', company.id)])
    if existing: return existing[0]
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
    wiz = Wizard('account.fiscalyear.create_periods')
    wiz.execute('start')
    wiz.form.fiscalyear = fy
    wiz.execute('create_periods')
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

# -------------------------------------------------
# EJECUCIÓN PRINCIPAL DINÁMICA
# -------------------------------------------------
def run_setup():
    # Parámetros desde el .bat: DB_NAME CONF_PATH LANG ACTION
    DB_NAME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('DB_NAME', 'tryton')
    CONF_FILE = sys.argv[2] if len(sys.argv) > 2 else '/etc/trytond.conf'
    TARGET_LANG = (sys.argv[3] if len(sys.argv) > 3 else APP_LANG).lower()
    ACTION = (sys.argv[4] if len(sys.argv) > 4 else 'FULL').upper()

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
    if ACTION in ['FULL', 'GEO']:
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
    if ACTION in ['FULL', 'LANG']:
        try:
            activate_languages(chart_mapping)
        except Exception as e:
             logging.error(msg['lang_error'].format(str(e)))
             logging.shutdown()
             sys.exit(30) # <--- Código específico para LANG

    # ACCIÓN: ACC (Solo contabilidad y empresa) o FULL
    if ACTION in ['FULL', 'ACC']:
        try:
            conf_data = get_company_config(CONF_FILE)
            sync_and_clean_modules()
            company = setup_or_get_company(conf_data['name'], conf_data['currency'])
            setup_accounts(company, chart_mapping)
            for year in [2026, 2027, 2028]:
                create_fiscalyear(year, company)
            logging.info(msg['success'])
        except Exception as e:
            logging.exception(msg['error'].format(str(e)))
            logging.shutdown()
            sys.exit(40) # <--- Código específico para ACC
            
        logging.info(msg['end_phase'].format(ACTION))
        logging.shutdown()  
        sys.exit(0)
    if ACTION not in ['FULL', 'GEO', 'LANG', 'ACC']:
        logging.error(msg['unsupported_action'].format(ACTION))
        logging.shutdown()
        sys.exit(11)
    logging.info(msg['end_phase'].format(ACTION))
    logging.shutdown()
    sys.exit(0)
if __name__ == "__main__":
    run_setup()
