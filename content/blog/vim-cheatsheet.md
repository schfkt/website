+++
title = "Vim cheatsheet"
author = ["Pavel Ivanov"]
description = "The list of Vim related commands for quick lookup"
lastmod = 2019-10-15T22:59:57+03:00
draft = false
+++

I've been using Vim heavily in the last two month. In order to not waste a lot of time looking up a certain feature or key combination, I came up with the idea to create a cheatsheet page for that. The one that I'll keep updated.

So here it is. I hope you'll find something useful here too ;)


# Vim {#vim}


## CLI {#cli}

-   `vim +PluginInstall` open Vim and run command


## Tabs {#tabs}

-   `gt` go to the next tab
-   `gT` go to the previous tab
-   `<c-w> T` open current buffer in the new tab
-   `:tabedit` open file for editing in a new tab


## Diff {#diff}

-   `:diffget` obtain changes from the other file
-   `:diffput` apply changes to the other file


## Marks {#marks}


## Folds {#folds}

-   `zM`
-   `zm`
-   `zR`
-   `zr`
-   `zC`
-   `zc`
-   `zO`
-   `zo`


## Positioning in the file {#positioning-in-the-file}

-   `zt` position the current line in the top of the window
-   `zz` position the current line in the middle of the window
-   `zb` position the current line in the bottom of the window


# Plugins {#plugins}


## CtrlP {#ctrlp}

-   `<c-t>` open file in a tab
-   `<c-d>` switch to search by file name only


## CtrlSF {#ctrlsf}

-   `<c-c>` stop the search
-   `t` open file in a new tab
-   `T` open file in a new tab, but keep focus on CtrlSF
-   `M` switch view mode (horizontal or vertical)