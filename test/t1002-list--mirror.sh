#!/bin/sh

test_description="git-repo-go mirror --mirror test"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "git-repo-go sync" '
	(
		cd work &&
		git-repo-go init --mirror -u $manifest_url -g all -b Maint &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "fail: cannot run status in mirrored repo" '
	(
		cd work/main.git &&
		git-repo-go list
	) >actual 2>&1 &&
	cat >expect <<-EOF &&
	drivers/driver-1 : drivers/driver1
	drivers/driver-2 : drivers/driver2
	main : main
	manifests : hello/manifests
	projects/app1 : project1
	projects/app1/module1 : project1/module1
	projects/app2 : project2
	EOF
	test_cmp expect actual
'

test_expect_success "git-repo-go list -n" '
	(
		cd work &&
		git-repo-go list -n
	) >actual &&
	cat >expect<<-EOF &&
	drivers/driver1
	drivers/driver2
	hello/manifests
	main
	project1
	project1/module1
	project2
	EOF
	test_cmp expect actual
'

test_done
