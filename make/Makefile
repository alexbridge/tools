# Copy Makefile to your user home directory
# use:
#	mmake branch
#	mmake reset

# Ubuntu on windows: ~\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu16.04onWindows_79rhkp1fndgsc\LocalState\rootfs
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
# example: $(call _i,Copying Makefile to user home ...)
define _0
	@echo make: $(1)
	@tput sgr0
endef

define _s
	@tput setaf 2
	$(call _0,$(1))
endef

define _e
	@tput setaf 1
	$(call _0,$(1))
endef

define _w
	@tput setaf 6
	$(call _0,$(1))
endef

define _i
	@tput setaf 3
	$(call _0,$(1))
endef

# Programms aliases
SHELL := /bin/bash
# add alias: alias mmake='make --file=~/Makefile'
MMAKE := make --file=~/Makefile
LATEST_TAG := git for-each-ref --sort=-taggerdate --count=1 --format '%(refname:short)' refs/tags

# ==== RECIPES ====

# Copy current Makefile to user home dir to use with mmake alias
cp-makefile:
	$(call _i,Copying Makefile to user home ...)
	@cp Makefile ~ && chmod 0600 ~/Makefile
	@$(call _s,Done)

# ================ GIT ACTIONS ==============

# Create a branch in current git directory
branch:
	@$(call _i,creating a branch on current git directory ...)
	@echo "Create a branch in current git directory"; \
	read -p "Enter branch name to create: " BRANCH; \
	read -ep "Enter source branch name: " SOURCE_BRANCH; \
	git reset --hard; git fetch origin -p; git checkout origin/$$SOURCE_BRANCH; git branch -D $$BRANCH; \
	git branch $$BRANCH origin/$$SOURCE_BRANCH; git checkout $$BRANCH; \
	git push origin $$BRANCH; git branch --set-upstream-to=origin/$$BRANCH; \
	echo Done!

# Reset git HEAD to given branch
reset:
	@$(call _i,Reset git go given branch/tag in current git directory ...)
	@echo "Reset git HEAD in current directory to given branch"; \
	read -ep "Enter branch name to reset: " BRANCH; \
	tput setaf 6; read -ep "Stash changes (y/n) ?: "; tput sgr0; \
	if [[ "$$REPLY" == "y" ]]; then git stash; fi; \
	git reset --hard; git fetch origin -p; git checkout origin/$$BRANCH; git branch -D $$BRANCH; \
	git branch $$BRANCH origin/$$BRANCH; git checkout $$BRANCH; git branch --set-upstream-to=origin/$$BRANCH; \
	if [[ "$$REPLY" == "y" ]]; then git stash pop; fi; \
	echo Done!

# Tag current state
git-tag:
	@$(call _i,Creating a git tag...)
	@ LATEST=$$(${LATEST_TAG}); \
	@tput setaf 7; echo Most recent tag: $$LATEST; tput sgr0; \
	tput setaf 6; read -ep "Enter new version: " -i "$${LATEST}" TAG; tput sgr0; \
	tput setaf 2; echo New version will be: $$TAG; tput sgr0; \
	git tag -d $$TAG; git tag $$TAG; git push origin tags/$$TAG; \
	echo Done!

# Create git archieve without ignored files
git-archive:
	@$(call _i,Making git archive ...)
	read -ep "Enter branch/tag to reset: " HEAD; \
	git reset --hard; git fetch origin -p; git checkout origin/$$HEAD; \
	read -ep "Enter archive name: " ARCHIVE; \
	git archive --format=tar -o $$ARCHIVE head; \
	echo Done!

# ================ AWS ACTIONS ==============

aws-stop:
	aws ec2 stop-instances --instance-ids "i-****************"

aws-start:
	aws ec2 start-instances --instance-ids "i-***************"
	
	
# =============== VIDEOS =====================
.ONESHELL:
download-m3u8:
	read -ep "Enter m3u8 URL: " URL;
	read -ep "Enter file name (withoum mp4 sufux): " FILE;
	ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i $$URL -c copy $$FILE.mp4
