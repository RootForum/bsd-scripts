BSD Scripts
===========

BSD Scripts is a collection of scripts which are particularly helpful for administrators of servers running FreeBSD.

apu (Automated Perl Upgrader)
-----------------------------

apu is a helper script that performs all the steps required to upgrade the Perl interpreter from one version to another (e. g. from 5.12 to 5.14) in all jails that have a Perl interpreter installed. This script is particularly useful when a a larger number of jails is hosted on one system, e. g. as described by the [FreeBSD Handbook](http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/jails-application.html).

Currently, apu performs the following checks before applying any change to the system:

* Check if a Perl interpreter is installed in the respective jail
* Check if the installed Perl interpreter's version is identical to the requested one
* Check if port for requested Perl interpreter version is available

Only if these checks indicate that an upgrade to the requested version is possible, the following steps are performed:

* Replace installed Perl interpreter by new version (using portmaster)
* re-compile all ports depending on the lang/perl port (using portmaster's -r flag)

update-python
-------------

`update-python` is a helper script that updates Python interpretes installed in jails. This script is particularly useful when a a larger number of jails is hosted on one system, e. g. as described by the [FreeBSD Handbook](http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/jails-application.html).

Currently, it performs the following steps:

* Check if a Python interpreter is installed within the respective jail
* If applicable, update (or reinstall) the actual Python interpreter (`lang/pythonXY`)
* Ensure that the meta ports (`lang/pythonX` and `lang/python`) are installed and up to date

The latter step happens per recommendation from August 17, 2013 in `/usr/ports/UPDATING`

> ### Please note:
>
> Currently, `update-python` cannot be used for upgrading Python installations to a new (minor or major) version.
> This means that you *can* use `update-python` to update Python from 2.7.x to 2.7.y, but not for an upgrade from
> 2.6 to 2.7 or even from 2.x to 3.y
>
> This feature might be implemented once Python 3 becomes the standard interpreter and upgrades between minor versions
> become once again more relevant than they are today...

update-ports
------------

`update-ports` is a helper script that updates all installed ports to their latest versions in portstree.

This script depends on `portupgrade` and `portversion` which are both part of the `ports-mgmt/portupgrade` port.

Credits
-------

This project is powered by the [RootForum](http://www.rootforum.org) community.
