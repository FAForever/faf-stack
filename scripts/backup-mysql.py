#!/usr/bin/env python

import sys
import argparse
import configparser
import pathlib

import pymysql

def parse_arguments(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('faf_stack', help='location of faf-stack directory', type=pathlib.Path)
    parser.add_argument('db_filesystem', help='zfs dataset name of the database data directory', type=pathlib.Path)
    options = parser.parse_args(argv[1:])
    return options

def main(options):
    config = configparser.ConfigParser()
    config.read(options.faf_stack / "config/faf-db/mysql.cnf")
    kwargs = {k: config['client'][k] for k in ('user', 'password', 'host')}

    conn = pymysql.Connection(**kwargs)
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("BACKUP STAGE START;")
            cursor.execute("BACKUP STAGE BLOCK_COMMIT;")
            # zfs snap
            cursor.execute("BACKUP STAGE END;")

if __name__ == '__main__':
    main(parse_arguments(sys.argv))
