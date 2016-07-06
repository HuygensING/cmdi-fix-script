# Dit script fixed de cmdi records

Onze cmdi records hadden een aantal syntax errors (op xml schema niveau). Dit script voert het script fix.xsl op ze uit en schrijft het resultaat terug naar de database.

Je gebruikt het als volgt:

```
docker run -it -e PGDATABASE=oaipmh -e PGUSER=theUser -e PGPASSWD=s0mep4ssw3rd huygensing/cmdifix
```

na afloop kun je het resultaat uit /root/output/results.txt uit de database trekken

als je het proces halverwege wil laten starten kan dat met `-e OFFSET=100`

als je een beperkte set wil runnen kan dat met  `-e LIMIT=10`