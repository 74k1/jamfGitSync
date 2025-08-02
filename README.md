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
- A generated Client ID & Client Secret for your Jamf Pro instance
    - Permissions required:
      ![required_permissions](/.github/assets/permissions.png)

      <details>
        <summary>in Text..</summary>
        
        - Create Scripts
        - Read Scripts
        - Update Scripts
        - Create Computer Extension Attributes
        - Create Mobile Device Extension Attributes
        - Create User Extension Attributes
        - Read Computer Extension Attributes
        - Read Mobile Device Extension Attributes
        - Read User Extension Attributes
        - Update Computer Extension Attributes
        - Update Mobile Device Extension Attributes
        - Update User Extension Attributes

      </details>

- A CI/CD tool for automation (Jenkins, CircleCI, Bitbucket Pipelines, GitHub Workflows, ...)
- A Runner with at least:
  - Bash 4.0 or higher (macOS ships with 3.2, beware if you use macOS runners)
  - `git` installed
  - [`jq`](https://github.com/jqlang/jq) installed


### Steps

1. Fork / Download this repository

2. Download all of your current scripts & extension attributes:

```sh
./jamfScriptSync.sh --url <YOUR_JAMF_PRO_SERVER> \
    --clientid <API_Client_ID> \
    --clientsecret <API_Client_Secret> \
    --download-scripts \
    --download-eas
```

3. Commit the repository populated with scripts to your git:

```sh
git add .
git commit -a -m "feat(init): initial setup"
```

4. Push this commit to your own repository. (wherever you'll want to have those scripts stored)


### Next Steps

After you're done with the initial setup, your Pipelines _could_ look something like this (ofcourse this depends on your own setup, and these are just examples):

- [Jenkins](https://github.com/74k1/jamfGitSync/wiki/Jenkins-example)
- [BitBucket](https://github.com/74k1/jamfGitSync/wiki/BitBucket-example)
- [GitHub Workflows](https://github.com/74k1/jamfGitSync/wiki/GitHub-Workflows-example)
- [CircleCI](https://github.com/74k1/jamfGitSync/wiki/CircleCI-example)

Now you can make changes to your scripts in your own repository, push those changes to git and watch your CI/CD do the rest of the job. :smile:

## Contribution

All contributions are greatly appreciated! It'd make my day if you could read the Contribution Guidelines first.

- [Contribution Guidelines](https://github.com/74k1/jamfGitSync/blob/main/docs/CONTRIBUTING.md)

I'm looking forward to your suggestions / improvements. :)
