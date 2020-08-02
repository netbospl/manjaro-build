FROM jonathonf/manjaro:latest

ADD pacman-trustall.conf /pacman-trustall.conf
RUN mv /etc/pacman.conf /pacman.conf && \
    mv /pacman-trustall.conf /etc/pacman.conf
RUN pacman-key --init && pacman-key --populate archlinux manjaro

RUN pacman-mirrors -c France -a -B stable
RUN pacman -Syuu --noconfirm --noprogressbar --needed base-devel sed ccache pacman-static && \
    sed -i "/\[core\]/ { N; s|\[core\]\n|\[packages\]\nSigLevel = Optional TrustAll\nServer = file:///build/packages\n\n&| } " /etc/pacman.conf && \
    pacman -Scc --noconfirm --noprogressbar && \
    rm -fr /var/cache/pacman/pkg/* && \
    rm -f /var/lib/pacman/sync/*

RUN rm -fr /var/cache/pacman/pkg && \
    ln -s /pkgcache /var/cache/pacman/pkg

RUN rm -f /etc/locale.conf && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    rm -f /etc/locale.gen && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    /usr/bin/locale-gen en_US.UTF-8

RUN /usr/bin/useradd -m builder && \
    echo 'builder ALL=(root) NOPASSWD:/usr/bin/pacman' > /etc/sudoers.d/makepkg

RUN sed -i '44cMAKEFLAGS="-j$(($(nproc) + 1))"' /etc/makepkg.conf && \
    sed -i '114cPKGDEST=/build/packages'        /etc/makepkg.conf && \
    sed -i '116cSRCDEST=/build/sources'         /etc/makepkg.conf && \
    sed -i '118cSRCPKGDEST=/build/srcpackages'  /etc/makepkg.conf && \
    sed -i '120cLOGDEST=/build/makepkglogs'     /etc/makepkg.conf && \
    sed -i '132cCOMPRESSXZ=(xz -c -z -T0 -)'    /etc/makepkg.conf

# RUN sed -i "/\[core\]/ { N; s|\[core\]\n|\
# \[packages\]\n\
# SigLevel = Optional TrustAll\n\
# Server = file:///build/packages\n\n&| } " /etc/pacman.conf

RUN rm /usr/sbin/pinentry && \
    ln -s /usr/sbin/pinentry-curses /usr/sbin/pinentry && \
    mkdir -p /data/ccache && \
    chmod 777 -R /data/ccache
ENV CCACHE_DIR=/data/ccache

ADD makepackage.sh /makepackage.sh
RUN chmod a+rx /makepackage.sh

VOLUME [ '/build' '/gpg' '/pkgcache' '/data' ]

CMD [ "/makepackage.sh" ]
