#!/bin/bash

REPO="ilkermeliksitki/ms-bemp-24w"
echo "Deleting all issues with a certain label in the repository '$REPO'..."

# Press y to continue
read -p "Press y to continue: " -n 1 -r
echo

# check if the user wants to continue
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting..."
    exit 1
fi

# take the label name as an argument
LABEL="$1"

# check if the label is provided
if [ -z "$LABEL" ]; then
    echo "Usage: $0 <label>"
    exit 1
fi

# Delete all issues with the specified label
for ISSUE_NUMBER in $(gh issue list --repo "$REPO" --label "$LABEL" --json number --jq ".[] | .number"); do
    # delete the issue by asking for confirmation
    ISSUE_NAME=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json title --jq ".title")

    echo "Issue: $ISSUE_NUMBER $ISSUE_NAME is being deleted..."

    gh issue delete "$ISSUE_NUMBER" --repo "$REPO" 
done

echo "All issues with label '$LABEL' have been deleted."

