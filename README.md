# puppet.kak

**puppet.kak** provides basic ![Puppet](https://puppet.com) language support
for the ![Kakoune](http://kakoune.org) editor.

# Installation

If you're using ![plug.kak](https://github.com/andreyorst/plug.kak) add this
to your `kakrc`:

```kak
plug "sjjf/puppet.kak"
```

Alternatively you can simply clone the repository somewhere and directly
`source` the `rc/puppet.kak` file from your `kakrc`.

# Linting with `puppet-lint`

`puppet-lint` doesn't integrate very neatly with Kakoune, mostly because of
the way that Kakoune presents the current buffer for linting - it writes the
buffer contents to a temporary file, which it then calls the linter on.
`puppet-lint` by default complains about the autoload layout when called this
way, because it can't find the expected directory structure. To avoid having
that false positive cluttering up things I add the following to my `kakrc`:

```kak
set-option window lintcmd 'puppet-lint --no-autoloader_layout-check --log-format "%{filename}:%{line}:%{column}: %{kind}: %{message}"'
```

# Formatting with `puppet-lint`

Kakoune also doesn't run its formatter commands in a way that `puppet-lint`
likes - `puppet-lint` wants to fix the file in place, but Kakoune expects
its formatters to be filters. To get something that works I've included a
small python script, `kak-puppet-fix`, which wraps `puppet-lint --fix` so that
it can be used as a filter. This can be used as the formatcmd by putting the
`kak-puppet-fix` script in your path, and adding the following to your
`kakrc`:

```kak
set-option window formatcmd 'kak-puppet-fix'
```

# Example `kakrc`

```kak
hook global WinSetOption filetype=puppet %{
    set-option window indentwidth 2
    set-option window formatcmd 'kak-puppet-fix'
    set-option window lintcmd 'puppet-lint --no-autoloader_layout-check --log-format "%{filename}:%{line}:%{column}: %{kind}: %{message}"'
    # if using puppet-editor-services
    lsp-start
    lsp-auto-hover-enable
}
```

# License

See the UNLICENSE file.
