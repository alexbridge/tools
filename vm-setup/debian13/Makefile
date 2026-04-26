SHELL := /usr/bin/env bash

.DEFAULT:
_recipe-list:
	@recipe=$$(grep -oE '^[a-z][a-zA-Z0-9-]+:' Makefile | tr -d ':' | \
	fzf --preview 'make --silent -n {} | head -n 5' --preview-window=50%:down); \
	[[ -n "$$recipe" ]] && make --silent $$recipe

apt-base:
	ansible-playbook apt/apt-base.yml --ask-become-pass
user-local:
	ansible-playbook user/user-local.yml --ask-become-pass
apps-npm-nodejs:
	ansible-playbook apps/apps-nodejs.yml
apps-npm-globals:
	ansible-playbook apps/apps-npm-globals.yml
apps-bcompare:
	ansible-playbook apps/apps-bcompare.yml --ask-become-pass
apps-chrome:
	ansible-playbook apps/apps-chrome.yml --ask-become-pass
apps-docker:
	ansible-playbook apps/apps-docker.yml --ask-become-pass
apps-tilix:
	ansible-playbook apps/apps-tilix.yml --ask-become-pass
apps-vscode:
	ansible-playbook apps/apps-vscode.yml --ask-become-pass
apps-antigravity:
	ansible-playbook apps/apps-antigravity.yml --ask-become-pass
apps-wsl:
	ansible-playbook apps/apps-wsl.yml --ask-become-pass
