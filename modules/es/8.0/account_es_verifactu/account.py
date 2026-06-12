# The COPYRIGHT file at the top level of
# this repository contains the full copyright notices and license terms.
import datetime as dt
import hashlib
import io
import os
from collections import defaultdict
from configparser import ConfigParser
from decimal import Decimal
from itertools import chain, groupby
from urllib.parse import urlencode

import qrcode
import qrcode.constants
from requests import Session
from sql import Select, Table
from sql.aggregate import Count
from sql.functions import CurrentTimestamp
from zeep import Client
from zeep.exceptions import Error as ZeepError
from zeep.settings import Settings
from zeep.transports import Transport

from trytond.cache import Cache
from trytond.config import config
from trytond.i18n import gettext
from trytond.model import (
    Index, ModelSingleton, ModelSQL, ModelView, Unique, Workflow, dualmethod,
    fields)
from trytond.model.exceptions import AccessError
from trytond.modules.account.exceptions import PeriodNotFoundError
from trytond.modules.company.model import CompanyValueMixin
from trytond.pool import Pool, PoolMeta
from trytond.pyson import Bool, Eval
from trytond.report import Report
from trytond.tools import grouped_slice
from trytond.transaction import Transaction

from .exceptions import ESVerifactuPostedInvoicesError

_URL = ('static_files/common/internet/dep/aplicaciones/es/aeat/tikeV1.0/cont/'
    'ws/SistemaFacturacion.wsdl')
WSDL_URL = {
    'production': f'https://www2.agenciatributaria.gob.es/{_URL}',
    'staging': f'https://prewww2.aeat.es/{_URL}',
    }
del _URL

SEND_SIZE = config.getint('es_verifactu', 'send_size', default=1000)
# SistemaInformatico data
SI_NAME = config.get(
    'es_verifactu', 'si_name', default='Tryton Verifactu Module')
SI_INSTALL_NUM = config.get('es_verifactu', 'si_install_num', default='')
SI_ID = config.get('es_verifactu', 'si_id', default='01')
with open(os.path.join(os.path.dirname(__file__), 'tryton.cfg')) as cfg_file:
    cfg_config = ConfigParser()
    cfg_config.read_file(cfg_file)
    SI_VERSION = dict(cfg_config.items('tryton'))['version']
TAX_KEYS = ['S1', 'S2', 'N1', 'N2', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6']
OPERATION_KEYS = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
    '11', '14', '15', '17', '18', '19', '20']


def format_amount(value):
    return value.quantize(Decimal('0.01'))


class Configuration(metaclass=PoolMeta):
    __name__ = 'account.configuration'

    es_verifactu_environment = fields.MultiValue(
        fields.Selection([
                (None, ""),
                ('staging', "Staging"),
                ('production', "Production"),
                ], "Verifactu Environment"))

    @classmethod
    def multivalue_model(cls, field):
        pool = Pool()
        if field in {'es_verifactu_environment'}:
            return pool.get('account.credential.verifactu')
        return super().multivalue_model(field)


class CredentialVerifactu(ModelSQL, CompanyValueMixin):
    "Account Credential Verifactu"
    __name__ = 'account.credential.verifactu'

    es_verifactu_environment = fields.Selection([
            (None, ""),
            ('staging', "Staging"),
            ('production', "Production"),
            ], "Verifactu Environment")

    @classmethod
    def get_client(cls, endpoint, certificate, private_key, **pattern):
        pool = Pool()
        Configuration = pool.get('account.configuration')

        config = Configuration(1)
        service = endpoint
        environment = config.get_multivalue(
            'es_verifactu_environment', **pattern)
        url = WSDL_URL.get(environment or 'production')
        if environment == 'staging':
            service += 'Pruebas'

        session = Session()
        session.cert = (certificate, private_key)
        # XXX: Can we remove forbid entitites with newer xsdl?
        settings = Settings(forbid_entities=False)
        transport = Transport(session=session)
        client = Client(url, transport=transport, settings=settings)
        return client.bind('sfVerifactu', service)


class Declaration(ModelSingleton, ModelSQL, ModelView):
    "Verifactu Declaration"
    __name__ = 'account.verifactu.declaration'

    display_name = fields.Function(
        fields.Char('Display Name'), 'get_declaration_info')
    nif = fields.Function(
        fields.Char('NIF'), 'get_declaration_info')
    direction = fields.Function(
        fields.Char('Direction'), 'get_declaration_info')
    date = fields.Function(
        fields.Char('Date'), 'get_declaration_info')
    place = fields.Function(
        fields.Char('Place'), 'get_declaration_info')
    software_composition = fields.Function(
        fields.Char('Software Composition'), 'get_declaration_info')
    software_description = fields.Function(
        fields.Char('Software Description'), 'get_declaration_info')
    software_version = fields.Function(
        fields.Char('Software Version'), 'get_declaration_info')
    phone_company = fields.Function(
        fields.Char('Phone Number'), 'get_declaration_info')
    fax_company = fields.Function(
        fields.Char('Fax'), 'get_declaration_info')
    email = fields.Function(
        fields.Char('Email'), 'get_declaration_info')
    web = fields.Function(
        fields.Char('Web'), 'get_declaration_info')
    web_product = fields.Function(
        fields.Char('Product Link'), 'get_declaration_info')

    @classmethod
    def __register__(cls, module_name):
        super().__register__(module_name)
        table = Table(cls._table)
        cursor = Transaction().connection.cursor()
        select = table.select(table.id)
        cursor.execute(*select)
        if not cursor.fetchone():
            insert = table.insert()
            cursor.execute(*insert)

    def get_declaration_info(self, name):
        if name == 'software_vesrion':
            return SI_VERSION
        config_name = {
            'display_name': 'manufacturer_name',
            'nif': 'manufacturer_nif',
            }.get(name, name)
        return config.get('es_verifactu', config_name, default='')


class DeclarationReport(Report):
    __name__ = 'account.verifactu.declaration'

    @classmethod
    def get_context(cls, records, header, data):
        context = super().get_context(records, header, data)
        Declaration = Pool().get('account.verifactu.declaration')
        declaration = Declaration.get_singleton()

        context['declaration'] = declaration
        return context


class _TaxMixin(metaclass=PoolMeta):
    es_verifactu_tax_key = fields.Selection(
        'get_es_verifactu_tax_keys', "Verifactu Tax Key", sort=False)
    es_verifactu_operation_key = fields.Selection(
        'get_es_verifactu_operation_keys',
        "Verifactu Operation Key", sort=False)
    es_exclude_from_verifactu = fields.Boolean("Exclude from Verifactu")

    @classmethod
    def get_es_verifactu_tax_keys(cls):
        return [
            (None, ''),
            *[(key, f'{key}: ' + gettext(
                    f'account_es_verifactu.msg_tax_key_{key}'))
                for key in TAX_KEYS]
            ]

    @classmethod
    def get_es_verifactu_operation_keys(cls):
        return [
            (None, ''),
            *[(key, key) for key in OPERATION_KEYS]
            ]


class TaxTemplate(_TaxMixin):
    __name__ = 'account.tax.template'

    def _get_tax_value(self, tax=None):
        values = super()._get_tax_value(tax)
        for name in [
                'es_verifactu_tax_key', 'es_verifactu_operation_key',
                'es_exclude_from_verifactu']:
            if not tax or getattr(tax, name) != getattr(self, name):
                values[name] = getattr(self, name)
        return values


class Tax(_TaxMixin):
    __name__ = 'account.tax'

    @classmethod
    def __setup__(cls):
        super().__setup__()
        for field in (
                'es_verifactu_tax_key',
                'es_verifactu_operation_key',
                'es_exclude_from_verifactu',
                ):
            getattr(cls, field).states['readonly'] = (
                Bool(Eval('template', -1)) & ~Eval('template_override', False))


class FiscalYear(metaclass=PoolMeta):
    __name__ = 'account.fiscalyear'

    es_verifactu_send_invoices = fields.Function(
        fields.Boolean("Send invoices to Verifactu"),
        'get_es_verifactu_send_invoices',
        setter='set_es_verifactu_send_invoices')

    def get_es_verifactu_send_invoices(self, name):
        result = None
        for period in self.periods:
            if period.type != 'standard':
                continue
            value = period.es_verifactu_send_invoices
            if value is not None:
                if result is None:
                    result = value
                elif result != value:
                    result = None
                    break
        return result

    @classmethod
    def set_es_verifactu_send_invoices(cls, fiscalyears, name, value):
        pool = Pool()
        Period = pool.get('account.period')

        periods = []
        for fiscalyear in fiscalyears:
            periods.extend(
                p for p in fiscalyear.periods if p.type == 'standard')
        Period.write(periods, {name: value})


class RenewFiscalYear(metaclass=PoolMeta):
    __name__ = 'account.fiscalyear.renew'

    def create_fiscalyear(self):
        fiscalyear = super().create_fiscalyear()
        previous_fiscalyear = self.start.previous_fiscalyear
        periods = [
            p for p in previous_fiscalyear.periods if p.type == 'standard']
        if periods:
            last_period = periods[-1]
            fiscalyear.es_verifactu_send_invoices = (
                last_period.es_verifactu_send_invoices)
        return fiscalyear


class Period(metaclass=PoolMeta):
    __name__ = 'account.period'
    es_verifactu_send_invoices = fields.Boolean(
        "Send invoices to Verifactu",
        states={
            'invisible': Eval('type') != 'standard',
            },
        help="Check to create Verifactu records for invoices in the period.")
    _verifactu_companies_cache = Cache(
        'account.period.verifactu.companies')

    @classmethod
    def create(cls, vlist):
        cls._verifactu_companies_cache.clear()
        return super().create(vlist)

    @classmethod
    def write(cls, *args):
        actions = iter(args)
        to_check = []
        for periods, values in zip(actions, actions):
            if 'es_verifactu_send_invoices' in values:
                for period in periods:
                    if (period.es_verifactu_send_invoices
                            != values['es_verifactu_send_invoices']):
                        to_check.append(period)
        cls.check_es_verifactu_posted_invoices(to_check)
        super().write(*args)
        cls._verifactu_companies_cache.clear()

    @classmethod
    def delete(cls, records):
        cls._verifactu_companies_cache.clear()
        return super().delete(records)

    @classmethod
    def check_es_verifactu_posted_invoices(cls, periods):
        pool = Pool()
        Invoice = pool.get('account.invoice')
        for sub_ids in grouped_slice(list(map(int, periods))):
            invoices = Invoice.search([
                    ('move.period', 'in', sub_ids),
                    ], limit=1)
            if invoices:
                invoice, = invoices
                raise ESVerifactuPostedInvoicesError(
                    gettext(
                        'account_es_verifactu.'
                        'msg_es_verifactu_posted_invoices',
                        period=invoice.move.period.rec_name))

    @classmethod
    def get_verifactu_companies(cls):
        pool = Pool()
        FiscalYear = pool.get('account.fiscalyear')
        cursor = Transaction().connection.cursor()
        fiscalyear = FiscalYear.__table__()

        count = cls._verifactu_companies_cache.get('items')
        if count is None:
            cursor.execute(
                *fiscalyear.select(Count(fiscalyear.company, distinct=True)))
            count, = cursor.fetchone()
            cls._verifactu_companies_cache.set('count', count)

        return count


class Invoice(metaclass=PoolMeta):
    __name__ = 'account.invoice'

    es_verifactu_qr_url = fields.Function(
        fields.Char("Verifactu QR URL"), 'get_verifactu_qr_url')
    es_verifactu_qr_code = fields.Function(
        fields.Binary("Verifactu QR Code"), 'get_verifactu_qr_code')

    @property
    def es_verifactu_party_tax_identifier(self):
        return self.party_tax_identifier or self.party.tax_identifier

    @property
    def es_verifactu_invoice_type(self):
        tax_identifier = bool(self.es_verifactu_party_tax_identifier)
        if 'credit_note' in self._sequence_field:
            if tax_identifier:
                return 'R1'
            else:
                return 'R5'
        else:
            if tax_identifier:
                return 'F1'
            else:
                return 'F2'

    @classmethod
    @ModelView.button
    @Workflow.transition('posted')
    def _post(cls, invoices):
        pool = Pool()
        InvoiceVerifactu = pool.get('account.invoice.verifactu')
        Date = pool.get('ir.date')

        today = Date.today()
        posted_invoices = [
            i for i in invoices if i.state in {'draft', 'validated'}]

        super()._post(invoices)

        if posted_invoices:

            def invoice_date(invoice):
                return invoice.invoice_date or today

            InvoiceVerifactu.save([
                    InvoiceVerifactu(invoice=i)
                    # Use same sorting used as invoice numbering
                    for i in sorted(posted_invoices, key=invoice_date)
                    if i.es_send_to_verifactu])

    @property
    def es_send_to_verifactu(self):
        pool = Pool()
        Date = pool.get('ir.date')
        Period = pool.get('account.period')

        if self.move:
            period = self.move.period
        else:
            with Transaction().set_context(company=self.company.id):
                today = Date.today()
            accounting_date = (
                self.accounting_date or self.invoice_date or today)
            try:
                period = Period.find(
                    self.company, date=accounting_date, test_state=False)
            except PeriodNotFoundError:
                return False
        return (self.type == 'out' and period.es_verifactu_send_invoices)

    @classmethod
    def view_attributes(cls):
        return super().view_attributes() + [
            ('/form/notebook/page[@id="verifactu_qr"]', 'states', {
                'invisible': ~Bool(Eval('es_verifactu_qr_url')),
            })
        ]

    def get_verifactu_qr_url(self, name):
        if (not self.es_send_to_verifactu
                or not self.tax_identifier
                or not self.invoice_date
                or not self.number):
            return None
        nif = self.tax_identifier.es_code()
        date = self.invoice_date.strftime('%d-%m-%Y')
        importe = str(format_amount(self.total_amount))
        return (
            "https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR"
            f"?nif={nif}&numserie={self.number}&fecha={date}&importe={importe}"
        )

    def get_qr_params(self):
        return {
            'version': 1,
            'error_correction': qrcode.constants.ERROR_CORRECT_M,
            'box_size': 10,
            'border': 4,
        }

    def get_verifactu_qr_code(self, name):
        if not self.es_verifactu_qr_url:
            return None
        qr_params = self.get_qr_params()
        qr = qrcode.QRCode(**qr_params)
        qr.add_data(self.es_verifactu_qr_url)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


class InvoiceVerifactu(ModelSQL, ModelView):
    "Invoice Verifactu"
    __name__ = 'account.invoice.verifactu'

    # TODO: Do we need to always relate to invoices are we need to
    # support also TPV tickets???
    invoice = fields.Many2One(
        'account.invoice', "Invoice", required=True, ondelete='RESTRICT',
        states={
            'readonly': Eval('state') != 'pending',
            },
        domain=[
            ('state', 'in', ['posted', 'paid', 'cancelled']),
            ])
    company = fields.Function(
        fields.Many2One('company.company', "Company"),
        'on_change_with_company', searcher='search_company')
    previous_record = fields.Many2One(
        'account.invoice.verifactu', "Previous Record", readonly=True,
        domain=[
            ('company', '=', Eval('company', -1)),
            ])
    fingerprint = fields.Char("FingerPrint", readonly=True)
    generated_at = fields.DateTime("Generated At", readonly=True)
    csv = fields.Char("CSV", readonly=True,
        help="A secure validation code that confirms the delivery of the "
        "related invoice.")
    error_code = fields.Char("Error Code", readonly=True,
        states={
            'invisible': ~Bool(Eval('error_code')),
            })
    error_description = fields.Text("Error Description", readonly=True,
        states={
            'invisible': ~Bool(Eval('error_description')),
            })
    state = fields.Selection([
            ('pending', "Pending"),
            ('sent', "Sent"),
            ('wrong', "Wrong"),
            ('rejected', "Rejected"),
            ], "State", readonly=True)

    @classmethod
    def __setup__(cls):
        super().__setup__()
        cls.__access__.add('invoice')

        t = cls.__table__()
        cls._sql_constraints = [
            ('invoice_unique', Unique(t, t.invoice),
                'account_es_verifactu.msg_es_verifactu_invoice_unique'),
            ]
        cls._sql_indexes.add(
            Index(
                t,
                (t.state, Index.Equality()),
                where=t.state.in_(['pending', 'wrong', 'rejected'])))
        cls._buttons.update({
            'resend': {
                'invisible': ~Eval('state').in_(['rejected', 'wrong']),
                'depends': ['state'],
                }
            })

    @classmethod
    def default_state(cls):
        return 'pending'

    def get_rec_name(self, name):
        return self.invoice.rec_name

    @classmethod
    def search_rec_name(cls, name, clause):
        return [('invoice.rec_name',) + tuple(clause[1:])]

    @fields.depends('invoice', '_parent_invoice.company')
    def on_change_with_company(self, name=None):
        return self.invoice.company if self.invoice else None

    @classmethod
    def search_company(cls, name, clause):
        return [('invoice.company',) + tuple(clause[1:])]

    @dualmethod
    def _set_previous_record(cls, records):
        # Sort by id to ensure same order as search
        records = sorted([i for i in records], key=lambda i: i.id)
        company2previous = {}
        for company, grouped_records in groupby(
                records, key=lambda i: i.company):
            for record in grouped_records:
                previous_record = company2previous.get(company)
                if previous_record is None:
                    previous = cls.search([
                            ('company', '=', company),
                            ('fingerprint', '!=', None),
                            ],
                        order=[
                            ('generated_at', 'DESC NULLS LAST'),
                            ('id', 'DESC NULLS LAST'),
                        ], limit=1)
                    if previous:
                        previous_record, = previous
                record.previous_record = previous_record
                company2previous[company] = record
        if records:
            cls.save(records)

    @dualmethod
    def set_fingerprint(cls, records):
        # Prevent modifing records that had been sent already
        records = [r for r in records if r.state != 'sent']
        cursor = Transaction().connection.cursor()
        # Use current timestamp to get transaction date
        cursor.execute(*Select([CurrentTimestamp()]))
        timestamp, = cursor.fetchone()
        timestamp = cls.generated_at.sql_format(timestamp)
        cls._set_previous_record(records)
        record2fingerprint = {}
        for record in records:
            record.generated_at = timestamp
            record.fingerprint = record._get_fingerprint(record2fingerprint)
            record2fingerprint[record] = record.fingerprint
        cls.save(records)

    @classmethod
    def create(cls, vlist):
        records = super().create(vlist)
        cls.set_fingerprint(records)
        return records

    @classmethod
    def delete(cls, records):
        for record in records:
            if record.csv:
                raise AccessError(
                    gettext('account_es_verifactu.'
                        'msg_es_verifactu_invoice_delete_sent',
                        invoice=record.invoice.rec_name))
        super().delete(records)

    @classmethod
    def _grouping_key(cls, record):
        return (
            ('company', record.invoice.company),
            ('tax_identifier', record.invoice.tax_identifier),
            )

    @classmethod
    def _credential_pattern(cls, key):
        return {
            'company': key['company'].id,
            }

    def get_verifactu_values(self):
        tax_values = defaultdict(list)
        tax_amount = Decimal('0.0')
        total_amount = Decimal('0.0')

        tax_lines = sorted(self.tax_lines, key=self.tax_grouping_key)
        for tax_key, tax_lines in groupby(
                tax_lines, key=self.tax_grouping_key):
            tax_lines = list(tax_lines)
            if tax_key:
                base_lines = set()
                for tax_line in tax_lines:
                    # Do not duplicate base for lines with multiple taxes
                    if (tax_line.type == 'base'
                            and not dict(tax_key).get('excluded')
                            and not tax_line.tax.es_reported_with
                            and tax_line.move_line.id not in base_lines):
                        total_amount += tax_line.amount
                        base_lines.add(tax_line.move_line.id)
            tax_lines = sorted(
                tax_lines, key=self.tax_detail_grouping_key)
            for detail_key, tax_lines in groupby(
                    tax_lines, key=self.tax_detail_grouping_key):
                key = dict(tax_key + detail_key)
                values = self._get_tax_values(key, list(tax_lines))
                if not values:
                    continue
                tax_lines_amount = (
                    Decimal(values.get('CuotaRepercutida') or '0.0')
                    + Decimal(values.get('CuotaRecargoEquivalencia') or '0.0'))
                tax_amount += tax_lines_amount
                total_amount += tax_lines_amount
                tax_values[tax_key].append(values)
        return tax_values, tax_amount, total_amount

    def _get_fingerprint(self, record2fingerprint):
        previous_fingerprint = ''
        if self.previous_record:
            previous_fingerprint = record2fingerprint.get(
                self.previous_record, self.previous_record.fingerprint)
        _, tax_amount, total_amount = self.get_verifactu_values()
        params = {
            'IDEmisorFactura': (self.tax_identifier
                and self.tax_identifier.es_code() or ''),
            'NumSerieFactura': self.invoice_number,
            'FechaExpedicionFactura': self.invoice_date.strftime('%d-%m-%Y'),
            'TipoFactura': self.invoice_type,
            'CuotaTotal': str(format_amount(tax_amount)),
            'ImporteTotal': str(format_amount(total_amount)),
            'Huella': previous_fingerprint,
            'FechaHoraHusoGenRegistro': self.generated_at_string
            }

        def empty_quote(value, *args, **kwargs):
            return value

        hash_params = urlencode(params, quote_via=empty_quote).encode('utf-8')
        return hashlib.sha256(hash_params).hexdigest().upper()

    @property
    def tax_lines(self):
        if self.invoice.move:
            return list(chain(*(l.tax_lines for l in self.invoice.move.lines)))
        raise AttributeError('Invoice must be accounted to verifactu lines.')

    @property
    def tax_identifier(self):
        return self.invoice.tax_identifier

    @property
    def invoice_number(self):
        return self.invoice.number

    @property
    def invoice_date(self):
        return self.invoice.invoice_date

    @property
    def invoice_type(self):
        return self.invoice.es_verifactu_invoice_type

    @property
    def generated_at_string(self):
        if not self.generated_at:
            return ''
        return self.generated_at.replace(
            microsecond=0, tzinfo=dt.timezone.utc).isoformat()

    @property
    def operation_description(self):
        return self.invoice.description or '.'

    @classmethod
    @ModelView.button
    def resend(cls, records):
        """
        Resend invoices with incorrect state
        """
        records = [r for r in records if r.state in ('rejected', 'wrong')]
        if records:
            records = sorted(records, key=lambda i: i.company)
            for company, grouped_records in groupby(
                    records, key=lambda i: i.company):
                grouped_records = list(grouped_records)
                cls.set_fingerprint(grouped_records)
                # We need to send first pending grouped_records if any
                timestamp = grouped_records[0].generated_at
                pending_records = cls.search([
                    ('company', '=', company.id),
                    ('generated_at', '<', timestamp),
                    ('state', '=', 'pending'),
                    ])
                cls.send(pending_records)
                cls.send(grouped_records)

    @classmethod
    def send(cls, records=None):
        """
        Send invoices

        The transaction is committed after each request (up to 10000 invoices).
        """
        transaction = Transaction()
        if not records:
            records = cls.search([
                    ('invoice.company', '=',
                        transaction.context.get('company')),
                    ('state', '=', 'pending'),
                    ])
        else:
            records = list(filter(lambda r: r.state != 'sent', records))

        cls.lock(records)
        records = sorted(records, key=cls._grouping_key)
        for key, grouped_records in groupby(records, key=cls._grouping_key):
            key = dict(key)
            for sub_records in grouped_slice(list(grouped_records), SEND_SIZE):
                # Use clear cache after a commit
                sub_records = cls.browse(sub_records)
                cls._send(key, sub_records)
                cls.save(sub_records)
                transaction.commit()

    @classmethod
    def _send(cls, key, sub_records):
        pool = Pool()
        Credential = pool.get('account.credential.verifactu')
        company = key['company']
        cls.lock(sub_records)
        payload = cls.get_request_payload(sub_records)
        # TODO: Set credentials for test and set data to staging webservice
        # or use a mock in scenario to test
        if pool.test:
            for record in sub_records:
                if record.id % 2 == 0:
                    record.state = 'sent'
                else:
                    record.state = 'wrong'
            return
        pattern = cls._credential_pattern(key)
        with company.es_verifactu_tmp_credentials() as (cert, pkey):
            client = Credential.get_client(
                'SistemaVerifactu', cert, pkey, **pattern)
            method = getattr(client, 'RegFactuSistemaFacturacion')
            try:
                resp = method(cls.get_headers(key), payload)
            except ZeepError as e:
                cls.set_error(sub_records, e.message, None)
            else:
                for record, response in zip(
                        sub_records, resp.RespuestaLinea):
                    record.set_state(response)
                    if response.CodigoErrorRegistro:
                        record.error_code = (
                            response.CodigoErrorRegistro)
                        record.error_description = (
                            response.DescripcionErrorRegistro)
                    else:
                        record.error_code = None
                        record.error_description = None
                    record.csv = resp.CSV

    def set_state(self, response):
        self.state = {
            'Correcto': 'sent',
            'Anulada': 'sent',
            'Incorrecto': 'rejected',
            'AceptadoConErrores': 'wrong',
            }.get(response.EstadoRegistro, 'pending')

    @classmethod
    def set_error(cls, records, message, code):
        for record in records:
            record.error_description = message
            record.error_code = code
            record.state = 'rejected'

    @classmethod
    def get_headers(cls, key):
        owner = {}
        owner['NombreRazon'] = key['company'].rec_name
        owner['NIF'] = key['company'].party.tax_identifier.es_code()
        return {
            'ObligadoEmision': owner,
            }

    @classmethod
    def get_request_payload(cls, records):
        invoices = []
        for record in records:
            data = record.get_payload_data()
            invoices.append(data)
        return invoices

    def get_payload_data(self):
        pool = Pool()
        Declaration = pool.get('account.verifactu.declaration')
        Period = pool.get('account.period')

        declaration = Declaration.get_singleton()
        invoice = self.invoice
        invoice_type = self.invoice_type
        company = invoice.company

        tax_values, tax_amount, total_amount = self.get_verifactu_values()

        # Fallback to company values if manufactures values are not set
        install_num = (
            SI_INSTALL_NUM or company.create_date.strftime("%Y%d%m%H%M%S"))
        manufacturer_name = declaration.display_name or company.party.name
        manufacturer_nif = (declaration.nif or (
            company.party.tax_identifier.es_code()
            if company.party.tax_identifier else ''))

        payload = {
            'IDVersion': '1.0',
            'IDFactura': {
                'IDEmisorFactura': invoice.tax_identifier.es_code(),
                'NumSerieFactura': self.invoice_number,
                'FechaExpedicionFactura': self.invoice_date.strftime(
                    '%d-%m-%Y'),
                },
            'RefExterna': invoice.reference or '',
            'NombreRazonEmisor': company.party.name[:120],
            'TipoFactura': invoice_type,
            'TipoRectificativa': 'I' if invoice_type.startswith('R') else None,
            'DescripcionOperacion': self.operation_description,
            'Desglose': {
                'DetalleDesglose': [
                    v for vl in tax_values.values() for v in vl]
                },
            'CuotaTotal': format_amount(tax_amount),
            'ImporteTotal': format_amount(total_amount),
            'Encadenamiento': self.get_payload_chaining(),
            'SistemaInformatico': {
                'NombreRazon': manufacturer_name[:120],
                'NIF': manufacturer_nif,
                'NombreSistemaInformatico': SI_NAME[:30],
                'IdSistemaInformatico': SI_ID[:2],
                'Version': SI_VERSION,
                'NumeroInstalacion': install_num[:100],
                'TipoUsoPosibleSoloVerifactu': 'S',
                'TipoUsoPosibleMultiOT': 'S',
                'IndicadorMultiplesOT': (
                    'S' if Period.get_verifactu_companies() > 1 else 'N'),
            },
            'FechaHoraHusoGenRegistro': self.generated_at_string,
            'TipoHuella': '01',
            'Huella': self.fingerprint,
            # Signatures are only required for NO-Verifactu
            # 'Signature': '',
            }
        party_identifier = invoice.es_verifactu_party_tax_identifier
        if party_identifier:
            identifier_values = party_identifier.es_verifactu_values()
            identifier_values['NombreRazon'] = (
                party_identifier.party.name[:120])
            payload['Destinatarios'] = [{
                    'IDDestinatario': identifier_values
                    }]
        if self.state != 'pending':
            payload['Subsanacion'] = 'S'
        if self.state == 'rejected':
            payload['RechazoPrevio'] = 'S' if self.csv else 'X'
        return {'RegistroAlta': payload}

    def get_payload_chaining(self):
        record = self.previous_record
        if record:
            payload = {
                'RegistroAnterior': {
                    'IDEmisorFactura': record.tax_identifier.es_code(),
                    'NumSerieFactura': record.invoice_number,
                    'FechaExpedicionFactura': record.invoice_date.strftime(
                        '%d-%m-%Y'),
                    'Huella': record.fingerprint,
                    }
                }
        else:
            payload = {
                'PrimerRegistro': 'S',
                }
        return payload

    @classmethod
    def _get_tax_values(cls, key, tax_lines):
        if not key or key.get('excluded'):
            return
        base_amount, tax_amount = Decimal('0.0'), Decimal('0.0')
        surcharge_taxes = []
        for tax_line in tax_lines:
            if tax_line.tax.es_reported_with:
                if tax_line.type == 'tax':
                    surcharge_taxes.append(tax_line)
                continue
            if tax_line.type == 'base':
                base_amount += tax_line.amount
            elif tax_line.type == 'tax':
                tax_amount += tax_line.amount

        values = {
            'Impuesto': '01',  # TODO
            'ClaveRegimen': key['operation_key'],
            'BaseImponibleOimporteNoSujeto': base_amount,
            # 'BaseImponibleACoste': TODO,
            'TipoImpositivo': str(key['rate']),
            'CuotaRepercutida': format_amount(tax_amount),
            }
        verifactu_key = key['verifactu_key']
        if verifactu_key.startswith('E'):
            values.update({
                    'TipoImpositivo': None,
                    'CuotaRepercutida': None,
                    'OperacionExenta': verifactu_key,
                    })
        else:
            values['CalificacionOperacion'] = verifactu_key
        if verifactu_key == '08':
            values.update({
                    'TipoImpositivo': None,
                    'CuotaRepercutida': None,
                    'BaseImponibleOimporteNoSujeto': None
                    })
        if surcharge_taxes:
            values['CuotaRecargoEquivalencia'] = format_amount(
                sum(t.amount for t in surcharge_taxes))
            values['TipoRecargoEquivalencia'] = str(
                (surcharge_taxes[0].tax.rate * 100).normalize())

        return values

    @classmethod
    def tax_grouping_key(cls, tax_line):
        if not tax_line.tax:
            return tuple()
        tax = tax_line.tax
        if tax.es_reported_with:
            tax = tax.es_reported_with
        if not tax.es_verifactu_operation_key:
            return tuple()
        return (
            ('verifactu_key', tax.es_verifactu_tax_key or ''),
            ('operation_key', tax.es_verifactu_operation_key or ''),
            ('excluded', bool(tax.es_exclude_from_verifactu)),
            )

    @classmethod
    def tax_detail_grouping_key(cls, tax_line):
        if not tax_line.tax:
            return tuple()
        tax = tax_line.tax
        if tax.es_reported_with:
            tax = tax.es_reported_with
        if not tax.es_verifactu_operation_key:
            return tuple()
        return (
            ('rate', round(tax.rate * 100, 2)),
            )
