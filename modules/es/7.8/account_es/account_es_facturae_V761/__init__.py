# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.

from trytond.pool import Pool

from . import account, party

__all__ = ['register']


def register():
    Pool.register(
        party.Party,
        account.Invoice,
        account.InvoiceFacturae,
        account.ExportFacturaeStart,
        account.ExportFacturaeResult,
        module='account_es_facturae', type_='model')
    Pool.register(
        account.ExportFacturae,
        module='account_es_facturae', type_='wizard')
    Pool.register(
        module='account_es_facturae', type_='report')
