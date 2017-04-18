=========
pass-code
=========
A pass_ extension that obscures the filenames and folder hierarchy
within your password store.

.. _pass: https://www.passwordstore.org/

Desciption
----------
In normal operation, ``pass`` stores the passwords in encrypted form, 
but the filenames that you use to access these passwords are 
unencrypted. These filenames would usually include the names of the 
websites and sometimes the names of the accounts. This is a security 
concern for some people.

``pass-code`` generates random filenames for each file in the password
store and keeps the mapping in an encrypted file. This way, no valuable
information is accessible even if your password store is leaked to the
public (unless your GPG private keys were also leaked). Nevertheless, 
you should always ensure proper protection of your password store.
