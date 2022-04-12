function precmd {
	# Check for untracked files or updated submodules since vcs_info does not.
	if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
		branch_format="($cyan%b %f%c%u$red●%f)"
	else
		branch_format="($cyan%b %f%c%u)"
	fi

	zstyle ':vcs_info:*:prompt:*' formats "${branch_format}"

	vcs_info 'prompt'
}

setopt LOCAL_OPTIONS

# Enable prompt substitutions
setopt prompt_subst
unsetopt XTRACE KSH_ARRAYS
prompt_opts=(cr percent sp subst)

  # Load required functions.
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  # Add hook for calling vcs_info before each command.
  # add-zsh-hook precmd prompt_steeef_precmd

  prompt_colors=(
	  "%F{cyan}"  # Turquoise
	  "%F{yellow}" # Orange
	  "%F{magenta}" # Purple
	  "%F{pink}" # Hotpink
	  "%F{green}" # Limegreen
	  "%F{blue}" # Limegreen
  )


local snowflake='❄'
local prompt_char='➜'
blue="%F{blue}"
cyan="%F{cyan}"  # Turquoise
green="%F{green}" # Limegreen
magenta="%F{magenta}"
pink="%F{pink}" # Hotpink
yellow="%F{yellow}"
red="%F{red}"

  # Formats:
  #   %b - branchname
  #   %u - unstagedstr (see below)
  #   %c - stagedstr (see below)
  #   %a - action (e.g. rebase-i)
  #   %R - repository path
  #   %S - path in the repository
  local branch_format="($cyan%b%f%u%c)"
  local action_format="($yellow%a%f)"
  local unstaged_format="$yellow●%f"
  local staged_format="$green●%f"


  # Set editor-info parameters.
  # zstyle ':prezto:module:editor:info:keymap:primary' format '❯ '


  autoload -Uz vcs_info

  # Set vcs_info parameters.
  # zstyle ':vcs_info:*' enable bzr git hg svn
  zstyle ':vcs_info:*' enable git svn
  zstyle ':vcs_info:*:prompt:*' check-for-changes true
  zstyle ':vcs_info:*:prompt:*' unstagedstr "${unstaged_format}"
  zstyle ':vcs_info:*:prompt:*' stagedstr "${staged_format}"
  zstyle ':vcs_info:*:prompt:*' actionformats "${branch_format}${action_format}"
  zstyle ':vcs_info:*:prompt:*' formats "${branch_format}"
  zstyle ':vcs_info:*:prompt:*' nvcsformats   ""







# # enable hooks, requires Zsh >=4.3.11
# if [[ $ZSH_VERSION == 4.3.<11->* || $ZSH_VERSION == 4.<4->* || $ZSH_VERSION == <5->* ]] ; then
#   # hook for untracked files
#   +vi-untracked() {
#     if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true'  ]] && \
#        [[ -n $(git ls-files --others --exclude-standard) ]] ; then
#        hook_com[staged]+='|☂'
#     fi
#   }

#   # unpushed commits
#   +vi-outgoing() {
#     local gitdir="$(git rev-parse --git-dir 2>/dev/null)"
#     [ -n "$gitdir" ] || return 0

#     if [ -r "${gitdir}/refs/remotes/git-svn" ] ; then
#       local count=$(git rev-list remotes/git-svn.. 2>/dev/null | wc -l)
#     else
#       local branch="$(cat ${gitdir}/HEAD 2>/dev/null)"
#       branch=${branch##*/heads/}
#       local count=$(git rev-list remotes/origin/${branch}.. 2>/dev/null | wc -l)
#     fi

#     if [[ "$count" -gt 0 ]] ; then
# 		echo $count
#       hook_com[staged]+="|↑$count"
#     fi
#   }

#   # hook for stashed files
#   +vi-stashed() {
#     if git rev-parse --verify refs/stash &>/dev/null ; then
#       hook_com[staged]+='|s'
#     fi
#   }

#   zstyle ':vcs_info:git*+set-message:*' hooks stashed untracked outgoing
# fi

# # required for *formats in vcs_info, see below
# BLUE="%F{blue}"
# RED="%F{red}"
# GREEN="%F{green}"
# CYAN="%F{cyan}"
# MAGENTA="%F{magenta}"
# YELLOW="%F{yellow}"
# WHITE="%F{white}"
# NO_COLOR="%f"

# # extend default vcs_info in prompt
zstyle ':vcs_info:*' actionformats "${MAGENTA}(${NO_COLOR}%s${MAGENTA})${YELLOW}-${MAGENTA}[${GREEN}%b${YELLOW}|${RED}%a%u%c${MAGENTA}]${NO_COLOR} " "zsh: %r"
zstyle ':vcs_info:*' formats       "${MAGENTA}(${NO_COLOR}%s${MAGENTA})${YELLOW}-${MAGENTA}[${GREEN}%b%u%c${MAGENTA}]${NO_COLOR}%} " "zsh: %r"


# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}

    if [[ -n ${remote} ]] ; then
        # for git prior to 1.7
        # ahead=$(git rev-list origin/${hook_com[branch]}..HEAD | wc -l)
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        (( $ahead )) && gitstatus+=( "${c3}+${ahead}${c2}" )

        # for git prior to 1.7
        # behind=$(git rev-list HEAD..origin/${hook_com[branch]} | wc -l)
        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
        (( $behind )) && gitstatus+=( "${c4}-${behind}${c2}" )


        hook_com[branch]="${hook_com[branch]} [${remote} ${(j:/:)gitstatus}]"
    fi
}


# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes

    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l)
        hook_com[misc]+=" (${stashes} stashed)"
    fi
}






# Define prompts.

local left_prompt=""

# Add user@host if on remote host
[[ $SSH_CONNECTION ]] && left_prompt+='[$yellow%n%f@$magenta%M%f] '

# Add path
left_prompt+="$blue%~%f"

# Add vcs information
left_prompt+=' ${vcs_info_msg_0_}'

# Add newline and prompt character
left_prompt+='
%(?.%F{green}.%F{red})$prompt_char%b%f '

# Set left prompt
PROMPT=$left_prompt

# Show nix-shell in right prompt
[[ ! -z "$IN_NIX_SHELL" ]] && RPROMPT="%F{blue}$IN_NIX_SHELL $snowflake $NIX_SHELL_PACKAGES"


zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*:*' get-revision true
zstyle ':vcs_info:git*:*' check-for-changes true

# hash changes branch misc
zstyle ':vcs_info:git*' formats "(%s) %12.12i %c%u %b%m"
zstyle ':vcs_info:git*' actionformats "(%s|%a) %12.12i %c%u %b%m"


zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash
