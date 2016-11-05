MPW: Manage your passwords!
*******************************************************

mpw is a little software which stores your passwords in `GnuPG <http://www.gnupg.org/>` encrypted files.

Features
========

* generate OTP code
* synchronize your passwords with SSH or FTP.
* copy your login, password or otp in clipboard

Install
=======

On debian or ubuntu::

	apt install ruby ruby-dev xclip
	gem install mpw


How to use
==========

A simple mpw usage::

	mpw config --init user@host.com
	mpw add
	mpw copy
	mpw add
	mpw list

Output::

	Bank
	 ==============================================================================
	  ID | Host          | User      | Protocol | Port | OTP | Comment                
	 ==============================================================================
	  1  | bank.com      | 1234456   | https    |      |  X  |                        

	Linux
	 ==============================================================================
	  ID | Host          | User      | Protocol | Port | OTP | Comment                
	 ==============================================================================
	  2  | linuxfr.org   | example   | https    |      |     | Da Linux French Site


Licence |License|
=================

Full license here: `LICENSE <https://github.com/nishiki/manage-password/blob/master/LICENSE>`

.. |License| image:: https://img.shields.io/badge/license-GPL--2.0-blue.svg
