[![Build Status](https://github.com/Apteryks/git-repo-go/actions/workflows/go.yml/badge.svg)](https://github.com/alibaba/git-repo-go/actions/workflows/go.yml)

## git-repo-go

**repo reimplemented in Golang and many others**

`git-repo-go` is `repo` reimplemented in Golang and with many other
features.  Using `git-repo-go`, a developer can create code reviews
(pull requests) from client side directly.  There will be no fork, no
feature branches, and no write permission needed.

`git-repo-go` is a command line tool, which adds more sub-commands to git,
and works for centralized git workflow like Gerrit, agit-flow of Alibaba.com,
and other agit-flow alike protocols...


## Installation

Download or compile the binary of `git-repo-go` from this repository,
and install (copy) the executable of `git-repo-go` to proper location,
such as `/usr/bin` of GNU/Linux and MacOS, and `C:\Windows\system32` of
Windows.

After installation, execute the following command to validate the installation:

    git repo-go version

### Using GNU Guix

`git-repo-go` can be installed via the [GNU
Guix](https://guix.gnu.org/) package manager, which is can be
installed on top of most GNU/Linux distributions:

```
guix install git-repo-go
```

## Git aliases installed from git-repo-go

`git-repo-go` installs some useful git configurations for user, some
unique alias commands are:

    git peer-review => git repo-go upload --single
    git pr => git repo-go upload --single
    git download => git repo-go download --single


## Single repository mode

### Create code-review directly from client side

1. Clone a repository

        git clone https://codeup.teambition.com/gotgit/demo.git

2. Create a local branch (optional)

        git checkout -b some/topic origin/master

3. Create commits in worktree...

4. Create code-review from command line:

        git pr

There are many options for git pr (or git peer-review, or git review), please
check the manual:

        git repo-go upload --help


### Download code-review to local repository for review

A new code-review (pull request) will be created or a old code-review will be
refreshed after running `git pr`.  Each code-review has a unique number, such
as pull request #123.

Reviewer can download it using command

    git download 123

, and make a code review in local worktree.


### Update code-review

Repeated command by author will update the code review:

    git pr


If a reviewer wants to update a code-review, he or she can run:

    git pr --change 123

(suppose 123 is the code review ID, the reviewer just downloaded)


## Multiple repositories

`git-repo-go` supports android style multiple repositories management.

* Init workspace from a manifest project.

        git repo-go init <manifest-url>

* Clone / update all repositories referenced in the manifest repository.

        git repo-go sync

* Create a local working branch instead of detached HEAD on all repositories.

        git repo-go start --all some/topic

* Send changes to remote server to create code reviews.

        git repo-go upload
