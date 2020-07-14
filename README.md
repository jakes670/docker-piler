# Mailpiler as Docker
[Piler](http://www.mailpiler.org/wiki/current:index) is a feature rich open source email archiving solution. This is a project to package it as a docker image.

## Why docker

* setup multiple mailpiler instances on a single server
* easy and fast setup
* reproducible setup
* easy backup

## How to start

```bash
#install docker
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
# start docker mailpiler instance (use port 2525 for smtp and 8025 for http)
docker run -d --restart unless-stopped --name piler-instance-1 \
 -p 2525:25 -p 8025:80 \
 -v /var/piler-1-data-:/var/piler \
 -v /var/piler-1-config:/config \
 -e PILER_HOST=archive.domain.com ebtc/piler
```

Shell access whilst the container is running: 

```bash
docker exec -it piler-1 /bin/bash
```


### Testing and rebuilder instance

```bash
docker rm piler-1
docker run -d --restart unless-stopped --name piler-1 \
 -p 2525:25 -p 8025:80 \
 -v /var/piler-1-data-:/data \
 -v /var/piler-1-config:/config \
 -e PILER_HOST=archive.domain.com ebtc/piler
docker logs piler --follow
```

## testing the beta based on Ubuntu 20.04 LTS Focal Fossa
  PILER_VAR_DATA=/var/piler-data ; 
  docker create --name=piler -e PUID=$(id -u) -e PGID=$(id -g) -e PILER_HOST=archive.example.org -p 25:25 -p 80:80 -p 443:443 -v ${PILER_VAR_DATA/config:-/dummy}:/config -v ${PILER_VAR_DATA/data:-/dummy}:/data woa7/piler:focal
  docker start piler ; docker logs -f piler
### OR
  PILER_VAR_DATA=/var/piler-data ; 
  docker run -d --name piler -e PUID=$(id -u) -e PGID=$(id -g) -e PILER_HOST=archive.example.org -p 25:25 -p 80:80 -p 443:443 -v ${PILER_VAR_DATA/config:-/dummy}:/config -v ${PILER_VAR_DATA/data:-/dummy}:/data woa7/piler:focal

## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```
  on the host OS:
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```
```
default logins:
admin account: admin@local
admin password: pilerrocks
auditor account auditor@local
auditor password: auditor
```

How to build

check out 
  git clone git@github.com:woa7/docker-piler.git && cd docker-piler

  Pick the latest deb package from Bitbucket download page (https://bitbucket.org/jsuto/piler/downloads/)
  and use it as the PACKAGE build argument, eg.

  docker build --build-arg PACKAGE=piler_1.3.7-bionic-94c54a0_amd64.deb --build-arg PACKAGE_DOWNLOAD_SHA256=025bf31155d31c4764c037df29703f85e2e56d66455616a25411928380f49d7c -t woa7/piler .

How to run the image

  Set the PILER_HOST env variable to match your hostname, eg.

  docker run -d --name piler1 -p 25:25 -p 80:80 -e PILER_HOST=archive.example.org woa7/piler


## Supported Architectures

Our image support only `amd64` at the time, as architectures. as the sphinx is only `amd64`.

## What is piler?

Email archiving provides lots of benefits to your company. Piler is a feature rich open source email archiving solution, and a viable alternative to commercial email archiving products; check out the comparison with Mailarchiva.

Piler has a nice GUI written in PHP supporting several authentication methods (AD/LDAP, SSO, Google OAuth, 2 FA, IMAP, POP3). Be sure to try the online demo!

Piler supports

* archiving and retention rules
* legal hold
* deduplication
* digital fingerprinting and verification
* full text search
* tagging emails
* view, export, restore emails
* bulk import/export messages
* audit logs
* Google Apps
* Office 365
* and many more

How does it work: 

mysql: piler stores crucial metadata of the messages
sphinx: a search engine used by the gui to return the search results
file system: this is where the encrypted and compressed messages, attachments are stored
How do emails get to the archive? You configure your email server to pass a copy of emails to the piler daemon via smtp, since piler is an SMTP(-talking) daemon. Note that you don't need to create any system or virtual users or email addresses for the piler daemon to work, because it simply archives every email it receives.

When an email is received, then it's parsed, disassembled, compressed, encrypted, and finally stored in the file system: one file for every email and attachment. Also, the textual data is written to the sph_index table. The periodic indexer job reads the sph_index table, and updates the sphinx databases.

The GUI uses sphinx and mysql database to return the search results to the users.

Piler has a built-in access control to prevent a user to access other's messages. Auditors can see every archived email. Piler parses the header and extracts the From:, To: and Cc: addresses (in case of From: it only stores the first email address, since some spammers include tons of addresses in the From: field), and when a user searches for his emails then piler tries to match his email addresses against the email addresses in the messages. To sum it up, a regular user can see only the emails he sent or received.

This leads to a limitation: piler will hide an email from a user if he was (only) in the Bcc: field. This limitation has another side effect related to external mailing lists. You have to maintain which user belongs to which external mailing lists, otherwise users won't see these messages. Internal mailing lists are not a problem as long as piler can extract the membership information from openldap OR Active Directory.

Fortunately both Exchange and postfix (and probably some other MTAs, too) are able to put envelope recipients to the email, so the limitation mentioned above is solved.
