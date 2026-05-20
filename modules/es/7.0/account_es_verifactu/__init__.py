# The COPYRIGHT file at the top level of
# this repository contains the full copyright notices and license terms.
from trytond.pool import Pool

from . import account, company, ir, party

__all__ = ['register']


def register():
    Pool.register(
        ir.Cron,
        company.Company,
        company.LoadCredentialVerifactuStart,
        account.Configuration,
        account.CredentialVerifactu,
        account.FiscalYear,
        account.Period,
        account.Declaration,
        account.TaxTemplate,
        account.Tax,
        account.Invoice,
        account.InvoiceVerifactu,
        party.Identifier,
        module='account_es_verifactu', type_='model')
    Pool.register(
        account.RenewFiscalYear,
        company.LoadCredentialVerifactu,
        module='account_es_verifactu', type_='wizard')
    Pool.register(
        account.DeclarationReport,
        module='account_es_verifactu', type_='report')
