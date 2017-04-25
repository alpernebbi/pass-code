=============
Notes to self
=============
``pass-code`` assumes the ``pass`` hierarchy will be flat, so the
``--path=sub-folder`` argument to ``pass init`` is not supported now.
Can probably be implemented by putting a .passcode file in the folder,
checking whether the paths from arguments refer to a folder that exist
and using the .passcode from those folder. Makes things quite
complicated.

Since the original pass commands are used whenever possible and the
file names passed to those are encrypted, ``git`` history is mostly
undecipherable. It would be possible to translate encoded/decoded values
in ``pass code git`` but I don't think that's a good idea.

When ``pass-code`` moves/removes/copies a folder, a ``git`` commit
is issued for every file in that folder. When moving, I can just
modify the filenames in the .passcode, but I feel that would make
merge conflicts harder to resolve.

I haven't tested what happens when you have to merge two differing
``git`` histories, but I guess there will be a conflict every time
you try to do so (at least on the .passcode file). Is a merge driver
possible? Could I get by with doing union merges for .passcode
and verifying referred encrypted files exist while reading it?

From ``{a, b}`` have branch ``x`` do ``cp a c``, and have branch ``y``
do ``cp b c``. Now the merge has two new encoded files, both of which
refer to ``c`` and have different content. Only conflicting file is
the .passcode, so merge driver can't remove one of the encoded ones.
I could do union, and prompt to manually delete one of the conflicting
files.

pass code init
--------------
I should make ``pass code init`` convert an existing password-store
to ``pass-code`` automatically.

- Fail if ``pass init`` not run already.
- Create ``.passcode`` if doesn't exist.
- Encode current passwords if they exist.
- Check ``.passcode`` and skip encoded ones
- If git repo, make a new branch and do ``git filter-branch`` magic.
- Don't forget to change filenames in commit messages
- ``pass init --path=sub-folder`` is going to cause problems
- Maybe preserve folder structure with ``encoded:*/decoded`` in 
  ``.passcode`` ?
