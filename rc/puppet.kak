# https://puppet.com
#

# Detect the filetype
hook global BufCreate .*\.(pp) %{
    set-option buffer filetype puppet
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group puppet-highlight global WinSetOption filetype=puppet %{
    add-highlighter window/puppet ref puppet
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/puppet}
}

hook global WinSetOption filetype=puppet %~
    require-module puppet

    hook window InsertChar \n -group puppet-indent puppet-indent-on-new-line
    hook window InsertChar [)}\]] -group puppet-indent puppet-indent-on-closing-matching
    hook window ModeChange insert:.* -group puppet-trim-indent %{ try %{ execute-keys -draft \; <a-x> s ^\h+$ <ret> d } }

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window puppet-.+ }
~

# delimiter stolen from rc/filetye/java.kak
provide-module puppet %§

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
    keywords="${keywords} application case consumes define produces site type title name"
    keywords="${keywords} unmounted role configured file directory link on_failure"

    # control
    control="and in or if elsif else case default unless"

    # functions
    functions="abs alert all assert_type binary_file break call camelcase capitalize"
    functions="${functions} ceiling chomp chop compare contain conver_to create_resources"
    functions="${functions} crit debug defined dig digest downcase each emerg empty epp"
    functions="${functions} err eyaml_lookup_key fail file filter find_file find_template"
    functions="${functions} flatten floor fqdn_rand generate get get_var group_by hiera"
    functions="${functions} hiera_array hiera_hash hiera_include hocon_data import include"
    functions="${functions} index info inline_epp inline_template join json_data keys"
    functions="${functions} length lest lookup lstrip map match max md5 min module_directory"
    functions="${functions} new next notice partition realize reduce regsubst"
    functions="${functions} require return reverse_each round rstrip scanf sha1 sha256"
    functions="${functions} shellquote size slice sort split sprintf step strftime strip"
    functions="${functions} tag tagged template then tree_each unique unwrap upcase values"
    functions="${functions} versioncmp warning with yaml_data"

    # types
    types="Any Array Binary Boolean Callable Catalogentry CatalogEntry Class Collection"
    types="${types} Data Default Deferred Enum"
    types="${types} Float Hash Integer NotUndef Numeric Optional Pattern Resource"
    types="${types} Regexp Runtime Scalar String Struct Timespan Tuple Type Undef Variant"

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
        try %< execute-keys -draft k x <a-x> s ^\h*#\h* <ret> y jgh P >
        # preserve previous line indent
        try %< execute-keys -draft \; K <a-&> >
        # cleanup trailing whitespaces from previous line
        try %< execute-keys -draft k x <a-x> s \h+$ <ret> d >
        # indent after line ending with :{([
        try %< execute-keys -draft k x <a-x> <a-k> [:{(\[]$ <ret> j <a-gt> >
    >
>

define-command -hidden puppet-indent-on-closing-matching %~
    # align to opening matching brace when alone on a line
    try %= execute-keys -draft -itersel <a-h><a-k>^\h*\Q %val{hook_param} \E$<ret> mGi s \A|.\z<ret> 1<a-&> =
~

define-command hiera-grep -params 0..1 -docstring "Search for a regex in the local repository hiera data" %{
    # assume that we're in a control repository layout, and search under data/
    #
    # we also have the option of looking at other locations - we can even look
    # for hiera.yaml and parse it for the exact location to search, but as a
    # starting point we just look under data/
    #
    # since the default grep implementation doesn't give any option for us to
    # reuse, we're cutting and pasting here
    evaluate-commands %sh{
        if [ $# -eq 0 ]; then
            set -- ${kak_selection}
        fi

        dpath='data'
        output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-grep.XXXXXXXX)/fifo
        mkfifo ${output}
        ( ${kak_opt_grepcmd} "$@" ${dpath}| tr -d '\r' > ${output} 2>&1 & ) > /dev/null 2>&1 < /dev/null

        printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
                edit! -fifo ${output} -scroll *grep*
                set-option buffer filetype grep
                set-option buffer grep_current_line 0
                hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
            }"
    }
}

define-command find-module-impl -params 0..1 -docstring "Find and open the file implementing the selected module name" %{
    # we need to assume that we're dealing with a control repository layout,
    # with code under site/ and manifests/. We could be really smart and find
    # the module search path specified in the environment.conf file, but it's
    # not really worth it.
    #
    # so, the implementation here is that we grep for `(class|define) foo::bar`
    # in those directories, opening the results in a grep buffer.
    evaluate-commands %sh{
        if [ $# -eq 0 ]; then
            set -- ${kak_selection}
        fi

        paths="site manifests"
        output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-grep.XXXXXXXX)/fifo
        mkfifo ${output}
        for path in $paths; do
            ( ${kak_opt_grepcmd} "(class|define) $1" ${path}|tr -d '\r' > ${output} 2>&1 & ) >/dev/null 2>&1 < /dev/null
        done

        printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
                edit! -fifo ${output} -scroll *module-impl*
                set-option buffer filetype grep
                set-option buffer grep_current_line 0
                hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
            }"
    }
}

§
