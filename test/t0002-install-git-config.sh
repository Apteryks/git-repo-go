#!/bin/sh

test_description="install extra config"

. lib/test-lib.sh

test_expect_success "before install extra git config" '
	test ! -f .gitconfig &&
	test ! -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	EOF
	test_must_fail git config --global --get-all include.path >actual &&
	test_cmp expect actual &&
	cat >expect <<-EOF
	EOF
'

test_expect_success "install git config by running git-repo-go" '
	test_must_fail git-repo-go &&
	test -f .gitconfig &&
	test -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	status
	EOF
	git config -f .git-repo-go/gitconfig alias.st >actual &&
	test_cmp expect actual
'

test_expect_success "install git config by running git-repo-go --version" '
	rm .gitconfig &&
	rm .git-repo-go/gitconfig &&
	git-repo-go --version &&
	test -f .gitconfig &&
	test -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	$HOME/.git-repo-go/gitconfig
	EOF
	git config --global --get-all include.path >actual &&
	test_cmp expect actual &&
	cat >expect <<-EOF &&
	branch
	commit -s
	checkout
	cherry-pick
	status
	EOF
	git config -f .git-repo-go/gitconfig alias.br  >actual &&
	git config -f .git-repo-go/gitconfig alias.ci >>actual &&
	git config -f .git-repo-go/gitconfig alias.co >>actual &&
	git config -f .git-repo-go/gitconfig alias.cp >>actual &&
	git config -f .git-repo-go/gitconfig alias.st >>actual &&
	test_cmp expect actual
'

test_expect_success "install git config by running git-repo-go version" '
	rm .gitconfig &&
	rm .git-repo-go/gitconfig &&
	git-repo-go version &&
	test -f .gitconfig &&
	test -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	status
	EOF
	git config -f .git-repo-go/gitconfig alias.st >actual &&
	test_cmp expect actual
'

test_expect_success "reinstall .git-repo-go/gitconfig by git-repo-go --version" '
	rm .git-repo-go/gitconfig &&
	test -f .gitconfig &&
	git-repo-go --version &&
	test -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	status
	EOF
	git config -f .git-repo-go/gitconfig alias.st >actual &&
	test_cmp expect actual

'

test_expect_success "reinstall .git-repo-go/gitconfig by git-repo-go version" '
	rm .git-repo-go/gitconfig &&
	test -f .gitconfig &&
	git-repo-go version &&
	test -f .git-repo-go/gitconfig &&
	cat >expect <<-EOF &&
	status
	EOF
	git config -f .git-repo-go/gitconfig alias.st >actual &&
	test_cmp expect actual
'

test_expect_success "include.path has bad file location" '
	location=$(git config -f .gitconfig include.path) &&
	test -f "$location" &&
	test_cmp expect actual &&
	git config -f .gitconfig include.path bad/file &&
	test_must_fail git config alias.pr
'

test_expect_success "fix wrong abs git repo-go go config path" '
	test -f .git-repo-go/gitconfig &&
	test -f .gitconfig &&
	git-repo-go version &&
	cat >expect <<-EOF &&
	repo-go upload --single
	EOF
	git config -f .git-repo-go/gitconfig alias.pr >actual &&
	test_cmp expect actual
'

test_done
