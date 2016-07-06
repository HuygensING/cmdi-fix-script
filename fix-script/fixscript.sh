#!/bin/bash

set -o errexit
set -u

export PGHOST=${PGHOST:-postgresql}
export PGUSER=${PGUSER:-test}
export PGPASSWORD=${PGPASSWORD:-test}
export PGDATABASE=${PGDATABASE:-oaipmh}
if [ -n "${LIMIT:-}" ]; then
  LIMIT=" LIMIT $LIMIT"
else
  LIMIT=""
fi
if [ -e /root/offset ]; then
  OFFSET=`cat /root/offset`
fi
if [ -n "${OFFSET:-}" ]; then
  start="$OFFSET"
  OFFSET=" OFFSET $OFFSET"
else
  start=0
  OFFSET=""
fi

mkdir -p output

echo "COPY (SELECT identifier, metadata_string from records ORDER BY identifier${LIMIT}${OFFSET}) TO STDOUT;"
## retrieve N documents
psql --file='-' > output/records <<-EOF
  COPY (SELECT identifier, metadata_string from records ORDER BY identifier${LIMIT}${OFFSET}) TO STDOUT;
EOF

## extract url > 00_oaipmh.xml
while read -r line; do
  id=$(echo "$line" | cut -f 1)
  echo "transforming no. $start: $id"
  #strip the id followed by 1 character (the tab). I don't know how to specify a tab in variable expansion so I use a wildcard
  echo -e "${line#$id?}" > output/00_oaipmh.xml

  ## extract cmdi
  xmlstarlet sel \
    -N cmdi="http://www.clarin.eu/cmd/" -t -c '/*/cmdi:CMD' output/00_oaipmh.xml > output/01_cmdi_wrong.xml

  ## fix cmdi
  saxonb-xslt -s:output/01_cmdi_wrong.xml -xsl:fix.xsl > output/02_cmdi_fixed.xml

  ## use sed and xmlstarlet to replace marker element with fixed cmdi.

  #We need to use sed because the resulting xml document is not quite valid xml so
  #xslt won't work and xml_starlet doesn't seem to be able to inject xml trees in
  #one go (I'm not that familiar with xmlstarlet so this might be a wrong
  #assumption)

  #first replace cmdi xml with a marker element (<jaucocmdifix/>)
  xmlstarlet ed \
    -N cmdi="http://www.clarin.eu/cmd/" \
    -N oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" \
    -d '/*/cmdi:CMD' \
    -a '/*/oai_dc:dc' -t elem -n jaucocmdifix output/00_oaipmh.xml > output/03_oaipmh_without_cmdi.xml

  #then we use sed to replace a string with the contents of a file
  #http://unix.stackexchange.com/questions/49377
  cat output/03_oaipmh_without_cmdi.xml | sed -e '/^ *<jaucocmdifix/ {' -e 'r output/02_cmdi_fixed.xml' -e d -e '}' > output/04_oaipmh_fixed.xml

  ## create a diff

  #exc-c14n normalizes the xml so they can be diffed without having cruft
  #for some reason doing --format AND --exc-c14n in one call doesn't work on my
  #machine
  xmllint --exc-c14n  output/00_oaipmh.xml | xmllint --format - > output/old
  xmllint --exc-c14n  output/04_oaipmh_fixed.xml | xmllint --format - > output/new
  git diff --color output/old output/new >> output/results.txt || true 

  ## post 04_oaipmh_fixed.xml back to the server
  psql --file='-' <<-EOF
    \set content \`cat output/04_oaipmh_fixed.xml\`
    UPDATE records SET metadata_string = :'content' WHERE identifier='$id';
EOF

  let start=$start+1
  echo $start > /root/offset
done < output/records
