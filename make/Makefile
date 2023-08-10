# Copy Makefile to your user home directory
# add alias: 
#   alias mmake='make --file=~/Makefile'
# use:
#	mmake git.branch
#	mmake git.reset

# tput setaf
#0	Black
#1	Red
#2	Green
#3	Yellow
#4	Blue
#5	Magenta
#6	Cyan
#7	White
#8	Not used
#9	Reset to default color

# Text color output
# example: $(call _green,Copying Makefile to user home ...)
define _0
	@tput setaf $(1)
	echo $(2)
	tput sgr0
endef

define _green
	$(call _0, 2, $(1))
endef

define _red
	$(call _0, 1, $(1))
endef

define _cyan
	@$(call _0, 6, $(1))
endef

define _yellow
	@$(call _0, 3, $(1))
endef

define promtChoices
	readarray -d '|' -t choices <<<"$(2)"
	printf "%s\n" "$${choices[@]}" | fzf --prompt='$(1): ' --header-first
endef
YES = yes
NO = no
PROMPT_SHELL = choices=($(YES) $(NO)); printf "%s\n" "$${choices[@]}" | fzf --prompt='${1}: ' --header-first
PROMPT_STASH = choices=($(YES) $(NO)); printf "%s\n" "$${choices[@]}" | fzf --prompt='Stach changes: ' --header-first
PROMPT = $(shell -c $(PROMPT_SHELL))
SHELL := /bin/bash
MMAKE := make --file=~/Makefile
LATEST_TAG := git for-each-ref --sort=-taggerdate --count=1 --format '%(refname:short)' refs/tags
THE_BRANCH := git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'

.ONESHELL:
.DEFAULT:
_mmake.default:
	@type fzf >/dev/null 2>&1 || { echo "Please install fzf"; exit 0; }
	@recipe=$$(grep -oE '^[a-z][a-zA-Z0-9.-]+:' ~/Makefile | tr -d ':' | \
	fzf --preview 'make --file=~/Makefile --silent -n {} | head -n 5' --preview-window=50%:down);
	if [[ -n "$$recipe" ]]; then make --silent --file=~/Makefile $$recipe; fi;

# Install each recipe as shell alias
_mmake.install:
	@echo "alias mmake='make --file=~/Makefile'" > ~/.mmake_aliases;
	grep -oE '^[a-z][a-zA-Z0-9.-]+:' Makefile | tr -d ':' | while read recipe; do echo "alias $$recipe='make --file=~/Makefile $$recipe'" >> ~/.mmake_aliases; done;
	grep '_mmake.install' ~/.bashrc > /dev/null || echo "make --file=~/Makefile _mmake.install; [[ -f ~/.mmake_aliases ]] && source ~/.mmake_aliases" >> ~/.bashrc

prompt:
	@$(call HELLO, some)
	RES=$(call PROMPT,Do you want to continue?)
	if [[ "$$RES" == "$(YES)" ]]; then echo 'YES Selected'; fi
	if [[ "$$RES" == "$(NO)" ]]; then echo 'NO Selected'; fi

# ==== RECIPES ====

# ================ GIT ACTIONS ==============
# Create a branch in current git directory
git.branch:
	@$(call _i,creating a branch on current git directory ...)
	@echo "Create a branch in current git directory";
	read -ep "Enter branch name to create: " -i "feature/" BRANCH;
	SOURCE_BRANCH=$$(git branch -r | fzf --prompt 'Source branch: ' | tr -d '[:space:]' | tr -d '*');
	SOURCE_BRANCH="$${SOURCE_BRANCH#origin/}";
	STASH=$$($(PROMPT_STASH));
	[[ "$$STASH" == "$(YES)" ]] && git stash;
	git reset --hard; git fetch origin -p; git checkout origin/$$SOURCE_BRANCH; git branch -D $$BRANCH;
	git checkout -b $$BRANCH;
	[[ "$$STASH" == "$(YES)" ]] && git stash pop;
	git show | head -n 5;
	echo Done!

# Reset git HEAD to given branch
git.reset:
	@$(call _i,Reset git go given branch/tag in current git directory ...)
	@git status;
	git fetch origin -p;
	echo '==============================================';
	BRANCH=$$(git branch -r | fzf | tr -d '[:space:]' | tr -d '*');
	BRANCH="$${BRANCH#origin/}"
	if [[ -n "$$BRANCH" ]]; then
		echo "Reset git HEAD in current directory to given branch: $${BRANCH}";
		STASH=$$($(PROMPT_STASH));
		[[ "$$STASH" == "$(YES)" ]] && git stash;
		git reset --hard; git checkout "origin/$${BRANCH}"; git branch -D $$BRANCH;
		git checkout -b $$BRANCH;
		[[ "$$STASH" == "$(YES)" ]] && git stash pop;
		echo '--------------------------------------------------------------';
		git show | head -n 5;
	echo Done!
	fi
# Tag current state
git.tag:
	@$(call _i,Creating a git tag...)
	@ LATEST=$$(${LATEST_TAG});
	@tput setaf 7; echo Most recent tag: $$LATEST; tput sgr0;
	tput setaf 6; read -ep "Enter new version: " -i "$${LATEST}" TAG; tput sgr0;
	tput setaf 2; echo New version will be: $$TAG; tput sgr0;
	git tag -d $$TAG; git tag $$TAG; git push origin tags/$$TAG;
	echo Done!

git.archive:
	# Create git archieve without ignored files
	@$(call _i,Making git archive ...)
	$(MMAKE) reset
	read -p "Enter archive name: " ARCHIVE;
	[ -n "$$ARCHIVE" ] && git archive --format=tar -o "$${ARCHIVE}.tar" HEAD;
	echo Done!

git.stash:
	@git stash -m "$$(${THE_BRANCH})"; git status

git.merge:
	$(call _i, Merging remote changes ...)
	git fetch origin -p;
	echo '==============================================';
	REMOTE_BRANCH=$$(git branch -r | fzf | tr -d '[:space:]' | tr -d '*');
	REMOTE_BRANCH="$${REMOTE_BRANCH#origin/}"
	if [[ -n "$$REMOTE_BRANCH" ]]; then
		echo "Merging origin/$$REMOTE_BRANCH;";
		git merge origin/$$REMOTE_BRANCH;
	fi	

git.log:
	@git log --oneline -10

# =============== VIDEOS =====================
download.m3u8:
	read -ep "Enter m3u8 URL: " URL;
	read -ep "Enter file name (withoum mp4 sufux): " FILE;
	ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i $$URL -c copy $$FILE.mp4
	printf '\a Download is done'

# =============== JSON =====================
json.select:
	@$(call _green,Selecting jsonpath ...)
	read -ep "Enter json file: " FILE;
	read -ep "Enter code to select entity: " CODE;
	jq ".[] | select(.code == \"$$CODE\")" $$FILE

#========= DOCKER ACTION ===================
docker.stop-all:
	docker container stop $$(docker container ps -aq | tail -n +2 | awk '{printf $$1 " "}') || true

docker.restart:
	sudo systemctl restart docker

docker.exec:
	@docker exec -it $$(docker ps | fzf | awk '{print $$2}') bash

docker.start:
	@docker start $$(docker ps -a | fzf | awk '{print $$2}')

docker.stop:
	@docker stop $$(docker ps | fzf | awk '{print $$2}')

docker.logs:
	@docker logs -f $$(docker ps -a | fzf | awk '{print $$2}')

docker.rm:
	@type=$(call promtChoices,Type ,container|volume|image)
	[ -n "$$type" ] && docker $$type rm $$(docker $$type ls -a | fzf | awk '{print $$2}')

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
	@$(call _green, Trying debug of make files ...);
	read -p "Enter variable: " VAR1;
	$(call _yellow,Entered: $$VAR1);
	if [[ -n "$${VAR1}" ]]; then
		echo "$$VAR1 is not empty";
		if [[ "$${VAR1}" -gt 0 ]]; then
			$(call _cyan,$$VAR1 is greater than 0);
		fi;
	fi;
	echo Done!

cron.url:
	@read -ep "Enter URL to crawl: " -i "https://google.com" URL;
	@read -ep "Enter Interval in seconds: " -i "10" INTERVAL;
	url=$$URL
	folder="/tmp/$${url:8}"
	mkdir -p "$${folder}" || exit 1
	cd "$${folder}"
	for i in {1..1000}; do 
		curl -v -m 10 -i -s "$$URL" -o "$$(date -Is).txt" &> /dev/null
		echo -ne "Done $${i} / 1000\r"
		sleep $$INTERVAL 
	done

