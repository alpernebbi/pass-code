======
Design
======
``pass-code`` should simply be a translator for the arguments of actual 
``pass`` commands whenever possible. It should be possible to migrate
to a ``pass-code`` workflow by doing an additional ``pass code init``,
then only adding ``code`` to whatever ``pass`` command we would have run
otherwise.

Mapping file
------------
- Store filename mappings in ``.passcode`` file.
- One line per file, colon seperated.
- One to one mapping.
- Fixed-length alphanumeric encoded part.
- Sorted on the decoded part.

To replicate on the example from the ``pass`` website, a corresponding 
mapping file would be::

    pjpg9m9ryx4m6ic8:Business/some-silly-business-site.com
    ws54wjtfuhc6wbq0:Business/another-business-site.net
    rig4xd9t90ypq3ah:Email/donenfeld.com
    5jv1d009jg3ihfz7:Email/zx2c4.com
    dn9n5icjgj2gvx7k:France/bank
    yaskztsk3ceuomir:France/freebox
    u35k4x1q68n3lvbg:France/mobilephone 

Where ``pass ls`` would show::

    Password Store
    ├── 5jv1d009jg3ihfz7
    ├── dn9n5icjgj2gvx7k
    ├── pjpg9m9ryx4m6ic8
    ├── rig4xd9t90ypq3ah
    ├── u35k4x1q68n3lvbg
    ├── ws54wjtfuhc6wbq0
    └── yaskztsk3ceuomir

And ``pass code ls`` should show::

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


Encoding and decoding
---------------------
- Try to read the file as few times as possible.
- ``code_read()`` to read file, generate ``encode()`` and ``decode()``.
- ``code_add()``, ``code_rm()`` to add/remove mappings, renew functions.
- ``encode()`` and ``decode()`` take one argument, echo one result 
  (or nothing on nonexistent mapping).
- ``pass encode`` and ``pass decode`` commands for user.

=============
Pass Commands
=============

pass code init
--------------
- Fail if ``pass init`` not run already.
- Create ``.passcode`` if doesn't exist.
- Encode current passwords if they exist.
- Check ``.passcode`` and skip encoded ones
- If git repo, make a new branch and do ``git filter-branch`` magic.
- Don't forget to change filenames in commit messages
- ``pass init --path=sub-folder`` is going to cause problems
- Maybe preserve folder structure with ``encoded:*/decoded`` in 
  ``.passcode`` ?

pass code ls
------------
We probably have all names in ``.passcode``, but better to be sure.

- Read ``pass ls``
- Skip first line completely but only four characters on the rest.
- Move the filenames through ``decode()``, then sort.
- If ``subfolder`` arg given, filter/modify filenames as necessary.
- Reconstruct tree from filenames.
  
pass code grep
--------------
Read ``pass grep <string>`` and decode filenames in output

pass code find
--------------
Same as ``ls`` but filter by the given argument.

pass code show
--------------
Encode, passthrough.

pass code insert
----------------
Encode, add mapping, passthrough.

pass code edit
----------------
Encode, add mapping if not exists, passthrough. 
Very easy to find the decoded argument.

pass code generate
------------------
Encode, add mapping, passthrough. 
Careful with the ``pass-length`` argument.

pass code rm
------------
Encode, remove from ``.passcode``, passthrough.
Mind the ``--recursive`` folder removal.

pass code mv
------------
Encode, add/remove new/old mappings, passthrough.
Mind moving into folders.

pass code cp
------------
Encode, add mapping, passthrough.
Mind copying into folders.

