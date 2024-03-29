#!/bin/bash

# Check Cpp files for linting errors
check_linting_errors()
{
	find . -name '*.cpp' -o -name '*.hpp' | clang-format -Werror --dry-run --style=webkit > errors.log 2>&1
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
	ERRORS="You need to fix these errors to comply with our code style"
	ERRORS="## **$ERRORS**
	"
	ERRORS="$ERRORS
	$(cat errors.log)"

	echo "Pushing linting errors to the repo......"

	# Using httpie and Github APIs to push the linting error file to the repo
	# http --ignore-stdin PUT https://api.github.com/repos/"$GITHUB_REPOSITORY"/contents/errors.log \
	# 	"Authorization: Bearer $WEB_SERVER_TOKEN" \
	# 	message="linting errors were detected!" \
	# 	content="$ERRORS" | jq .

	# Using httpie to post the linting errors as an issue, label it and assign it to
	# the responsible developer
	http --ignore-stdin POST https://api.github.com/repos/"$GITHUB_REPOSITORY"/issues \
		"Authorization: Bearer $GITHUB_TOKEN" \
		title="Cpp linting errors by $GITHUB_ACTOR" \
		labels:='["linting", "invalid"]' \
		assignees:='["'"$GITHUB_ACTOR"'"]' \
		body="$ERRORS" | jq .
}

# Fix all the linting errors inplace if the "FIXIT" keyword mentioned in the commit message
fix_linting_errors()
{
	check_linting_errors

	# Fix all the errors inplace using -i option
	if find . -name '*.cpp' -o -name '*.hpp' | xargs clang-format -Werror -i --style=webkit
	then
		echo "All errors were resolved"
	else
		echo "Not all errors were resolved, please double check!"
		exit 1
	fi
}

check_arguments()
{
	if jq '.commits[].message, .head_commit.message' < "$GITHUB_EVENT_PATH" | grep -iq "$*";
	then
		echo "$* Keyword argument was found!"
		fix_linting_errors
	else
		echo "$* Keyword argument was not found!"
		push_linting_errors
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
