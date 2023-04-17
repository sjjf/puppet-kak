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

    # functions - built-in
    bi_functions="abs alert all annotate any assert_type binary_file break call camelcase"
    bi_functions="${bi_functions} capitalize ceiling chomp chop compare contain convert_to"
    bi_functions="${bi_functions} create_resources crit debug defined dig digest downcase"
    bi_functions="${bi_functions} each emerg empty epp err eyaml_lookup_key fail file filter"
    bi_functions="${bi_functions} find_file find_template flatten floor fqdn_rand generate"
    bi_functions="${bi_functions} get getvar group_by hiera hiera_array hiera_hash hiera_include"
    bi_functions="${bi_functions} hocon_data import include index info inline_epp inline_template"
    bi_functions="${bi_functions} join json_data keys length lest lookup lstrip map match max"
    bi_functions="${bi_functions} md5 min module_directory new next notice partition realize"
    bi_functions="${bi_functions} reduce regsubst require return reverse_each round rstrip scanf"
    bi_functions="${bi_functions} sha1 sha256 shellquote size slice sort split sprintf step"
    bi_functions="${bi_functions} strftime strip tag tagged template then tree_each type unique"
    bi_functions="${bi_functions} unwrap upcase values versioncmp warning with yaml_data"

    # functions - stdlib
    sl_functions="any2array any2bool assert_private base64 basename batch_escape bool2num bool2str"
    sl_functions="${sl_functions} clamp concat convert_base count deep_merge defined_with_params"
    sl_functions="${sl_functions} delete delete_at delete_regex delete_undef_values delete_values"
    sl_functions="${sl_functions} deprecation difference dirname dos2unix enclose_ipv6 ensure_packages"
    sl_functions="${sl_functions} ensure_resource ensure_resources fact fqdn_rand_string fqdn_rotate"
    sl_functions="${sl_functions} fqdn_uuid get_module_path getparam getvar glob grap has_interface_with"
    sl_functions="${sl_functions} has_ip_address has_ip_network intersection is_a is_absolute_path"
    sl_functions="${sl_functions} is_array is_bool is_domain_name is_email_address is_float"
    sl_functions="${sl_functions} is_function_available is_hash is_integer is_ip_address is_ipv4_address"
    sl_functions="${sl_functions} is_ipv6_address is_mac_address is_numeric is_string"
    sl_functions="${sl_functions} join_keys_to_values load_module_metadata loadjson loadyaml member"
    sl_functions="${sl_functions} merge num2bool os_version_gte parsehocon parsejson parsepson parseyaml"
    sl_functions="${sl_functions} pick pick_default powershell_escape prefix pry pw_hash range"
    sl_functions="${sl_functions} regexescape reject reverse seeded_rand seeded_rand_string shell_escape"
    sl_functions="${sl_functions} shell_join shell_split shuffle sprintf_hash squeeze"
    sl_functions="${sl_functions} stdlib::deferrable_epp stdlib::end_with stdlib::ensure stdlib::extname"
    sl_functions="${sl_functions} stdlib::ip_in_range stdlib::start_with stdlib::str2resource"
    sl_functions="${sl_functions} stdlib::xml_encode str2bool str2saltedpbkdf2 str2saltedsha512 suffix"
    sl_functions="${sl_functions} swapcase time to_bytes to_json to_json_pretty to_python to_ruby"
    sl_functions="${sl_functions} to_toml to_yaml type_of union unix2dos uriescape"
    sl_functions="${sl_functions} validate_absolute_path validate_array validate_augeas valicate_bool"
    sl_functions="${sl_functions} validate_cmd validate_domain_name validate_email_address"
    sl_functions="${sl_functions} validate_hash validate_integer validate_ip_address"
    sl_functions="${sl_functions} validate_ipv4_address validate_ipv6_address validate_legacy"
    sl_functions="${sl_functions} validate_numeric validate_re validate_slength validate_string"
    sl_functions="${sl_functions} validate_x509_rsa_key_pair values_at zip"

    # collected functions
    functions="${bi_functions} ${sl_functions}"

    # types
    types="Any Array Binary Boolean Callable CatalogEntry Class Collection"
    types="${types} Data Default Deferred Enum"
    types="${types} Float Hash Integer NotUndef Numeric Optional Pattern Resource"
    types="${types} Regexp Runtime Scalar SemVer SemVerRange Sensitive String Struct "
    types="${types} Timespan Tuple Type Undef Variant"

    # lower cased type names
    lc_types="$(echo ${types} |tr '[:upper:]' '[:lower:]')"

    # built-in resources
    bi_resources="exec file filebucket group notify package resources schedule service stage tidy user"

    # stdlib resources
    sl_resources="anchor file_line"

    # puppetlabs core resources (moved to their own modules as of puppet6, packaged with
    # puppet-agent)
    pa_resources="augeas cron host mount scheduled_task selboolean selmodule ssh_authorized_key sshkey"
    pa_resources="${pc_resources} yumrepo zfs zpool zone"

    # puppetlabs core resources moved to notionally maintained modules, not package with
    # puppet-agent
    pc_resources="k5login mailalias maillist"

    # older resources, used to be part of standard library but no longer, not maintained,
    # generally don't support puppet7
    #
    # nagios_core
    oc_resources="nagios_command nagios_contact nagios_contactgroup nagios_host nagios_hostdependency"
    oc_resources="${oc_resources} nagios_hostescalation nagios_hostextinfo nagios_hostgroup nagios_service"
    oc_resources="${oc_resources} nagios_servicedependency nagios_serviceescalation nagios_serviceextinfo"
    oc_resources="${oc_resources} nagios_servicegroup nagios_timeperiod"
    # macdslocal_core
    oc_resources="${oc_resources} computer macauthorization mcx"
    # network_device_core (very notmaintained)
    oc_resources="${oc_resources} interface router vlan"

    # collected resources
    resources="${bi_resources} ${sl_resources} ${pa_resources} ${pc_resources} ${oc_resources}"

    # Special values
    special="true false undef"

    join() { sep=$2; eval set -- $1; IFS="$sep"; echo "$*"; }

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=puppet %{
        set-option window static_words $(join "${typedef} ${keywords} ${types} ${lc_types} ${functions} ${resources} ${special} ${control}" ' ')'
    }"

    # Highlight keywords
    printf %s "
        add-highlighter shared/puppet/code/typedef regex '\b($(join "${typedef}" '|'))\b' 0:module
        add-highlighter shared/puppet/code/keywords regex '\b($(join "${keywords}" '|'))\b' 0:keyword
        add-highlighter shared/puppet/code/control regex '\b($(join "${control}" '|'))\b' 0:operator
        add-highlighter shared/puppet/code/functions regex '\b($(join "${functions}" '|'))\b\s*[(|]' 1:builtin
        add-highlighter shared/puppet/code/functions_chained regex '\.\b($(join "${functions}" '|'))\b' 1:builtin
        add-highlighter shared/puppet/code/types regex '\b($(join "${types}" '|'))\b' 0:type
        add-highlighter shared/puppet/code/resources regex '\b($(join "${resources}" '|'))\b' 0:module
        add-highlighter shared/puppet/code/special regex '\b($(join "${special}" '|'))\b' 0:meta
    "
}

add-highlighter shared/puppet/code/variabledef regex '(^|\W)(\$[a-z][\w_]*)\s*=\s*([^,]+),?' 1:variable 2:value
add-highlighter shared/puppet/code/variableref regex '(\$(::)?[a-z][\w_]*(::[a-z][\w_]*)*)' 0:value
add-highlighter shared/puppet/code/attribute regex '\b([a-z][\w_]*)\s*(\+>|=>)\s*' 0:attribute
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
