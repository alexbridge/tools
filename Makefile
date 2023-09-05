# Copy Makefile to your user home directory
# add alias: 
#   alias mmake='make --file=$(MAKE_FILE)'
# use:
#	mmake git.branch
#	mmake git.reset

SHELL := /bin/bash
WORK_DIR := $(shell pwd)
#MAKE_FILE := $(WORK_DIR)/Makefile
MAKE_FILE := $$HOME/Makefile
MMAKE := make --file=$$HOME/Makefile

# Text color output
#0	Black 1 Red 2 Green 3 Yellow 4 Blue 5 Magenta 6 Cyan 7 White
# example: $(call RED,Copying Makefile to user home ...)
RED = $$(tput setaf 1; echo -n "$(1)"; tput sgr0)
GREEN = $$(tput setaf 2; echo -n "$(1)"; tput sgr0)
BLUE = $$(tput setaf 6; echo -n "$(1)"; tput sgr0)
YELLOW = $$(tput setaf 3; echo -n "$(1)"; tput sgr0)
WHITE = $$(tput setaf 7; echo -n "$(1)"; tput sgr0)

# Propmt helpers
YES := yes
NO := no
PROMPT_YES_NO = $$(readarray -d '|' -t choices <<<"$(YES)|$(NO)"; printf "%s\n" "$${choices[@]}" | fzf --prompt='$(1): ' --header-first)
PROMPT_CHOICES = $$(readarray -d '|' -t choices <<<"$(2)"; printf "%s\n" "$${choices[@]}" | fzf --prompt='$(1): ' --header-first)

# Git variables
LATEST_TAG = $$(git for-each-ref --sort=-taggerdate --count=1 --format '%(refname:short)' refs/tags)
THE_BRANCH = $$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')
REMOTE_BRANCH = $$(git fetch origin -p; git branch -r | fzf --prompt '$(1): ' | tr -d '[:space:]' | tr -d '*')

.ONESHELL:
.DEFAULT:
_mmake.default:
	@type fzf >/dev/null 2>&1 || { echo "Please install fzf"; exit 0; }
	@recipe=$$(grep -oE '^[a-z][a-zA-Z0-9.-]+:' $(MAKE_FILE) | tr -d ':' |
	fzf --preview 'make --file=$(MAKE_FILE) --silent -n {} | head -n 5' --preview-window=50%:down);
	if [[ -n "$$recipe" ]]; then make --silent --file=$(MAKE_FILE) $$recipe; fi;

# Install each recipe as shell alias
_mmake.install:
	@echo "alias mmake='make --file=$(MAKE_FILE)'" > ~/.mmake_aliases;
	grep FZF_DEFAULT_OPTS ~/.bashrc || echo "export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --exact'" >> ~/.bashrc
	grep -oE '^[a-z][a-zA-Z0-9.-]+:' Makefile | tr -d ':' | while read recipe; do echo "alias $$recipe='make --file=$(MAKE_FILE) $$recipe'" >> ~/.mmake_aliases; done;
	grep '_mmake.install' ~/.bashrc > /dev/null || echo "make --file=$(MAKE_FILE) _mmake.install; [[ -f ~/.mmake_aliases ]] && source ~/.mmake_aliases" >> ~/.bashrc

_echo.vars:
	@echo "Working Directory: $(call BLUE,$(WORK_DIR))"
	echo "Makefile to use: $(call BLUE,$(MAKE_FILE))"
_prompt:
	@RES=$(call PROMPT_YES_NO,Choose)
	if [[ "$$RES" == "$(YES)" ]]; then echo 'YES Selected'; fi
	if [[ "$$RES" == "$(NO)" ]]; then echo 'NO Selected'; fi

# ==== RECIPES ====

# ================ GIT ACTIONS ==============
git.latest.tag:
	echo "Latest git tag: $(LATEST_TAG)"

git.branch:
	@echo "$(call GREEN,Creating new git branch)"
	read -ep "Enter branch name to create: " -i "feature/" BRANCH;
	SOURCE_BRANCH=$(call REMOTE_BRANCH,Source branch);
	SOURCE_BRANCH="$${SOURCE_BRANCH#origin/}";
	STASH=$(call PROMPT_YES_NO,Stash changes);
	[[ "$$STASH" == "$(YES)" ]] && git stash;
	git reset --hard; git fetch origin -p; git checkout origin/$$SOURCE_BRANCH; git branch -D $$BRANCH;
	git checkout -b $$BRANCH;
	[[ "$$STASH" == "$(YES)" ]] && git stash pop;
	git show | head -n 5;
	echo Done!

git.reset:
	@echo "$(call GREEN,Reset to existing remote git branch)"
	git status;
	git fetch origin -p;
	echo '==============================================';
	BRANCH=$(call REMOTE_BRANCH,Source branch);
	BRANCH="$${BRANCH#origin/}"
	if [[ -n "$$BRANCH" ]]; then
		echo "Reset to given branch: $${BRANCH}";
		STASH=$(call PROMPT_YES_NO,Stash changes);
		[[ "$$STASH" == "$(YES)" ]] && git stash;
		git reset --hard; git checkout "origin/$${BRANCH}"; git branch -D $$BRANCH;
		git checkout -b $$BRANCH;
		[[ "$$STASH" == "$(YES)" ]] && git stash pop;
		echo '--------------------------------------------------------------';
		git show | head -n 5;
	echo Done!
	fi

git.tag:
	@echo "$(call GREEN,Creating a git tag)"
	LATEST="$(LATEST_TAG)";
	echo "Most recent tag: $(call WHITE,$${LATEST})"
	read -ep "Enter new version: " -i "$${LATEST}" TAG;
	echo "New version will be: $(call GREEN,$${TAG})"
	git tag -d $$TAG; git tag $$TAG; git push origin tags/$$TAG;
	echo Done!

git.archive:
	@$(call GREEN,Making git archive)
	$(MMAKE) git.reset
	read -p "Enter archive name: " ARCHIVE;
	[ -n "$$ARCHIVE" ] && git archive --format=tar -o "$${ARCHIVE}.tar" HEAD;
	echo Done!

git.stash:
	@git stash -m "$(THE_BRANCH)"; git status

git.merge:
	@echo "$(call GREEN, Merging remote changes)"
	git fetch origin -p;
	echo '==============================================';
	REMOTE_BRANCH=$(call REMOTE_BRANCH,Remote branch to merge);
	REMOTE_BRANCH="$${REMOTE_BRANCH#origin/}"
	if [[ -n "$$REMOTE_BRANCH" ]]; then
		echo "Merging $(call BLUE, origin/$${REMOTE_BRANCH})";
		git merge origin/$$REMOTE_BRANCH;
	fi	

git.log:
	@git log --oneline -10

# Interactive NPM
npmi:
	# Interactive npm scripts
	script=$$(jq -r '.scripts | to_entries[] | "\(.key) => \(.value)"' < package.json | sort | fzf | cut -d' ' -f1); \
	[ -n "$$script" ] && npm run $$script

# =============== VIDEOS =====================
download.m3u8:
	read -ep "Enter m3u8 URL: " URL;
	read -ep "Enter file name (withoum mp4 sufux): " FILE;
	ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i $$URL -c copy $$FILE.mp4
	printf '\a Download is done'

# =============== JSON =====================
json.select:
	@echo "$(call GREEN,Selecting jsonpath ...)"
	read -ep "Enter json file: " FILE;
	read -ep "Enter code to select entity: " CODE;
	jq ".[] | select(.code == \"$$CODE\")" $$FILE

#========= DOCKER ACTION ===================
D_CONTAINERS := --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.State}}"

docker.stop-all:
	docker container stop $$(docker container ps -q | tail -n +2 | awk '{printf $$1 " "}') || true

docker.restart:
	sudo systemctl restart docker

docker.exec:
	@docker exec -it $$(docker ps $(D_CONTAINERS) | fzf | awk '{print $$2}') bash

docker.start:
	@docker start $$(docker ps -a $(D_CONTAINERS) | fzf | awk '{print $$2}')

docker.stop:
	@docker stop $$(docker ps $(D_CONTAINERS) | fzf | awk '{print $$2}')

docker.logs:
	@docker logs -f $$(docker ps -a $(D_CONTAINERS) | fzf | awk '{print $$2}')

docker.rm:
	@type=$(call PROMPT_CHOICES,Type ,container|image|volume)
	[ -n "$$type" ] && $(MMAKE) --silent "_docker.rm.$${type}"
_docker.rm.container:
	ctr=$$(docker container ls -a | fzf --cycle --prompt='Container to remove: ' | awk '{print $$1}')
	[ -n "$$ctr" ] && docker container rm $$ctr && $(MMAKE) --silent _docker.rm.container || true
_docker.rm.image:
	img=$$(docker image ls | fzf --cycle --prompt='Image to remove: ' | awk '{print $$3}')
	[ -n "$$img" ] && docker image rm $$img && $(MMAKE) --silent _docker.rm.image || true
_docker.rm.volume:
	vol=$$(docker volume ls | fzf --cycle --prompt='Volume to remove: ' | awk '{print $$2}')
	[ -n "$$vol" ] && docker volume rm $$vol && $(MMAKE) --silent _docker.rm.volume || true

#========= DIFF ACTION ===================
diff.json:
	read -ep "Enter file 1: " FILE1
	read -ep "Enter file 2: " FILE2
	jq --sort-keys . $$FILE1 > "$$FILE1.s"
	jq --sort-keys . $$FILE2 > "$$FILE2.d"
	git diff --no-index "$$FILE1.s" "$$FILE2.d"

# ========= MISC
local.history:
	history -w; tac ~/.bash_history | fzf +s --exact | tee -a ~/.bash_history | bash

try.make:
	@echo "$(call GREEN, Trying debug of make files ...)"
	read -p "Enter variable: " VAR1
	echo "$(call YELLOW,Entered: $$VAR1)"
	if [[ -n "$${VAR1}" ]]; then
		echo "$(call GREEN,$${VAR1}) is not empty";
		if [[ "$${VAR1}" -gt 0 ]]; then
			echo "$(call BLUE,$${VAR1}) is greater than 0"
		fi;
	fi;
	echo Done!

cron.url:
	@read -ep "Enter URL to crawl: " -i "https://google.com" URL;
	read -ep "Enter Interval in seconds: " -i "10" INTERVAL;
	url=$$URL
	folder="/tmp/$${url:8}"
	mkdir -p "$${folder}" || exit 1
	cd "$${folder}"
	for i in {1..1000}; do 
		curl -v -m 10 -i -s "$$URL" -o "$$(date -Is).txt" &> /dev/null
		echo -ne "Done $${i} / 1000\r"
		sleep $$INTERVAL 
	done

