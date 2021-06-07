INSTALL_BIN:=install

.PHONY: install
install:
	$(INSTALL_BIN) -o buildbot -g buildbot -m 755 -t /home/buildbot/ build-mc-from-git.sh buildbot.sh initial-build.sh target-build.sh
	$(INSTALL_BIN) -o andrey -g andrey -m 644 -t /home/andrey/ contrib/apt-ftparchive/.apt-*.conf
	$(INSTALL_BIN) -o andrey -g andrey -m 755 -t /home/andrey/bin/ contrib/*.sh contrib/local-repo-update
	$(INSTALL_BIN) -o root -g root -m 644 -t /etc/pbuilder/ contrib/pbuilder/*
