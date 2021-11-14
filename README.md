# NAME

git-hyperfine(1) - wrapper around man:hyperfine\[1\], intercepts -L
*\<rev\>*, benchmarks git revisions

# SYNOPSIS

> 
> 
>     git hyperfine [<git-hyperfine-options>] -L rev <comma-delimited-git-revisions> [<hyperfine-options>]
>     git hyperfine [<git-hyperfine-options>] -L rev HEAD1,HEAD0 -r 1 pwd
>     git hyperfine [--ghf-dry-run] --ghf-worktree-xargs [<args>]
>     git hyperfine --ghf-worktree-list

See more examples under [EXAMPLES](#XMPL) below.

# DESCRIPTION

git-hyperfine is a thin wrapper around man:hyperfine\[1\] designed to
make it convenient to benchmark different git revisions within a git
repository.

It *-L rev \<git-revisions\>* and sets up a git-worktree(1) for each one
under a prefix you configure. Providing *-L rev\` is mandatory and will
be used to create the '\<path\>* fed to *git worktree add*. We’ll then
wrap man:hyperfine\[1\] so that any commands are run within this newly
setup worktree.

The rest of the usage is the same as man:hyperfine\[1\] itself, but see
[OPTIONS](#OPT) and [ALTERED OPTIONS](#ALTOPT) for extra options on top,
and details about how we intercept and munge certain options.

It needs the --setup option from
<https://github.com/sharkdp/hyperfine/pull/448>, and some of the
examples here use the recent (as of late 2021) support for *-r 1*.

# DISCUSSION

To test say a \<git-revisions\> of *HEAD<sub>1,HEAD</sub>0* well resolve
those comma-delimited revisions in the current working directory. You’re
assumed to be running this within git repository, if not we’ll die.

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
of directories over multiple runs. We’ll expect that you can re-use them
if you keep testing the last N revisions.

# OPTIONS

All options that *git-hyperfine* interprets are prefixed with *--ghf-*.
Any other option is passed through to man:hyperfine\[1\]. We’ll change
some of them as noted in [ALTERED OPTIONS](#ALTOPT).

  - \--ghf-dry-run  
    Don’t run the man:git-hyperfine\[1\] command, show what would have
    been run.

  - \--ghf-worktree-list  
    A convenience wrapper, runs man:git-worktree\[1\] with *list
    --porcelain* and emits only those paths configured under our
    *hyperfine-run-dir* prefix. Useful for e.g.:
    
        git hyperfine --ghf-worktree-list | xargs -n 1 git worktree remove

  - \--ghf-worktree-xargs  
    A convenience wrapper for piping *--ghf-worktree-list* output to
    man:xargs\[1\]. Equivalent to:
    
        git hyperfine --ghf-worktree-list | xargs -n 1 $(git config hyperfine.xargs-options) <your command>
    
    Use it as e.g.:
    
        git hyperfine --ghf-worktree-xargs git worktree remove
    
    To clean up the worktrees which git-hyperfine will create for
    running benchmarks.
    
    Under *--dry-run* we inject an *echo* before whatever command it is
    you wanted to run.

  - \--ghf-trace  
    Instrument generated code with "set -x". For use with
    man:git-hyperfine\[1\]*s '--show-output*.

  - \--ghf-debug, --ghf-debug-trace  
    For debugging git-hyperfine itself. *--ghf-debug* shows debug output
    about option parsing etc. The *--ghf-debug-trace* turn on *set -x*
    for git-hyperfine itself, as opposed to *--ghf-trace* which’ll only
    do it for your code.

# ALTERED OPTIONS

\<command\>: In addition to being altered for [1](git-worktree) use this
is optional if *hyperfine.hook.command* is defined. See [HOOK
CONFIGURATION](#HOOKCFG).

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

## MANDATORY CONFIGURATION

  - hyperfine.run-dir  
    Mandatory configuration which determines where to place the
    man:git-worktree\[1\] trees we create for resting the *{rev}*
    arguments.
    
    Environment variables are supported, they’re not understood by
    man:git-config\[1\], but we’ll shell *eval()* this value.
    
    A good setting would be:
    
        [hyperfine]
        run-dir = $XDG_RUNTIME_DIR/git-perf

  - hyperfine.xargs-options  
    Options given to man:xargs\[1\] when the “--ghf-worktree-xargs”
    option is used. Set this to *-r* to use the GNU extension to ignore
    empty input. Otherwise supplying e.g. "git worktree remove" will
    show an annoying usage error from [1](git-worktree) if there’s no
    worktrees to operate on.

## HOOK CONFIGURATION\[HOOKCFG\]\]

This will affect all git-hyperfine invocations, but you can use the path
includes in *git config* to limit them, or e.g. set them per-repository.

All of the hooks are arbitrary shell commands (interpolated into the
relevant man:hyperfine\[1\] options).

If they’re defined they’ll be run even if you didn’t provide the
relevant optional *--setup*, *--prepare*, *\<command\>* or *--cleanup*
option.

In the case of *--setup* this wouldn’t matter either way, since
*git-hyperfine* always provides its own *--setup* template, but it might
be unexpected in other cases.

This is so that e.g. the *--cleanup* hook can be (ab)used to optionally
cleanup *git-hyperfine’s own litter, you can even (ab)use it omit the
'\<command\>* name and run the ook instead. In that case the title of
the command will be the value defined in the hook configuration.

  - hyperfine.hook.setup  
    A hook for the *--setup* phase.
    
    I use the *setup* hook to copy a *config.mak* in-place with build
    configuration for *git.git*, and *prepare* can be used to always
    drop FS caches.

  - hyperfine.hook.prepare  
    A hook for the *--prepare* phase.
    
    Can be used to e.g. drop FS caches, as shown in the
    man:hyperfine\[1\] README.md:
    <https://github.com/sharkdp/hyperfine#basic-benchmark>

  - hyperfine.hook.command  
    A hook for the *\<command\>* phase.
    
    It’s probably a bad idea to use this hook for anything, any use of
    it will go into your benchmark results, but it’s here for
    completeness and flexibility.

  - hyperfine.hook.cleanup  
    A hook for the *\<command\>* cleanup phase.
    
    The cleanup hook could be defined to e.g.:
    
        git hyperfine --ghf-worktree-xargs remove

See the *git-hyperfine-gitconfig.cfg* file in the *git-hyperfine*
repository for configuration examples. That’s also available at
<https://gitlab.com/avar/git-hyperfine/-/blob/master/git-hyperfine-gitconfig.cfg>
and
<https://github.com/avar/git-hyperfine/blob/master/git-hyperfine-gitconfig.cfg>

# EXAMPLES

Test two revisions, and show that w we’ll run in our worktree paths:

    git hyperfine -L rev HEAD,HEAD~ -r 2 -s 'echo setup: $(pwd)' 'echo run: $(pwd)' -c 'echo cleanup: $(pwd)' -p 'echo prepare: $(pwd)' --show-output

Show when all of our hooks and commands would be run relative to one
another:

    git -c hyperfine.hook.setup='echo HOOK setup' \
        -c hyperfine.hook.prepare='echo HOOK prepare' \
        -c hyperfine.hook.command='echo HOOK command' \
         -c hyperfine.hook.cleanup='echo HOOK cleanup' \
         hyperfine --show-output -r 2 -L rev HEAD~1,HEAD~0 \
         -s 'echo setup' \
         -p 'echo prepare' \
         -c 'echo cleanup' \
         'git -P log --pretty=reference -1'

# DEPENDENCIES

POSIX shell script. See [COMPATIBILITY](#COMPAT) below.

To install documentation you’ll need man:asciidoctor\[1\].

# COMPATIBILITY

*git-hyperfine* is written in in POSIX shellscript. It should be
compatible with Linux systems, BSDs, OSX, Solaris (not its /bin/sh
though), AIX, HP/UX etc. etc. Any incompatibility is a (probably small
and easily fixed) bug.

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

    make man
    sudo make install-man prefix=/usr

# HIPSTER INSTALLATION

Like piping random code from the Internetz to man:sudo\[1\]? This one’s
for you:

    sudo bash -c "make prefix=$HOME/local HIPSTER=Y install install-man -f<(curl -s -o - https://gitlab.com/avar/git-hyperfine/-/raw/master/Makefile)"

It doesn’t even require man:bash\[1\] (or man:sudo\[1\]), but if you
like to live dangerously.

# AUTHOR

Ævar Arnfjörð Bjarmason

# LICENSE

*git-hyperfine* is triple-licensed under GPL v2.0 or later, MIT License,
and Apache License 2.0 or later.

I.e. a more than generous combination of the licenses of upstream
utilities it uses and extends. See
<https://github.com/sharkdp/hyperfine/#license> and
<https://github.com/git/git/blob/master/COPYING>

# SEE ALSO

man:hyperfine\[1\]

# BUGS

If man:hyperfine\[1\] introduces a new option *git-hyperfine* currently
needs to be updated to know how to pass it through (its option usage is
somewhat irregular).

[HIPSTER INSTALLATION](#HIPSTER) mode will cache the downloaded program
in the current working directory by virtue of being a functioning
*Makefile* under the hood. It should probably download a 1GB tarball
from somewhere instead to provide the full experience.
