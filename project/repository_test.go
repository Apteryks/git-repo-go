package project

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/Apteryks/git-repo-go/manifest"
	"github.com/stretchr/testify/assert"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing/object"
)

func TestRepositoryInit(t *testing.T) {
	var (
		remote, remoteURL string
	)

	assert := assert.New(t)

	tmpdir, err := os.MkdirTemp("", "git-repo-go-")
	if err != nil {
		panic(err)
	}
	defer func(dir string) {
		os.RemoveAll(dir)
	}(tmpdir)

	// Initial bare.git
	repoPath := filepath.Join(tmpdir, "bare.git")
	repo := Repository{
		GitDir: repoPath,
		IsBare: true,
	}
	remoteURL = ""
	err = repo.Init(remote, remoteURL, "")
	assert.Nil(err)
	// repo is created in path directly, not in .git
	assert.True(repo.Exists())
	// check git config
	cfg := repo.Config()
	assert.NotNil(cfg)
	value := cfg.GetBool("core.bare", false)
	assert.True(value)
	value = cfg.GetBool("core.logallrefupdates", false)
	assert.False(value)
	// check raw config
	raw := repo.Raw()
	c, err := raw.Config()
	assert.Nil(err)
	assert.True(c.Core.IsBare)

	// Initial repo.git, not bare
	repoPath = filepath.Join(tmpdir, "repo.git")
	repo = Repository{
		GitDir: repoPath,
		IsBare: false,
	}
	remoteURL = ""
	err = repo.Init(remote, remoteURL, "")
	assert.Nil(err)
	// repo is created in path directly, not in .git
	assert.True(repo.Exists())
	// check git config
	cfg = repo.Config()
	assert.NotNil(cfg)
	value = cfg.GetBool("core.bare", false)
	assert.False(value)
	value = cfg.GetBool("core.logallrefupdates", false)
	assert.True(value)
	// check raw config
	raw = repo.Raw()
	c, err = raw.Config()
	assert.Nil(err)
	assert.False(c.Core.IsBare)
}

func TestRepositoryIsUnborn(t *testing.T) {
	var (
		remote, remoteURL string
	)

	assert := assert.New(t)

	tmpdir, err := os.MkdirTemp("", "git-repo-go-")
	if err != nil {
		panic(err)
	}
	defer func(dir string) {
		os.RemoveAll(dir)
	}(tmpdir)

	// Initial bare.git
	repoPath := filepath.Join(tmpdir, "bare.git")
	repo := Repository{
		GitDir: repoPath,
		IsBare: true,
	}
	err = repo.Init(remote, remoteURL, "")
	assert.Nil(err)
	// repo is created in path directly, not in .git
	assert.True(repo.Exists())

	assert.True(repo.isUnborn())
}

func TestRepositoryFetch(t *testing.T) {
	var (
		remote, remoteURL string
	)

	assert := assert.New(t)

	tmpdir, err := os.MkdirTemp("", "git-repo-go-")
	if err != nil {
		panic(err)
	}
	defer func(dir string) {
		os.RemoveAll(dir)
	}(tmpdir)

	// Create a workdir
	workDir := filepath.Join(tmpdir, "workdir")
	repoDir := filepath.Join(workDir, ".git")
	err = os.MkdirAll(workDir, 0755)
	assert.Nil(err)
	r, err := git.PlainInit(workDir, false)
	assert.Nil(err)

	w, err := r.Worktree()
	assert.Nil(err)

	// Create a commit in workdir
	filename := filepath.Join(workDir, "example-git-file")
	err = os.WriteFile(filename, []byte("hello world!"), 0644)
	assert.Nil(err)

	_, err = w.Add("example-git-file")
	assert.Nil(err)
	commit, err := w.Commit("example go-git commit", &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Jiang Xin",
			Email: "worldhello.net@gmail.com",
			When:  time.Now(),
		},
	})
	assert.Nil(err)
	assert.False(commit.IsZero())
	commitHash := commit.String()

	// Create a reference repo
	refRepoPath := filepath.Join(tmpdir, "ref.git")
	refRepo := Repository{
		Project: manifest.Project{
			RemoteName: "origin",
			Revision:   "master",
		},
		GitDir:   refRepoPath,
		IsBare:   true,
		Settings: &RepoSettings{},
	}
	remote = "origin"
	remoteURL = repoDir
	err = refRepo.Init(remote, remoteURL, "")
	assert.Nil(err)

	// Fetch from workdir to reference refRepo
	err = refRepo.Fetch(remote, &FetchOptions{})
	assert.Nil(err)
	_, err = refRepo.Raw().Reference("refs/heads/master", true)
	assert.Nil(err)

	// Push commit in workdir to ref.git
	err = os.WriteFile(filename, []byte("hello world!\nBye\n"), 0644)
	assert.Nil(err)

	_, err = w.Add("example-git-file")
	assert.Nil(err)
	commit, err = w.Commit("Update example git file", &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Jiang Xin",
			Email: "worldhello.net@gmail.com",
			When:  time.Now(),
		},
	})
	assert.Nil(err)
	assert.False(commit.IsZero())
	commitHash2 := commit.String()
	assert.NotEqual(commitHash, commitHash2)

	// Create another repo
	newRepoPath := filepath.Join(tmpdir, "repo.git")
	newRepo := Repository{
		Project: manifest.Project{
			Name:       "repo",
			RemoteName: "origin",
		},
		GitDir:    newRepoPath,
		Reference: refRepoPath,
		IsBare:    false,
		Settings:  &RepoSettings{},
	}
	remote = "origin"
	remoteURL = repoDir
	err = newRepo.Init(remote, remoteURL, refRepoPath)
	assert.Nil(err)

	// fetch from reference repo, then fetch from upstream
	err = newRepo.Fetch(remote, &FetchOptions{})
	assert.Nil(err)
	reference, err := newRepo.Raw().Reference("refs/remotes/origin/master", true)
	assert.Nil(err)
	assert.Equal(commitHash2, reference.Hash().String())
}
