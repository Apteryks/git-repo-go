#!/bin/sh

test_description="test 'git-repo-go forall' on mirrors"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work &&
	(
		cd work &&
		git-repo-go init --mirror -g all -u $manifest_url &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "check project mirrors' cwd" '
	(
		cd work &&
		git-repo-go forall -p -j 1 -g all -c pwd
	) >out &&
	sed -e "s#$HOME#...#g" <out >actual &&
	cat >expect<<-EOF &&
	project main/
	.../work/main.git
	
	project project1/
	.../work/project1.git
	
	project project1/module1/
	.../work/project1/module1.git
	
	project project2/
	.../work/project2.git
	
	project drivers/driver1/
	.../work/drivers/driver1.git
	
	project drivers/driver2/
	.../work/drivers/driver2.git
	
	project hello/manifests/
	.../work/hello/manifests.git
	EOF
	test_cmp expect actual
'

test_done
