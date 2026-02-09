{keyd}

sudo stow --adopt -t / keyd

sudo keyd reload

after that-

```bash
sudo EDITOR=nvim visudo
```

add this- 

```shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd```
