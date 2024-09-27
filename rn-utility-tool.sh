#!/bin/bash



# Jira API base URL
JIRA_API_BASE="https://issues.redhat.com/rest/api/2/issue"

# Your Jira credentials (API token, or username:token)
JIRA_TOKEN="$MY_TOKEN"
#echo "My token is $JIRA_TOKEN"

# Functionality 1: Known Issues Checker
known_issues_checker() {

    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
read -p "Enter the y-stream release number to check known issue bug statsus. For example, for 4.15, enter "15": " Y_STREAM

# Construct the release notes URL dynamically based on user input
RELEASE_NOTES_URL="https://docs.openshift.com/container-platform/4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.html#ocp-4-$Y_STREAM-known-issues_release-notes"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    # Extract content of the "Known Issues" section
    KNOWN_ISSUES=$(awk '/Known issues<\/h2>/, /Asynchronous errata updates<\/h2>/' "$TEMP_FILE")

    # Extract OCPBUGS links from the known issues section
    BUG_URLS=$(echo "$KNOWN_ISSUES" | grep -oP 'https://issues.redhat.com/browse/OCPBUGS-\d+' | uniq)

    # Check Jira status for each bug and report those that are not closed
    echo "Checking known issue OCPBUGS statuses for 4.$Y_STREAM..."

    for bug_url in $BUG_URLS; do
        # Extract the bug ID (e.g., OCPBUGS-12345)
        BUG_ID=$(echo "$bug_url" | grep -oP 'OCPBUGS-\d+')

        # Fetch the bug status from Jira
        BUG_STATUS=$(curl -sSL -H "Authorization: Bearer $JIRA_TOKEN" "$JIRA_API_BASE/$BUG_ID" | jq -r '.fields.status.name')

        # Report the bug if the status is not "Closed"
        echo "$BUG_ID has status: $BUG_STATUS"
        
    done

    # Cleanup
    rm "$TEMP_FILE"

}

# Functionality 2: Check for duplicate OCPBUGS links
check_duplicate_ocpbugs() {
    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
    read -p "Enter the y-stream release number, e.g., for 4.15, enter 15: " Y_STREAM

    # Construct the release notes URL dynamically based on user input
    RELEASE_NOTES_URL="https://docs.openshift.com/container-platform/4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.html"

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
    else
        echo "No duplicate OCPBUGS links found."
    fi

    # Cleanup
    rm "$TEMP_FILE"
}

# Functionality 3: Check for mismatched OCPBUGS links
check_mismatched_ocpbugs() {
    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
    read -p "Enter the y-stream release number, e.g., for 4.15, enter 15: " Y_STREAM

    # Construct the release notes URL dynamically based on user input
    RELEASE_NOTES_URL="https://docs.openshift.com/container-platform/4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.html"

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
    # This regex captures both the actual bug ID and the displayed bug ID
    MISMATCHES=$(grep -oP '<a href="https://issues.redhat.com/browse/(OCPBUGS-\d+)"><strong>(OCPBUGS-\d+)</strong></a>' "$TEMP_FILE")

    # Initialize a flag for found mismatches
    FOUND_MISMATCHES=0

    # Process each mismatch line
    while read -r line; do
        # Extract the actual bug ID and the displayed bug ID
        ACTUAL_BUG=$(echo "$line" | grep -oP 'https://issues.redhat.com/browse/(OCPBUGS-\d+)' | grep -oP 'OCPBUGS-\d+')
        DISPLAYED_BUG=$(echo "$line" | grep -oP '<strong>(OCPBUGS-\d+)</strong>' | grep -oP 'OCPBUGS-\d+')

        # Compare and report any mismatches
        if [[ "$ACTUAL_BUG" != "$DISPLAYED_BUG" ]]; then
            echo "Mismatch found: Link points to $ACTUAL_BUG but displays $DISPLAYED_BUG"
            FOUND_MISMATCHES=1  # Set the flag indicating at least one mismatch was found
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
    # Prompt the user to input the bug link
    read -p "Enter the full OCPBUGS link (e.g., https://issues.redhat.com/browse/OCPBUGS-12345): " BUG_LINK

    # Extract the bug ID from the link (e.g., OCPBUGS-12345)
    BUG_ID=$(echo "$BUG_LINK" | grep -oP 'OCPBUGS-\d+')

    # Prompt the user to input the current Y-stream release number (e.g., for 4.15, they will enter 15)
    read -p "Enter the current Y-stream release number, e.g., for 4.15, enter 15: " CURRENT_Y_STREAM

    # Check for valid input (current Y-stream should be an integer greater than or equal to 4)
    if ! [[ "$CURRENT_Y_STREAM" =~ ^[0-9]+$ ]] || [[ "$CURRENT_Y_STREAM" -lt 4 ]]; then
        echo "Invalid Y-stream number. Please enter a valid number (e.g., 15 for version 4.15)."
        return
    fi

    # Loop through the previous 3 Y-streams (e.g., 4.14, 4.13, and 4.12)
    for (( i=1; i<=3; i++ )); do
        PREV_Y_STREAM=$((CURRENT_Y_STREAM - i))

        # Construct the release notes URL dynamically for each previous Y-stream
        RELEASE_NOTES_URL="https://docs.openshift.com/container-platform/4.$PREV_Y_STREAM/release_notes/ocp-4-$PREV_Y_STREAM-release-notes.html"

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
        if grep -q "$BUG_ID" "$TEMP_FILE"; then
            echo "$BUG_ID was found in release notes for 4.$PREV_Y_STREAM"
        else
            echo "$BUG_ID was not found in release notes for 4.$PREV_Y_STREAM"
        fi

        # Cleanup
        rm "$TEMP_FILE"
    done
}

# Main menu function
main_menu() {
    echo "Select an option using the number keys:"
    select option in \
        "Check the Jira status of doc'd known issues in a previous Y release" \
        "Check a Y release for duplicate OCPBUGS in the release notes" \
        "Check links for mismatches between the Jira ID specified in the link's human-readable text vs the Jira ID targeted in the link" \
        "Search previous Y-streams for a specific bug"; do
        case $REPLY in
            1) known_issues_checker; break ;;
            2) check_duplicate_ocpbugs; break ;;
            3) check_mismatched_ocpbugs; break ;;
            4) search_previous_ystreams_for_bug; break ;;
            *) echo "Invalid option. Try again." ;;
        esac
    done
}

# Run the main menu
main_menu