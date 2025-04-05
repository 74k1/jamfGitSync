# jamfGitSync

Use git as the source of truth for your scripts! Utilizes CI/CD pipelines that uploads the most recently changed scripts to a Jamf Pro server.

This is a rewrite of [git4jamfpro](https://github.com/alectrona/git4jamfpro) (which is a rewrite of [git2jss](https://github.com/badstreff/git2jss)). Both very good scripts, however I quickly found out both of them still use the [classic API endpoint](https://developer.jamf.com/jamf-pro/docs/getting-started-2) and not the new [Jamf Pro API Endpoint](https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview). (I also preffered json instead of xml files)

## Benefits of the above mentioned alternatives

- No python dependency
- No xmlstarlet dependency
- Uses Client ID & Client Secrets through API roles and clients instead of Bearer Auth
- Allows you to upload very large scripts ([INSTALLOMATOR](https://github.com/Installomator/Installomator) for example)
- Allows you to download all scripts in parallel from a Jamf Pro server

## Usage

### Requirements

- A Jamf Pro instance (ofcourse)
- A git vcs server (github, bitbucket, ...)
- [`jq`](https://github.com/jqlang/jq) installed
- A generated Client ID & Client Secret for your Jamf Pro instance
    - Permissions required:
        - Create Scripts
        - Read Scripts
        - Update Scripts
- A CI/CD tool for automation (Jenkins, CircleCI, Bitbucket Pipelines, GitHub Workflows, ...)

### Steps

1. Fork / Download this repository

2. Download all of your current scripts:

```sh
./jamfScriptSync.sh --url <YOUR_JAMF_PRO_SERVER> \
    --clientid <API_Client_ID> \
    --clientsecret <API_Client_Secret> \
    --download-scripts
```

3. Commit the repository populated with scripts to your git:

```sh
git add .
git commit -a -m "feat(init): initial setup"
```

4. Configure your CI/CD pipeline (see [Wiki](https://github.com/74k1/jamfGitSync/wiki/Pipeline-examples))

5. Now you can make changes to your scripts locally, push those changes to git and watch your CI/CD do the rest of the job.

## Contribution

Feel free to submit PRs! I'm looking forward to your suggestions / improvements. :)
