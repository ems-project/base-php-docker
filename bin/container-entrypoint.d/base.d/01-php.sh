#!/usr/bin/env bash

echo -e "  Setup PHP INI Configuration File(s) ..."

OUTDIR="/app/etc/php/conf.d"
mkdir -p $OUTDIR

apply-template /app/config/php/conf.d /app/etc/php/conf.d

true
