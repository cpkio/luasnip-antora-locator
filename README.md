# LuaSnip Antora Locator snippet

This snippet and plugin allows you to build Antora locator URLs on the fly,
allowing you to select only what in each component is *on your hard drive*
(checked out by Git).

Antora locator URL looks like this:

```
git-branch@component:module:family$file-location[]
```

`git-branch` selection is not yet supported.

The plugin requires all of your Antora components to be under one common
directory. Point setup function to this directory. The plugin will scan all the
directories, find Antora components (by `antora.yml`) and load components
name and `/modules` content (component → modules → families → files).

This in-memory structure will be used by the snippet to suggest only what is
actually available to you.

## Requirements

1. LuaFileSystem library (`lfs`) for cross-platform directory traversing

2. `yq` to convert `antora.yml` (Antora component config) to JSON, which is
   parseable by Neovim

Using with [nvim-fzf-ui-select](https://github.com/cpkio/nvim-fzf-ui-select)
plugin is strongly recommended.

## Usage

`require('luasnip-antora-locator').setup([[your-antora-components-directory]])` in your `init.lua`

Set `ft=asciidoc`, input `xref` Luasnip-trigger, choose snippet. Use Tab to switch to next
input field and your mapping of choice to select next snippet choice option.

If components, modules, families or files were added or removed on disk while Neovim is
running, use `:AntoraLocatorUpdate` command to update snippet choices.

## Compatibility

Nvim0.10 introduced breaking changes to API, changing `vim._system()` call to
`vim.system()`. Commits now have tags, noting compatibility changes.
