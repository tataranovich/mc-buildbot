#!/bin/bash

export LC_ALL=C
export LANG=C

# Import environment variables
if [ -f "${HOME}/.gnupg/gpg-agent.env" ]; then
        . "${HOME}/.gnupg/gpg-agent.env"
        export GPG_AGENT_INFO
fi

if [ -f "${HOME}/.ssh/ssh-agent.env" ]; then
        . "${HOME}/.ssh/ssh-agent.env"
        export SSH_AUTH_SOCK
fi

unset GPG_TTY
unset SSH_TTY
