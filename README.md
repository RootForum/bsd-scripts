BSD Scripts
==========

BSD Scripts is a collection of scripts which are particularly helpful for administrators of servers running FreeBSD.

apu (Automated Perl Upgrader)
--------------------------

apu is a helper script that performs all the steps required to upgrade the Perl interpreter from one version to another (e. g. from 5.12 to 5.14) in all jails that have a Perl interpreter installed. This script is particularly useful when a a larger number of jails is hosted on one system, e. g. as described by the [FreeBSD Handbook](http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/jails-application.html).

Currently, apu performs the following checks before applying any change to the system:

* Check if a Perl interpreter is installed in the respective jail
* Check if the installed Perl interpreter's version is identical to the requested one
* Check if port for requested Perl interpreter version is available

Only if these checks indicate that an upgrade to the requested version is possible, the following steps are performed:

* Replace installed Perl interpreter by new version (using portmaster)
* re-compile all ports depending on the lang/perl port (using portmaster's -r flag)

Credits
------

This project is powered by the [RootForum](http://www.rootforum.org) community.
