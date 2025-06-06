#!/bin/sh

test_description="upload with args to select projects"

. lib/test-lib.sh

# Create manifest repositories
manifest_url="file://${REPO_TEST_REPOSITORIES}/hello/manifests"

test_expect_success "setup" '
	# create .repo file as a barrier, not find .repo deeper
	touch .repo &&
	mkdir work
'

test_expect_success "git-repo-go init & sync" '
	(
		cd work &&
		git-repo-go init -u $manifest_url -g all -b Maint &&
		git-repo-go sync \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}"
	)
'

test_expect_success "create commits" '
	(
		cd work &&
		git repo-go start --all my/topic1 &&
		test_tick &&
		(
			cd main &&
			echo hack >topic1.txt &&
			git add topic1.txt &&
			git commit -m "topic1: new file"
		) &&
		test_tick &&
		(
			cd projects/app1 &&
			echo hack >topic1.txt &&
			git add topic1.txt &&
			test_tick &&
			git commit -m "topic1: new file"
		)
	)
'

test_expect_success "edit script for multiple uploadable branches" '
	(
		cd work &&
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--no-edit \
			--mock-no-tty \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
			>out 2>&1 &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		cat >expect<<-EOF &&
		[1/2] project main: my/topic1
		Upload project main/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		[2/2] project projects/app1: my/topic1
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		Error: nothing confirmed for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "upload with args: project1" '
	(
		cd work &&
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--no-edit \
			--mock-no-tty \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
			project1 \
			>out 2>&1 &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		cat >expect<<-EOF &&
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		Error: nothing confirmed for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "upload with args: projects/app1" '
	(
		cd work &&
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--no-edit \
			--mock-no-tty \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
			projects/app1 \
			>out 2>&1 &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		cat >expect<<-EOF &&
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		Error: nothing confirmed for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "upload with args: app1" '
	(
		cd work &&
		(
			cd projects &&
			test_must_fail git-repo-go upload \
				-v \
				--assume-no \
				--no-edit \
				--mock-no-tty \
				--mock-ssh-info-status 200 \
				--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
				app1 \
				2>&1
		) >out &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		cat >expect<<-EOF &&
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		Error: nothing confirmed for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "upload with args: ." '
	(
		cd work &&
		(
			cd projects/app1 &&
			test_must_fail git-repo-go upload \
				-v \
				--assume-no \
				--no-edit \
				--mock-no-tty \
				--mock-ssh-info-status 200 \
				--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
				. \
				2>&1
		) >out &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		cat >expect<<-EOF &&
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 1 commit(s)):
		         <hash>
		to https://example.com (y/N)? No
		ERROR: upload aborted by user
		Error: nothing confirmed for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "upload with args: main, projects/app1" '
	(
		cd work &&
		cat >expect<<-EOF &&
		INFO: editor is '"'"':'"'"', return directly
		NOTE: no editor, input data unchanged
		##############################################################################
		# Step 1: Input your options for code review
		#
		# Note: Input your options below the comments and keep the comments unchanged
		##############################################################################
		
		# [Title]       : one line message below as the title of code review
		
		# [Description] : multiple lines of text as the description of code review
		
		# [Issue]       : multiple lines of issue IDs for cross references
		
		# [Reviewer]    : multiple lines of user names as the reviewers for code review
		
		# [Cc]          : multiple lines of user names as the watchers for code review
		
		# [Draft]       : a boolean (yes/no, or true/false) to turn on/off draft mode
		
		# [Private]     : a boolean (yes/no, or true/false) to turn on/off private mode
		
		
		##############################################################################
		# Step 2: Select project and branches for upload
		#
		# Note: Uncomment the branches to upload, and not touch the project lines
		##############################################################################
		
		#
		# project main/:
		#  branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>
		#
		# project projects/app1/:
		#  branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>

		FATAL: nothing uncommented for upload
		EOF
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--mock-no-tty \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
			main projects/app1 projects/app2 \
			>out 2>&1 &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" <out >actual &&
		test_cmp expect actual
	)
'

test_expect_success "upload with args: main, projects/app1" '
	(
		cd work &&
		cat >mock-edit-script<<-EOF &&
		INFO: editor is '"'"':'"'"', return directly:
		# Uncomment the branches to upload:
		#
		# project main/:
		branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>
		#
		# project projects/app1/:
		 branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>
		FATAL: nothing uncommented for upload
		EOF
		test_must_fail git-repo-go upload \
			-v \
			--assume-no \
			--mock-no-tty \
			--mock-git-push \
			--mock-edit-script=mock-edit-script \
			--mock-ssh-info-status 200 \
			--mock-ssh-info-response \
			"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
			main projects/app1 projects/app2 \
			>out 2>&1 &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" out >actual &&
		cat >expect<<-EOF &&
		INFO: editor is '"'"':'"'"', return directly
		NOTE: no editor, input data unchanged
		##############################################################################
		# Step 1: Input your options for code review
		#
		# Note: Input your options below the comments and keep the comments unchanged
		##############################################################################
		
		# [Title]       : one line message below as the title of code review
		
		# [Description] : multiple lines of text as the description of code review
		
		# [Issue]       : multiple lines of issue IDs for cross references
		
		# [Reviewer]    : multiple lines of user names as the reviewers for code review
		
		# [Cc]          : multiple lines of user names as the watchers for code review
		
		# [Draft]       : a boolean (yes/no, or true/false) to turn on/off draft mode
		
		# [Private]     : a boolean (yes/no, or true/false) to turn on/off private mode
		
		
		##############################################################################
		# Step 2: Select project and branches for upload
		#
		# Note: Uncomment the branches to upload, and not touch the project lines
		##############################################################################
		
		#
		# project main/:
		#  branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>
		#
		# project projects/app1/:
		#  branch my/topic1 ( 1 commit(s)) to remote branch Maint:
		#         <hash>
		
		FATAL: nothing uncommented for upload
		EOF
		test_cmp expect actual
	)
'

test_expect_success "create commits" '
	(
		cd work &&
		git repo-go start --all my/topic1 &&
		(
			cd projects/app1 &&
			for i in $(test_seq 1 5)
			do
				test_tick &&
				git commit --allow-empty -m "commit #$i" ||
				exit 1
			done
		)
	)
'

test_expect_success "if has many commits, must confirm before upload" '
	(
		cd work &&
		cat >expect<<-EOF &&
		Upload project projects/app1/ to remote branch Maint:
		  branch my/topic1 ( 6 commit(s)):
		         <hash>
		         <hash>
		         <hash>
		         <hash>
		         <hash>
		         <hash>
		to https://example.com (y/N)? Yes
		ATTENTION: You are uploading an unusually high number of commits.
		YOU PROBABLY DO NOT MEAN TO DO THIS. (Did you rebase across branches?)
		If you are sure you intend to do this, type '"'"'yes'"'"': Yes
		NOTE: projects/app1> will execute command: git push ssh://git@ssh.example.com/project1.git refs/heads/my/topic1:refs/for/Maint/my/topic1
		NOTE: projects/app1> with extra environment: AGIT_FLOW=git-repo-go/n.n.n.n
		NOTE: projects/app1> with extra environment: GIT_SSH_COMMAND=ssh -o SendEnv=AGIT_FLOW
		
		----------------------------------------------------------------------
		EOF
		(
			git-repo-go upload \
				-v \
				--assume-yes \
				--no-edit \
				--mock-no-tty \
				--mock-git-push \
				--mock-ssh-info-status 200 \
				--mock-ssh-info-response \
				"{\"host\":\"ssh.example.com\", \"port\":22, \"type\":\"agit\", \"version\":2}" \
				projects/app1 \
				2>&1
		) >out &&
		sed -e "s/[0-9a-f]\{40\}/<hash>/g" -e "s/git-repo-go\/[^ \"\\]*/git-repo-go\/n.n.n.n/g" <out >actual &&
		test_cmp expect actual
	)
'

test_done
