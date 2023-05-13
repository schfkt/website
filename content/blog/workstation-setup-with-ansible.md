---
title: "Automate workstation setup with Ansible"
date: 2023-05-13
---

Since the early days of my software engineering career I was trying different ways to automate setup of my workstations. The first attempt that served me well, but was quite basic, included just a github repo with all my dotfiles plus a bash script to automate symlinking of these configs. Package instalation and some other tweaking were still done manually, although in case of macOS it was easy thanks to Brewfile with all the packages I needed.

Then a few years later I had to play with Ansible at work. I liked its simplicity and quickly realized: why not just use it to setup my machines? It was especially important at that time, because I was using both macos and linux setups. And both of the systems had specific setup steps that I, of course, could add into the bash script, but it would quickly become tedious.

After maybe a year of using Ansible at work and for my homelab setup I decided to try it also to configure my machines. It turned out to be great! In case I need to setup a new workstation now, it'll just take me around 15 minutes to replicate the same setup that I have everywhere. With the same dotfiles I use, which are synced across all the machines thanks to [syncthing](https://syncthing.net/) (this is another great tool that deserves its own blogpost!).

# Ansible 101

Ansible consists of many interesting features, but the one you are gonna use the most is a playbook. A playbook describes what has to be done on a list of hosts. For example: installing packages, copying config files, configuring a firewall. For each such kind of task, there's a module responsible for it. A module is a Python library that implements that functionality. Some modules are bultin into most of the Ansible installations. And there are plenty of them. Every time I want to do something new with Ansible, I find a module for that.

Here are a couple of examples:
- [authorized_key](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html)
- [ufw](https://docs.ansible.com/ansible/latest/collections/community/general/ufw_module.html)
- [template](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)

I think, template module is the one that I use the most. It allows to use [jinja2 templating engine](http://jinja.pocoo.org/docs/) to build files based on, well, templates. When some config file requires configurability (by substituting certain variables), this is the module to go for.

Below is a basic example of a playbook:

```yml
- name: setup smarthome server
  hosts: smarthome
  become: true
  vars:
    disks:
      - uuid: "b041aa26-a64b-47c5-922a-84d2102bca24"
        fstype: ext4
  tasks:
    - name: mount disks
      ansible.posix.mount:
        src: "UUID={{item.uuid}}"
        path: /srv
        state: mounted
        fstype: "{{ item.fstype }}"
      tags:
        - disks
      loop: "{{ disks }}"
  roles:
    - { role: sshd, tags: sshd }
```

Each playbook contains an array of so-called "plays". A "play" is just a list of tasks applied to a list of hosts. That particular playbook has only one "play" with:
- List of hosts to apply tasks to. Here we have only one host: `smarthome`.
- `become: true` tells Ansible that all the tasks has to be run as `root` (can be changed with `become_user` too).
- Variables definitions. These can later be used in tasks or for substitutions in templates.
- Individual tasks to apply to hosts.
- List of roles to apply to hosts (more on roles below).

This is just a high-level overview of what a playbook can look like. For more information, please refer to the docs: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html

Sometimes, when you want to extract related tasks out of a playbook, there's also a way to do this. Roles are used just for that. A role is a set of tasks and configurations. It's just a way to share some tasks as a whole unit. And Ansible also allows to distribute it like packages through Ansible Galaxy. There are a lot of great roles made by the community, like a role for nginx, grafana, etc. In my configuration for workstations, I use roles to group related tasks and apply them separately when needed. For example, I have a role for nvim that installs and configures nvim together with plugins and external tools needed for them.

You can read more about roles in the official docs here: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html

And there is much more to cover about Ansible, but for this guide, this should be enough.

# Practical example

> **NOTE:** refer to this repository for the most up-to-date version of the setup described here https://github.com/schfkt/ansible-workstation

Let's get to a real-world example of how everything I mentioned above can be used to set up a machine. Here's the playbook I use:

```yml
- hosts: localhost
  become: false
  vars:
    dotfiles_dir: "{{ lookup('env', 'HOME') }}/sync/df"
  roles:
    - { role: packages, tags: packages }
    - { role: alacritty, tags: alacritty }
    - { role: vim, tags: vim }
    - { role: nvim, tags: nvim }
    - { role: tmux, tags: tmux }
    - { role: tig, tags: tig }
    - { role: bash, tags: bash }
    - { role: i3, tags: i3 }
    - { role: hibernate, tags: hibernate }
    - { role: firewall, tags: firewall }
    - { role: nodejs, tags: nodejs }
    - { role: gpg, tags: gpg }
    - { role: tailscale, tags: tailscale }
    - { role: syncthing, tags: syncthing }
```

It's quite basic and consists of:
- A global variable `dotfiles_dir` that can be used later in the roles/tasks to create symlinks to config files. That way I don't have to duplicate this value everywhere.
- A list of roles.

And that's it. As you can see, it's mostly split into separate parts by using roles. Most of the roles here describe how a particular tool has to be set up. Except for the `packages` role that just contains the list of packages to install (with brew or apt).

Because I use both macOS and Linux, each role may contain steps specific to each OS. And this can also be easily achieved with Ansible. Let's look at the role for `Neovim`. Here's its structure:

```
$ tree roles/nvim/
roles/nvim/
└── tasks
    ├── main.yml
    └── packages
        ├── macos.yml
        ├── main.yml
        └── ubuntu.yml
```

And the entrypoint `tasks/main.yml` looks like this:

```yml
- name: install required packages
  include_tasks: packages/main.yml

- name: create directories for nvim
  file:
    path: "{{ item }}"
    state: directory
  loop:
    - "~/.config"
    - "~/.local/share/nvim/site/autoload"
    - "~/.local/share/nvim/undo"
    - "~/.local/share/nvim/backup"
    - "~/.local/share/nvim/swap"

- name: install vim-plug
  get_url:
    url: "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    dest: "~/.local/share/nvim/site/autoload/plug.vim"
    mode: 0600

- name: link the configs
  file:
    src: "{{ dotfiles_dir }}/{{ item.src }}"
    path: "{{ item.dest }}"
    state: link
  loop:
    - {src: ".config/nvim", dest: "~/.config/nvim"}
    - {src: ".vim/ultisnips", dest: "~/.local/share/nvim/ultisnips"}

- name: install the plugins
  command: 'nvim -E -s -c "source ~/.config/nvim/init.vim" -c PlugInstall -c qa'
  ignore_errors: true

- name: compile YCM
  command:
    chdir: "~/.local/share/nvim/plugged/YouCompleteMe"
    cmd: "./install.py --clang-completer --go-completer --ts-completer --rust-completer"
```

It's pretty self-descriptive: it creates config directories, installs everything related to neovim, and makes symlinks to configs.

All of the tasks, except the first one, are the same for macOS and Linux. But the first task includes tasks from another file:

```yml
- name: install packages for PopOS
  include_tasks: ubuntu.yml
  when: ansible_distribution == 'Pop!_OS'

- name: install packages for macOS
  include_tasks: macos.yml
  when: ansible_distribution == 'MacOSX'

- name: install package for python plugins support
  command:
    cmd: "python3 -m pip install --user --upgrade pynvim"
```

And here goes the "magic": it conditionally includes OS-specific tasks based on the value of `ansible_distribution` variable (which is populated by Ansible). So for Linux it does this:

```yml
- name: install prerequisites for PPA
  become: true
  apt:
    name:
      - software-properties-common
    install_recommends: no
    state: present

- name: add PPA repo
  become: true
  apt_repository:
    repo: 'ppa:neovim-ppa/stable'

- name: install packages for YCM
  become: true
  apt:
    name:
      - python3-dev
      - python3-pip
      - build-essential
      - cmake
      - golang
      - nodejs
      - npm
    state: present

- name: install neovim
  become: true
  apt:
    name:
      - neovim
    install_recommends: no
    state: present

- name: install additional packages
  become: true
  apt:
    name:
      - fzf
      - ripgrep
    install_recommends: no
    state: present
```

And for macOS this:

```yml
- name: install packages for YCM
  homebrew:
    name:
      - cmake
      - golang
      - nodejs
      - rustup-init
    state: present

- name: install nvim
  homebrew:
    name: nvim

- name: install additional packages
  homebrew:
    name:
      - fzf
      - ripgrep
```

So that single role can configure Neovim for both macOS and Linux based machines.

And now that we've got the playbook with tasks and roles set, how do we run it to apply changes on a machine? Here you go:

```sh
ansible-playbook --ask-become-pass playbook.yml
```

`--ask-become-pass` tells Ansible to ask for a user password upfront (it's used to invoke `sudo` in tasks that have `become: true` set).

There's also a way to apply only specific tasks or roles. You can do so by passing a list of tags, and Ansible will filter out only roles and tasks that have these tags set. Looking at this part of the playbook:

```yml
roles:
  - { role: packages, tags: packages }
  - { role: alacritty, tags: alacritty }
```

You can tell Ansible to apply only `alacritty` role like this:

```yml
ansible-playbook --ask-become-pass -t alacritty playbook.yml
```

# Conclusion

It takes time to familiarise with Ansible, but it's much more powerful for setting up machines compared to a bunch of bash scripts. Moreover, lots of features are already present as modules, so you don't need to reinvent the wheel.

Anyway, It was a short, but hopefully useful introduction to Ansible.