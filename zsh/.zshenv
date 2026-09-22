# Zsh environment — loaded for ALL zsh invocations (before .zshrc).
# Ubuntu-family guard: /etc/zsh/zshrc runs system compinit unless the
# skip-global-compinit variable is set; marlonrichert/zsh-autocomplete owns
# compinit itself at first precmd ("Remove any calls to compinit" — upstream
# README), so the system call would double-initialize. No-op on Arch (no global compinit).
skip_global_compinit=1
