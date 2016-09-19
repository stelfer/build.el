# build.el

## Overview
This is a wrapper around the built-in emacs compile functionality. This works for Makefile projects only at this point.  It works well with `helm-mode` to manage most of the menus, and `projectile-mode` to manage projects.  The main useful functions are:

| Function | Description |
| --- | --- |
| `build-project()` | Builds the projectile project |
| `build-target-from-current()` | Uses `make -np` to discover possible targets related to the current buffer |
| `build()` | Runs the compilation |


In my own emacs config, I use the following two key bindings
```
(define-key my-c-mode-map (kbd "C-c") 'build)
(define-key my-c-mode-map (kbd "m") 'build-target-from-current)
```
This allows `C-c C-c` to replace the default compile/recompile.  In a lot of IDEs this would be bound to `f5`. Then `C-c m` is used to discover possible Makefile-based targets related to the current buffer.

## Getting Started
To get started, you need to make sure you have `projectile-mode` installed.  Then just put `build.el` in your path and add
```
(require build)
```
to your emacs config.
