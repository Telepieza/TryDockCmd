============================
Account ES Verifactu Invoice
============================

Imports::

    >>> import datetime as dt
    >>> import time
    >>> from decimal import Decimal

    >>> from proteus import Model
    >>> from trytond.tests.tools import activate_modules
    >>> from trytond.modules.currency.tests.tools import get_currency
    >>> from trytond.modules.company.tests.tools import (
    ...     create_company, get_company)
    >>> from trytond.modules.account.tests.tools import (
    ...     create_fiscalyear, create_chart, get_accounts)
    >>> from trytond.modules.account_invoice.tests.tools import (
    ...     set_fiscalyear_invoice_sequences)

Activate modules::

    >>> config = activate_modules('account_es_verifactu')

    >>> AccountConfig = Model.get('account.configuration')
    >>> Cron = Model.get('ir.cron')
    >>> Invoice = Model.get('account.invoice')
    >>> InvoiceVerifactu = Model.get('account.invoice.verifactu')
    >>> Party = Model.get('party.party')
    >>> Tax = Model.get('account.tax')

Create company::

    >>> _ = create_company(currency=get_currency('EUR'))
    >>> company = get_company()
    >>> company_party = company.party
    >>> es_vat = company_party.identifiers.new(type='es_vat')
    >>> es_vat.code = '00000000T'
    >>> company_party.save()

Create fiscal year::

    >>> fiscalyear = set_fiscalyear_invoice_sequences(create_fiscalyear())
    >>> fiscalyear.click('create_period')
    >>> first_period = fiscalyear.periods[0]
    >>> first_period.es_verifactu_send_invoices = False
    >>> first_period.save()
    >>> second_period = fiscalyear.periods[1]
    >>> second_period.es_verifactu_send_invoices = True
    >>> second_period.save()

Create chart of accounts::

    >>> _ = create_chart(company, 'account_es.pgc_0_pyme')
    >>> acccounts = get_accounts()

    >>> tax, = Tax.find([
    ...         ('group.kind', '=', 'sale'),
    ...         ('name', 'ilike', '%bienes%'),
    ...         ], limit=1)

Create customer::

    >>> customer = Party(name="Customer")
    >>> customer.save()

No verifactu record is generated if not activated::

    >>> invoice = Invoice(type='out', party=customer)
    >>> invoice.invoice_date = first_period.start_date
    >>> line = invoice.lines.new()
    >>> line.account = acccounts['revenue']
    >>> line.quantity = 5
    >>> line.unit_price = Decimal('50.0000')
    >>> line.taxes.append(Tax(tax.id))
    >>> invoice.click('post')
    >>> invoice.state
    'posted'
    >>> InvoiceVerifactu.find([])
    []

Create invoice on activated date::

    >>> invoice = Invoice(type='out', party=customer)
    >>> invoice.invoice_date = second_period.start_date
    >>> line = invoice.lines.new()
    >>> line.account = acccounts['revenue']
    >>> line.quantity = 5
    >>> line.unit_price = Decimal('50.0000')
    >>> line.taxes.append(Tax(tax.id))
    >>> invoice.click('post')
    >>> invoice.state
    'posted'

Check Verifactu fields::

    >>> record, = InvoiceVerifactu.find([])
    >>> record.invoice == invoice
    True
    >>> bool(record.generated_at)
    True
    >>> str(record.fingerprint).isupper()
    True
    >>> record_fingerprint = record.fingerprint
    >>> record_generated_at = record.generated_at
    >>> bool(record.previous_record)
    False

Duplicate invoice and test fields are re-generated::

    >>> new_invoice, = invoice.duplicate()
    >>> new_invoice.invoice_date = second_period.start_date
    >>> new_invoice.click('post')
    >>> len(InvoiceVerifactu.find([]))
    2
    >>> new_record, = InvoiceVerifactu.find([('invoice', '=', new_invoice.id)])
    >>> bool(new_record.generated_at)
    True
    >>> bool(new_record.fingerprint)
    True
    >>> new_record_fingerprint = new_record.fingerprint
    >>> new_record_generated_at = new_record.generated_at
    >>> new_record.previous_record == record
    True

Send records using cron::

    >>> cron, = Cron.find([('method', '=', 'account.invoice.verifactu|send')])
    >>> cron.click('run_once')
    >>> record.reload()
    >>> record.state
    'wrong'
    >>> new_record.reload()
    >>> new_record.state
    'sent'

Fingerprint and previous records are recomputed for wrong records::

    >>> time.sleep(1)  # Sleep to increase timestamp
    >>> record.click('resend')
    >>> record.previous_record == new_record
    True
    >>> record.fingerprint != record_fingerprint
    True
    >>> record.generated_at != record_generated_at
    True

Fingerprint and previous records are keep::

    >>> new_record.reload()
    >>> new_record.previous_record == record
    True
    >>> new_record.fingerprint == new_record_fingerprint
    True
    >>> new_record.generated_at == new_record_generated_at
    True

Post multiple invoices in diferent order preserves the numbering order::

    >>> invoice2, = invoice.duplicate()
    >>> invoice2.invoice_date = second_period.start_date + dt.timedelta(days=1)
    >>> invoice3, = invoice.duplicate()
    >>> invoice3.invoice_date = second_period.start_date
    >>> invoice4, = invoice.duplicate()
    >>> invoice4.invoice_date = second_period.start_date
    >>> Invoice.click([invoice4, invoice2, invoice3], 'post')
    >>> invoice2.number
    '6'
    >>> invoice3.number
    '5'
    >>> invoice4.number
    '4'
    >>> record2, = InvoiceVerifactu.find([('invoice', '=', invoice2.id)])
    >>> record3, = InvoiceVerifactu.find([('invoice', '=', invoice3.id)])
    >>> record4, = InvoiceVerifactu.find([('invoice', '=', invoice4.id)])
    >>> record4.previous_record == record
    True
    >>> record3.previous_record == record4
    True
    >>> record2.previous_record == record3
    True
