#!/bin/sh
#
# Copyright (c) 2019 Jiang Xin
#

test_description='Test git repo-go sync with submoudles'

# Note: In order to allow link local repos for git-submodule,
#       we need to enable file protocol, e.g.:
#
#       git -c protocol.file.allow=always submodule ...

. lib/test-lib.sh

test_expect_success 'setup submodules' '
	mkdir repo &&
	git init --bare repo/main.git &&
	git init --bare repo/submodule-1.git &&
	git init --bare repo/submodule-1-1.git &&
	git init --bare repo/submodule-2.git &&
	(
		cd repo/main.git &&
		test_tick &&
		commit=$(echo initial | git commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904) &&
		git update-ref refs/heads/master $commit
	) &&
	(
		cd repo/submodule-1.git &&
		test_tick &&
		commit=$(echo initial | git commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904) &&
		git update-ref refs/heads/master $commit
	) &&
	(
		cd repo/submodule-2.git &&
		test_tick &&
		commit=$(echo initial | git commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904) &&
		git update-ref refs/heads/master $commit
	) &&

	(
		cd repo/submodule-1-1.git &&
		test_tick &&
		commit=$(echo initial | git commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904) &&
		git update-ref refs/heads/master $commit
	) &&
	mkdir work1 &&
	git clone repo/main.git --separate-git-dir=work1/main.git work1/main &&
	(
		cd work1/main &&
		echo main >main.txt &&
		git add main.txt &&
		test_tick &&
		git commit -m "initial main" &&
		git push
	) &&
	(
		cd work1/main &&
		git -c protocol.file.allow=always submodule add ../submodule-1.git submodule-1
	) &&
	(
		cd work1/main/submodule-1 &&
		echo submodule-1 >submodule-1.txt &&
		git add submodule-1.txt &&
		test_tick &&
		git commit -m "initial submodule-1" &&
		git push
	) &&
	(
		cd work1/main &&
		git add -u submodule-1 &&
		test_tick &&
		git commit -m "add submodule-1" &&
		git push
	) &&
	(
		cd work1/main &&
		git -c protocol.file.allow=always submodule add ../submodule-2.git submodule-2
	) &&
	(
		cd work1/main/submodule-2 &&
		echo submodule-2 >submodule-2.txt &&
		git add submodule-2.txt &&
		test_tick &&
		git commit -m "initial submodule-2" &&
		git push
	) &&
	(
		cd work1/main &&
		git add -u submodule-2 &&
		test_tick &&
		git commit -m "add submodule-2" &&
		git push
	) &&
	(
		cd work1/main/submodule-1 &&
		git -c protocol.file.allow=always submodule add ../submodule-1-1.git submodule-1-1
	) &&
	(
		cd work1/main/submodule-1/submodule-1-1 &&
		echo submodule-1-1 >submodule-1-1.txt &&
		git add submodule-1-1.txt &&
		test_tick &&
		git commit -m "initial submodule-1-1" &&
		git push
	) &&
	(
		cd work1/main/submodule-1 &&
		git add -u submodule-1-1 &&
		test_tick &&
		git commit -m "add submodule-1-1 in submodule-1" &&
		git push
	) &&
	(
		cd work1/main &&
		git add -u submodule-1 &&
		test_tick &&
		git commit -m "update submodule-1" &&
		git push
	)
'

test_expect_success 'check .gitmodules' '
	cat >expect <<EOF &&
[submodule "submodule-1"]
	path = submodule-1
	url = ../submodule-1.git
[submodule "submodule-2"]
	path = submodule-2
	url = ../submodule-2.git
EOF
	test_cmp expect work1/main/.gitmodules &&
	cat >expect <<EOF &&
[submodule "submodule-1-1"]
	path = submodule-1-1
	url = ../submodule-1-1.git
EOF
	test_cmp expect work1/main/submodule-1/.gitmodules
'

test_expect_success 'create manifest project' '
	git init --bare repo/manifests.git &&
	git clone repo/manifests.git work1/manifests &&
	(
		cd work1/manifests &&
		cat >default.xml <<-EOF &&
		<?xml version="1.0" encoding="UTF-8"?>
		<manifest>
		  <remote  name="origin"
			   fetch=".."
			   review="https://example.com" />
		  <default remote="origin"
			   revision="master"
			   sync-j="4" />
		  <project name="repo/manifests" path="manifests" groups="app"/>
		  <project name="repo/main" path="main" groups="app"/>
		</manifest>
		EOF
		git add default.xml &&
		git commit -m "initial manifests" &&
		git push -u origin master
	)
'

test_expect_success 'git repo-go go sync and update submodules' '
	url="file://$HOME/repo/manifests.git" &&
	touch .repo &&
	mkdir work2 &&
	(
		cd work2 &&
		git repo-go init -u "$url" &&
		git repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\"}"
	) &&
	(
		cd work2/main &&
		git submodule init &&
		git -c protocol.file.allow=always submodule update --recursive --init
	) &&
	(
		cd work2/main &&
		test -f .git &&
		git log -1 --pretty="%s" &&
		( cd submodule-1 && git log -1 --pretty="%s" ) &&
		( cd submodule-1/submodule-1-1 && git log -1 --pretty="%s" ) &&
		( cd submodule-2 && git log -1 --pretty="%s" )
	) >actual &&
	cat >expect <<-EOF &&
	update submodule-1
	add submodule-1-1 in submodule-1
	initial submodule-1-1
	initial submodule-2
	EOF
	test_cmp expect actual
'

test_done
