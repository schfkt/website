+++
title = "Vim cheatsheet"
date = 2019-10-15
lastmod = 2020-08-23T20:45:54+03:00
draft = false
+++

I've been using Vim heavily in the last two month. In order to not waste a lot of time looking up a certain feature or key combination, I came up with the idea to create a cheatsheet page for that.

So here it is. I hope you'll find something useful here too ;)

<!--more-->


# CLI {#cli}

-   `vim +PluginInstall` open Vim and run command


# Splits {#splits}

-   Move split window:
    -   `<c-w> H` left
    -   `<c-w> J` down
    -   `<c-w> K` up
    -   `<c-w> L` right


# QuickFix list {#quickfix-list}

QuickFix list contains the list of items. For example, if you use YouCompleteMe to find all the variable references, the result is populated into the QuickFix list. The following commands are used to manage the list:

-   `:copen` open the list
-   `:cclose` close the list
-   `:cnext` go to the next item
-   `:cprev` go to the previous item
-   `:colder` open the previous content of QuickFix (yes, it has history)
-   `:cnewer` open the next context of QuickFix


# Tabs {#tabs}

-   `gt` go to the next tab
-   `gT` go to the previous tab
-   `5gt` go to tab 5
-   `<c-w> T` open current buffer in the new tab
-   `:tabedit` open file for editing in a new tab


# Diff {#diff}

-   `:diffget` obtain changes from the other file
-   `:diffput` apply changes to the other file


# Folds {#folds}

-   Go to:
    -   `zk` the previous fold
    -   `zj` the next fold
-   `zm` fold one level more
-   `zM` close all folds
-   `zr` reduce folding by one level
-   `zR` open all folds
-   `zc` close one fold under the cursor
-   `zC` close all folds under the cursor recursively
-   `zo` open one fold under the cursor
-   `zO` open all folds under the cursor recursively

# Positioning in the file {#positioning-in-the-file}

-   Position the current line in:
    -   `zt` the top of the window
    -   `zz` the middle of the window
    -   `zb` the bottom of the window

# CtrlSF {#ctrlsf}

-   `<c-c>` stop the search
-   `t` open file in a new tab
-   `T` open file in a new tab, but keep focus on CtrlSF
-   `M` switch view mode (horizontal or vertical)


# vim-signify {#vim-signify}

-   `[c` go to the previous change
-   `]c` go to the next change
