# Copier template to create Plone/Zope setup - EXPERIMENTAL !!!

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)

It supports storage backends standalone, ZEO and Relstorage and is using pyruvate as WSGI server.
This template is meant to work standalone and inside an Plone addon.

## Features

- support's 3 storage options: direct (standalone), ZEO, relstorage
- uses pyproject.toml and [UV](https://docs.astral.sh/uv/) with [hatchling](https://hatch.pypa.io/1.13/config/build/#build-system) build-backend
- is able to update existing setups when the template changes

More info about [Copier](https://copier.readthedocs.io/en/stable/) to generate things from templates.


## Usage

### Install `copier`

If you don't have `copier` already installed, the easiest way is running this command:

```sh
uv tool install copier
```

This will install copier as a `uv` tool and you can run it directly.

### Create project

```sh
copier copy gh:plone/copier-zope-setup . --trust
```

### Install `invoke`

if you don't have `invoke` installed, the easiest way is running this command:

```sh
uv tool install invoke
```


### Install or update dependencies

```sh
invoke install
```

### Start Plone

```sh
invoke start
```

### Update existing project

When ever the template has updates, you can update your generated project.

```sh
copier update --trust
```

or without the answering the questions again:

```sh
copier update --defaults --trust
```

You can also add `https://github.com/MrTango/pdmplone` to trusted locations in Copier settings file and run the commands without the `--trust` parameter.

https://copier.readthedocs.io/en/stable/settings/#trusted-locations

#### Example Copier settings file

On Linux:

```sh
mkdir ~/.config/copier
touch ~/.config/copier/settings.yml
```

Note: for the default to work, the question has to have a default parameter set!

```yml
defaults:
  user_name: "MrTango"
  user_email: md@derico.de
  github_user: "MrTango"
  gitlab_user: "MrTango78"
  mastodon_handle: "https://mastodon.social/@mrtango"
  dbuser: "plonerel"
trust:
  - https://github.com/plone/
  - gh:plone/
```