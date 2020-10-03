

# M-Link on Jabber.org

## Accessing hermes.jabber.org

```sh
ssh -p5437 waqas@hermes.jabber.org
```

## M-Link config paths

```
userdir: /var/isode/ms/users
tls_ca_path: /etc/isode/ssl/certs/
tls_cert_file: /etc/isode/ssl/certs/jabber.org.p12
muc_archive_dir: /home/jabber/archive/muc
```

## Paths

* /tmp
    - Misc stuff and some docs
* /etc/isode
    - /mlink.conf
    - /mlink.rc
        + Does e.g., `echo '/home/jabber/cores/core_%e_%p_%s' >/proc/sys/kernel/core_pattern`
    - /mlinklogging.xml -- logging config
    - /ssl
        + /openssl.cnf
        + /misc -- cert related scripts
        + /certs -- various certs
            * `*.{pem,p12,crt,key}`
* /var/isode
    - /apache-tomcat -- 7.3 MB
    - /d3-db -- 33 GB
        + /backup -- 24 GB -- old backup?
        + /config -- LDAP DB (cn=config) -- 11 MB
        + /dsa.pid -- PID file
        + /gdam1 -- XSF LDAP DB (o=XSF) -- 5.2 GB
            * /changelog -- 2.5 MB
                - last modified Jul 3, while today is Jul 18, so not an actively updating changelog?
            * /config/indexes.ddf -- 12 KB
                - index `2.5.4.3` is `jid.eq`
            * /snapshots -- 5.2 GB
                - /{00000000002e9a8{0,1,2,3}}/{0000000{00..27}}.ddf
                - last modified for any file is Jul 4, while today is Jul 18, so not actively updating DB?
            * /xsf.ldif -- 28 KB
        + /gdam1.* -- unused sample/test DBs?
        + /seed.dat -- binary file, 1 KB -- some random seed?
        + Most recently modified file is from Jul 4, while today is Jul 18...
            * not actively updating?
            * or simply no-one has changed their LDAP data in this timeframe?
    - /log -- 7.6 GB
    - /MegaSAS.log -- 20 KB
    - /tmp -- 0 KB
    - /ms
        + /pubsub -- 17 MB (572 directories)
            * recursive file stats:
                - config -- 568
                - hdr.dat -- 449
                - template-room.xml -- 448
                - template-room.db -- 448
                - {hostname}.xml -- 628
            * /conference.jabber.org
                - /{room}.db -- MUC room history data?
                - /config
                    + /{room}.xml -- MUC room configuration
            * /jabber.org
                - http%3A%2F%2Fisode.com%2Fmlink%2Fconfig%2Fnode.db (compiled config?)
        + /stats -- 24 KB -- from 2015
        + /users
            * /{0..250}/{username}/xmpp
                - e.g., `/var/isode/ms/users/59/waqas/xmpp`
                - e.g., `/var/isode/ms/users/171/mwild1/xmpp`
                - e.g., `/var/isode/ms/users/44/mattj/xmpp`
                - /roster.db -- 'HT03' format
                - /pep
                    + /{urlencoded-pep-node}.db -- 'PSIS' format
                    + /config/{urlencoded-pep-node}.xml -- PEP auth/config (can be ignored?)
                    + `sudo ls -R /var/isode/ms/users/59/ | grep '\.db' | head -n 10000 | sort | uniq -c | sort -rn | less`
                    + These include vcard, offline messages, etc
                    + Incoming subscriptions are also in this, not in the roster
                - The {0..250} part is the FNV-1 32-bit hash of the username, mod 251
                    + TODO figure out how non-ascii characters work
* /home/jabber/archive/muc
    - /{YYYY}/{M}/{D}/{room_jid}
        + file containing XML elements
            * no outer wrapper
            * no separator between elements
            * elements seem to be always <muc_state state='{presence|message|join|leave|...}'...>...</muc_state>

Notes:
* .db.bak files may exist

## LDAP database format

(SPECULATION WARNING)

Basic structure is an LDAP object.

There are two DB parts
1) changelog: append-only files gaining new LDAP objects
2) snapshots: sorted LDAP objects
    + consists of 50 MB files
    + files don't seem interally sorted by CN
    + but file N seems to have all stuff < file N+1
    + 4 snapshots seem to exist, exact same usernames in all of them

Suspected operation:
* The LDAP server appends modifications to changelog
* As part of vacuum operations, snapshots are updated
* During lookups, changelog files (likely also kept in RAM) are scanned
* Fallbacks to binary search in snapshots, if not found in changelog
* Or LDAP server might be holding everything in RAM, dataset is not that large

LDAP object format:
* Text format, newline separated
* First line: 8 hex digits, likely some id
* Second line: `dn:{...}`
    - e.g., `dn:uid={username},ou=Users,dc=jabber,dc=org,o=XSF`
    - or `dn::{base64 string}` -- possibly when UID has invalid characters
    - or `dn:jid=...,o=XSF`
    - etc
* Followed by one or more properties:
    - First line: `\d+(\.\d+)*` e.g., `2.5.24.2`
        + likely a property ID defined in a schema somewhere
        + the dots might represent some hierarchy
        + `2.5.4.35` is "userPassword"
            * `value = base64("\u0004\n{plain password}")`
        + `1.3.6.1.4.1.453.24.2.79` is "jid"
            * `value = base64("\u001e {UTF-16 bare JID}")`
    - One or more base64 encoded lines (property values)
    - A single hyphen (`\n-\n`)
* Object ends with an empty line (`\n\n`)

## .db binary format (PSIS)

* Magic string: `PSIS`
* Contains a list of records.
* Each record ends in `PSIS_REC`.
* `\0` might be field terminator.
* Feels tabular (each record has multiple values inside).
* Schema is not present in the file itself.
* Records have a marker, length and type.

## LDAP data

Get LDAP data (JID, password, etc) for individual user:

```sh
ldapsearch -D 'cn=DSA Manager,cn=Users,o=XSF' -x -W -h localhost -p 19389 -b 'o=XSF' 'jid=waqas@jabber.org'
```

## Misc

Roster can be dumped via:
```
sudo /opt/isode/sbin/roster_dump waqas
```

`/opt/isode/sbin/xep227` supports export and import. Docs: https://www.isode.com/documentation/MLINKADM.pdf

