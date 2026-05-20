# ===============================================================================
# PROGRAM:   import_postal_codes.py
# PROJECT:   Tryton Docker Manager
# VERSION:   1.1.30
# DATE:      20/05/2026
# DESCRIPTION: import postal code con proteus version 7 y 8
# ==============================================================================
import warnings
import os
warnings.filterwarnings("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"

import csv
import sys

try:
    from urllib.error import HTTPError
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen, HTTPError

import zipfile
from argparse import ArgumentParser
from io import BytesIO, TextIOWrapper

try:
    import argcomplete
except ImportError:
    argcomplete = None

try:
    from tqdm import tqdm
except ImportError:
    tqdm = None

try:
    from proteus import Model, config
except ImportError:
    prog = os.path.basename(sys.argv[0])
    sys.exit("proteus must be installed to use %s" % prog)


def _progress(iterable, **kwargs):
    if tqdm:
        return tqdm(iterable, disable=None, file=sys.stdout, **kwargs)
    else:
        return iterable


def clean(code):
    print('Cleaning', end='', flush=True)
    PostalCode = Model.get('country.postal_code')
    PostalCode._proxy.delete(
        [c.id for c in PostalCode.find([('country.code', '=', code)])], {})
    print('.')


def fetch(code):
    print('Fetching', end='', flush=True)
    url = 'https://downloads.tryton.org/geonames/%s.zip' % code
    try:
        responce = urlopen(url)
    except HTTPError as e:
        sys.exit("\nError downloading %s: %s" % (code, e.reason))
    data = responce.read()
    with zipfile.ZipFile(BytesIO(data)) as zf:
        data = zf.read('%s.txt' % code)
    print('.')
    return data


def import_(data):
    PostalCode = Model.get('country.postal_code')
    Country = Model.get('country.country')
    Subdivision = Model.get('country.subdivision')
    print('Importing')

    def get_country(code):
        nonlocal countries
        country = countries.get(code)
        if not country:
            try:
                country, = Country.find([('code', '=', code)])
            except ValueError:
                sys.exit("Error missing country with code %s" % code)
            countries[code] = country
        return country
    countries = {}

    def get_subdivision(country, code):
        nonlocal subdivisions
        if not code:
            return None
        code = '%s-%s' % (country, code)
        subdivision = subdivisions.get(code)
        if not subdivision:
            try:
                subdivision, = Subdivision.find([('code', '=', code)])
            except ValueError:
                return None
            subdivisions[code] = subdivision
        return subdivision
    subdivisions = {}

    f = TextIOWrapper(BytesIO(data), encoding='utf-8')
    codes = []
    chunk_size = 1000
    chunk_count = 0
    total_records_processed = 0 # Inicializa un contador para el total de registros

    for row in _progress(csv.DictReader(
                f, fieldnames=_fieldnames, delimiter='\t'),
            total=data.count(b'\n')):
        country = get_country(row['country'])
        subdivision = None
        # Find the most specific subdivision
        for sub_code_field in ['code1', 'code2', 'code3']:
            if row[sub_code_field]:
                sub = get_subdivision(row['country'], row[sub_code_field])
                if sub:
                    subdivision = sub
                    break # Use the first valid subdivision found (most specific)

        codes.append(
            PostalCode(country=country, subdivision=subdivision,
                postal_code=row['postal'], city=row['place']))
        if len(codes) >= chunk_size:
            PostalCode.save(codes)
            total_records_processed += len(codes) # Suma los registros del chunk al total
            chunk_count += 1
            print(f'Saved chunk {chunk_count} ({len(codes)} records). Total records processed: {total_records_processed}', flush=True)
            codes = []
    if codes:
        processed_now = len(codes)
        PostalCode.save(codes)
        total_records_processed += processed_now # Suma los registros restantes al total
        chunk_count += 1
        print(f'Saved final chunk {chunk_count} ({processed_now} records). Grand Total: {total_records_processed}', flush=True)
    print(f'=== IMPORT COMPLETED: {total_records_processed} postal codes recorded ===', flush=True)


_fieldnames = ['country', 'postal', 'place', 'name1', 'code1',
    'name2', 'code2', 'name3', 'code3', 'latitude', 'longitude', 'accuracy']


def main(database, codes, config_file=None):
    config.set_trytond(database, config_file=config_file)
    do_import(codes)


def do_import(codes):
    for code in codes:
        print(code)
        code = code.upper()
        clean(code)
        import_(fetch(code))


def run():
    parser = ArgumentParser()
    parser.add_argument('-d', '--database', dest='database', required=True)
    parser.add_argument('-c', '--config', dest='config_file',
        help='the trytond config file')
    parser.add_argument('codes', nargs='+')
    if argcomplete:
        argcomplete.autocomplete(parser)

    args = parser.parse_args()
    main(args.database, args.codes, args.config_file)


if __name__ == '__main__':
    run()