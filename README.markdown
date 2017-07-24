# pasteurize.vim

[Common User Access][cua] (CUA) cut, copy, and paste for Vim.

## Rationale

The default keybindings Vim provides for interacting with the system clipboard
are quite cumbersome: in normal mode, actions involving the clipboard must be
prefixed by `"+`. In insert mode, Vim provides several keybindings, but these
all have problems: `<C-R>+` interprets control characters, so is unsafe;
`<C-R><C-R>+` inserts linebreaks that don't exist in the original text; and
`<C-R><C-O>+` and `<C-R><C-P>+` can paste outside of surrounding quote marks.
Each of these is also cumbersome to type.

This plugin attempts to simplify access to the clipboard in the spirit of
`mswin.vim`, which is included (but not loaded) in stock Vim. `mswin.vim`
itself is not suitable because it goes beyond mappings that deal with the
clipboard, and also has its own problems with pasting.

## Desiderata

1. Clobber no more keybindings than `mswin.vim`
2. Provide secure pasting, i.e. ASCII control sequences should not be
   interpreted
3. Keep CUA keybindings
4. If the user pastes when the cursor is between two quote marks, the pasted
   text is always inserted between the two quote marks

I think these desiderata are pretty "commonsense": gedit follows all of them.

## Features

In addition to following the desiderata listed above, this plugin offers the
following:

-   Stripping of leading and trailing newlines. If text is copied in Vim using
    visual line mode and standard mappings (e.g. `V"+y`), a trailing newline is
    included in the clipboard. I rarely want this, so this plugin strips these
    newlines, both when copying out of Vim and when pasting into Vim. If you
    want to disable this, add `let g:pasteurize_no_strip_newlines = 1` to your
    vimrc.

-   Selective mappings. All mappings are provided using `<Plug>` mappings. If
    you want to disable the provided mappings so you can map them on your own,
    just add `let g:pasteurize_no_mappings = 1` to your vimrc.

## Installation

The plugin works with the major plugin and runtime path managers.

With [vim-plug][plug], place in your vimrc:

```vim
Plug 'riceissa/vim-pasteurize'
```

Then run `:PlugInstall`.

With [pathogen.vim][pathogen]:

    cd ~/.vim/bundle && \
    git clone https://github.com/riceissa/vim-pasteurize.git

## License

Distributed under the same terms as Vim itself. See `:help license`.

[cua]: https://en.wikipedia.org/wiki/IBM_Common_User_Access
[pathogen]: https://github.com/tpope/vim-pathogen
[plug]: https://github.com/junegunn/vim-plug
