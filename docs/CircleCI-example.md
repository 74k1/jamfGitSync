[Setup your variables](https://circleci.com/docs/env-vars/) so that:

- `$JAMF_PRO_URL` should be `https://yourcompany.jamfcloud.com`
- `$CLIENT_ID` should be the generated Client ID from your Jamf Instance.
- `$CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

```yml
version: 2.1

jobs:
  push-changes-to-jamf-pro:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - run:
          name: "Install Requirements"
          command: sudo apt-get update && sudo apt-get install jq -y
      - run:
          name: "Update changes in Jamf Pro Server 1"
          command: ./jamfGitSync.sh --url "$JAMF_PRO_URL" --clientid "$CLIENT_ID" --clientsecret "$CLIENT_SECRET" --push-changes-to-jamf-pro --backup-updated
      - store_artifacts:
          path: ./backups

workflows:
  jamfGitSync-workflow:
    jobs:
      - push-changes-to-jamf-pro
```
