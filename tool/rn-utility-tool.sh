#!/bin/bash

# Jira API base URL
JIRA_API_BASE="https://issues.redhat.com/rest/api/2/issue"

# Retrieve passed arguments
option=$1
y_stream=$2
bug_id=$3

# Functionality 1: Known Issues Checker
known_issues_checker() {
    # Construct the release notes URL dynamically based on the passed y-stream release number
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$y_stream/release_notes/ocp-4-$y_stream-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    KNOWN_ISSUES=$(awk '/== Known issues/ {flag=1} flag && /== Asynchronous errata updates/ {exit} flag' "$TEMP_FILE")
    
    # Extract OCPBUGS links from the known issues section
    BUG_URLS=$(echo "$KNOWN_ISSUES" | grep -oP 'https://issues.redhat.com/browse/OCPBUGS-\d+' | uniq)

    # Check Jira status for each bug and report those that are not closed
    echo "Checking known issue OCPBUGS statuses for 4.$y_stream..."

    for bug_url in $BUG_URLS; do
        # Extract the bug ID (e.g., OCPBUGS-12345)
        KI_BUG_ID=$(echo "$bug_url" | grep -oP 'OCPBUGS-\d+')

        # Fetch the bug status from Jira
        BUG_STATUS=$(curl -sSL "$JIRA_API_BASE/$KI_BUG_ID" | jq -r '.fields.status.name')

        # Report the bug if the status is not "Closed"
        echo "$KI_BUG_ID has status: $BUG_STATUS"
    done

    # Cleanup
    rm "$TEMP_FILE"
}

# Functionality 2: Check for duplicate OCPBUGS links
check_duplicate_ocpbugs() {
    # Construct the release notes URL dynamically based on the passed y-stream release number
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$y_stream/release_notes/ocp-4-$y_stream-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    # Check if the download was successful
    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "Failed to download release notes or the file is empty. Please check the version number."
        return
    fi

    # Extract all OCPBUGS links from the release notes
    BUG_URLS=$(grep -oP 'https://issues.redhat.com/browse/OCPBUGS-\d+' "$TEMP_FILE")

    # Check for duplicates using awk
    DUPLICATES=$(echo "$BUG_URLS" | sort | uniq -d)

    # Report any duplicates found
    if [[ -n "$DUPLICATES" ]]; then
        echo "Duplicate OCPBUGS links found:"
        echo "$DUPLICATES"
        echo ""
        echo "NOTE: Often no action is required for duplicate bugs reported by this tool. Often bugs appear twice as part of the known issue --> fix announcements."
        echo ""
    else
        echo "No duplicate OCPBUGS links found."
    fi

    # Cleanup
    rm "$TEMP_FILE"
}

# Functionality 3: Check for mismatched OCPBUGS links
check_mismatched_ocpbugs() {
    # Construct the release notes URL dynamically based on the passed y-stream release number
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$y_stream/release_notes/ocp-4-$y_stream-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    # Check if the download was successful
    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "Failed to download release notes or the file is empty. Please check the version number."
        return
    fi

    # Extract OCPBUGS links and their human-readable text
    MISMATCHES=$(grep -oP 'link:https://issues.redhat.com/browse/OCPBUGS-\d+\[\*OCPBUGS-\d+\*\]' "$TEMP_FILE")

    # Initialize a flag for found mismatches
    FOUND_MISMATCHES=0

    # Process each mismatch line
    while read -r line; do
        # Extract the actual bug ID and the displayed bug ID
        ACTUAL_BUG=$(echo "$line" | grep -oP 'link:https://issues.redhat.com/browse/OCPBUGS-\d+' | grep -oP 'OCPBUGS-\d+')
        DISPLAYED_BUG=$(echo "$line" | grep -oP '\[\*OCPBUGS-\d+\*\]' | grep -oP 'OCPBUGS-\d+')

        # Compare and report any mismatches
        if [[ "$ACTUAL_BUG" != "$DISPLAYED_BUG" ]]; then
            echo "Mismatch found: Link points to $ACTUAL_BUG but displays $DISPLAYED_BUG"
            FOUND_MISMATCHES=1
        fi
    done <<< "$MISMATCHES"

    # If there are no mismatches
    if [[ $FOUND_MISMATCHES -eq 0 ]]; then
        echo "No mismatched OCPBUGS links found."
    fi

    # Cleanup
    rm "$TEMP_FILE"
}

# Functionality 4: Search previous Y-streams for a specific bug
search_previous_ystreams_for_bug() {

    # Loop through the previous 3 Y-streams
    for (( i=1; i<=3; i++ )); do
        PREV_Y_STREAM=$((y_stream - i))

        # Construct the release notes URL dynamically for each previous Y-stream
        RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$PREV_Y_STREAM/release_notes/ocp-4-$PREV_Y_STREAM-release-notes.adoc"

        # Temporary file to store fetched release notes
        TEMP_FILE="/tmp/ocp_release_notes_4_$PREV_Y_STREAM.html"

        # Download the release notes for the previous Y-stream
        curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

        # Check if the download was successful
        if [[ ! -s "$TEMP_FILE" ]]; then
            echo "Failed to download release notes for 4.$PREV_Y_STREAM or the file is empty."
            continue
        fi

        # Search for the bug ID in the downloaded release notes
        if grep -q "$bug_id" "$TEMP_FILE"; then
            echo "$bug_id was found in release notes for 4.$PREV_Y_STREAM"
        else
            echo "$bug_id was not found in release notes for 4.$PREV_Y_STREAM"
        fi

        # Cleanup
        rm "$TEMP_FILE"
    done
}

# Functionality 5: Check TP tables for features that are GA for past three releases
check_tp_tables() {
    # Construct the release notes URL dynamically based on the passed y-stream release number
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$y_stream/release_notes/ocp-4-$y_stream-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "Failed to download release notes for 4.$y_stream or the file is empty."
        return
    fi

    lines_array=()

    # Read the file line by line into an array
    while IFS= read -r line; do
        lines_array+=("$line")
    done < "$TEMP_FILE"

    # Check for the pattern and report the line before it
    for ((i = 2; i < ${#lines_array[@]}; i++)); do
        if [[ ${lines_array[$i]} == "|General Availability" && \
            ${lines_array[$i-1]} == "|General Availability" && \
            ${lines_array[$i-2]} == "|General Availability" ]]; then
            echo "Pattern found. If the following feature is GA for the past three releases, you should remove it from the Tech Preview status table:"
            echo "${lines_array[$i-3]}"
        fi
    done

    # Cleanup
    rm "$TEMP_FILE"
}

# Handle the flow based on the passed option
case $option in
    1) known_issues_checker ;;
    2) check_duplicate_ocpbugs ;;
    3) check_mismatched_ocpbugs ;;
    4) search_previous_ystreams_for_bug "$y_stream" ;;
    5) check_tp_tables ;;
    *) echo "Invalid option. Please provide a valid number (1-5)." ;;
esac
   
