#!/usr/bin/env bash

echo -e "  Setup PHP INI Configuration File(s) ..."

apply-template /app/config/php/conf.d /app/etc/php/conf.d

true
