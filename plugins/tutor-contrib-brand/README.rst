.. _tutor_contrib_brand:

##################
Tutor Brand Plugin
##################

This plugin orchestrates Open edX branding from a versioned ``brand-openedx``-style repository.

It works alongside ``tutor-contrib-paragon``:

* ``tutor-contrib-paragon`` remains responsible for serving Paragon theme CSS.
* ``tutor-contrib-brand`` prepares the brand repository, runs the Paragon build flow, appends CSS overrides, copies font assets, and serves non-Paragon assets such as logos.

Configuration
=============

The main inputs are:

* ``BRAND_REPOSITORY``: local path relative to Tutor root, or a git repository URL.
* ``BRAND_VERSION``: branch, tag, or commit to use.

Logo settings accept either:

* an absolute URL, or
* a path relative to the brand repository root.

Usage
=====

1. Enable the plugins::

    tutor plugins enable paragon brand

2. Point the plugin at your brand repository::

    tutor config save --set BRAND_REPOSITORY=brand-openedx --set BRAND_VERSION=jiltarjih

3. Build the required images::

    tutor images build paragon-builder brand-builder

4. Run the orchestration command::

    tutor local do brand-build

5. Restart the MFE service if needed::

    tutor local restart mfe

Served logo URLs
================

The plugin serves package-root logo assets under::

    http://apps.local.openedx.io/static/brand/

Examples::

    http://apps.local.openedx.io/static/brand/logo.svg
    http://apps.local.openedx.io/static/brand/logo-white.svg
