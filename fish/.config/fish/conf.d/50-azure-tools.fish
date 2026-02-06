# Azure CLI and Microsoft Graph API tools
# Dependencies: az (azure-cli), op (1password-cli), jq

# ============================================================================
# Configuration (uses universal variables with defaults)
# ============================================================================
set -q AZURE_OP_VAULT; or set -U AZURE_OP_VAULT Work
set -q AZURE_OP_ITEM; or set -U AZURE_OP_ITEM azure-data-extraction
set -q AZURE_OP_FIELD; or set -U AZURE_OP_FIELD access_token
set -q AZURE_GRAPH_RESOURCE; or set -U AZURE_GRAPH_RESOURCE "https://graph.microsoft.com"
set -q AZURE_SP_HOST; or set -U AZURE_SP_HOST "contoso.sharepoint.com"
set -q AZURE_USE_OP; or set -U AZURE_USE_OP false

# Defaults for reset
set -g __AZF_DEFAULT_VAULT Work
set -g __AZF_DEFAULT_ITEM azure-data-extraction
set -g __AZF_DEFAULT_FIELD access_token
set -g __AZF_DEFAULT_RESOURCE "https://graph.microsoft.com"
set -g __AZF_DEFAULT_SP_HOST "contoso.sharepoint.com"
set -g __AZF_DEFAULT_USE_OP false

# ============================================================================
# Helper Functions
# ============================================================================
function __azf_get_token -d "Get Azure token"
    argparse op -- $argv
    if set -q _flag_op; or test "$AZURE_USE_OP" = true
        op read "op://$AZURE_OP_VAULT/$AZURE_OP_ITEM/$AZURE_OP_FIELD"
    else
        az account get-access-token --resource $AZURE_GRAPH_RESOURCE --query accessToken -o tsv
    end
end

function __azf_colors -d "Setup colors"
    set -g __azf_bold (set_color --bold)
    set -g __azf_green (set_color green)
    set -g __azf_yellow (set_color yellow)
    set -g __azf_cyan (set_color cyan)
    set -g __azf_dim (set_color brblack)
    set -g __azf_red (set_color red)
    set -g __azf_reset (set_color normal)
end

function __azf_help_main -d "Show main help"
    __azf_colors
    echo $__azf_bold"az-fish"$__azf_reset" - Azure CLI tools for fish shell"
    echo ""
    echo $__azf_bold"Usage:"$__azf_reset" az-fish <command> [options]"
    echo ""
    echo $__azf_bold"Commands:"$__azf_reset
    echo "  "$__azf_green"auth"$__azf_reset"      Update Azure access token in 1Password"
    echo "  "$__azf_green"api"$__azf_reset"       Call Microsoft Graph API"
    echo "  "$__azf_green"config"$__azf_reset"    View and manage configuration"
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish auth status"$__azf_reset"               "$__azf_dim"# show token info and expiry"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query /me"$__azf_reset"             "$__azf_dim"# get current user"$__azf_reset
    echo "  "$__azf_cyan"az-fish api helpers get-all-sites"$__azf_reset" "$__azf_dim"# list SharePoint sites"$__azf_reset
    echo "  "$__azf_cyan"az-fish config"$__azf_reset"                    "$__azf_dim"# show config"$__azf_reset
    echo ""
    echo "Run "$__azf_cyan"az-fish <command> --help"$__azf_reset" for command-specific help"
end

function __azf_help_auth -d "Show auth help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish auth <command> [OPTIONS]"
    echo ""
    echo "Manage Azure authentication and tokens"
    echo ""
    echo $__azf_bold"Commands:"$__azf_reset
    echo "  "$__azf_green"status"$__azf_reset"     Show token status, tenant, and expiry"
    echo "  "$__azf_green"update"$__azf_reset"     Update token in 1Password"
    echo ""
    echo "Run "$__azf_cyan"az-fish auth <command> --help"$__azf_reset" for command-specific help"
end

function __azf_help_auth_update -d "Show auth update help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish auth update [OPTIONS]"
    echo ""
    echo "Update Azure access token in 1Password"
    echo ""
    echo $__azf_bold"Options:"$__azf_reset
    echo "  "$__azf_green"-h"$__azf_reset", "$__azf_green"--help"$__azf_reset"          Show this help message"
    echo "  "$__azf_green"-v"$__azf_reset", "$__azf_green"--vault"$__azf_reset"="$__azf_yellow"NAME"$__azf_reset"    1Password vault "$__azf_dim"(default: $AZURE_OP_VAULT)"$__azf_reset
    echo "  "$__azf_green"-i"$__azf_reset", "$__azf_green"--item"$__azf_reset"="$__azf_yellow"NAME"$__azf_reset"     1Password item "$__azf_dim"(default: $AZURE_OP_ITEM)"$__azf_reset
    echo "  "$__azf_green"-f"$__azf_reset", "$__azf_green"--field"$__azf_reset"="$__azf_yellow"NAME"$__azf_reset"    Field to update "$__azf_dim"(default: $AZURE_OP_FIELD)"$__azf_reset
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish auth update"$__azf_reset"                       "$__azf_dim"# uses all defaults"$__azf_reset
    echo "  "$__azf_cyan"az-fish auth update -v Personal"$__azf_reset"           "$__azf_dim"# custom vault"$__azf_reset
    echo "  "$__azf_cyan"az-fish auth update --vault=Work --item=my-item"$__azf_reset
end

function __azf_help_api -d "Show api help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish api <command> [OPTIONS]"
    echo ""
    echo "Call Microsoft Graph API"
    echo ""
    echo $__azf_bold"Commands:"$__azf_reset
    echo "  "$__azf_green"query"$__azf_reset"      Execute a Graph API query"
    echo "  "$__azf_green"helpers"$__azf_reset"    Pre-built API helper commands"
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query /me"$__azf_reset"               "$__azf_dim"# get current user"$__azf_reset
    echo "  "$__azf_cyan"az-fish api helpers get-all-sites"$__azf_reset"   "$__azf_dim"# list all SharePoint sites"$__azf_reset
    echo ""
    echo "Run "$__azf_cyan"az-fish api <command> --help"$__azf_reset" for command-specific help"
end

function __azf_help_api_query -d "Show api query help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish api query [OPTIONS] ENDPOINT"
    echo ""
    echo "Call Microsoft Graph API"
    echo ""
    echo $__azf_bold"Options:"$__azf_reset
    echo "  "$__azf_green"-h"$__azf_reset", "$__azf_green"--help"$__azf_reset"          Show this help message"
    echo "  "$__azf_green"-o"$__azf_reset", "$__azf_green"--op"$__azf_reset"            Use 1Password token instead of Azure CLI"
    echo "  "$__azf_green"-X"$__azf_reset", "$__azf_green"--method"$__azf_reset"="$__azf_yellow"METHOD"$__azf_reset"  HTTP method "$__azf_dim"(default: GET)"$__azf_reset
    echo "  "$__azf_green"-d"$__azf_reset", "$__azf_green"--data"$__azf_reset"="$__azf_yellow"JSON"$__azf_reset"      Request body for POST/PATCH"
    echo "  "$__azf_green"-r"$__azf_reset", "$__azf_green"--raw"$__azf_reset"            Output raw JSON without jq"
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query /me"$__azf_reset"                                        "$__azf_dim"# get current user"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query --op /me"$__azf_reset"                                   "$__azf_dim"# use 1Password token"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query /sites/contoso.sharepoint.com:/sites/MySite"$__azf_reset"  "$__azf_dim"# get SharePoint site"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query -X POST -d '{...}' /teams"$__azf_reset"                  "$__azf_dim"# create a team"$__azf_reset
    echo "  "$__azf_cyan"az-fish api query -r /me"$__azf_reset"                                     "$__azf_dim"# raw output"$__azf_reset
end

function __azf_help_api_helpers -d "Show api helpers help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish api helpers <command>"
    echo ""
    echo "Pre-built API helper commands with formatted output"
    echo ""
    echo $__azf_bold"Commands:"$__azf_reset
    echo "  "$__azf_green"get-all-sites"$__azf_reset"    List all SharePoint sites"
    echo "  "$__azf_green"get-site-drives"$__azf_reset"  List all drives for a site"
    echo "  "$__azf_green"get-drive-id"$__azf_reset"     Get drive ID for a site and drive name"
    echo ""
    echo $__azf_bold"Common Options:"$__azf_reset
    echo "  "$__azf_green"-H"$__azf_reset", "$__azf_green"--host"$__azf_reset"="$__azf_yellow"HOST"$__azf_reset"  SharePoint hostname for multi-geo support"
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish api helpers get-all-sites"$__azf_reset"                              "$__azf_dim"# list all sites"$__azf_reset
    echo "  "$__azf_cyan"az-fish api helpers get-site-drives MySite"$__azf_reset"                     "$__azf_dim"# list drives"$__azf_reset
    echo "  "$__azf_cyan"az-fish api helpers get-drive-id MySite Documents"$__azf_reset"              "$__azf_dim"# get drive ID"$__azf_reset
end

# ============================================================================
# Subcommands
# ============================================================================
function __azf_cmd_auth -d "Auth subcommand"
    set -l subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case -h --help ''
            __azf_help_auth
        case status
            __azf_cmd_auth_status $argv
        case update
            __azf_cmd_auth_update $argv
        case '*'
            echo (set_color red)"Unknown auth command: $subcmd"(set_color normal) >&2
            echo "Run 'az-fish auth --help' for usage" >&2
            return 1
    end
end

function __azf_cmd_auth_status -d "Show token status"
    argparse h/help o/op -- $argv
    or return

    if set -q _flag_help
        __azf_colors
        echo $__azf_bold"Usage:"$__azf_reset" az-fish auth status [OPTIONS]"
        echo ""
        echo "Display current token status including tenant, user, expiry, and scopes"
        echo ""
        echo $__azf_bold"Options:"$__azf_reset
        echo "  "$__azf_green"-h"$__azf_reset", "$__azf_green"--help"$__azf_reset"          Show this help message"
        echo "  "$__azf_green"-o"$__azf_reset", "$__azf_green"--op"$__azf_reset"            Use 1Password token instead of Azure CLI"
        return 0
    end

    # Determine token source
    set -l token_source
    set -l op_flag
    if set -q _flag_op; or test "$AZURE_USE_OP" = true
        set op_flag --op
        set token_source 1Password
    else
        set token_source "Azure CLI"
    end
    set -l token (__azf_get_token $op_flag 2>/dev/null)
    if test -z "$token"
        echo (set_color red)"✗ Failed to get token from $token_source."(set_color normal) >&2
        if test "$token_source" = "Azure CLI"
            echo (set_color brblack)"Run 'az login' to authenticate."(set_color normal) >&2
        end
        return 1
    end

    set -l payload (echo $token | cut -d. -f2)
    set -l json (echo $payload== | base64 -d 2>/dev/null)

    if test -z "$json"
        echo (set_color red)"✗ Failed to decode token"(set_color normal) >&2
        return 1
    end

    __azf_colors

    # Extract token claims
    set -l upn (echo $json | jq -r '.upn // .email // "unknown"')
    set -l name (echo $json | jq -r '.name // "unknown"')
    set -l tid (echo $json | jq -r '.tid // "unknown"')
    set -l aud (echo $json | jq -r '.aud // "unknown"')
    set -l exp (echo $json | jq -r '.exp')
    set -l iat (echo $json | jq -r '.iat')
    set -l now (date +%s)

    # Calculate times
    set -l exp_date (date -r $exp "+%Y-%m-%d %H:%M:%S" 2>/dev/null; or date -d @$exp "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
    set -l iat_date (date -r $iat "+%Y-%m-%d %H:%M:%S" 2>/dev/null; or date -d @$iat "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
    set -l remaining (math $exp - $now)
    set -l lifetime (math $exp - $iat)

    # Format remaining time
    if test $remaining -gt 0
        set -l hours (math "floor($remaining / 3600)")
        set -l mins (math "floor(($remaining % 3600) / 60)")
        set -l secs (math "$remaining % 60")
        if test $hours -gt 0
            set remaining_fmt "$hours"h" $mins"m
        else if test $mins -gt 0
            set remaining_fmt "$mins"m" $secs"s
        else
            set remaining_fmt "$secs"s
        end
        set -l status_icon (set_color green)"●"(set_color normal)
        set -l status_text (set_color green)"Valid"(set_color normal)
    else
        set remaining_fmt Expired
        set -l status_icon (set_color red)"●"(set_color normal)
        set -l status_text (set_color red)"Expired"(set_color normal)
    end

    # Header
    echo ""
    if test $remaining -gt 0
        echo "  "(set_color green)"●"(set_color normal)" Token Status: "(set_color green)"Valid"(set_color normal)" "$__azf_dim"(from $token_source)"$__azf_reset
    else
        echo "  "(set_color red)"●"(set_color normal)" Token Status: "(set_color red)"Expired"(set_color normal)" "$__azf_dim"(from $token_source)"$__azf_reset
    end
    echo ""

    # User section
    echo $__azf_bold"  User"$__azf_reset
    echo "    "$__azf_dim"name"$__azf_reset"      "$__azf_cyan"$name"$__azf_reset
    echo "    "$__azf_dim"upn"$__azf_reset"       "$__azf_cyan"$upn"$__azf_reset
    echo ""

    # Tenant section
    echo $__azf_bold"  Tenant"$__azf_reset
    echo "    "$__azf_dim"id"$__azf_reset"        "$__azf_cyan"$tid"$__azf_reset
    echo "    "$__azf_dim"resource"$__azf_reset"  "$__azf_cyan"$aud"$__azf_reset
    echo ""

    # Token timing section
    echo $__azf_bold"  Token Lifetime"$__azf_reset
    echo "    "$__azf_dim"issued"$__azf_reset"    "$__azf_yellow"$iat_date"$__azf_reset
    echo "    "$__azf_dim"expires"$__azf_reset"   "$__azf_yellow"$exp_date"$__azf_reset
    if test $remaining -gt 0
        echo "    "$__azf_dim"remaining"$__azf_reset" "(set_color green)"$remaining_fmt"(set_color normal)
    else
        echo "    "$__azf_dim"remaining"$__azf_reset" "(set_color red)"$remaining_fmt"(set_color normal)
    end
    echo "    "$__azf_dim"lifetime"$__azf_reset"  "(math "$lifetime / 60")"m"
    echo ""

    # Scopes section
    echo $__azf_bold"  Scopes"$__azf_reset
    echo $json | jq -r '.scp // ""' | tr ' ' '\n' | while read -l scope
        test -z "$scope"; and continue
        set -l colored (echo $scope | awk -F. '{
            printf "\033[32m%s\033[0m", $1
            if ($2) printf ".\033[33m%s\033[0m", $2
            if ($3) printf ".\033[36m%s\033[0m", $3
            if ($4) printf ".\033[35m%s\033[0m", $4
        }')
        echo "    "$colored
    end
    echo ""
end

function __azf_cmd_auth_update -d "Update token in 1Password"
    argparse h/help 'v/vault=' 'i/item=' 'f/field=' -- $argv
    or return

    if set -q _flag_help
        __azf_help_auth_update
        return 0
    end

    set -l vault (string length -q -- "$_flag_vault" && echo "$_flag_vault" || echo "$AZURE_OP_VAULT")
    set -l item (string length -q -- "$_flag_item" && echo "$_flag_item" || echo "$AZURE_OP_ITEM")
    set -l field (string length -q -- "$_flag_field" && echo "$_flag_field" || echo "$AZURE_OP_FIELD")

    set -l token (az account get-access-token --resource $AZURE_GRAPH_RESOURCE --query accessToken -o tsv)
    if test -z "$token"
        echo (set_color red)"Failed to get token. Run 'az login' first."(set_color normal) >&2
        return 1
    end

    op item edit $item --vault $vault "$field=$token"
    or return

    echo (set_color green)"✓"(set_color normal)" Token updated in 1Password ("(set_color cyan)"$vault/$item/$field"(set_color normal)")"
    echo (set_color brblack)"Token Preview: "(set_color normal)(string sub -l 50 $token)"..."
end

function __azf_cmd_api -d "API subcommand"
    set -l subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case -h --help ''
            __azf_help_api
        case query
            __azf_cmd_api_query $argv
        case helpers
            __azf_cmd_api_helpers $argv
        case '*'
            echo (set_color red)"Unknown api command: $subcmd"(set_color normal) >&2
            echo "Run 'az-fish api --help' for usage" >&2
            return 1
    end
end

function __azf_cmd_api_query -d "Execute Graph API query"
    argparse h/help 'X/method=' 'd/data=' r/raw o/op -- $argv
    or return

    if set -q _flag_help
        __azf_help_api_query
        return 0
    end

    set -l endpoint $argv[1]
    if test -z "$endpoint"
        echo (set_color red)"Error: ENDPOINT is required"(set_color normal) >&2
        echo "Run 'az-fish api query --help' for usage" >&2
        return 1
    end

    set -l method (string length -q -- "$_flag_method" && echo "$_flag_method" || echo "GET")
    set -l op_flag
    if set -q _flag_op
        set op_flag --op
    end
    set -l token (__azf_get_token $op_flag)

    if test -z "$token"
        echo (set_color red)"Failed to get token"(set_color normal) >&2
        return 1
    end

    set -l curl_args -s -X $method
    set -a curl_args -H "Authorization: Bearer $token"
    set -a curl_args -H "Content-Type: application/json"

    if set -q _flag_data
        set -a curl_args -d "$_flag_data"
    end

    set -l url "$AZURE_GRAPH_RESOURCE/v1.0$endpoint"

    if set -q _flag_raw
        curl $curl_args "$url"
    else
        curl $curl_args "$url" | jq
    end
end

# ============================================================================
# API Helpers
# To add a new helper:
#   1. Add a case in __azf_cmd_api_helpers switch
#   2. Create function __azf_cmd_api_helpers_<name>
#   3. Update __azf_help_api_helpers with the new command
#   4. Add -H/--host flag support for multi-geo SharePoint queries:
#      - Use: argparse h/help 'H/host=' -- $argv
#      - Get host: set -l sp_host (string length -q -- "$_flag_host" && echo "$_flag_host" || echo "$AZURE_SP_HOST")
#      - For site queries, use: /sites/$sp_host/sites?search=*
#      - For site-specific queries, use: /sites/$sp_host:/sites/$site_name:
# ============================================================================
function __azf_cmd_api_helpers -d "API helpers subcommand"
    set -l subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case -h --help ''
            __azf_help_api_helpers
        case get-all-sites
            __azf_cmd_api_helpers_get_all_sites $argv
        case get-site-drives
            __azf_cmd_api_helpers_get_site_drives $argv
        case get-drive-id
            __azf_cmd_api_helpers_get_drive_id $argv
        case '*'
            echo (set_color red)"Unknown helper command: $subcmd"(set_color normal) >&2
            echo "Run 'az-fish api helpers --help' for usage" >&2
            return 1
    end
end

function __azf_cmd_api_helpers_get_all_sites -d "List all SharePoint sites"
    argparse h/help 'H/host=' o/op -- $argv
    or return

    if set -q _flag_help
        __azf_colors
        echo $__azf_bold"Usage:"$__azf_reset" az-fish api helpers get-all-sites [OPTIONS]"
        echo ""
        echo "List all SharePoint sites with colored output (handles pagination)"
        echo ""
        echo $__azf_bold"Options:"$__azf_reset
        echo "  "$__azf_green"-o"$__azf_reset", "$__azf_green"--op"$__azf_reset"          Use 1Password token instead of Azure CLI"
        echo "  "$__azf_green"-H"$__azf_reset", "$__azf_green"--host"$__azf_reset"="$__azf_yellow"HOST"$__azf_reset"  SharePoint hostname "$__azf_dim"(default: $AZURE_SP_HOST)"$__azf_reset
        echo ""
        echo "Output format:"
        echo "  "$__azf_dim"NUM."$__azf_reset" "$__azf_cyan"Display Name"$__azf_reset" "$__azf_dim"→ https://"$__azf_yellow"tenant"$__azf_dim".sharepoint.com/sites/"$__azf_green"site-slug"$__azf_reset
        echo ""
        echo $__azf_bold"Examples:"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-all-sites"$__azf_reset"                         "$__azf_dim"# uses default host"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-all-sites --op"$__azf_reset"                    "$__azf_dim"# use 1Password token"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-all-sites -H contoso-eur.sharepoint.com"$__azf_reset" "$__azf_dim"# EUR geo"$__azf_reset
        return 0
    end

    set -l sp_host (string length -q -- "$_flag_host" && echo "$_flag_host" || echo "$AZURE_SP_HOST")
    echo host: $sp_host

    # Get token once for all requests
    set -l op_flag
    if set -q _flag_op
        set op_flag --op
    end
    set -l token (__azf_get_token $op_flag)
    if test -z "$token"
        echo (set_color red)"Failed to get token"(set_color normal) >&2
        return 1
    end

    set -l tmpresponse /tmp/azf_response.json
    set -l tmpresults /tmp/azf_results.txt
    rm -f $tmpresponse $tmpresults
    touch $tmpresults

    set -l url "$AZURE_GRAPH_RESOURCE/v1.0/sites/$sp_host/sites?search=*&top=500"
    set -l page 1

    echo (set_color brblack)"Querying host: $sp_host"(set_color normal) >&2

    while test -n "$url"
        echo (set_color brblack)"Fetching page $page..."(set_color normal) >&2

        curl -s -H "Authorization: Bearer $token" "$url" >$tmpresponse
        jq -r '.value[] | "\(.displayName)\t\(.webUrl)"' $tmpresponse >>$tmpresults

        set url (jq -r '."@odata.nextLink" // empty' $tmpresponse)
        set page (math $page + 1)
    end

    set -l total (wc -l < $tmpresults | string trim)
    echo (set_color brblack)"Done. Found $total sites."(set_color normal) >&2

    # Format and output all results
    awk -F'\t' '{split($2, url, "/sites/"); split(url[1], domain, "://"); split(domain[2], host, "."); printf "\033[90m%3d.\033[0m \033[36m%s\033[0m \033[90m→ https://\033[33m%s\033[90m.sharepoint.com/sites/\033[32m%s\033[0m\n", NR, $1, host[1], url[2]}' $tmpresults

    rm -f $tmpresponse $tmpresults
end

function __azf_cmd_api_helpers_get_site_drives -d "List all drives for a site"
    argparse h/help 'H/host=' o/op -- $argv
    or return

    if set -q _flag_help
        __azf_colors
        echo $__azf_bold"Usage:"$__azf_reset" az-fish api helpers get-site-drives [OPTIONS] <site-name>"
        echo ""
        echo "List all drives (document libraries) for a SharePoint site"
        echo ""
        echo $__azf_bold"Options:"$__azf_reset
        echo "  "$__azf_green"-o"$__azf_reset", "$__azf_green"--op"$__azf_reset"          Use 1Password token instead of Azure CLI"
        echo "  "$__azf_green"-H"$__azf_reset", "$__azf_green"--host"$__azf_reset"="$__azf_yellow"HOST"$__azf_reset"  SharePoint hostname "$__azf_dim"(default: $AZURE_SP_HOST)"$__azf_reset
        echo ""
        echo $__azf_bold"Arguments:"$__azf_reset
        echo "  "$__azf_yellow"site-name"$__azf_reset"    The site name (e.g., ProjectDeliverables)"
        echo ""
        echo $__azf_bold"Examples:"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-site-drives ProjectDeliverables"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-site-drives --op MySite"$__azf_reset"             "$__azf_dim"# use 1Password token"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-site-drives -H contoso-eur.sharepoint.com MySite"$__azf_reset
        return 0
    end

    set -l site_name $argv[1]

    if test -z "$site_name"
        echo (set_color red)"Error: site-name is required"(set_color normal) >&2
        echo "Run 'az-fish api helpers get-site-drives --help' for usage" >&2
        return 1
    end

    set -l sp_host (string length -q -- "$_flag_host" && echo "$_flag_host" || echo "$AZURE_SP_HOST")

    set -l op_flag
    if set -q _flag_op
        set op_flag --op
    end
    set -l token (__azf_get_token $op_flag)
    if test -z "$token"
        echo (set_color red)"Failed to get token"(set_color normal) >&2
        return 1
    end

    set -l url "$AZURE_GRAPH_RESOURCE/v1.0/sites/$sp_host:/sites/$site_name:/drives?select=name,id,webUrl"
    set -l response (curl -s -H "Authorization: Bearer $token" "$url")

    # Check for error
    set -l error (echo $response | jq -r '.error.message // empty')
    if test -n "$error"
        echo (set_color red)"Error: $error"(set_color normal) >&2
        return 1
    end

    # Format output
    __azf_colors
    echo ""
    echo $__azf_bold"  Drives in $site_name"$__azf_reset" "$__azf_dim"($sp_host)"$__azf_reset
    echo ""
    echo $response | jq -r '.value[] | "\(.name)\t\(.id)\t\(.webUrl)"' | while read -l line
        set -l name (echo $line | cut -f1)
        set -l id (echo $line | cut -f2)
        set -l weburl (echo $line | cut -f3)
        echo "  "$__azf_cyan"$name"$__azf_reset
        echo "    "$__azf_dim"id:"$__azf_reset"  $id"
        echo "    "$__azf_dim"url:"$__azf_reset" $weburl"
        echo ""
    end
end

function __azf_cmd_api_helpers_get_drive_id -d "Get drive ID for a site and drive name"
    argparse h/help 'H/host=' o/op -- $argv
    or return

    if set -q _flag_help
        __azf_colors
        echo $__azf_bold"Usage:"$__azf_reset" az-fish api helpers get-drive-id [OPTIONS] <site-name> <drive-name>"
        echo ""
        echo "Get the drive ID for a SharePoint site's drive"
        echo ""
        echo $__azf_bold"Options:"$__azf_reset
        echo "  "$__azf_green"-o"$__azf_reset", "$__azf_green"--op"$__azf_reset"          Use 1Password token instead of Azure CLI"
        echo "  "$__azf_green"-H"$__azf_reset", "$__azf_green"--host"$__azf_reset"="$__azf_yellow"HOST"$__azf_reset"  SharePoint hostname "$__azf_dim"(default: $AZURE_SP_HOST)"$__azf_reset
        echo ""
        echo $__azf_bold"Arguments:"$__azf_reset
        echo "  "$__azf_yellow"site-name"$__azf_reset"    The site name (e.g., ProjectDeliverables)"
        echo "  "$__azf_yellow"drive-name"$__azf_reset"   The drive name (e.g., Documents)"
        echo ""
        echo $__azf_bold"Examples:"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-drive-id ProjectDeliverables Documents"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-drive-id --op MySite Docs"$__azf_reset"           "$__azf_dim"# use 1Password token"$__azf_reset
        echo "  "$__azf_cyan"az-fish api helpers get-drive-id -H contoso-eur.sharepoint.com MySite Docs"$__azf_reset
        return 0
    end

    set -l site_name $argv[1]
    set -l drive_name $argv[2]

    if test -z "$site_name" -o -z "$drive_name"
        echo (set_color red)"Error: site-name and drive-name are required"(set_color normal) >&2
        echo "Run 'az-fish api helpers get-drive-id --help' for usage" >&2
        return 1
    end

    set -l sp_host (string length -q -- "$_flag_host" && echo "$_flag_host" || echo "$AZURE_SP_HOST")

    set -l op_flag
    if set -q _flag_op
        set op_flag --op
    end
    set -l token (__azf_get_token $op_flag)
    if test -z "$token"
        echo (set_color red)"Failed to get token"(set_color normal) >&2
        return 1
    end

    set -l url "$AZURE_GRAPH_RESOURCE/v1.0/sites/$sp_host:/sites/$site_name:/drives?select=name,id"
    set -l response (curl -s -H "Authorization: Bearer $token" "$url")

    set -l drive_id (echo $response | jq -r --arg name "$drive_name" '.value[] | select(.name == $name) | .id')

    if test -z "$drive_id"
        echo (set_color red)"Drive '$drive_name' not found in site '$site_name'"(set_color normal) >&2
        echo (set_color brblack)"Available drives:"(set_color normal) >&2
        echo $response | jq -r '.value[].name' | while read -l name
            echo "  - $name" >&2
        end
        return 1
    end

    echo $drive_id
end

function __azf_help_config -d "Show config help"
    __azf_colors
    echo $__azf_bold"Usage:"$__azf_reset" az-fish config [COMMAND]"
    echo ""
    echo "View and manage az-fish configuration"
    echo ""
    echo $__azf_bold"Commands:"$__azf_reset
    echo "  "$__azf_green"(none)"$__azf_reset"     Show current configuration"
    echo "  "$__azf_green"set"$__azf_reset"        Set a configuration value"
    echo "  "$__azf_green"reset"$__azf_reset"      Reset all values to defaults"
    echo ""
    echo $__azf_bold"Config Keys:"$__azf_reset
    echo "  "$__azf_yellow"vault"$__azf_reset"     1Password vault name"
    echo "  "$__azf_yellow"item"$__azf_reset"      1Password item name"
    echo "  "$__azf_yellow"field"$__azf_reset"     1Password field name"
    echo "  "$__azf_yellow"resource"$__azf_reset"  Azure resource URL"
    echo "  "$__azf_yellow"sp_host"$__azf_reset"   SharePoint hostname (e.g., contoso.sharepoint.com)"
    echo "  "$__azf_yellow"use_op"$__azf_reset"    Use 1Password by default (true/false)"
    echo ""
    echo $__azf_bold"Examples:"$__azf_reset
    echo "  "$__azf_cyan"az-fish config"$__azf_reset"                            "$__azf_dim"# show config"$__azf_reset
    echo "  "$__azf_cyan"az-fish config set vault Personal"$__azf_reset"         "$__azf_dim"# change vault"$__azf_reset
    echo "  "$__azf_cyan"az-fish config set use_op true"$__azf_reset"            "$__azf_dim"# always use 1Password"$__azf_reset
    echo "  "$__azf_cyan"az-fish config set sp_host myorg.sharepoint.com"$__azf_reset
end

function __azf_cmd_config -d "Config subcommand"
    argparse h/help -- $argv
    or return

    if set -q _flag_help
        __azf_help_config
        return 0
    end

    set -l subcmd $argv[1]

    switch $subcmd
        case set
            set -l key $argv[2]
            set -l value $argv[3]

            if test -z "$key" -o -z "$value"
                echo (set_color red)"Usage: az-fish config set <key> <value>"(set_color normal) >&2
                echo "Run 'az-fish config --help' for available keys" >&2
                return 1
            end

            switch $key
                case vault
                    set -U AZURE_OP_VAULT $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_OP_VAULT = "(set_color cyan)"$value"(set_color normal)
                case item
                    set -U AZURE_OP_ITEM $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_OP_ITEM = "(set_color cyan)"$value"(set_color normal)
                case field
                    set -U AZURE_OP_FIELD $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_OP_FIELD = "(set_color cyan)"$value"(set_color normal)
                case resource
                    set -U AZURE_GRAPH_RESOURCE $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_GRAPH_RESOURCE = "(set_color cyan)"$value"(set_color normal)
                case sp_host
                    set -U AZURE_SP_HOST $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_SP_HOST = "(set_color cyan)"$value"(set_color normal)
                case use_op
                    if test "$value" != true -a "$value" != false
                        echo (set_color red)"Error: use_op must be 'true' or 'false'"(set_color normal) >&2
                        return 1
                    end
                    set -U AZURE_USE_OP $value
                    echo (set_color green)"✓"(set_color normal)" AZURE_USE_OP = "(set_color cyan)"$value"(set_color normal)
                case '*'
                    echo (set_color red)"Unknown config key: $key"(set_color normal) >&2
                    echo "Valid keys: vault, item, field, resource, sp_host, use_op" >&2
                    return 1
            end

        case reset
            set -U AZURE_OP_VAULT $__AZF_DEFAULT_VAULT
            set -U AZURE_OP_ITEM $__AZF_DEFAULT_ITEM
            set -U AZURE_OP_FIELD $__AZF_DEFAULT_FIELD
            set -U AZURE_GRAPH_RESOURCE $__AZF_DEFAULT_RESOURCE
            set -U AZURE_SP_HOST $__AZF_DEFAULT_SP_HOST
            set -U AZURE_USE_OP $__AZF_DEFAULT_USE_OP
            echo (set_color green)"✓"(set_color normal)" Configuration reset to defaults"
            __azf_cmd_config

        case ''
            __azf_colors
            echo $__azf_bold"Current Configuration:"$__azf_reset
            echo ""
            echo "  "$__azf_dim"vault"$__azf_reset"      = "$__azf_cyan"$AZURE_OP_VAULT"$__azf_reset
            echo "  "$__azf_dim"item"$__azf_reset"       = "$__azf_cyan"$AZURE_OP_ITEM"$__azf_reset
            echo "  "$__azf_dim"field"$__azf_reset"      = "$__azf_cyan"$AZURE_OP_FIELD"$__azf_reset
            echo "  "$__azf_dim"resource"$__azf_reset"   = "$__azf_cyan"$AZURE_GRAPH_RESOURCE"$__azf_reset
            echo "  "$__azf_dim"sp_host"$__azf_reset"    = "$__azf_cyan"$AZURE_SP_HOST"$__azf_reset
            echo "  "$__azf_dim"use_op"$__azf_reset"     = "$__azf_cyan"$AZURE_USE_OP"$__azf_reset
            echo ""
            if test "$AZURE_USE_OP" = true
                echo $__azf_dim"Token source: 1Password (op://$AZURE_OP_VAULT/$AZURE_OP_ITEM/$AZURE_OP_FIELD)"$__azf_reset
            else
                echo $__azf_dim"Token source: Azure CLI (az account get-access-token)"$__azf_reset
            end

        case '*'
            echo (set_color red)"Unknown config command: $subcmd"(set_color normal) >&2
            echo "Run 'az-fish config --help' for usage" >&2
            return 1
    end
end

# ============================================================================
# Main Entry Point
# ============================================================================
function az-fish -d "Azure CLI tools for fish shell"
    set -l cmd $argv[1]
    set -e argv[1]

    switch $cmd
        case -h --help ''
            __azf_help_main
        case auth
            __azf_cmd_auth $argv
        case api
            __azf_cmd_api $argv
        case config
            __azf_cmd_config $argv
        case '*'
            echo (set_color red)"Unknown command: $cmd"(set_color normal) >&2
            echo "Run 'az-fish --help' for usage" >&2
            return 1
    end
end
