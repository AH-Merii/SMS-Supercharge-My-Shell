function gh-ssh --description "DEPRECATED: use ggh instead"
    echo "gh-ssh is deprecated. Use ggh instead:" >&2
    echo "  ggh op add --org <org> --name <name> --email <email>" >&2
    echo "" >&2
    echo "For help: ggh --help" >&2
    return 1
end
