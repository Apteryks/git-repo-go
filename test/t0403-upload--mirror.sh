#!/bin/sh

test_description="upload used with --mirror"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "git-repo-go init" '
	(
		cd work &&
		git-repo-go init --mirror -u $manifest_url -g all -b Maint &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}" \
			-- main
	)
'

test_expect_success "fail: cannot run upload used with --mirror" '
	(
		cd work/main.git &&
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--no-edit \
			--mock-no-tty \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	) >actual 2>&1 &&
	cat >expect <<-EOF &&
	FATAL: cannot run in a mirror
	EOF
	test_cmp expect actual
'

test_done
