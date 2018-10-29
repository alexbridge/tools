# Copy Makefile to your user home directory
# use:
#	mmake ext-clone
#	mmake ext-remove
#	mmake ext-checkout
#	mmake ext-install

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
	git reset --hard; git fetch origin -p; git checkout origin/$$BRANCH; git branch -D $$BRANCH; \
	git branch $$BRANCH origin/$$BRANCH; git checkout $$BRANCH; git branch --set-upstream-to=origin/$$BRANCH; \
	echo Done!
