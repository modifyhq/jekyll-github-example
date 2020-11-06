# Jekyll Demo

Publishing Modify managed content to a Jekyll repository using Github Pages.

This example assumes the following:
- Modify Team: healthforge
- Modify Workspace: demo
- Github Username: healthforge
- Github Repository: jekyll-demo

## Local testing

This repository contains a standard Jekyll site setup for hosting on Github Pages.

For local testing it requires:

- rbenv
- bundler

To serve locally:
```bash
bundle install
bundle exec jekyll serve
```

Site should be accessible on http://127.0.0.1:4000/jekyll-demo/

## Github configuration

The workflow is defined in `.github/workflows/update.yml`. It is designed to be run by Modify Jobs,
but it can also be run manually from Github Actions UI provided the required `inputs` are passed:

- refresh_token: Modify refresh token
- team: Team slug
- workspace: Workspace slug
- workspace_branch: Workspace branch slug (defaults to master)
- connector: Connector slug (defaults to docs)
- connector_path: Connector path (defaults to /)

To publish the site on Github Pages, go to Settings (https://github.com/healthforge/jekyll-demo/settings)
and set the GitHub Pages source to `master` and the path to `/` (root). The site should then be
available on https://healthforge.github.io/jekyll-demo/

## Modify configuration

Create a Modify Connector in your workspace called `docs` with protected access mode.

Branch the new connector to `develop` in order to make changes.

Add a file to the connector root called `2020-11-11-test-post.md` with the following content:
```
---
layout: post
title:  "Test Post"
date:   2020-11-11 11:11:11 +0000
---
## Subtitle

Some text
``` 
and commit your changes.

Use Update Branch to merge your changes back to `master`.

Create a new Job:

- Name: Jekyll Demo
- Target: POST https://api.github.com/repos/healthforge/jekyll-demo/actions/workflows/update.yml/dispatches
- Headers:
    - Accept: application/vnd.github.v3+json
- Payload:
    ```
    {
      "ref": "master",
      "inputs": {
        "refresh_token":"{{REFRESH_TOKEN}}",
        "job_instance_id":"{{JOB_INSTANCE_ID}}",
        "team": "healthforge",
        "workspace": "demo"
      }
    }
    ```
- Credentials: Authorised to write to the Github repository

When this job is run, it should start the Github workflow and update the Jekyll posts. Once the job
is complete you should see the new post at https://healthforge.github.io/jekyll-demo/2020/11/11/test-post.html