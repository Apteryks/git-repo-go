#!/bin/sh

test_description="test git-repo-go version"

. lib/test-lib.sh

test_expect_success "git-repo-go version output test" '
	git-repo-go version >out &&
	grep "^git-repo-go version" out |
		sed -e "s/[0-9][0-9]*\.[0-9][0-9]*\.[0-9].*$/N.N.N/" \
		>actual &&
	cat >expect <<-EOF &&
	git-repo-go version N.N.N
	EOF
	test_cmp expect actual
'

test_done
