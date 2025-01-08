# Release note utility tool

The aim of this tool is to automate some common tasks when creating and reviewing OCP release notes. This tool is currently in development. Feel free to open an issue or submit a PR.

# Installing the tool

To test the tool locally, complete these steps:

1. Clone repo locally and ensure you have exectuable access for the script: `chmod +x rn-utility-tool.sh`

2. Create a personal Jira token here: https://issues.redhat.com/secure/ViewProfile.jspa?selectedTab=com.atlassian.pats.pats-plugin:jira-user-personal-access-tokens

3. Save the token in a `.env` file locally:
    
    ```bash
    cat > .env <<EOF
    MY_TOKEN=<REDACTED>
    EOF
    ```

4. Export the token from the local environment:

    ```bash
    source .env
    export MY_TOKEN
    ```
5. Run the script: `./rn-utility-tool.sh`

**IMPORTANT** - Do not make your Jira token public, do not include in any commits to Github!

# Running the tool

1. For each shell session, load the environment variable containing your token: `source .env`

2. Run the script: `./rn-utility-tool.sh`

## Functionality options when using the tool

1. **Check current status in Jira for known issues in a Y-stream**: Check known issues in set of Y-stream release notes and fetches the Jira status of each known issue.

2. **Finds duplicate bugs in a release**: Check for duplicate OCPBUGS links in a Y-stream (may be good reason for duplicates but flags anyway).

3. **Check bug links vs human readable labels**: Check all OCPBUGS in a Y-stream and verify links to ensure the OCPBUGS ID in the human readable label matches the ID in the target link.

4. **Search previous Y-streams for a bug**: Check the three previous Y-stream release notes for a bug.

5. **Review TP tables** Check Tech Preview status tables for features that are Ga for three consecutive releases. These should be removed.
