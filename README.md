# Github deploy action

![CI](https://github.com/rollbar/github-deploy-action/workflows/CI/badge.svg)

A GitHub action that notifies deploys to [Rollbar](https://rollbar.com).


## Usage

This action requires that you set the `ROLLBAR_ACCESS_TOKEN` environment variable with a token that must have the [`post_server_item`](https://explorer.docs.rollbar.com/#section/Authentication/Project-access-tokens) scope.
You can find it under your project's settings in the Project access token section.

When notifiying deploys in two stages, for sending to Rollbar when a deploy starts and the status of its result (succeeded or failed ) you need
also to set the `DEPLOY_ID` environment variable with the ouput of the previous step.

Optionally set `ROLLBAR_USERNAME` environment variable, usernames can be found at:
> https://rollbar.com/settings/accounts/YOUR_TEAM/members/

> NOTE: When using [`github.actor`](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context) as the `ROLLBAR_USERNAME` ensure the username in Rollbar matches your github username.


### Inputs

| Input          | Required  | Default      | Description                                      |
| -------------- | --------- | ------------ | ------------------------------------------------ |
| `environment`  | `true`    |              | The environment where the deploy is being done.  |
| `version`      | `true`    |              | The version being deployed.                      |
| `status`       | `false`   | `succeeded`  | The status of the deploy.                        |
| `source_maps`  | `false`   |              | JS source map files.                             |
| `minified_urls`| `false`   |              | Minified URLs linked to source maps above        |

### Ouputs

| Input        | Description           |
| ------------ | --------------------- |
| `deploy_id`  | The id of the deploy. |


### Example

```yaml
steps:
  - name: Notify deploy to Rollbar
    uses: rollbar/github-deploy-action@1.1.0
    id: rollbar_deploy
    with:
      environment: 'production'
      version: ${{ github.sha }}
    env:
      ROLLBAR_ACCESS_TOKEN: ${{ secrets.ROLLBAR_ACCESS_TOKEN }}
      ROLLBAR_USERNAME: ${{ github.actor }}
```


### Example with deploy update

```yaml
steps:
  - name: Notify start deploy to Rollbar
    uses: rollbar/github-deploy-action@1.1.0
    id: rollbar_pre_deploy
    with:
      environment: 'production'
      version: ${{ github.sha }}
      status: 'started'
    env:
      ROLLBAR_ACCESS_TOKEN: ${{ secrets.ROLLBAR_ACCESS_TOKEN }}
      ROLLBAR_USERNAME: ${{ github.actor }}

...

steps:
  - name: Notify finish deploy to Rollbar
    uses: rollbar/github-deploy-action@1.1.0
    id: rollbar_post_deploy
    with:
      environment: 'production'
      version: ${{ github.sha }}
      status: 'succeeded'
    env:
      ROLLBAR_ACCESS_TOKEN: ${{ secrets.ROLLBAR_ACCESS_TOKEN }}
      ROLLBAR_USERNAME: ${{ github.actor }}
      DEPLOY_ID: ${{ steps.rollbar_pre_deploy.outputs.deploy_id }}
```
### Example with JS Source Map
```yaml
jobs:
  # This workflow builds source maps
  build:
    - uses: actions/checkout@v2
    - name: npm run build
      run: npm run build --prefix templates/static/
    - uses: actions/upload-artifact@v2
      with:
        name: bundle.js.map
        path: public/bundle.js.map
    - uses: actions/upload-artifact@v2
      with:
        name: bundle2.js.map
        path: public/bundle2.js.map

  deploy:
    needs: build
    steps:
    - uses: actions/checkout@v2      
    - uses: actions/download-artifact@v2
      with:
        name: bundle.js.map
    - uses: actions/download-artifact@v2
      with:
        name: bundle2.js.map
    - name: Rollbar deploy
      uses: rollbar/github-deploy-action@1.1.0
      with:
        environment: production
        version: ${{ github.sha }}
        status: succeeded
        source_maps: bundle.js.map bundle2.js.map
        minified_urls: https://www.example.com/public/bundle.js https://www.example.com/public/bundle2.js
      env:
          ROLLBAR_ACCESS_TOKEN: ${{ secrets.ROLLBAR_ACCESS_TOKEN }}
```
