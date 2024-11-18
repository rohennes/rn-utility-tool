# Release note utility tool

The aim of this tool is to automate some common tasks when creating and reviewing OCP release notes. This tool is currently in development.

To test the tool locally, complete these steps:

1. Create a personal Jira token here: https://issues.redhat.com/secure/ViewProfile.jspa?selectedTab=com.atlassian.pats.pats-plugin:jira-user-personal-access-tokens

2. Export the token to a local $MY_TOKEN variable: `export MY_TOKEN=<personal_jira_token>`

3. Download the sccript locally and ensure you have exectuable access: `chmod +x rn-utility-tool.sh`

4. Run the script: `./rn-utility-tool.sh`

**IMPORTANT** - Do not make your Jira token public, do not include in any commits to Github!

## Options

1. **Check current status in Jira for known issues in a Y-stream**: Check known issues in set of Y-stream release notes and fetches the Jira status of each known issue.

2. **Finds duplicate bugs in a release**: Check for duplicate OCPBUGS links in a Y-stream (may be good reason for duplicates but flags anyway).

3. **Check bug links vs human readable labels**: Check all OCPBUGS in a Y-stream and verify links to ensure the OCPBUGS ID in the human readable label matches the ID in the target link.

4. **Search previous Y-streams for a bug**: Check the three previous Y-stream release notes for a bug.

5. **Review TP tables** Check Tech Preview status tables for features that are Ga for three consecutive releases. These should be removed.
