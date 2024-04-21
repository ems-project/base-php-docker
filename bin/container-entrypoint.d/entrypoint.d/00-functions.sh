#!/usr/bin/env bash

function apply-template {

  TPLDIR=$1
  OUTDIR=$2

  for f in ${TPLDIR}/*.tmpl; do
    ff=$(basename $f)
    if [ -w "$OUTDIR" ]; then
      gomplate \
        -f ${TPLDIR}/${ff} \
        -o ${OUTDIR}/${ff%.tmpl}
    else
      echo "    Write permission is NOT granted on $OUTDIR ."
    fi

  done

}

true
