# Git Semver Tag Resource

A resource for managing a version number on a git repository by using tags.

Conceptually it is based on the [concourse semver resource](https://github.com/concourse/semver-resource) but there is only git and it is focused on tags instead of a file in the repository.
It also allows auto bump versioning based on git commit messages.

## Installing

Use this resource by adding the following to the `resource_types` section of a pipeline config:

```yaml
resource_types:
- name: concourse-git-semver-tag
  type: docker-image
  source:
    repository: laurentverbruggen/concourse-git-semver-tag-resource
```

## Source Configuration

* `initial_version`: *Optional (default: 0.0.0).* The version number to use when bootstrapping, i.e. when there is not a version number present (no tag yet) in the source.

* `tag_prefix`: *Optional.* A prefix to use when constructing a tag from a version. e.g. Use `tag_prefix: v` to record the version `1.2.3` as tag `v1.2.3` and only read tags starting with `v`

* `uri`: *Required.* The repository URL.

* `branch`: *Required.* The branch all tags were made on.

* `private_key`: *Optional.* The SSH private key to use when pulling from/pushing to to the repository.

* `username`: *Optional.* Username for HTTP(S) auth when pulling/pushing.
   This is needed when only HTTP/HTTPS protocol for git is available (which does not support private key auth) and auth is required.

* `password`: *Optional.* Password for HTTP(S) auth when pulling/pushing.

### Example

With the following resource configuration:

``` yaml
resources:
- name: version
  type: concourse-git-semver-tag
  source:
    uri: git@github.com:concourse/concourse.git
    branch: version
    private_key: {{concourse-repo-private-key}}
```

Bumping with a `get` and then a `put`:

``` yaml
plan:
- get: version
  params: {bump: minor}
- task: a-thing-that-needs-a-version
- put: version
  params: {file: version/number}
```

Or, bumping with an atomic `put`:

``` yaml
plan:
- put: version
  params: {bump: minor}
- task: a-thing-that-needs-a-version
```

## Behavior

### `check`: Report the current version number.

Detects new versions by scanning tags on a git repository. If no tags exist yet, it returns the `initial_version`.

### `in`: Provide the version as a file, optionally bumping it.

Provides the version number to the build as a `number` file in the destination.

Can be configured to bump the version locally, which can be useful for getting
the `final` version ahead of time when building artifacts.

#### Parameters

* `bump` and `pre`: *Optional.* See [Version Bumping Semantics](#version-bumping-semantics).

Note that `bump` and `pre` don't update the version resource - they just
modify the version that gets provided to the build. An output must be
explicitly specified to actually update the version.


### `out`: Set the version or bump the current one.

Given a file, use its contents to update the version. Or, given a bump
strategy, bump whatever the current version is. If there is no current version,
the bump will be based on `initial_version`.

The `file` parameter should be used if you have a particular version that you
want to force the current version to be. This can be used in combination with
`in`, but it's probably better to use the `bump` and `pre` params as they'll
perform an atomic in-place bump.

#### Parameters

One of the following must be specified:

* `file`: *Optional.* Path to a file containing the version number to set.

* `bump` and `pre`: *Optional.* See [Version Bumping Semantics](#version-bumping-semantics).

When `bump` and/or `pre` are used, the version bump will be applied atomically.


## Version Bumping Semantics

Both `in` and `out` support bumping the version semantically via two params: `bump` and `pre`.

* `bump`: *Optional (default: patch).* Bump the version number semantically. The value must
be one of:

  * `major`: Bump the major version number, e.g. `1.0.0` -> `2.0.0`.
  * `minor`: Bump the minor version number, e.g. `0.1.0` -> `0.2.0`.
  * `patch`: Bump the patch version number, e.g. `0.0.1` -> `0.0.2`.
  * `auto`: analyse commit messages between HEAD and current version number. Bump the minor version number by default except if the commits contain the following (both is not possible):
    * `[breaking]`: Bump the major version number
    * `[patch]`: Bump the patch version number

  Note: if the current version is a `pre` version and `pre` is not defined then any of the above will result in a final release, e.g. `1.0.0-rc.1` -> `1.0.0`

* `pre`: *Optional.* When bumping, bump to a prerelease (e.g. `rc` or `alpha`), or bump an existing prerelease.

If present, and the version is already a prerelease matching this value, its number is bumped. If the version is already a prerelease of another type, (e.g. `alpha` vs. `beta`), the type is switched and the prerelease version is reset to `0`. If the version is *not* already a pre-release, then `pre` is added, starting at `0`.
