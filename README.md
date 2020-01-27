ABNF compiler plugin for rebar3
=====

This plugin adds compiler for ABNF to rebar3.

Requirements
------------
This plugin requires rebar 3.7+.

Build
-----

    $ rebar3 compile

Use
---

Add the plugin to your rebar config:

    {plugins, [
        {rebar3_abnf_compiler, {git, "https://github.com/rbkmoney/rebar3_abnf_compiler.git", {tag, "0.1.0"}}}
    ]}.

Following config options supported:
    
    {abnf_opts, [
        binary, % return result in binary instead of list
        verbose % verbose mode
    ]}.
