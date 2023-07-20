[![CI](https://github.com/tj-actions/vercel-wait/workflows/CI/badge.svg)](https://github.com/tj-actions/vercel-wait/actions?query=workflow%3ACI)
[![Update release version.](https://github.com/tj-actions/vercel-wait/workflows/Update%20release%20version./badge.svg)](https://github.com/tj-actions/vercel-wait/actions?query=workflow%3A%22Update+release+version.%22)
[![Public workflows that use this action.](https://img.shields.io/endpoint?url=https%3A%2F%2Fused-by.vercel.app%2Fapi%2Fgithub-actions%2Fused-by%3Faction%3Dtj-actions%2Fvercel-wait%26badge%3Dtrue)](https://github.com/search?o=desc\&q=tj-actions+vercel-wait+path%3A.github%2Fworkflows+language%3AYAML\&s=\&type=Code)

## vercel-wait

Github action to wait for Vercel's GitHub integration automated deploys to be ready which enables triggering any dependent workflows.

### Example for push event

```yaml
on:
  push:
    branches:
      - main

...
    steps:
      - name: Wait for vercel deployment (push)
        uses: tj-actions/vercel-wait@v1
        with:
          project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          token:  ${{ secrets.VERCEL_TOKEN }}
          sha: ${{ github.sha }}
```

### Example for pull request events

```yaml
on:
  pull_request:
    branches:
      - main

...
    steps:
      - name: Wait for vercel deployment (push)
        uses: tj-actions/vercel-wait@v1
        with:
          project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          token:  ${{ secrets.VERCEL_TOKEN }}
          sha: ${{ github.event.pull_request.head.sha }}
```

## Inputs

<!-- AUTO-DOC-INPUT:START - Do not remove or modify this section -->

|   INPUT    |  TYPE  | REQUIRED | DEFAULT |                                        DESCRIPTION                                         |
|------------|--------|----------|---------|--------------------------------------------------------------------------------------------|
|   delay    | string |  false   | `"10"`  |                                      Delay in seconds                                      |
| project-id | string |   true   |         | Vercel project id can be <br>obtained from `https://vercel.com/<team>/<project>/settings`  |
|    sha     | string |   true   |         |                              The commit sha to wait <br>for                                |
|  team-id   | string |  false   |         |    Vercel team id can be <br>obtained from `https://vercel.com/teams/<team>/settings`      |
|  timeout   | string |  false   | `"600"` |                                     Timeout in seconds                                     |
|   token    | string |   true   |         |          Vercel token can be obtained <br>from https://vercel.com/account/tokens           |

<!-- AUTO-DOC-INPUT:END -->

## Outputs

<!-- AUTO-DOC-OUTPUT:START - Do not remove or modify this section -->

|         OUTPUT         |  TYPE  |        DESCRIPTION         |
|------------------------|--------|----------------------------|
| deployment-alias-error | string | The deployment alias error |
|     deployment-id      | string |     The deployment id      |
|    deployment-state    | string |    The deployment state    |
|     deployment-url     | string |     The deployment url     |

<!-- AUTO-DOC-OUTPUT:END -->

*   Free software: [MIT license](LICENSE)

If you feel generous and want to show some extra appreciation:

[![Buy me a coffee][buymeacoffee-shield]][buymeacoffee]

[buymeacoffee]: https://www.buymeacoffee.com/jackton1

[buymeacoffee-shield]: https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png

## Credits

This package was created with [Cookiecutter](https://github.com/cookiecutter/cookiecutter) using [cookiecutter-action](https://github.com/tj-actions/cookiecutter-action)

## Report Bugs

Report bugs at https://github.com/tj-actions/vercel-wait/issues.

If you are reporting a bug, please include:

*   Your operating system name and version.
*   Any details about your workflow that might be helpful in troubleshooting.
*   Detailed steps to reproduce the bug.
