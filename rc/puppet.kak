# https://puppet.com
#

# Detect the filetype
hook global BufCreate .*\.(pp) %{
    set-option buffer filetype puppet
}

add-highlighter shared/puppet regions
add-highlighter shared/puppet/code default-region group
add-highlighter shared/puppet/single_string region "'"   (?<!\\)(\\\\)*'  fill string
add-highlighter shared/puppet/comment       region '#'   '$'              fill comment

add-highlighter shared/puppet/double_string region '"'   (?<!\\)(\\\\)*"  group
add-highlighter shared/puppet/double_string/fill fill string
add-highlighter shared/puppet/double_string/interpolation regex \$\{(::)?[a-z][\w_]*\} 0:value

add-highlighter shared/puppet/heredoc_string region -match-capture '@\("?([\h\w_]+)"?(/\w*)?\)' '^\h*(?:\|\h*)?-?\h*([\h\w_]+)$' group
add-highlighter shared/puppet/heredoc_string/fill fill string
add-highlighter shared/puppet/heredoc_string/interpolation regex \$\{(::)?[a-z][\w_]*\} 0:value

evaluate-commands %sh{
    # type definitions
    typedef="class define node inherits"

    # keywords
    keywords="include present absent purged latest installed running stopped mounted"
    keywords="${keywords} unmounted role configured file directory link on_failure"

    # control
    control="if elsif else case default unless"

    # functions
    functions="alert create_resources crit debug emerg err fail include info notice realize"
    functions="${functions} require search tag warning defined file fqdn_rand "
    functions="${functions} generate inline_template regsubst sha1 shellquote"
    functions="${functions} split sprintf tagged template versioncmp lookup hiera"

    # types
    types="Any Array Boolean Callable Catalogentry Collection Data Default Enum"
    types="${types} Float Hash Integer Numeric Optional Pattern Regexp Scalar"
    types="${types} String Struct Tuple Type Undef Variant"

    # built-in resources
    resources="augeas computer cron exec file filebucket group host interface"
    resources="${resources} k5login macauthorization mailalias maillist mcx"
    resources="${resources} mount nagios_command nagios_contact"
    resources="${resources} nagios_contactgroup nagios_host"
    resources="${resources} nagios_hostdependency nagios_hostescalation"
    resources="${resources} nagios_hostextinfo nagios_hostgroup"
    resources="${resources} nagios_service nagios_servicedependency"
    resources="${resources} nagios_serviceescalation nagios_serviceextinfo"
    resources="${resources} nagios_servicegroup nagios_timeperiod notify"
    resources="${resources} package resources router schedule scheduled_task"
    resources="${resources} selboolean selmodule service ssh_authorized_key"
    resources="${resources} sshkey stage tidy user vlan yumrepo zfs zone"
    resources="${resources} zpool"

    # Special values
    special="true false undef"

    join() { sep=$2; eval set -- $1; IFS="$sep"; echo "$*"; }

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=puppet %{
        set-option window static_words $(join "${typedef} ${keywords} ${types} ${functions} ${resources} ${special} ${control}" ' ')'
    }"

    # Highlight keywords
    printf %s "
        add-highlighter shared/puppet/code/typedef regex '\b($(join "${typedef}" '|'))\b' 0:module
        add-highlighter shared/puppet/code/keywords regex '\b($(join "${keywords}" '|'))\b' 0:keyword
        add-highlighter shared/puppet/code/control regex '\b($(join "${control}" '|'))\b' 0:operator
        add-highlighter shared/puppet/code/functions regex '\b($(join "${functions}" '|'))\b\s*\(' 1:builtin
        add-highlighter shared/puppet/code/types regex '\b($(join "${types}" '|'))\b' 0:type
        add-highlighter shared/puppet/code/resources regex '\b($(join "${resources}" '|'))\b' 0:module
        add-highlighter shared/puppet/code/special regex '\b($(join "${special}" '|'))\b' 0:meta
    "
}

add-highlighter shared/puppet/code/variabledef regex '(^|\W)(\$[a-z][\w_]*)\s*=\s*([^,]+),?' 1:variable 2:value
add-highlighter shared/puppet/code/variableref regex '(\$(::)?[a-z][\w_]*(::[a-z][\w_]*)*)' 0:value
add-highlighter shared/puppet/code/attribute regex '\b([a-z][\w_]*)\s*=>\s*' 0:attribute
add-highlighter shared/puppet/code/instance regex '(((::)?[a-z][\w_]*(::[a-z][\w_]*)*)\b(?:\s+))\{|$' 1:module
add-highlighter shared/puppet/code/deftype regex '\b(define)\s+([\S]+)\s+[{(]' 1:type 2:module
add-highlighter shared/puppet/code/classdef regex '\b(class)\s+([\S]+)\s+[{(]' 1:type 2:module
add-highlighter shared/puppet/code/operators regex (?<=[\w\s\d'"_])(<|<=|=|==|>=|=>|>|=~|!=|!~|\bin\b|\band\b|\bor\b|\?|!|\+|-|/|\*|%|<<|>>|) 0:operator

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden puppet-indent-on-new-line %<
    evaluate-commands -draft -itersel %<
        # copy '#' comment prefix and following white spaces
        try %< execute-keys -draft k <a-x> s ^\h*#\h* <ret> y jgh P >
        # preserve previous line indent
        try %< execute-keys -draft \; K <a-&> >
        # cleanup trailing whitespaces from previous line
        try %< execute-keys -draft k <a-x> s \h+$ <ret> d >
        # indent after line ending with :{([
        try %< execute-keys -draft k <a-x> <a-k> [:{(\[]$ <ret> j <a-gt> >
    >
>

define-command -hidden puppet-indent-on-closing-matching %~
    # align to opening matching brace when alone on a line
    try %= execute-keys -draft -itersel <a-h><a-k>^\h*\Q %val{hook_param} \E$<ret> mGi s \A|.\z<ret> 1<a-&> =
~

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group puppet-highlight global WinSetOption filetype=puppet %{
    add-highlighter window/puppet ref puppet
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/puppet}
}

hook global WinSetOption filetype=puppet %~
    hook window InsertChar \n -group puppet-indent puppet-indent-on-new-line
    hook window InsertChar [)}\]] -group puppet-indent puppet-indent-on-closing-matching
    hook window ModeChange insert:.* -group puppet-trim-indent %{ try %{ execute-keys -draft \; <a-x> s ^\h+$ <ret> d } }

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window puppet-.+ }
~
