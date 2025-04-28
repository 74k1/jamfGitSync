[Setup your variables](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/) so that:

- `$JAMF_PRO_URL` should be `https://yourcompany.jamfcloud.com`
- `$CLIENT_ID` should be the generated Client ID from your Jamf Instance.
- `$CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

```yml
image: atlassian/default-image:3

pipelines:
  default:
     - step:
         name: 'Update changes in Jamf Pro server'
         clone:
           depth: 2
         script:
           - apt-get update && apt-get install libxml2-utils xmlstarlet -y
           - ./jamfGitSync.sh --url "$JAMF_PRO_URL" --clientid "$CLIENT_ID" --clientsecret "$CLIENT_SECRET" --push-changes-to-jamf-pro --backup-updated
         artifacts:
           - backups/**
```
