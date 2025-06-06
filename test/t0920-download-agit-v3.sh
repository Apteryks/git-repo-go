#!/bin/sh

test_description="test 'git-repo-go download' basic for agit v3"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work &&
	(
		cd work &&
		git-repo-go init -u $manifest_url &&
		git-repo-go sync \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" &&
		git-repo-go start --all jx/topic
	)
'

test_expect_success "download and checkout" '
	(
		cd work &&
		git-repo-go download \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" \
			main 123/1
	) &&
	(
		cd work/main &&
		echo "Branch: $(git_current_branch)" &&
		git log --pretty="    %s" -2 &&
		git show-ref | cut -c 42- | grep changes
	) >out 2>&1 &&
	sed -e "s/(no branch)/Detached HEAD/g" out >actual &&
	cat >expect<<-EOF &&
	Branch: Detached HEAD
	    New topic
	    Version 0.1.0
	refs/changes/123/1
	EOF
	test_cmp expect actual
'

test_expect_success "download again with already merged notice" '
	(
		cd work &&
		git-repo-go download \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" \
			main 123/1
	) >actual 2>&1 &&
	cat >expect<<-EOF &&
	NOTE: [main] change 123/1 has already been merged
	EOF
	test_cmp expect actual &&
	(
		cd work/main &&
		echo "Branch: $(git_current_branch)" &&
		git log --pretty="    %s" -2 &&
		git show-ref | cut -c 42- | grep changes
	) >out 2>&1 &&
	sed -e "s/(no branch)/Detached HEAD/g" out >actual &&
	cat >expect<<-EOF &&
	Branch: Detached HEAD
	    New topic
	    Version 0.1.0
	refs/changes/123/1
	EOF
	test_cmp expect actual
'

test_expect_success "restore using sync and start again" '
	(
		cd work &&
		git-repo-go sync --detach \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" &&
		git-repo-go start --all jx/topic
	)
'

test_expect_success "download using cherry-pick" '
	(
		cd work &&
		git-repo-go download \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" \
			--cherry-pick main 123
	) &&
	(
		cd work/main &&
		echo "Branch: $(git_current_branch)" &&
		git log --pretty="    %s" -2 &&
		git show-ref | cut -c 42- | grep changes
	) >actual 2>&1 &&
	cat >expect<<-EOF &&
	Branch: jx/topic
	    New topic
	    Version 2.0.0-dev
	refs/changes/123/1
	refs/changes/123/head
	EOF
	test_cmp expect actual
'

test_expect_success "restore using sync and start again" '
	(
		cd work &&
		git-repo-go sync --detach \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" &&
		git-repo-go start --all jx/topic
	)
'

test_expect_success "download failed using ff-only" '
	(
		cd work &&
		test_must_fail git-repo-go download \
			--no-cache \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":3}" \
			--ff-only main 123
	) >actual 2>&1 &&
	cat >expect<<-EOF &&
	fatal: Not possible to fast-forward, aborting.
	Error: exit status 128
	EOF
	test_cmp expect actual
'

test_done
