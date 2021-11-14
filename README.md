# NAME

git-hyperfine(1) - wrapper around man:hyperfine\[1\], intercepts -L
*\<rev\>*, benchmarks git revisions

# SYNOPSIS

Instead of:

    hyperfine [<hyperfine-options>]

Do:

    git hyperfine -L rev <git-revisions> [<hyperfine-options>]

# DESCRIPTION

This is a wrapper around man:hyperfine\[1\] which intercepts *-L rev
\<git-revisions\>* and sets up a git-worktree(1) for each one.

It needs the --setup option from
<https://github.com/sharkdp/hyperfine/pull/448>, and can benefit from
*-r 1* as well: <https://github.com/sharkdp/hyperfine/pull/447>

To test say a \<git-revisions\> of *HEAD<sub>1,HEAD</sub>0* well resolve
those comma-delimited revisions in the current working directory (which
is assumed to be a git repository, or we’ll die).

We’ll then expect a *hyperfine.run-dir* in your git-config(1) of e.g.
(we’ll *eval* it, so you can use an env variable name):

    [hyperfine]
    run-dir = $XDG_RUNTIME_DIR/git-perf

Which, on e.g. modern systemd-using system will resolve to a ramdisk
directory such as */run/user/1001/git-perf*. We’ll then create (with
*git worktree add*) both of:

    /run/user/1001/git-perf/HEAD~0
    /run/user/1001/git-perf/HEAD~1

Note that we use those literal names, i.e. *HEAD\~0*, not whatever *git
rev-parse HEAD\~0*. This is so that we won’t create an arbitrary number
of directories. We’ll expect that you can re-use them if you keep
testing the last N revisions.

# OPTIONS

All options that *git-hyperfine* interprets are prefixed with *--ghf-*.
Any other option is passed through to man:hyperfine\[1\]. We’ll change
some of them as noted in [ALTERED OPTIONS](#ALTOPT).

  - \--ghf-debug  
    Emit debugging messages about what we’re doing internally.

  - \--ghf-trace  
    Instrument generated code with "set -x". For use with
    man:git-hyperfine\[1\]*s '--show-output*.

  - \--ghf-dry-run  
    Don’t run the man:git-hyperfine\[1\] command, show what would have
    been run.

  - \--ghf-worktree-list  
    A convenience wrapper, runs man:git-worktree\[1\] with *list
    --porcelain* and emits only those paths configured under our
    *hyperfine-run-dir* prefix. Useful for e.g.:
    
        git hyperfine --ghf-worktree-list | xargs -n 1 git worktree remove

  - \--ghf-worktree-xargs  
    A convenience wrapper for piping 'ghf-worktree-list to the above
    man:xargs\[1\] command. Use it as e.g:
    
        git hyperfine --ghf-worktree-xargs remove
    
    Which will be the equivalent of the above command.

# ALTERED OPTIONS

  - \--help, --version  
    git-hyperfine’s help and version output. The help output is the raw
    asciidoc of the installed man page.

  - \--setup, --prepare, \<command\>  
    Your *--setup* command (if any) will be chained behind the setup
    command we’ll use to setup the man:git-worktree\[1\].
    
    All of these will be passed through as-is, except we’ll add a thin
    wrapper of *cd \<run-dir\> && …​*.

  - \-L, --parameter-list  
    Passed through as-is, except as a sanity check we’ll die if you
    don’t create a *-L rev …​* option. Our *--setup* option requires
    it to work.

  - \-n, --command-name  
    You’re not allowed to supply this anymore, as we’ll need it to
    relabel our ugly generated *cd \<x\> && …​* command name.

# CONFIGURATION

This command can be configured through man:git-config\[1\], all the
options are in the *hyperfine.\** namespace:

  - hyperfine.run-dir  
    Mandatory configuration which determines where to place the
    man:git-worktree\[1\] trees we create for resting the *{rev}*
    arguments.
    
    Environment variables are supported, they’re not understood by
    man:git-config\[1\], but we’ll shell *eval()* this value.
    
    A good setting would be:
    
        [hyperfine]
        run-dir = $XDG_RUNTIME_DIR/git-perf

See the *git-hyperfine-gitconfig.cfg* file in the *git-hyperfine*
repository for configuration examples. That’s also available at
<https://gitlab.com/avar/git-hyperfine/-/blob/master/git-hyperfine-gitconfig.cfg>
and
<https://github.com/avar/git-hyperfine/blob/master/git-hyperfine-gitconfig.cfg>

# EXAMPLES

Test two revisions, and show that w we’ll run in our worktree paths:

    git hyperfine -L rev HEAD,HEAD~ -r 2 -s 'echo setup: $(pwd)' 'echo run: $(pwd)' -c 'echo cleanup: $(pwd)' -p 'echo prepare: $(pwd)' --show-output

# DEPENDENCIES

POSIX shell script. See [COMPATIBILITY](#COMPAT) below.

To install documentation you’ll need man:asciidoctor\[1\].

# COMPATIBILITY

*git-hyperfine* is written in in POSIX shellscript. It should be
compatible with Linux systems, BSDs, OSX, Solaris (not its /bin/sh
though), AIX, HP/UX etc. etc. Any incompatibility is a (probably small
and easily fixed) bug.

# AUTHOR

Ævar Arnfjörð Bjarmason

# INSTALLATION

"git clone" the repository and add it to your *$PATH* for a quick
try-out (or don’t add it to *$PATH* and provide the full path name).

For a proper installation there’s an old-school GNU make *Makefile* in
the top-level, to build and see what we’d install do:

    make install INSTALL='@echo install'

And to install it for real drop the *INSTALL* parameter, e.g.:

    sudo make install prefix=/usr

To build and install documentation add *install-man* to that (only the
latter target is needed). You can provide *ASCIIDOCTOR* to be the path
to your *asciidoctor* (or compatible) program.

make man sudo make install-man prefix=/usr ---

# HIPSTER INSTALLATION

Like piping random code from the Internetz to man:sudo\[1\]? This one’s
for you:

    sudo bash -c "make prefix=$HOME/local HIPSTER=Y install install-man -f<(curl -s -o - https://gitlab.com/avar/git-hyperfine/-/raw/master/Makefile)"

It doesn’t even require man:bash\[1\] (or man:sudo\[1\]), but if you
like to live dangerously.

# BUGS

If man:hyperfine\[1\] introduces a new option *git-hyperfine* currently
needs to be updated to know how to pass it through (its option usage is
somewhat irregular).

[HIPSTER INSTALLATION](#HIPSTER) mode will cache the downloaded program
in the current working directory by virtue of being a functioning
*Makefile* under the hood. It should probably download a 1GB tarball
from somewhere instead to provide the full experience.

# LICENSE

*git-hyperfine* is triple-licensed under GPL v2.0 or later, MIT License,
and Apache License 2.0 or later.

I.e. a more than generous combination of the licenses of upstream
utilities it uses and extends. See
<https://github.com/sharkdp/hyperfine/#license> and
<https://github.com/git/git/blob/master/COPYING>

# SEE ALSO

man:hyperfine\[1\]
