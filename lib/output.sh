#!/usr/bin/env bash

emit_result() {

    local id="$1"
    local title="$2"
    local risk="$3"
    local status="$4"
    local evidence="$5"
    local recommendation="$6"
    local fix_available="$7"
    local changed="${8:-false}"

    jq -nc \
    --arg id "$id" \
    --arg title "$title" \
    --arg risk "$risk" \
    --arg status "$status" \
    --arg evidence "$evidence" \
    --arg recommendation "$recommendation" \
    --argjson fix_available "$fix_available" \
    --argjson changed "$changed" \
    \
    '{
        id: $id,
        title: $title,
        risk: $risk,
        status: $status,
        evidence: $evidence,
        recommendation: $recommendation,
        fix_available: $fix_available,
        changed: $changed
    }' >> "$RESULTS_FILE"

}

render_output() {
    
    local format="$1"

    case "$format" in
    json)
        jq -s \
        --arg profile "$PROFILE" \
        --arg generated_at "$(now_utc)" \
        '{tool:"hardenkit", profile:$profile, generated_at:$generated_at, results:.}' \
        "$RESULTS_FILE"
        ;;
    markdown)
        jq -sr '
        "# Linux Hardening Audit\n\n" +
        "| ID | Risk | Status | Finding |\n" +
        "|---|---|---|---|\n" +
        (map("| \(.id) | \(.risk) | \(.status) | \(.title) |") | join("\n")) +
        "\n\n## Evidence\n\n" +
        (map("### \(.id) - \(.title)\n\n- Risk: `\(.risk)`\n- Status: `\(.status)`\n- Evidence: `\(.evidence)`\n- Recommendation: \(.recommendation)\n") | join("\n"))
        ' "$RESULTS_FILE"
        ;;
    table)
        jq -r '"ID\tRISK\tSTATUS\tTITLE", (.[] | "\(.id)\t\(.risk)\t\(.status)\t\(.title)")' "$RESULTS_FILE" |
        column -t -s $'\t'
        ;;
    esac

}

exit_with_audit_status() {

    if jq -e 'select(.status == "fail" or .status == "error")' "$RESULTS_FILE" >/dev/null; then
    exit 1

    fi

    exit 0
    
}