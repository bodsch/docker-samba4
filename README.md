docker-samba4
==============

small, alpine based, container with a Samba4 AD

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-samba4.svg?branch)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-samba4.svg?branch)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-samba4.svg?branch)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-samba4/
[microbadger]: https://microbadger.com/images/bodsch/docker-samba4
[travis]: https://travis-ci.org/bodsch/docker-samba4

# Build

Your can use the included Makefile.

To build the Container: `make`

To remove the builded Docker Image: `make clean`

Starts the Container with a simple set of environment vars: `make run`

Starts the Container with Login Shell: `make shell`

Entering the Container: `make exec`

Stop (but **not kill**): `make stop`

see the History `make history`


# Docker Hub

You can find the Container also at  [DockerHub](https://hub.docker.com/r/bodsch/docker-samba4/)


# supported Environment Vars

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `SAMBA_DC_ADMIN_PASSWD`            | autogenerated        | Administrator Password                                          |
| `KERBEROS_PASSWORD`                | autogenerated        | Kerberos Passwort                                               |
| `SAMBA_DC_DOMAIN`                  | `smb`                |                                                                 |
| `SAMBA_DC_REALM`                   | `SAMBA.LAN`          |                                                                 |
| `SAMBA_DC_DNS_BACKEND`             | `SAMBA_INTERNAL`     | `BIND9_FLATFILE` is also supported and starts an internal bind  |
| `SAMBA_OPTIONS`                    | -                    |                                                                 |
|                                    |                      |                                                                 |
| `TEST_USER`                        | -                    | if `true` the container will import some test users:<br>`grillstarling` and `bodsch` |


# Test

    ldapsearch -H ldaps://localhost -D "Administrator@samba.lan"  -w "${SAMBA_DC_ADMIN_PASSWD}" -b "DC=samba,DC=lan"  '(objectClass=*)'
    ldapsearch -H ldaps://localhost -D "Administrator@samba.lan"  -w "${SAMBA_DC_ADMIN_PASSWD}" -b "DC=samba,DC=lan" -x -LLL -z 0

With `TEST_USER` enabled, you can check the `grillstarling` User:

    ldapsearch -H ldaps://localhost  -D "Administrator@samba.lan"  -w "${SAMBA_DC_ADMIN_PASSWD}" -b "CN=Users,DC=samba,DC=lan" '(&(objectClass=user)(sAMAccountName=grillstarling))'
