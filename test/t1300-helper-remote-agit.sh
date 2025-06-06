#!/bin/sh

test_description="git-repo-go helper proto --type agit"

. lib/test-lib.sh

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
		"origin",
		"refs/heads/my/topic:refs/for/master/my/topic"
	]
}
EOF

test_expect_success "upload command (SSH protocol, verison 0)" '
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
	  "RemoteName": "origin",
	  "RemoteURL": "ssh://git@example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --upload >actual 2>&1 &&
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
		"origin",
		"refs/heads/my/topic:refs/for/master/my/topic"
	],
	"env": [
		"AGIT_FLOW=git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (SSH protocol, verison 2)" '
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
	  "RemoteName": "origin",
	  "RemoteURL": "ssh://git@example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --version 2 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
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
		"origin",
		"refs/heads/my/topic:refs/drafts/master/my/topic"
	],
	"env": [
		"AGIT_FLOW=git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (SSH protocol, draft, version 2)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "", "Ref": ""},
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": true,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
		["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "RemoteName": "origin",
	  "RemoteURL": "ssh://git@example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --version 2 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
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
		"example",
		"refs/heads/my/topic:refs/for/master/my/topic"
	],
	"gitconfig": [
		"http.extraHeader=AGIT-FLOW: git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (HTTP protocol, version 0)" '
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
	  "RemoteName": "example",
	  "RemoteURL": "https://example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
	test_cmp expect actual
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
		"ssh://git@example.com:29418/test/repo.git",
		"refs/heads/my/topic:refs/for-review/12345"
	]
}
EOF

test_expect_success "upload command (SSH protocol with code review ID, version 0)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "12345", "Ref": "refs/merge-requests/12345"},
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
	  "RemoteURL": "ssh://git@example.com:29418/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --upload >actual 2>&1 &&
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
		"ssh://git@example.com:29418/test/repo.git",
		"refs/heads/my/topic:refs/for-review/12345"
	],
	"env": [
		"AGIT_FLOW=git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (SSH protocol with code review ID, version 2)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "12345", "Ref": "refs/merge-requests/12345"},
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
	  "RemoteURL": "ssh://git@example.com:29418/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --version 2 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
	test_cmp expect actual
'

cat >expect <<EOF
{
	"cmd": "git",
	"args": [
		"push",
		"-o",
		"review=123",
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
		"ssh://git@example.com:29418/test/repo.git",
		"refs/heads/my/topic:refs/heads/master"
	],
	"env": [
		"AGIT_FLOW=git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (SSH protocol with code review ID, version 3)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "123", "Ref": "refs/changes/123/head"},
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
	  "RemoteURL": "ssh://git@example.com:29418/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --version 3 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&

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
		"origin",
		"refs/heads/my/topic:refs/for-review/12345"
	],
	"gitconfig": [
		"http.extraHeader=AGIT-FLOW: git-repo-go/n.n.n.n"
	]
}
EOF

test_expect_success "upload command (HTTP protocol with code review ID, draft)" '
	cat <<-EOF |
	{
	  "CodeReview": {"ID": "12345", "Ref": "refs/merge-requests/12345"},
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": true,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
		["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "RemoteName": "origin",
	  "RemoteURL": "http://example.com/test/repo.git",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
	}
	EOF
	git-repo-go helper proto --type agit --version 2 --upload >out 2>&1 &&
	sed -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
	test_cmp expect actual
'

test_expect_success "download MR 123456 (agit-v2)" '
	printf "12345\n" | \
	git-repo-go helper proto --type agit --version 2 --download >actual 2>&1 &&
	cat >expect <<-EOF &&
		refs/merge-requests/12345/head
	EOF
	test_cmp expect actual
'

test_expect_success "download CR 123 (agit-v3)" '
	printf "123\n" | \
	git-repo-go helper proto --type agit --version 3 --download >actual 2>&1 &&
	cat >expect <<-EOF &&
		-o review=123
		refs/changes/123/head
	EOF
	test_cmp expect actual
'

test_expect_success "download CR 123/2 (agit-v3)" '
	printf "123/2\n" | \
	git-repo-go helper proto --type agit --version 3 --download >actual 2>&1 &&
	cat >expect <<-EOF &&
		-o review=123
		refs/changes/123/2
	EOF
	test_cmp expect actual
'

test_done
