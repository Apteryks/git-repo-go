#!/bin/sh

test_description="git-repo-go sync multiple jobs test"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "init with multiple jobs" '
	(
		cd work &&
		git-repo-go init -u $manifest_url
	)
'

test_expect_success "git-repo-go sync (-n), default jobs" '
	(
		cd work &&
		git-repo-go sync -n
	)
'

test_expect_success "git-repo-go sync (-n), 100 jobs" '
	(
		cd work &&
		git-repo-go sync -n -j 100
	)
'

test_expect_success "git-repo-go sync (-n), 1 job" '
	(
		cd work &&
		git-repo-go sync -n -j 1
	)
'

test_expect_success "git-repo-go sync (-n), 0 job" '
	(
		cd work &&
		git-repo-go sync -n -j 0
	)
'

test_expect_success "git-repo-go sync (-l), default jobs" '
	(
		cd work &&
		git-repo-go sync -l \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "git-repo-go sync (-l), 0 job" '
	(
		cd work &&
		git-repo-go sync -l -j 0 \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "git-repo-go sync (-l), 1 job" '
	(
		cd work &&
		git-repo-go sync -l -j 1 \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "git-repo-go sync (-l), 100 jobs" '
	(
		cd work &&
		git-repo-go sync -l -j 100 \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_done
