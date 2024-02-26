#!/bin/bash

# Check Cpp files for linting errors
check_linting_errors()
{
	clang-format -Werror --dry-run --style=webkit ./*.cpp ./*/*.cpp 2&> errors.log
	if [[ $(wc -l < errors.log) == 0 ]];
	then
		echo "No linting errors were found!"
		exit 0
	fi
	echo "Some errors have been found!"
}

# Push the found linting erros to the repo if there are any
push_linting_errors()
{
	check_linting_errors

	# Convert the linting error file to base64 to push to Github
	# ERRORS=$( base64 < ./errors.log )

	echo "Pushing linting errors to the repo......"
	# Using httpie and Github APIs tp push the linting error file to the repo
	# http PUT https://api.github.com/repos/"$GITHUB_REPOSITORY"/contents/errors.log \
	# 	"Authorization: Bearer $GITHUB_TOKEN" \
	# 	message="linting errors were detected!" \
	# 	committer:="{ \"name\": \"$GITHUB_ACTOR\", \"email\": \"$GITHUB_ACTOR@github.com\" }" \
	# 	content="$ERRORS" | jq .
	# curl -L \
	# 	-X PUT \
	# 	-H "Accept: application/vnd.github+json" \
	# 	-H "Authorization: Bearer $WEB_SERVER_TOKEN" \
	# 	-H "X-GitHub-Api-Version: 2022-11-28" \
	# 	https://api.github.com/repos/"$GITHUB_REPOSITORY"/contents/errors.log \
	# 	-d \'{"message":"linting errors were detected!","content":"$ERRORS"}\'
	git config --global --add safe.directory /github/workspace
	git add ./errors.log
	git commit -m "Linting errors were detected!"
	git push https://"$GITHUB_REPOSITORY_OWNER_ID":"$WEB_SERVER_TOKEN"@github.com/"$GITHUB_REPOSITORY".git main
}

# Fix all the linting errors inplace if the "FIXIT" keyword mentioned in the commit message
fix_linting_errors()
{
	check_linting_errors

	# Fix all the errors inplace using -i option
	if clang-format -Werror -i --style=webkit ./*.cpp ./*/*.cpp;
	then
		echo "All errors were resolved"
	else
		echo "Not all errors were resolved, please double check!"
		exit 1
	fi
}

check_arguments()
{
	if jq '.commits[].message, .head-commit.message' < "$GITHUB_EVENT_PATH" | grep -iq "$*";
	then
		echo "$* Keyword argument was found!"
		fix_linting_errors
	else
		echo "$* Keyword argument was not found!"
		exit 1
	fi
}

if [ -z "$GITHUB_EVENT_PATH" ];
then
	echo "Something went wrong!"
	exit 1
fi

if [ -n "$*" ];
then
	check_arguments "$@"
else
	echo "Check Cpp files for linting erros......"
	push_linting_errors
fi
