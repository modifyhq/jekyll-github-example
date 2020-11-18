# Jekyll Demo

This demo repository is intended to show how to publish Modify managed content to a Jekyll
repository using Github Pages.

## Jekyll

This repository contains a standard Jekyll site setup for hosting on Github Pages.

To test it locally you need a working ruby 2.6 environment. We recommend using `rbenv` for this, 
setup instructions are available at https://github.com/rbenv/rbenv

Install bundler
```bash
gem install bundler
```

Serve locally
```bash
bundle exec jekyll serve
```
Site should be accessible on http://127.0.0.1:4000/jekyll-demo/

## `update_posts.sh`

This script is designed to be run by Github Actions and will
- Download blog posts from a Modify connector
- Empty `_posts` and unpack the downloaded posts to replace the previous content
- Commit and push changes to Github
- Notify Modify it has completed (if provided with a JOB_INSTANCE_ID)

## Github Actions

A Github Actions workflow is defined in `.github/workflows/update.yml`. It is designed to be run by
Modify Jobs, but it can also be run manually from Github Actions UI provided the required `inputs`
are passed:

- `refresh_token`: Modify refresh token
- `team`: Team slug
- `workspace`: Workspace slug
- `workspace_branch`: Workspace branch slug (defaults to `master`)
- `connector`: Connector slug (defaults to `docs`)
- `connector_path`: Connector path (defaults to `/`)

## Step 1 - Github configuration

The publish cycle of this setup requires changes to be committed and pushed to Github in order for
Github Pages to use them. So you need to fork the respository e.g. `my-org/modify-jekyll-demo`

To publish the site on Github Pages, go to Settings in your new repository
(https://github.com/healthforge/jekyll-demo/settings) and in the Github Pages section, set:
- Source to `master`
- Path to `/` (root)
 
The site should then be available on https://my-org.github.io/modify-jekyll-demo/

You will need to generate a Github Personal Access Token to allow Modify to trigger the workflow.
You can do this at https://github.com/settings/tokens. It requires full control of private
repositories as changes will be committed when updating posts.

## Step 2 - Setup Modify

The following steps assume you have a Modify team called `my-team`. 

Create a new workspace called `jekyll-demo`.

Create a new connector in your workspace called `docs` with protected access mode.

Create a new workspace branch (e.g `develop`) in order to make changes.

Add a file to the connector called `/jekyll/2020-11-11-test-post.md` with the following content:
```
---
title: Test Post
date:   2020-11-11 11:11:11 +0000
---
## Subtitle

Some text
``` 
and commit your changes.

Use Update Branch to merge your changes back to the root branch (`master`).

If you have an existing connector that you would like to use, then you will need to adjust the Job
Definition payload in [Step 3](#step-3---create-modify-job) to suit.

## Step 3 - Create Modify Job

In Modify, select the correct team and workspace and go to the Jobs section.

Click the `Create Job` button and enter the following:

- Name: `Jekyll Demo`
- Target: `POST https://api.github.com/repos/my-org/modify-jekyll-demo/actions/workflows/update.yml/dispatches`
- Headers:
    - `Accept`: `application/vnd.github.v3+json`
- Payload:
    ```
    {
      "ref": "master",
      "inputs": {
        "refresh_token":"{{REFRESH_TOKEN}}",
        "job_instance_id":"{{JOB_INSTANCE_ID}}",
        "team": "my-team",
        "workspace": "jekyll-demo",
        "workspace_branch": "master",
        "connector": "docs",
        "connector_path": "/jekyll/"
      }
    }
    ```

Next click `+` next to Credentials and enter the following:
- Name: `Jekyll Demo`
- Username: `<Github username>`
- Password: `<Github personal access token>`

Then click `Add Credential` to create the new credential and return to the `Create Job` form.

Your new credential should have been selected automatically, so you can finally click `Create` to
save your new Job Definition.

Click the name of the new Job Definition to display the details.

## Step 4 - Run the Modify Job

Click `Start` to run the Job and a new Job Instance will be created. This will `POST` the payload to
the Github API gateway along with configured credentials, `REFRESH_TOKEN` and `JOB_INSTANCE_ID`.
Modify expects the remote system to notify when the job is complete using these details.

When this is complete you should see the Job Instance in Modify change from `Started` to `Finished`,
and the updated site will be visible at https://my-org.github.io/modify-jekyll-demo/. You should
also see a commit called `Updating _posts` with changes to the posts.
