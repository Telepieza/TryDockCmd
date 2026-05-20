# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from lxml import etree

from trytond.exceptions import UserError
from trytond.i18n import gettext
from trytond.model import ModelSQL, ModelView, Unique, Workflow, fields
from trytond.pool import Pool, PoolMeta
from trytond.pyson import Eval
from trytond.wizard import Button, StateTransition, StateView, Wizard


class Invoice(metaclass=PoolMeta):
    __name__ = 'account.invoice'

    @classmethod
    def _post(cls, invoices):
        pool = Pool()
        Invoicefacturae = pool.get('account.invoice.facturae')
        posted_invoices = {
            i for i in invoices if i.state in {'draft', 'validated'}}
        super()._post(invoices)
        invoices_facturae = []
        for invoice in posted_invoices:
            if invoice.party.facturae:
                invoices_facturae.append(
                        Invoicefacturae(
                            invoice=invoice,
                            method=invoice.party.facturae))
        Invoicefacturae.save(invoices_facturae)


class ExportFacturaeStart(ModelView):
    "Export Facturae Start"
    __name__ = 'account.invoice.facturae.export.start'

    version = fields.Selection([
        ('3.2.1', "3.2.1"),
        ('3.2.2', "3.2.2"),
        ], "Version", translate=False, required=True)


class ExportFacturaeResult(ModelView):
    "Export Facturae Result"
    __name__ = 'account.invoice.facturae.export.result'

    filename = fields.Char("Filename", readonly=True)
    result = fields.Binary("Result", filename='filename', readonly=True)


class ExportFacturae(Wizard):
    "Export Facturae"
    __name__ = 'account.invoice.facturae_export'

    start = StateView(
        'account.invoice.facturae.export.start',
        'account_es_facturae.export_facturae_start_view_form', [
            Button("Cancel", 'end', 'tryton-cancel'),
            Button("Export", 'export', 'tryton-print', default=True),
            ])
    export = StateTransition()
    result = StateView(
        'account.invoice.facturae.export.result',
        'account_es_facturae.export_facturae_result_view_form', [
            Button("Close", 'end', 'tryton-ok', default=True),
            ])

    def transition_export(self):
        pool = Pool()
        Facturae = pool.get('edocument.es.facturae.invoice')

        facturae = Facturae(self.record.invoice)
        try:
            self.result.result = facturae.render(self.start.version)
        except etree.DocumentInvalid as e:
            # Filter duplicated error messages
            errors = {error.message for error in e.error_log}
            raise UserError(gettext(
                    'account_es_facturae.msg_invalid_facturae_xml_file',
                    invoice=(
                        self.record.invoice.rec_name
                        if self.record and self.record.invoice
                        else None),
                    message="\n".join(errors)))

        return 'result'

    def default_result(self, fieldnames):
        defaults = {
            'filename': '%s.xml' % self.record.invoice.rec_name,
            }
        if self.result.result:
            defaults['result'] = self.result.result
        return defaults


class InvoiceFacturae(Workflow, ModelSQL, ModelView):
    "Invoice Facturae"
    __name__ = 'account.invoice.facturae'

    invoice = fields.Many2One(
        'account.invoice', "Invoice", required=True,
        domain=[
            ('state', 'in', ['posted', 'paid']),
            ])
    method = fields.Selection(
        'get_facturae_methods', "Method", readonly=True)
    state = fields.Selection([
            ('pending', "Pending"),
            ('sent', "Sent"),
            ], "State", readonly=True)

    @classmethod
    def __setup__(cls):
        super().__setup__()
        cls._buttons.update({
            'export_facturae': {
                'invisible': ((Eval('method') != 'manual')
                    | (Eval('state') != 'pending')),
                'depends': ['method']
                },
            'pending': {
                'invisible': ((Eval('method') != 'manual')
                    | (Eval('state') != 'sent')),
                'depends': ['state', 'method'],
                },
            'sent': {
                'invisible': ((Eval('method') != 'manual')
                    | (Eval('state') != 'pending')),
                'depends': ['state', 'method']
                },
            })
        t = cls.__table__()
        cls._sql_constraints = [
            ('invoice_unique', Unique(t, t.invoice),
                'account_es_facturae.msg_invoice_unique'),
            ]
        cls._transitions |= set((
                ('pending', 'sent'),
                ('sent', 'pending'),
                ))
        cls.__access__.add('invoice')

    @classmethod
    def default_state(cls):
        return 'pending'

    @classmethod
    def default_method(cls):
        return 'manual'

    def get_rec_name(self, name):
        return self.invoice.rec_name

    @classmethod
    def search_rec_name(cls, name, clause):
        return [('invoice.rec_name',) + tuple(clause[1:])]

    @classmethod
    def get_facturae_methods(cls):
        pool = Pool()
        Party = pool.get('party.party')
        field_name = 'facturae'
        return Party.fields_get([field_name])[field_name]['selection']

    @fields.depends('invoice')
    def on_change_invoice(self):
        if self.invoice and self.invoice.party.facturae:
            self.method = self.invoice.party.facturae
        else:
            self.method = self.default_method()

    @classmethod
    @ModelView.button_action('account_es_facturae.wizard_export_facturae')
    def export_facturae(cls, records):
        pass

    @classmethod
    @ModelView.button
    @Workflow.transition('pending')
    def pending(cls, records):
        pass

    @classmethod
    @ModelView.button
    @Workflow.transition('sent')
    def sent(cls, records):
        pass
