FROM docker.io/library/archlinux as base

ARG PACMAN_PARALLELDOWNLOADS=5
RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && sed 's/ParallelDownloads = \d+/ParallelDownloads = ${PACMAN_PARALLELDOWNLOADS}/g' -i /etc/pacman.conf \
    && sed 's/NoProgressBar/#NoProgressBar/g' -i /etc/pacman.conf

# update mirrorlist
ADD https://raw.githubusercontent.com/greyltc/docker-archlinux/master/get-new-mirrors.sh /usr/bin/get-new-mirrors
RUN chmod +x /usr/bin/get-new-mirrors
RUN get-new-mirrors

RUN pacman -Syy --noconfirm && pacman -Syu --noconfirm
RUN pacman -Syyu --noconfirm ansible-core chezmoi curl go fish \
        git base-devel neovim openssh sudo tmux unzip wget \
    ; pacman -Rns $(pacman -Qtdq) \
    ; pacman -Scc --noconfirm \
    ; rm -Rf /var/cache/pacman/pkg/*

# We need to create a new user with sudo privileges
RUN useradd -m -G wheel -s /usr/bin/fish gamzer
RUN echo "gamzer:gamzer" | chpasswd
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER gamzer
WORKDIR /home/gamzer
RUN cd ~ && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm

RUN yay -S asdf-vm --noconfirm \
    ; sudo pacman -Rns $(pacman -Qtdq) \
    ; sudo pacman -Scc --noconfirm \
    ; sudo rm -Rf .cache/yay/* \
    ; sudo rm -Rf /var/cache/foreign-pkg/*

RUN source /opt/asdf-vm/asdf.sh \
    && asdf plugin-add lua \
    && asdf plugin-add nodejs \
    && asdf plugin-add python \
    && asdf plugin-add rust

FROM base AS ometz
USER gamzer
WORKDIR /home/gamzer/ansible
RUN ansible-galaxy collection install community.general
COPY --chown=gamzer:gamzer . .
