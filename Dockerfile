FROM ubuntu:16.04 AS xenial

LABEL \
    Description="Build a CopperheadOS update" \
    Version="1"

ARG UID=1000
ARG GID=1000

RUN \
    getent group $GID >/dev/null || groupadd --gid $GID build; \
    getent passwd $UID >/dev/null || useradd --uid $UID --gid $GID --create-home --home-dir /build build; \
    mkdir /build/.gnupg; chmod 700 /build/.gnupg; chown build /build/.gnupg; \
    apt-get -qq update; \
    apt-get -qq install -y --no-install-recommends \
        build-essential coreutils cpio dirmngr file git gnupg-curl libssl-dev \
        openjdk-8-jdk-headless python python3 python3-requests sudo unzip wget zip ; \
    echo apt-get -qq upgrade -y; \
    apt-get -qq clean; \
    gpg --quiet --batch --recv-keys 65EEFE022108E2B708CBFCF7F9E712E59AF5F22A; \
    gpg --quiet --batch --recv-keys C963C21D63564E2B10BB335B29846B3C683686CC; \
    gpg --quiet --batch --recv-keys 37D2C98789D8311948394E3E41E7044E1DBA2E89;

    # 65EEFE022108E2B708CBFCF7F9E712E59AF5F22A = CopperheadOS Daniel Micay
    # C963C21D63564E2B10BB335B29846B3C683686CC = Mike Perry
    # 37D2C98789D8311948394E3E41E7044E1DBA2E89 = F-Droid

ADD ["./docker-sudoers", "/etc/sudoers.d/build"]

USER $UID:$GID
WORKDIR /build

CMD ["/build/update-wrapper.sh", "angler", "--no-tor"]
