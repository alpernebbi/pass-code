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
concern for some people, and filename encryption has been requested
as a feature in the password-store mailing list repeatedly `[1]`_
`[2]`_ `[3]`_. Another extension that fulfils this purpose is
pass-tomb_ which stores your entire password storage in an encrypted
volume.

.. _[1]: https://lists.zx2c4.com/pipermail/password-store/2017-February/002700.html
.. _[2]: https://lists.zx2c4.com/pipermail/password-store/2017-February/002737.html
.. _[3]: https://lists.zx2c4.com/pipermail/password-store/2016-January/001880.html
.. _pass-tomb: https://github.com/roddhjav/pass-tomb

``pass-code`` generates random filenames for each file in the password
store and keeps the mapping in an encrypted file. This way, no valuable
information is accessible even if your password store is leaked to the
public (unless your GPG private keys were also leaked). Nevertheless, 
you should always ensure proper protection of your password store.

``pass-code`` is designed to behave as closely to ``pass`` as possible,
to the point that it currently passes all but two tests from the
original ``pass`` test suite with appropriate modifications.

Example
-------

For someone who doesn't have your GPG keys, your password-store looks
like this::

    $ pass ls
    Password Store
    ├── 5jv1d009jg3ihfz7
    ├── dn9n5icjgj2gvx7k
    ├── pjpg9m9ryx4m6ic8
    ├── rig4xd9t90ypq3ah
    ├── u35k4x1q68n3lvbg
    ├── ws54wjtfuhc6wbq0
    └── yaskztsk3ceuomir

With the ``pass-code`` extension (and your GPG keys), you can see
the true form of the password store::

    $ pass code ls
    Password Store
    ├── Business
    │   ├── some-silly-business-site.com
    │   └── another-business-site.net
    ├── Email
    │   ├── donenfeld.com
    │   └── zx2c4.com
    └── France
        ├── bank
        ├── freebox
        └── mobilephone

The mappings between the two is stored in a ``.passcode.gpg`` file
with a very simple, human-readable format::

    $ pass show .passcode
    pjpg9m9ryx4m6ic8:Business/some-silly-business-site.com
    ws54wjtfuhc6wbq0:Business/another-business-site.net
    rig4xd9t90ypq3ah:Email/donenfeld.com
    5jv1d009jg3ihfz7:Email/zx2c4.com
    dn9n5icjgj2gvx7k:France/bank
    yaskztsk3ceuomir:France/freebox
    u35k4x1q68n3lvbg:France/mobilephone

Usage
-----
Almost all ``pass`` commands are supported with the same argument lists,
the exceptions being ``pass code init`` and ``pass code git`` which
only pass their arguments directly to their ``pass`` counterparts).
See the `man page for pass`_.

.. _man page for pass: https://git.zx2c4.com/password-store/about/

::

    pass code init [args...]
        No pass-code specific initialization is done, instead
        passes the options to "pass init" unconditionally.
        The pass-code extension does not support encrypted
        subfolders (with the --path option), but still passes
        these options through.

    pass code git [args...]
        No pass-code specific manipulation is done to the
        arguments, stdin or the stdout. Instead, the given
        options are simply passed to "pass git".

    pass code pass-command [args...]
        See help text for "pass pass-command". When
        necessary, the pass-names are encoded/decoded, file
        mappings are created/changed/removed and written to the
        ".passcode" pass-name in the password storage.

    pass code encode pass-code-name...
        List whichever pass-names in the password storage
        correspond to the given encoded names. Outputs one line
        with the encoded name (or an empty line) per argument.

    pass code decode pass-name...
        List whichever pass-code-names in the .passcode file
        correspond to the given decoded names. Outputs one line
        with the decoded name (or an empty line) per argument.

    pass code [help] [pass]
        Show this message, or the "pass help" message.

    pass code version [pass]
        Show version information for pass-code or pass.

Installation
------------
First, ensure that ``pass version`` reports ``v1.7`` or later, which
is needed for extension support. If so, copy the ``code.bash`` file to
``~/.password-store/.extensions/``. You also need to set the
``PASSWORD_STORE_ENABLE_EXTENSIONS`` environment variable to ``true``
for ``pass`` to execute extensions.

Caveats
-------
See ``DESIGN.rst`` for notes I keep about issues and things to
implement.
