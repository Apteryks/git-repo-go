// Copyright © 2019 Alibaba Co. Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/Apteryks/git-repo-go/helper"
	"github.com/spf13/cobra"
)

type helperProtoCommand struct {
	cmd *cobra.Command
	O   struct {
		Upload   bool
		Download bool
		Type     string
		Version  int
	}
}

func (v *helperProtoCommand) Command() *cobra.Command {
	if v.cmd != nil {
		return v.cmd
	}

	v.cmd = &cobra.Command{
		Use:   "proto",
		Short: "execute proto helper",

		RunE: func(cmd *cobra.Command, args []string) error {
			return v.Execute(args)
		},
	}
	v.cmd.Flags().StringVar(&v.O.Type,
		"type",
		"",
		"type of protocol")
	v.cmd.Flags().IntVar(&v.O.Version,
		"version",
		0,
		"version of protocol")
	v.cmd.Flags().BoolVar(&v.O.Upload,
		"upload",
		false,
		"output JSON for git upload commands")
	v.cmd.Flags().BoolVar(&v.O.Download,
		"download",
		false,
		"output JSON for download git reference")

	return v.cmd
}

func (v *helperProtoCommand) Execute(arts []string) error {
	var (
		buf         []byte
		err         error
		ref         string
		options     []string
		protoHelper helper.ProtoHelper
	)

	if v.O.Type == "" {
		return fmt.Errorf("must provide type of proto")
	}
	sshInfo := helper.SSHInfo{ProtoType: v.O.Type, ProtoVersion: v.O.Version}
	protoHelper = helper.NewProtoHelper(&sshInfo)

	if v.O.Download && v.O.Upload {
		return fmt.Errorf("cannot use --download and --upload together")
	}

	if v.O.Download {
		var (
			id, patch string
		)
		buf, err = io.ReadAll(os.Stdin)
		if err != nil {
			return err
		}
		matches := reChange.FindStringSubmatch(strings.TrimSpace(string(buf)))
		if len(matches) >= 2 {
			id = matches[1]
		}
		if len(matches) >= 3 {
			patch = matches[2]
		}
		ref, options, err = protoHelper.GetDownloadRefOptions(id, patch)
		if err != nil {
			return err
		}
		for _, option := range options {
			fmt.Printf("-o %s\n", option)
		}
		fmt.Println(ref)
		return nil
	}

	buf, err = helper.GetGitPushCommandPipe(protoHelper)
	if err != nil {
		return err
	}
	fmt.Println(string(buf))
	return nil
}

var helperProtoCmd = helperProtoCommand{}

func init() {
	helperCmd.Command().AddCommand(helperProtoCmd.Command())
}
