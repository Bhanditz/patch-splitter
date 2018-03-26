# patch-splitter

This takes the output of `git log -p --reverse --binary --pretty=fuller --parents --full-history -m` and turns it into a kotlin script that will produce an identical CloudEFS repository; this can be used for migrations or for testing purposes.

# Running

It does not yet run.

# Build Instructions

You need Haskell Stack to build this; instructions to get that can be found at [https://docs.haskellstack.org/en/stable/README/](https://docs.haskellstack.org/en/stable/README/).

The command to build the project is `stack build`, run in the base project directory. You will need a reasonably recent version of haskell stack, so you may need to run `stack upgrade` first if you have a version earlier than 1.6.

