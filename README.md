# Pandoctitude

## Description

`Pandoctitude` is a Vim plugin that provides the proper attitude for working
with Pandoc-like documents: motions, text-objects, and syntax highlighting for
Pandoc mode.

### Key Mappings

- `gG`        : Report header hierarchy at current location.
- `[[`        : Move to *previous* header (of any level) (for `{count`} repeats).
- `]]`        : Move to *next* header (of any level) (for `{count`} repeats).
- `[=`        : Move to *previous* sibling header (for `{count`} repeats).
- `]=`        : Move to *next* sibling header (for `{count`} repeats).
- `[.`        : Move to header of current section.
- `[-`        : Move to parent header of current section (for `{count`} repeats).
- `{count}[_` : Move to *previous* line with header-level of `{count}`.
- `{count}]_` : Move to *next* line with header-level of `{count}`.
- `<#`        : Decrease heading level (promote header).
- `>#`        : Increase heading level (demote header).

### Commands

- `:Toc` : Produce a table-of-contents in the location list.

### Customization

If you are unhappy with the default key-mappings you can provide your own by
defining custom mappings in your _`.vim/after/ftplugin/pandoc.vim`_. For
example to replicate the default mappings, you would define the following:

~~~
    map <buffer> gG <Plug>(PandoctitudeEchoLocation)
    map <buffer> [[ <Plug>(PandoctitudeMoveToPreviousHeader)
    map <buffer> ]] <Plug>(PandoctitudeMoveToNextHeader)
    map <buffer> [= <Plug>(PandoctitudeMoveToPreviousSiblingHeader)
    map <buffer> ]= <Plug>(PandoctitudeMoveToNextSiblingHeader)
    map <buffer> [. <Plug>(PandoctitudeMoveToCurrentHeader)
    map <buffer> [- <Plug>(PandoctitudeMoveToParentHeader)
    map <buffer> [_ <Plug>(PandoctitudeMoveToPreviousAbsoluteHeaderLevel)
    map <buffer> ]_ <Plug>(PandoctitudeMoveToNextAbsoluteHeaderLevel)
    map <buffer> <# <Plug>(PandoctitudeHeaderPromote)
    map <buffer> ># <Plug>(PandoctitudeHeaderDemote)
~~~

## Installation

### [pathogen.vim](https://github.com/tpope/vim-pathogen)

~~~
    $ cd ~/.vim/bundle
    $ git clone git://github.com/jeetsukumaran/vim-pandoctitude.git
~~~


### [Vundle](https://github.com/gmarik/vundle.git)

~~~
    :BundleInstall jeetsukumaran/vim-pandoctitude
~~~

Add the line below into your _.vimrc_.

~~~
    Bundle 'jeetsukumaran/vim-pandoctitude'
~~~

## Acknowledgements

Pandoctitude uses code modified from the following:

    https://github.com/plasticboy/vim-markdown.git
    https://github.com/vim-pandoc/vim-pandoc.git
