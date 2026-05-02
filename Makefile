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
PROMPT_NO_YES = $$(readarray -d '|' -t choices <<<"$(NO)|$(YES)"; printf "%s\n" "$${choices[@]}" | fzf --prompt='$(1): ' --header-first)
PROMPT_CHOICES = $$(readarray -d '|' -t choices <<<"$(2)"; printf "%s\n" "$${choices[@]}" | fzf --prompt='$(1): ' --header-first)

# Git variables
LATEST_TAG = $$(git for-each-ref --sort=-taggerdate --count=1 --format '%(refname:short)' refs/tags)
THE_BRANCH = $$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
REMOTE_BRANCH = $$(git fetch origin -p; git branch -r | fzf --prompt '$(1): ' | tr -d '[:space:]' | tr -d '*')

# FZF
FZF_DEFAULT_OPTS ?='--height 50% --layout=reverse --border --exact --bind 'ctrl-y:execute-silent(xclip -selection clipboard {})''
FZF_MULTI = --cycle --multi --bind="space:toggle"

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
	grep -oE '^[a-z][a-zA-Z0-9.-]+:' $(MAKE_FILE) | tr -d ':' | while read recipe; do echo "alias $$recipe='make --file=$(MAKE_FILE) $$recipe'" >> ~/.mmake_aliases; done;
	grep '_mmake.install' ~/.bashrc > /dev/null || echo "make --file=$(MAKE_FILE) _mmake.install; [[ -f ~/.mmake_aliases ]] && source ~/.mmake_aliases" >> ~/.bashrc

_echo.vars:
	@echo "Working Directory: $(call BLUE,$(WORK_DIR))"
	echo "Makefile to use: $(call BLUE,$(MAKE_FILE))"
	echo "Bash PID: $$(echo $$$$)"
	echo "Git Branch: $(THE_BRANCH)"
_prompt:
	@RES=$(call PROMPT_YES_NO,Choose)
	if [[ "$$RES" == "$(YES)" ]]; then echo 'YES Selected'; fi
	if [[ "$$RES" == "$(NO)" ]]; then echo 'NO Selected'; fi

# ==== RECIPES ====

# ================ GIT ACTIONS ==============
git.latest.tag:
	echo "Latest git tag: $(LATEST_TAG)"

git.ls:
	@git fetch origin -p
	git branch -r

git.branch:
	@echo "$(call GREEN,Creating new git branch)"
	read -ep "Enter branch name to create: " -i "feature/" BRANCH;
	SOURCE_BRANCH=$(call REMOTE_BRANCH,Source branch);
	SOURCE_BRANCH="$${SOURCE_BRANCH#origin/}";
	STASH=$(call PROMPT_NO_YES,Stash changes);
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
		STASH=$(call PROMPT_NO_YES,Stash changes);
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
	@read -p "Stash message: [$(THE_BRANCH)]: " message;
	git add .
	git stash -m "$${message}: $(THE_BRANCH)"; git status

git.stash.apply:
	@stash=$$(git stash list | fzf --preview "git stash show -p \$$(echo {} | awk '{print \$$1}' | tr -d ':')" | awk '{print $$1}' | tr -d ':')
	[ -n "$${stash}" ] && git stash apply $$stash
	DROP_STASH=$(call PROMPT_YES_NO,Drop stash?);
	[[ "$$DROP_STASH" == "$(YES)" ]] && git stash drop $$stash;
git.stash.drop:
	@stash=$$(git stash list | fzf --preview "git stash show -p \$$(echo {} | awk '{print \$$1}' | tr -d ':')" | awk '{print $$1}' | tr -d ':')
	[ -n "$${stash}" ] && git stash drop $$stash

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
git.rebase:
	@echo "$(call GREEN, Rebasing remote changes)"
	git fetch origin -p;
	echo '==============================================';
	REMOTE_BRANCH=$(call REMOTE_BRANCH,Remote branch to rebase);
	REMOTE_BRANCH="$${REMOTE_BRANCH#origin/}"
	if [[ -n "$$REMOTE_BRANCH" ]]; then
		cmd="git rebase origin/$${REMOTE_BRANCH}"
		if [[ "$$REMOTE_BRANCH" =~ "feature" ]]; then
			echo "Select base for origin/$${REMOTE_BRANCH}"
			base=$$(git log --oneline -10 | fzf | cut -d' ' -f1)
			cmd+=" --onto $${base}"
		fi
		echo "Rebasing $(call BLUE, origin/$${REMOTE_BRANCH})";
		$$cmd
	fi
git.cherry.prod:
	@echo "$(call GREEN, Cherry-pick to prod)"
	read -ep "Commit to cherry-pick: " COMMIT;
	git cherry-pick $$COMMIT;
	echo '=== COMPARE local TO PROD =======================';
	git log origin/prod..HEAD --oneline
	echo '=== --------------------- =======================';
	echo '=== COMPARE PROD to local =======================';
	git log HEAD..origin/prod --oneline
	echo '=== --------------------- =======================';

git.log:
	@git log --oneline -10

git.rm:
	@git branch -D $$(git branch | fzf $(FZF_MULTI) | awk '{print $$1}')

# Interactive NPM
npmi:
	# Interactive npm scripts
	script=$$(jq -r '.scripts | to_entries[] | "\(.key) => \(.value)"' < package.json | sort | fzf | cut -d' ' -f1); \
	[ -n "$$script" ] && npm run $$script

# =============== VIDEOS =====================
download.m3u8:
	read -ep "Enter m3u8 URL: " URL;
	read -ep "Enter file name (with extension): " FILE;
	ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i $$URL -c copy $$FILE
	printf '\a Download \a is \a done \a'
mp4-compress-all:
	for f in *.mp4; do temp="temp_$f"; ffmpeg -i "$f" -c:v libx264 -crf 28 -c:a copy -y "$temp" && mv -f "$temp" "$f"; done
mp4-compress-single:
	read -ep "Enter file to compress: " FILE;
	ffmpeg -i $$FILE -c:v libx264 -crf 28 -c:a copy "$${FILE}.compressed.mp4"
download-mp3:
	@for i in $$(seq -w 1 14); do \
		wget -nc -q --show-progress \
		"https://archive.org/download/01-10_202604/01-$${i}.mp3"; \
	done

# =============== JSON =====================
json.select:
	@echo "$(call GREEN,Selecting jsonpath ...)"
	read -ep "Enter json file: " FILE;
	read -ep "Enter code to select entity: " CODE;
	jq ".[] | select(.code == \"$$CODE\")" $$FILE

#========= DOCKER ACTION ===================
DOCKER_FORMAT := --format "table {{.ID}} \t{{.Names}}\t{{.Status}}\t{{ printf \"%.40s\" .Ports}}"
DOCKER_CYCLE_MULTI := --cycle --multi --bind="space:toggle"

docker.stop-all:
	docker container stop $$(docker container ps -q | tail -n +2 | awk '{printf $$1 " "}') || true

docker.restart:
	sudo systemctl restart docker &>/dev/null || true
	sudo systemctl status docker | head -n 10

docker.ps:
	@docker ps $(DOCKER_FORMAT)

docker.exec:
	@container=$$(docker ps $(DOCKER_FORMAT) | fzf | awk '{print $$2}'); \
	docker exec -it $$container bash -c 'pwd; ls -la; sh' \
	|| docker exec -it $$container sh -c 'pwd; ls -la; sh'

docker.inspect:
	@docker inspect $$(docker ps $(DOCKER_FORMAT) | fzf | awk '{print $$2}')
docker.inspect.exit:
	@docker inspect $$(docker ps -a $(DOCKER_FORMAT) | fzf | awk '{print $$2}') --format='{{.State.ExitCode}}'

docker.start:
	@docker start $$(docker ps -a $(DOCKER_FORMAT) | fzf $(DOCKER_CYCLE_MULTI) | awk '{print $$1}')

docker.stop:
	@docker stop $$(docker ps $(DOCKER_FORMAT) | fzf $(DOCKER_CYCLE_MULTI) | awk '{print $$1}')

docker.logs:
	@docker logs -f $$(docker ps -a $(DOCKER_FORMAT) | fzf | awk '{print $$2}')

docker.rm:
	@type=$(call PROMPT_CHOICES,Type ,container|image|volume|network)
	[ -n "$$type" ] && $(MMAKE) --silent "_docker.rm.$${type}"
_docker.rm.container:
	ctr=$$(docker container ls -a | fzf $(DOCKER_CYCLE_MULTI) --prompt='Container to remove (space for multiselect): ' | awk '{print $$1}')
	[ -n "$$ctr" ] && docker container rm $$ctr
_docker.rm.image:
	img=$$(docker image ls | fzf $(DOCKER_CYCLE_MULTI) --prompt='Image to remove (space for multiselect): ' | awk '{print $$3}')
	[ -n "$$img" ] && docker image rm $$img
_docker.rm.volume:
	vol=$$(docker volume ls | fzf $(DOCKER_CYCLE_MULTI) --prompt='Volume to remove (space for multiselect): ' | awk '{print $$2}')
	[ -n "$$vol" ] && docker volume rm $$vol
_docker.rm.network:
	vol=$$(docker network ls | fzf $(DOCKER_CYCLE_MULTI) --prompt='Network to remove (space for multiselect): ' | awk '{print $$2}')
	[ -n "$$vol" ] && docker network rm $$vol

#========= DIFF ACTION ===================
diff.json:
	read -ep "Enter file 1: " FILE1
	read -ep "Enter file 2: " FILE2
	jq --sort-keys . $$FILE1 > "$$FILE1.s"
	jq --sort-keys . $$FILE2 > "$$FILE2.d"
	git diff --no-index "$$FILE1.s" "$$FILE2.d"

# ========= MISC
local.history:
	@history | sort --unique > ~/.local_history2
	mv ~/.local_history2 ~/.local_history
	cat ~/.local_history <(cat ~/.bash_history | sort --unique) | \
	fzf --no-sort --exact | tee -a ~/.local_history | tee >(xclip -selection clipboard) | bash

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
cddd:
	has_dot_git() { while read -r line; do [[ -d "$${line}/.git" ]] && echo "$${line}"; done; }
	f=$$(find . -maxdepth 3 -type d -not -path "." | has_dot_git | fzf)
	[[ -n "$${f}" ]] && cd "$$(pwd)/$${f}"

random-password:
	openssl rand -base64 16


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
gradle.run.changed.tests:
	@read -p "Diff or Show ? (diff): " MODE;
	@changed=$$(git $$MODE --name-only | grep modules | grep java \
	| awk '{m=substr($$0, 9, index($$0, "src") - 10); print m":test", m":integTest"}' \
	| sort --unique | tr '/\n' '- ')
	./gradlew $$changed
	echo -e "TESTS EXECUTED FOR MODULES:\n$$(echo "$$changed" | tr ' ' '\n\t')";
update-programs-ubuntu:
	sudo apt-get install google-chrome-stable

programs-reset:
	rm ~/.config/bcompare/registry.dat
cleanup-ubuntu:
	echo "Used DF $$(df -h | grep '/dev' | awk '{print $$3}')"
	sudo find /var/log -type f -mtime +3 -delete
	sudo find /home -name '*.log' -mtime +3 -delete
	docker system prune -af
	docker volume prune -af
	sudo apt update || true
	sudo apt autoremove --purge -y || true
	sudo apt clean || true
	sudo apt autoclean || true
	sudo rm -rf /var/cache/apt/archives/* || true
	sudo rm -rf /var/cache/apt/*.bin || true
	sudo apt install deborphan || true
	sudo deborphan | xargs -r sudo apt -y remove --purge || true
	sudo journalctl --vacuum-size=1 || true
	sudo rm -rf /var/cache/apt/archives/* || true
	rm -rf ~/.cache/* || true
	snap list --all | awk '/disabled/{print $$1, $$3}' | \
	while read snapname revision; do sudo snap remove "$$snapname" --revision="$$revision";	done
	echo "Used DF $$(df -h | grep '/dev' | awk '{print $$3}')"
cleanup-npm:
	cd /home
	read -p "Where to look node_modules " NPM_ROOT
	find $$NPM_ROOT -name "node_modules" -type d -prune -exec rm -rf '{}' +
backup-ubuntu:
	dconf dump /com/gexperts/Tilix/ > ~/programs/tilix-settings.conf
	zip --recurse-paths --quiet Ubuntu.Backup.zip \
	~/Makefile ~/.ssh \
	~/.bash_profile ~/.bashrc ~/.gitconfig \
	~/.aws \
	~/.config/bcompare ~/.config/JetBrains ~/.config/KeePass ~/.config/sublime-text ~/.config/git \
	~/.config/systemd \
	~/docker.install.sh get-docker.sh gpg-no-tty.sh \
	~/.docker/config.json ~/programs/c24.kdbx ~/programs/bookmarks.html \
	~/bash_completion.d ~/programs/tilix-settings.conf ~/programs/chrome_passwords.csv \
	~/programs/dict-DE-de \
	~/Downloads/jira ~/Downloads/Postman ~/Documents/Trainings ~/Work \
	~/claude \
	/opt/install-intellij.sh \
	$$(find "$${HOME}/IdeaProjects" -type f -wholename '*/.idea/workspace.xml') \
	$$(find "$${HOME}/programs" -type f -name 'CLAUDE.md')
	du -h Ubuntu.Backup.zip
	cp Ubuntu.Backup.zip /mnt/d/_Backup/Ubuntu.Backup.zip && rm Ubuntu.Backup.zip
gpg-key-gen:
	gpg --gen-key
	gpg --list-secret-keys --keyid-format LONG
	read -p "Enter key: " KEY
	gpg --armor --export $$KEY
	echo "Replace key in ~/.gitconfig"
clip:
	@xclip -sel clip
clip2img:
	@image="/tmp/$$(date +%Y-%m-%d_%H%M%S).png"; \
	xclip -selection clipboard -t image/png -o > $$image; \
	echo $$image | xclip -sel clip
