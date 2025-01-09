#!/bin/bash



# Jira API base URL
JIRA_API_BASE="https://issues.redhat.com/rest/api/2/issue"

# Functionality 1: Known Issues Checker
known_issues_checker() {

    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
read -p "Enter the y-stream release number to check known issue statsus. For example, for 4.15, enter "15": " Y_STREAM
echo ""

    # Construct the release notes URL dynamically based on user input
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    KNOWN_ISSUES=$(awk '/== Known issues/ {flag=1} flag && /== Asynchronous errata updates/ {exit} flag' "$TEMP_FILE")
    
    # Extract OCPBUGS links from the known issues section
    BUG_URLS=$(echo "$KNOWN_ISSUES" | grep -oP 'https://issues.redhat.com/browse/OCPBUGS-\d+' | uniq)

    # Check Jira status for each bug and report those that are not closed
    echo "Checking known issue OCPBUGS statuses for 4.$Y_STREAM..."

    for bug_url in $BUG_URLS; do
            # Extract the bug ID (e.g., OCPBUGS-12345)
            BUG_ID=$(echo "$bug_url" | grep -oP 'OCPBUGS-\d+')

            # Fetch the bug status from Jira
            BUG_STATUS=$(curl -sSL "$JIRA_API_BASE/$BUG_ID" | jq -r '.fields.status.name')

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
    echo ""

    # Construct the release notes URL dynamically based on user input
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.adoc"

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
    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
    read -p "Enter the y-stream release number, e.g., for 4.15, enter 15: " Y_STREAM
    echo ""

    # Construct the release notes URL dynamically based on user input
    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.adoc"

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
    MISMATCHES=$(grep -oP 'link:https://issues.redhat.com/browse/OCPBUGS-\d+\[\*OCPBUGS-\d+\*\]' "$TEMP_FILE")

    # Initialize a flag for found mismatches
    FOUND_MISMATCHES=0

    # Process each mismatch line
    while read -r line; do
        # Extract the actual bug ID and the displayed bug ID
        ACTUAL_BUG=$(echo "$line" | grep -oP 'link:https://issues.redhat.com/browse/OCPBUGS-\d+' | grep -oP 'OCPBUGS-\d+')
        # Extract the displayed bug ID (inside the [* *] brackets)
        DISPLAYED_BUG=$(echo "$line" | grep -oP '\[\*OCPBUGS-\d+\*\]' | grep -oP 'OCPBUGS-\d+')

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
    echo ""

    # Check for valid input (current Y-stream should be an integer greater than or equal to 4)
    if ! [[ "$CURRENT_Y_STREAM" =~ ^[0-9]+$ ]] || [[ "$CURRENT_Y_STREAM" -lt 4 ]]; then
        echo "Invalid Y-stream number. Please enter a valid number (e.g., 15 for version 4.15)."
        return
    fi

    # Loop through the previous 3 Y-streams (e.g., 4.14, 4.13, and 4.12)
    for (( i=1; i<=3; i++ )); do
        PREV_Y_STREAM=$((CURRENT_Y_STREAM - i))

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
        if grep -q "$BUG_ID" "$TEMP_FILE"; then
            echo "$BUG_ID was found in release notes for 4.$PREV_Y_STREAM"
        else
            echo "$BUG_ID was not found in release notes for 4.$PREV_Y_STREAM"
        fi

        # Cleanup
        rm "$TEMP_FILE"
    done
}

# Functionality 5: Check TP tables for features that are GA for past three releases
check_tp_tables() {

    # Ask the user to input the y-stream release number (e.g., for 4.15, they will enter 15)
    read -p "Enter the y-stream release to examine. For example, for 4.15, enter "15": " Y_STREAM
    echo ""

    RELEASE_NOTES_URL="https://raw.githubusercontent.com/openshift/openshift-docs/refs/heads/enterprise-4.$Y_STREAM/release_notes/ocp-4-$Y_STREAM-release-notes.adoc"

    # Temporary file to store fetched release notes
    TEMP_FILE="ocp_release_notes.html"

    # Download the release notes
    curl -s "$RELEASE_NOTES_URL" -o "$TEMP_FILE"

    # Check if the download was successful
     if [[ ! -s "$TEMP_FILE" ]]; then
         echo "Failed to download release notes for 4.$Y_STREAM or the file is empty."
         continue
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

# Main menu function
main_menu() {
    echo ""
    echo "#################"
    echo ""
    echo "Select an option using the number keys:"
    select option in \
        "Check the Jira status of published known issues for a specific Y release" \
        "Check a Y release for duplicate OCPBUGS in the release notes" \
        "Check links for mismatches between the Jira ID specified in the link's human-readable text vs the Jira ID targeted in the link" \
        "Search previous Y-streams for a specific bug" \
        "Check Tech Preview status tables for features that are GA for 3 consecutive releases"; do
        case $REPLY in
            1) known_issues_checker; break ;;
            2) check_duplicate_ocpbugs; break ;;
            3) check_mismatched_ocpbugs; break ;;
            4) search_previous_ystreams_for_bug; break ;;
            5) check_tp_tables; break ;;
            *) echo "Invalid option. Try again." ;;
        esac
    done
    # Function to handle the flow after the main menu
    while true; do
        echo ""
        read -p "Do you want to return to the menu or quit? (Enter 'm' to continue or 'q' to exit): " user_choice
        case $user_choice in
            m)
                main_menu  # Restart the main menu
                break
                ;;
            q)
                echo "Exiting the tool. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid input. Please enter 'm' or 'q'."
                ;;
        esac
    done
}

# Run the main menu
main_menu


