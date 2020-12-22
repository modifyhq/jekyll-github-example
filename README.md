# Jekyll Example Job

This example repository is intended to show how to define and run a job that publishes Modify 
managed content to GitHub Pages using Jekyll and Github Pages for the build. 

## Jekyll

The root of the repository contains a standard Jekyll site setup for hosting on Github Pages.

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

There is a Github Actions workflow defined in `.github/workflows/main.yml` which will be run by
Modify Jobs. It can also be run manually from Github Actions UI provided the required `inputs` are
passed:

- `refresh_token`: Modify refresh token
- `team_slug`: Team slug
- `workspace_slug`: Workspace slug
- `workspace_branch_slug`: Workspace branch slug (defaults to `master`)
- `connector_slug`: Connector slug (defaults to `docs`)
- `connector_path_slug`: Connector path (defaults to `/`)

## Step 1 - Github configuration

The publication cycle of this setup requires changes to be committed and pushed to Github in order for
Github Pages to use them. So you need to fork the repository e.g. `my-org/jekyll-example-job`.

Once forked, the workflow will be disabled by default. To enable it, go to `Actions` in the Github
console and click the `I understand my workflows, go ahead and enable them` button.

To publish the site on Github Pages, go to `Settings` in the Github console
(https://github.com/modifyhq/jekyll-example-job/settings) and in the Github Pages section, set:
- Source to `master`
- Path to `/` (root)
 
The site should then be available at https://my-org.github.io/jekyll-example-job/

Finally, you will need to generate a Github Personal Access Token to allow Modify to trigger the
workflow. You can do this at https://github.com/settings/tokens. It requires full control of private
repositories as changes need to be committed in order to update posts.

## Step 2 - Setup Modify

The following steps assume you have a Modify team with the slug `my-team`. 

Create a new workspace with the slug `jekyll-example-job` and base branch ID `master`.

Create a new Modify connector in your workspace called `docs` with `Editable` access mode.

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

If you have an existing connector that you would like to use, then you will need to adjust the Job
Definition payload in [Step 3](#step-3---create-modify-job) to suit.

## Step 3 - Create Modify Job

In Modify, select the correct team and workspace and go to the Jobs section.

Click the `Create Job` button and and then select the `Tutorial: Publish Jekyll to GitHub Pages`
template:

You will need to complete the following fields:

- Github Owner: `my-org`
- Github Repository: `jekyll-example-job`

Next click `+` next to Credentials and enter the following:
- Name: `Jekyll Example Job`
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
and the updated site will be visible at https://my-org.github.io/jekyll-example-job/. You should
also see a commit called `Updating _posts` with changes to the posts.
