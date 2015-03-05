DEPRECATED
==========

The contents of this repo have been merged into oc-chef-pedant.

All test development should be done there. This repository is maintained
only for support of older versions, and tests modified here will not be
pulled into oc-chef-pedant.

Chef Pedant
===========

This repo contains the full integration test suite for Chef Server


It is included with the omnibus build of Chef Server.

To run the suite from an Omnibus Server Build:

    (sudo) chef-server-ctl test

Setting up precommit hooks
==========================

It's strongly advised that you link the included pre-commit.sh in as
a precommit hook, in order to prevent accidentally committing code
containing a :focus tag.

To do so:

    $ cd .git/hooks
    $ ln -s ../../pre-commit.sh pre-commit

If you ever need to skip this commit hook ( such as when using :focus in
documentation) you can use:

    $ git commit -n

