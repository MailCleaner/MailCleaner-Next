USE mc_config;

DROP TABLE IF EXISTS fail2ban_jail;

CREATE TABLE fail2ban_jail (
        id                      int not NULL AUTO_INCREMENT,
	enabled			BOOLEAN DEFAULT TRUE,
        name                    varchar(150) NOT NULL UNIQUE,
        maxretry                int not NULL,
        findtime                int not NULL,
        bantime                 int not NULL,
        port                    varchar(50) NOT NULL,
        filter                  varchar(50) NOT NULL,
        banaction               varchar(50) NOT NULL,
        logpath                 varchar(250) NOT NULL,
	max_count		int not NULL,
        send_mail               BOOLEAN DEFAULT FALSE,
        send_mail_bl            BOOLEAN DEFAULT TRUE,
        PRIMARY KEY (id)
);


INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-exim-bl", 1, 1, -1, "25,465,587", "mc-exim-filter", "mc-ipset", "/var/mailcleaner/log/exim/reject.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-ssh-bl", 1, 1, -1, "22", "sshd", "mc-ipset", "/var/log/auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-webauth-bl", 1, 1, -1, "80,443", "mc-webauth-filter", "mc-ipset", "/var/mailcleaner/log/apache/mc_auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-exim-1d", 5, 3600, 86400, "25,465,587", "mc-exim-filter", "mc-ipset", "/var/mailcleaner/log/exim/reject.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-ssh-1d", 3, 3600, 86400, "22", "sshd", "mc-ipset", "/var/log/auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-webauth-1d", 5, 3600, 86400, "80,443", "mc-webauth-filter", "mc-ipset", "/var/mailcleaner/log/apache/mc_auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-exim-1w", 10, 172800, 604800, "25,465,587", "mc-exim-filter", "mc-ipset", "/var/mailcleaner/log/exim/reject.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-ssh-1w", 6, 172800, 604800, "22", "sshd", "mc-ipset", "/var/log/auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-webauth-1w", 10, 172800, 604800, "80,443", "mc-webauth-filter", "mc-ipset", "/var/mailcleaner/log/apache/mc_auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-exim-1m", 15, 1209600, 2678400, "25,465,587", "mc-exim-filter", "mc-ipset", "/var/mailcleaner/log/exim/reject.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-ssh-1m", 9, 1209600, 2678400, "22", "sshd", "mc-ipset", "/var/log/auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-webauth-1m", 15, 1209600, 2678400, "80,443", "mc-webauth-filter", "mc-ipset", "/var/mailcleaner/log/apache/mc_auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-exim-1y", 20, 5356800, 2056800, "25,465,587", "mc-exim-filter", "mc-ipset", "/var/mailcleaner/log/exim/reject.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-ssh-1y", 12, 5356800, 2056800, "22", "sshd", "mc-ipset", "/var/log/auth.log", -1, 0);
INSERT INTO fail2ban_jail(enabled, name, maxretry, findtime, bantime, port, filter, banaction, logpath, max_count, send_mail, send_mail_bl) VALUES(NULL, 0, "mc-webauth-1y", 20, 5356800, 2056800, "80,443", "mc-webauth-filter", "mc-ipset", "/var/mailcleaner/log/apache/mc_auth.log", -1, 0);
