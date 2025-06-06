#!/bin/sh

test_description="sync overwrites modified files in branch without a remote tracking branch"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "git-repo-go sync to Maint branch" '
	(
		cd work &&
		git-repo-go init -u $manifest_url -b Maint &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	)
'

test_expect_success "create branch, but do not track remote branch" '
	(
		cd work &&
		(cd drivers/driver-1 && git checkout -b test) &&
		(cd projects/app1 && git checkout -b test) &&
		(cd projects/app1/module1 && git checkout -b test) &&
		(cd projects/app2 && git checkout -b test)
	)
'

test_expect_success "edit files in workdir" '
	(
		cd work &&
		test -f drivers/driver-1/VERSION &&
		echo hacked >drivers/driver-1/VERSION &&
		test -f projects/app1/VERSION &&
		echo hacked >projects/app1/VERSION &&
		test -f projects/app1/module1/VERSION &&
		echo hacked >projects/app1/module1/VERSION &&
		test -f projects/app2/VERSION &&
		echo hacked >projects/app2/VERSION &&
		(
			cd projects/app2 &&
			git add -A
		)
	)
'

test_expect_success "changes are preserved even switch from untracking branch" '
	(
		cd work &&
		git-repo-go init -u $manifest_url -b master &&
		test_must_fail git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}" &&
		cat >expect <<-EOF &&
		drivers/driver-1/VERSION: hacked
		projects/app1/VERSION: hacked
		projects/app2/VERSION: hacked
		EOF
		echo "drivers/driver-1/VERSION: $(cat drivers/driver-1/VERSION)" >actual &&
		echo "projects/app1/VERSION: $(cat projects/app1/VERSION)" >>actual &&
		echo "projects/app2/VERSION: $(cat projects/app2/VERSION)" >>actual &&
		test_cmp expect actual
	)
'

test_done
