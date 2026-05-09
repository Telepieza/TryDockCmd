******
Design
******

The *Account ES Facturae Module* introduces the following concepts:

.. _model-account.invoice.facturae:

Facturae Invoice
================

The main concept introduced by the *Account ES Facturae Module* is the *Facturae Invoice*.
It relates a `Invoice <account_invoice:model-account.invoice>` with it
state in the :abbr:`Facturae` communication format.
A record is automatically created when an invoices that has enabled the Facturae
format is posted.

In case of manual delivery the invoice can be exported directly using a wizard.

.. seealso::

   The Facturae Invoices can be found by opening the main menu item:

      |Financial --> Invoices --> Facturae|__

      .. |Financial --> Invoices --> Facturae| replace:: :menuselection:`Financial --> Invoices --> Facturae Invoices`
      __ https://demo.tryton.org/model/account.invoice.facturae

Wizards
-------

.. _wizard-account.invoice.facturae.export:

Export Facturae
^^^^^^^^^^^^^^^

The *Export facturae* its used to export a
`Facturae Invoice <model-account.invoice.facturae>` for an specific Facturae
version.
