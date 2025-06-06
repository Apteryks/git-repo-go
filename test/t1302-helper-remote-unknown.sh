#!/bin/sh

test_description="git-repo-go helper proto --type agit"

. lib/test-lib.sh

PATH="$HOME/bin":$PATH
export PATH

test_expect_success "setup" '
	(
		mkdir bin && cd bin &&
		cat >git-repo-go-helper-proto-unknown1 <<-EOF &&
		#!/bin/sh

		git-repo-go helper proto --type agit "\$@"
		EOF
		chmod a+x git-repo-go-helper-proto-unknown1 &&
		cat >git-repo-go-helper-proto-unknown2 <<-EOF &&
		#!/bin/sh

		git-repo-go helper proto --type gerrit "\$@"
		EOF
		chmod a+x git-repo-go-helper-proto-unknown2
	)
'

cat >expect <<EOF
{
	"cmd": "git",
	"args": [
		"push",
		"--receive-pack=agit-receive-pack",
		"-o",
		"title=title of code review",
		"-o",
		"description=description of code review",
		"-o",
		"issue=123",
		"-o",
		"reviewers=u1,u2",
		"-o",
		"cc=u3,u4",
		"ssh://git@example.com/test/repo.git",
		"refs/heads/my/topic:refs/for/master/my/topic"
	]
}
EOF

test_expect_success "upload command (SSH protocol, version 0)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "", "Ref": ""},
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": false,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
		["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "RemoteName": "",
	  "RemoteURL": "ssh://git@example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type unknown1 --upload >actual 2>&1 &&
	test_cmp expect actual
'

cat >expect <<EOF
{
	"cmd": "git",
	"args": [
		"push",
		"-o",
		"title=title of code review",
		"-o",
		"description=description of code review",
		"-o",
		"issue=123",
		"-o",
		"reviewers=u1,u2",
		"-o",
		"cc=u3,u4",
		"ssh://git@example.com/test/repo.git",
		"refs/heads/my/topic:refs/for/master/my/topic"
	],
	"env": [
		"AGIT_FLOW=git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (SSH protocol, version 2)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "", "Ref": ""},
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": false,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
		["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "RemoteName": "",
	  "RemoteURL": "ssh://git@example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type unknown1 --version 2 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
	test_cmp expect actual
'

cat >expect <<EOF
refs/changes/45/12345/1
EOF

test_expect_success "download ref" '
	printf "12345\n" | \
	git-repo-go helper proto --type unknown2 --download >actual 2>&1 &&
	test_cmp expect actual
'

cat >expect <<EOF
Error: cannot find helper 'git-repo-go-helper-proto-unknown3'
EOF

test_expect_success "cannot find helper program" '
	printf "12345\n" | \
	test_must_fail git-repo-go helper proto --type unknown3 --download >actual 2>&1 &&
	test_cmp expect actual
'

test_done
