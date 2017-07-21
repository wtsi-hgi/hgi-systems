[![Build Status](https://travis-ci.org/wtsi-hgi/git-common-sync.svg?branch=master)](https://travis-ci.org/wtsi-hgi/git-common-sync)
[![codecov](https://codecov.io/gh/wtsi-hgi/git-common-sync/branch/master/graph/badge.svg)](https://codecov.io/gh/wtsi-hgi/git-common-sync)
[![PyPI version](https://badge.fury.io/py/gitcommonsync.svg)](https://badge.fury.io/py/gitcommonsync)


# Git Common Sync
_A tool to synchronise common files between Git repositories._


## Features
- Programmatically synchronises git repositories according to a specification.
- Supports synchronisation of:
    - Files and directories.
    - Directories managed by [git-subrepo](https://github.com/ingydotnet/git-subrepo).
    - Content generated using templates and project specific values.
- Ansible support.


## How to use
### Prerequisites
 - git >= 2.10.0
 - git-subrepo >= 0.3.1
 - python >= 3.6
 - rsync >= 3.1.1


### Installation
#### Ansible Module
```yaml
- gitcommonsync:
    repository: http://www.example.com/repository.git
    committer_name: Ansible Synchroniser
    committer_email: team@example.com
    key_file: /custom/id_rsa
    files:
      - src: /example/README.md
        dest: README.md
        overwrite: false
      - src: /example/directory/
        dest: config
    templates:
      - src: /example/ansible-groups.sh.j2
        dest: ci/before_scripts.d/start.sh
        variables:
          message: "Hello world"
        overwrite: true
    subrepos:
      - src: http://www.example.com/other-repository.git
        dest: subrepos/other-repository
        branch: master
        overwrite: true
```


## Development
### Setup
Install both library dependencies and the dependencies needed for testing:
```bash
$ pip install -q -r requirements.txt
$ pip install -q -r test_requirements.txt
```

### Testing
To run the tests and generate a coverage report with unittest:
```bash
./test-runner.sh
```
If you wish to run the tests inside a Docker container (recommended), build `Docker.test`.


## Alternatives
- Powerful but complex Ruby based alternative from the Puppet community: https://github.com/voxpupuli/modulesync.


## License
[MIT license](LICENSE.txt).

Copyright (c) 2017 Genome Research Limited
