+++
title = "Vim cheatsheet"
author = ["PI"]
description = "The list of Vim related commands for quick lookup"
date = 2019-10-15
lastmod = 2019-12-07T20:46:42+02:00
draft = false
+++

I've been using Vim heavily in the last two month. In order to not waste a lot of time looking up a certain feature or key combination, I came up with the idea to create a cheatsheet page for that.

So here it is. I hope you'll find something useful here too ;)


# CLI {#cli}

-   `vim +PluginInstall` open Vim and run command


# Tabs {#tabs}

-   `gt` go to the next tab
-   `gT` go to the previous tab
-   `<c-w> T` open current buffer in the new tab
-   `:tabedit` open file for editing in a new tab


# Diff {#diff}

-   `:diffget` obtain changes from the other file
-   `:diffput` apply changes to the other file


# Marks {#marks}


# Folds {#folds}

-   `zk` go to the previous fold
-   `zj` go to the next fold
-   `zM`
-   `zm`
-   `zR`
-   `zr`
-   `zC`
-   `zc`
-   `zO`
-   `zo`


# Positioning in the file {#positioning-in-the-file}

-   Position the current line in:
    -   `zt` the top of the window
    -   `zz` the middle of the window
    -   `zb` the bottom of the window


# CtrlP {#ctrlp}

-   `<c-t>` open file in a tab
-   `<c-v>` open file in a vertical split
-   `<c-x>` open file in a horizontal split
-   `<c-d>` switch to search by file name only


# CtrlSF {#ctrlsf}

-   `<c-c>` stop the search
-   `t` open file in a new tab
-   `T` open file in a new tab, but keep focus on CtrlSF
-   `M` switch view mode (horizontal or vertical)


# vim-signify {#vim-signify}

-   `[c` go to the previous change
-   `]c` go to the next change