#!/bin/sh

test_description="git-repo-go init"

. lib/test-lib.sh

manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"
main_repo_url="file://${REPO_TEST_REPOSITORIES}/hello/main.git"
wrong_url="file://${REPO_TEST_REPOSITORIES}/hello/bad"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "init from wrong url" '
	(
		cd work &&
		test_must_fail git-repo-go init -u $wrong_url &&
		test ! -d .repo/manifests.git
	)
'

test_expect_success "init from main url without a valid xml" '
	(
		cd work &&
		test_must_fail git-repo-go init -u $main_repo_url >out 2>&1 &&
		grep "^Error" out >actual &&
		cat >expect<<-EOF &&
		Error: link manifest failed, cannot find file '"'"'manifests/default.xml'"'"'
		EOF
		test_cmp expect actual
	)
'

test_done
