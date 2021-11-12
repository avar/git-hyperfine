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

It needs the --build option from
<https://github.com/sharkdp/hyperfine/pull/448>, and can benefit from
*-r 1* as well: <https://github.com/sharkdp/hyperfine/pull/447>

To use it you must, instead of:

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

  - \--ghc-debug  
    Emit debugging messages about what we’re doing internally.

  - \--ghc-trace  
    Intrument generated code with "set -x". For use with
    man:git-hyperfine\[1\]*s '--show-output*.

# ALTERED OPTIONS

  - \--build, --prepare, \<command\>  
    Your *--build* command (if any) will be chained behind the build
    command we’ll use to setup the man:git-worktree\[1\].
    
    All of these will be passed through as-is, except we’ll add a thin
    wrapper of *cd \<run-dir\> && …​*.

<!-- end list -->

    git hyperfine -L rev HEAD,HEAD~ -r 2 -b 'echo build: $(pwd)' 'echo run: $(pwd)' -c 'echo cleanup: $(pwd)' -p 'echo prepare: $(pwd)' --show-output

# SEE ALSO

man:hyperfine\[1\]
