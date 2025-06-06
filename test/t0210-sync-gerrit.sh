#!/bin/sh

test_description="test 'git-repo-go sync' basic"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "git-repo-go sync (-n)" '
	(
		cd work &&
		git-repo-go init -u $manifest_url &&
		git-repo-go sync -n
	)
'

test_expect_success "beforce sync local-half, gerrit hooks are not installed" '
	(
		cd work &&
		test -d .repo/project-objects/main.git/hooks &&
		test -d .repo/project-objects/project1.git/hooks &&
		test -d .repo/project-objects/project2.git/hooks &&
		test -d .repo/project-objects/project1/module1.git/hooks &&
		test -d .repo/project-objects/drivers/driver1.git/hooks &&
		test ! -e .repo/project-objects/main.git/hooks/commit-msg &&
		test ! -e .repo/project-objects/project1.git/hooks/commit-msg &&
		test ! -e .repo/project-objects/project2.git/hooks/commit-msg &&
		test ! -e .repo/project-objects/project1/module1.git/hooks/commit-msg &&
		test ! -e .repo/project-objects/drivers/driver1.git/hooks/commit-msg
	)
'

test_expect_success "git-repo-go sync (-l), server has gerrit response" '
	(
		cd work &&
		git-repo-go sync -l \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"ssh.example.com 29418"

	)
'

test_expect_success "projects hooks link to project-objects hooks" '
	(
		cd work &&
		test -L .repo/projects/main.git/hooks &&
		test -L .repo/projects/projects/app1.git/hooks &&
		test -L .repo/projects/projects/app2.git/hooks &&
		test -L .repo/projects/projects/app1/module1.git/hooks &&
		test -L .repo/projects/drivers/driver-1.git/hooks
	)
'

test_expect_success "Installed gerrit hooks for gerrit projects" '
	(
		cd work &&
		test -d .repo/project-objects/main.git/hooks &&
		test -d .repo/project-objects/project1.git/hooks &&
		test -d .repo/project-objects/project2.git/hooks &&
		test -d .repo/project-objects/project1/module1.git/hooks &&
		test -d .repo/project-objects/drivers/driver1.git/hooks &&
		test -L .repo/project-objects/main.git/hooks/commit-msg &&
		test -L .repo/project-objects/project1.git/hooks/commit-msg &&
		test -L .repo/project-objects/project2.git/hooks/commit-msg &&
		test -L .repo/project-objects/project1/module1.git/hooks/commit-msg &&
		test -L .repo/project-objects/drivers/driver1.git/hooks/commit-msg
	)
'

test_done
