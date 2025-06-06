#!/bin/sh

test_description="test 'git-repo-go forall'"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work &&
	(
		cd work &&
		git-repo-go init -g all -u $manifest_url &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "execute shell (-g all)" '
	(
		cd work &&
		git-repo-go forall -g all -c '"'"'echo $REPO_PATH'"'"'
	) >actual &&
	cat >expect<<-EOF &&
	main
	projects/app1
	projects/app1/module1
	projects/app2
	drivers/driver-1
	drivers/driver-2
	EOF
	test_cmp expect actual
'

test_expect_success "execute shell (-g app)" '
	(
		cd work &&
		git-repo-go forall -g app -p -j 1 -c '"'"'echo $REPO_PROJECT'"'"'
	) >actual &&
	cat >expect<<-EOF &&
	project main/
	main
	
	project projects/app1/
	project1
	
	project projects/app1/module1/
	project1/module1
	
	project projects/app2/
	project2
	EOF
	test_cmp expect actual
'

test_expect_success "execute cmd (-r module1)" '
	(
		cd work &&
		git-repo-go forall -r module1 -r driver-1 -p -j 1 -c echo ...
	) >actual &&
	cat >expect<<-EOF &&
	project projects/app1/module1/
	...

	project drivers/driver-1/
	...
	EOF
	test_cmp expect actual
'

test_expect_success "execute cmd (-i module1)" '
	(
		cd work &&
		git-repo-go forall -i module1 -i driver-2 -p -j 1 -c pwd
	) >out &&
	sed -e "s#$HOME#...#g" <out >actual &&
	cat >expect<<-EOF &&
	project main/
	.../work/main
	
	project projects/app1/
	.../work/projects/app1
	
	project projects/app2/
	.../work/projects/app2

	project drivers/driver-1/
	.../work/drivers/driver-1
	EOF
	test_cmp expect actual
'

test_done
