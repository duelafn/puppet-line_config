
Puppet line_config Module
=========================

Manipulate individual lines of a file

This module came about when I realized that augeas lenses are tied to
specific config files, hence I could not use it to edit arbitrary ini files
on my system (without creating a custom lens for each one).

This module is trying to be appropriate for line-based config files.
Currently it should be able to handle line-by-line configs, KEY=VALUE, and
INI-style config files. It does not yet support puppet filebuckets or line
ordering (See the TODO file).

I consider this module usable and it works for me on production systems. I
do NOT, however, consider it stable - some changes in behavior may occur
between releases.


Examples (see also examples directory):

    # default provider replaces /^\s*KEY\s*=/ with "KEY=VALUE"
    # default provider ignores lines matching /^\s*#/
    line_config { "/etc/adduser.conf: DHOME":
        path     => "/etc/adduser.conf",
        key      => "DHOME",
        value    => "/nfs/home",
    }

    # sets general.smoothScroll to false.
    # ignores all comment lines
    # will replace any existing (uncommented) general.smoothScroll setting
    line_config { "/home/duelafn/etc/mozilla/user.js: general.smoothScroll":
        provider => "basic",
        path     => "/home/duelafn/etc/mozilla/user.js",
        content  => 'user_pref("general.smoothScroll", false);',
        ignore   => "^\\s*//",
        replace  => "[\\"']general\\.smoothScroll[\\"']",
    }

    # Set a default value only if missing
    line_config { "/etc/abcde.conf: OUTPUTTYPE":
        path     => "/etc/abcde.conf",
        ensure   => "set",
        key      => "OUTPUTTYPE",
        value    => "ogg",
    }


    # Use a define (see examples directory) to make config settings quite nice:
    kdmrc { "NoPassUsers": ensure => "unset" }
    kdmrc { "DefaultUser":
        value => "guest",
        section => "X-:0-Greeter"
    }


Attributes
==========

    line_config { 'resource title':
        path                    => # The path to the file to manage.
        ensure                  => # Whether the line should exist, and if so what...
        content                 => # Line content to insert.
        section                 => # Section of file to restrict search to.
        key                     => # Key name.
        value                   => # Value.
        ignore                  => # Regexp of lines to ignore when searching.
        accept                  => # Regexp matching lines which should be considered equivalent to this value.
        replace                 => # Regexp matching lines which should be replaced by this value.
        replaceonly             => # When true, only insert if the 'replace' regexp matches.
        nofile                  => # Behavior when file does not exist.
    }

## path

The path to the file to manage. Must be fully qualified. This is a required
option.

On Windows, the path should include the drive letter and should use `/` as
the separator character (rather than `\\`).

## ensure

Whether the line should exist, and if so, what exactly to do about it.
Possible values are `present`, `absent`, `set`, `unset`.

* `present` content (or `accepts` pattern) appears in file

* `absent` content (or `accepts` pattern) does not appear in file

* `set` (requires `keyval` feature) the key is set. `value` parameter is
  used only as a default.

* `unset` (requires `keyval` feature) the key is not set. `value` parameter
  is not used.

The default value is `present`

## content

Line content to insert.

Is set to /KEY/`=`/VALUE/ by default for `default` and `ini` providers if
the `key` and `value` attributes are set.

## section

Section of file to restrict search to (requires `section` feature).

The default is any section.

## key

Key name (requires `keyval` feature). Used to construct a default `content`
for the `default` and `ini` providers.

## value

Value (requires `keyval` feature). Used to construct a default `content`
for the `default` and `ini` providers.

## ignore

One or more regexps of lines to ignore when searching.

Is set to `^\\s*#` by default for `default` and `ini` providers.

## accept

One or more regexps matching lines which should be considered equivalent to
this value.

The pattern `^\s*`/KEY/`\s*=['"]?`/VALUE/`['"]?` is appended to this list
for the `ini` provider if the `key` and `value` attributes are set.

## replace

One or more regexps matching lines which should be replaced by this value.

Is set to `^\s*`/KEY/`\s*=` for `default` and `ini` providers if the `key`
attribute is set.

## replaceonly

When true, only insert if the 'replace' regexp matches.

## nofile

Behavior when file does not exist. Possible values are `error` or `ignore`.

* `error` fail if file does not exist.

* `ignore` to skip configuration if file is missing.

The default value is `error`


Providers
=========

## `basic`

Basic provider with no features.

## `default`

Shell-like files.

* Supports `keyval` feature. Sets "key=value". Does no quoting of either
  key or value.

* Sets a default `ignore` value of `^\\s*#`, typical shell comments.

## `ini`

INI files.

* Supports `section` feature. Sets the line or key/value in the named
  section.

* Supports `keyval` feature. Sets "key=value". Does no quoting of either
  key or value.

* Sets a default `ignore` value of `^\\s*#`, typical shell comments.


Provider Features
=================

Available features:

* `keyval` -- provider can set lines by `key` and `value` attributes as a
  replacement for `content`.

* `section` -- provider can add lines to different sections of the file.

Provider | keyval | section
-------- | -----  | -------
basic    |        |
default  |   X    |
ini      |   X    |    X
