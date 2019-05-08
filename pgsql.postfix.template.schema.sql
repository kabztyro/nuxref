--   Copyright 2014 Chris Caron <lead2gold@gmail.com>
--
--   This is free software: you can redistribute it and/or modify it under the
--   terms of the GNU General Public License as published by the Free Software
--   Foundation, either version 3 of the License, or (at your option) any later
--   version.
--
--   This file is distributed in the hope that it will be useful, but WITHOUT
--   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
--   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
--   more details.
--
--   You should have received a copy of the GNU General Public License along
--   with this file. If not, see http://www.gnu.org/licenses/.
-------------------------------------------------------------------------------
--
-- This template was created based on a blog post I prepared on http://nuxref.com
-- It is a slight deviation from the original which didn't:
--      - support vacation automated replies
--      - disk quota's
--      - locked down permissions
--      - preparation for dovecot access and control
--
--? This template requires that the user substitute a vew fariables into it in
--? order to successfully be able to load it into their postgresql database:
--?      - %PGROUSER% with the Mail Server's Read Only UserID
--?      - %PGRWUSER% with the Mail Server's Administrator (Read/Write) User ID
--?      - %DOMAIN% with the Mail Server's primary domain identification
--?
--? For more information visit http://nuxref.com
--?
--?
--? The simpliest way to preform this might be doing this on the shell:
--?
--?  # Define your variables
--?  PGROUSER=mailreader
--?  PGRWUSER=mailwriter
--?  DOMAIN=nuxref.com
--?
--?  # Create a copy of this template with the variables populated correctly:
--?  sed -e '/^--?/d' \
--?      -e "s/%PGROUSER%/$PGROUSER/g" \
--?      -e "s/%PGRWUSER%/$PGRWUSER/g" \
--?      -e "s/%DOMAIN%/$DOMAIN/g" \
--?          pgsql.postfix.template.schema.sql > /tmp/pgsql.postfix.schema.sql
--?
--?  # Now load the data into your PostgreSQL database.
--?
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
CREATE PROCEDURAL LANGUAGE plpgsql;
ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;
SET search_path = public, pg_catalog;
CREATE FUNCTION merge_quota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            UPDATE quota SET current = NEW.current + current WHERE username = NEW.username AND path = NEW.path;
            IF found THEN
                RETURN NULL;
            ELSE
                RETURN NEW;
            END IF;
      END;
      $$;
ALTER FUNCTION public.merge_quota() OWNER TO %PGRWUSER%;
CREATE FUNCTION merge_quota2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            IF NEW.messages < 0 OR NEW.messages IS NULL THEN
                -- ugly kludge: we came here from this function, really do try to insert
                IF NEW.messages IS NULL THEN
                    NEW.messages = 0;
                ELSE
                    NEW.messages = -NEW.messages;
                END IF;
                return NEW;
            END IF;
            LOOP
                UPDATE quota2 SET bytes = bytes + NEW.bytes,
                    messages = messages + NEW.messages
                    WHERE username = NEW.username;
                IF found THEN
                    RETURN NULL;
                END IF;
                BEGIN
                    IF NEW.messages = 0 THEN
                    INSERT INTO quota2 (bytes, messages, username) VALUES (NEW.bytes, NULL, NEW.username);
                    ELSE
                        INSERT INTO quota2 (bytes, messages, username) VALUES (NEW.bytes, -NEW.messages, NEW.username);
                    END IF;
                    return NULL;
                    EXCEPTION WHEN unique_violation THEN
                    -- someone just inserted the record, update it
                END;
            END LOOP;
        END;
        $$;
ALTER FUNCTION public.merge_quota2() OWNER TO %PGRWUSER%;
CREATE FUNCTION merge_domain_quota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            IF NEW.messages < 0 OR NEW.messages IS NULL THEN
                -- ugly kludge: we came here from this function, really do try to insert
                IF NEW.messages IS NULL THEN
                    NEW.messages = 0;
                ELSE
                    NEW.messages = -NEW.messages;
                END IF;
                return NEW;
            END IF;

            LOOP
                UPDATE domain_quota SET bytes = bytes + NEW.bytes,
                    messages = messages + NEW.messages
                    WHERE domain = NEW.domain;
                IF found THEN
                    RETURN NULL;
                END IF;
                BEGIN
                    IF NEW.messages = 0 THEN
                        INSERT INTO domain_quota (bytes, messages, domain) VALUES (NEW.bytes, NULL, NEW.domain);
                    ELSE
                        INSERT INTO domain_quota (bytes, messages, domain) VALUES (NEW.bytes, -NEW.messages, NEW.domain);
                    END IF;
                    return NULL;
                    EXCEPTION WHEN unique_violation THEN
                    -- someone just inserted the record, update it
                END;
            END LOOP;
        END;
        $$;
ALTER FUNCTION public.merge_domain_quota() OWNER TO %PGRWUSER%;

SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE admin (
    username character varying(255) NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.admin OWNER TO %PGRWUSER%;
COMMENT ON TABLE admin IS 'Postfix Admin - Virtual Admins';
CREATE TABLE alias (
    address character varying(255) NOT NULL,
    goto text NOT NULL,
    domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.alias OWNER TO %PGRWUSER%;
COMMENT ON TABLE alias IS 'Postfix Admin - Virtual Aliases';
CREATE TABLE alias_domain (
    alias_domain character varying(255) NOT NULL,
    target_domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.alias_domain OWNER TO %PGRWUSER%;
COMMENT ON TABLE alias_domain IS 'Postfix Admin - Domain Aliases';
CREATE TABLE config (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    value character varying(20) NOT NULL
);
ALTER TABLE public.config OWNER TO %PGRWUSER%;
CREATE SEQUENCE config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;
ALTER TABLE public.config_id_seq OWNER TO %PGRWUSER%;
ALTER SEQUENCE config_id_seq OWNED BY config.id;
CREATE TABLE domain (
    domain character varying(255) NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    aliases integer DEFAULT 0 NOT NULL,
    mailboxes integer DEFAULT 0 NOT NULL,
    maxquota bigint DEFAULT 0 NOT NULL,
    quota bigint DEFAULT 0 NOT NULL,
    transport character varying(255) DEFAULT NULL::character varying,
    backupmx boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.domain OWNER TO %PGRWUSER%;
COMMENT ON TABLE domain IS 'Postfix Admin - Virtual Domains';
CREATE TABLE domain_admins (
    username character varying(255) NOT NULL,
    domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.domain_admins OWNER TO %PGRWUSER%;
COMMENT ON TABLE domain_admins IS 'Postfix Admin - Domain Admins';
CREATE TABLE fetchmail (
    id integer NOT NULL,
    mailbox character varying(255) DEFAULT ''::character varying NOT NULL,
    src_server character varying(255) DEFAULT ''::character varying NOT NULL,
    src_auth character varying(15) NOT NULL,
    src_user character varying(255) DEFAULT ''::character varying NOT NULL,
    src_password character varying(255) DEFAULT ''::character varying NOT NULL,
    src_folder character varying(255) DEFAULT ''::character varying NOT NULL,
    poll_time integer DEFAULT 10 NOT NULL,
    fetchall boolean DEFAULT false NOT NULL,
    keep boolean DEFAULT false NOT NULL,
    protocol character varying(15) NOT NULL,
    extra_options text,
    returned_text text,
    mda character varying(255) DEFAULT ''::character varying NOT NULL,
    date timestamp with time zone DEFAULT now(),
    usessl boolean DEFAULT false NOT NULL,
    CONSTRAINT fetchmail_protocol_check CHECK (((protocol)::text = ANY ((ARRAY['POP3'::character varying, 'IMAP'::character varying, 'POP2'::character varying, 'ETRN'::character varying, 'AUTO'::character varying])::text[]))),
    CONSTRAINT fetchmail_src_auth_check CHECK (((src_auth)::text = ANY ((ARRAY['password'::character varying, 'kerberos_v5'::character varying, 'kerberos'::character varying, 'kerberos_v4'::character varying, 'gssapi'::character varying, 'cram-md5'::character varying, 'otp'::character varying, 'ntlm'::character varying, 'msn'::character varying, 'ssh'::character varying, 'any'::character varying])::text[])))
);
ALTER TABLE public.fetchmail OWNER TO %PGRWUSER%;
CREATE SEQUENCE fetchmail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;
ALTER TABLE public.fetchmail_id_seq OWNER TO %PGRWUSER%;
ALTER SEQUENCE fetchmail_id_seq OWNED BY fetchmail.id;
CREATE TABLE log (
    "timestamp" timestamp with time zone DEFAULT now(),
    username character varying(255) DEFAULT ''::character varying NOT NULL,
    domain character varying(255) DEFAULT ''::character varying NOT NULL,
    action character varying(255) DEFAULT ''::character varying NOT NULL,
    data text DEFAULT ''::text NOT NULL
);
ALTER TABLE public.log OWNER TO %PGRWUSER%;
COMMENT ON TABLE log IS 'Postfix Admin - Log';
CREATE TABLE mailbox (
    username character varying(255) NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    maildir character varying(255) DEFAULT ''::character varying NOT NULL,
    quota bigint DEFAULT 0 NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    domain character varying(255),
    local_part character varying(255) NOT NULL
);

ALTER TABLE public.mailbox OWNER TO %PGRWUSER%;
COMMENT ON TABLE mailbox IS 'Postfix Admin - Virtual Mailboxes';
CREATE TABLE quota (
    username character varying(255) NOT NULL,
    path character varying(100) NOT NULL,
    current bigint
);
ALTER TABLE public.quota OWNER TO %PGRWUSER%;
CREATE TABLE quota2 (
    username character varying(100) NOT NULL,
    bytes bigint DEFAULT 0 NOT NULL,
    messages integer DEFAULT 0 NOT NULL
);
ALTER TABLE public.quota2 OWNER TO %PGRWUSER%;
CREATE TABLE domain_quota (
    domain character varying(100) NOT NULL,
    bytes bigint DEFAULT 0 NOT NULL,
    messages integer DEFAULT 0 NOT NULL
);
ALTER TABLE public.domain_quota OWNER TO %PGRWUSER%;
CREATE TABLE vacation (
    email character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    created timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    domain character varying(255)
);
ALTER TABLE public.vacation OWNER TO %PGRWUSER%;
COMMENT ON TABLE vacation IS 'Postfix Admin - Vacation';
CREATE TABLE vacation_notification (
    on_vacation character varying(255) NOT NULL,
    notified character varying(255) NOT NULL,
    notified_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.vacation_notification OWNER TO %PGRWUSER%;
COMMENT ON TABLE vacation_notification IS 'Postfix Admin - Vacation Notification';

ALTER TABLE config ALTER COLUMN id SET DEFAULT nextval('config_id_seq'::regclass);
ALTER TABLE fetchmail ALTER COLUMN id SET DEFAULT nextval('fetchmail_id_seq'::regclass);
ALTER TABLE ONLY admin
    ADD CONSTRAINT admin_key PRIMARY KEY (username);
ALTER TABLE ONLY alias_domain
    ADD CONSTRAINT alias_domain_pkey PRIMARY KEY (alias_domain);
ALTER TABLE ONLY alias
    ADD CONSTRAINT alias_key PRIMARY KEY (address);
ALTER TABLE ONLY config
    ADD CONSTRAINT config_name_key UNIQUE (name);
ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);
ALTER TABLE ONLY domain
    ADD CONSTRAINT domain_key PRIMARY KEY (domain);
ALTER TABLE ONLY fetchmail
    ADD CONSTRAINT fetchmail_pkey PRIMARY KEY (id);
ALTER TABLE ONLY mailbox
    ADD CONSTRAINT mailbox_key PRIMARY KEY (username);
ALTER TABLE ONLY domain_quota
    ADD CONSTRAINT domain_quota_pkey PRIMARY KEY (domain);
ALTER TABLE ONLY quota2
    ADD CONSTRAINT quota2_pkey PRIMARY KEY (username);
ALTER TABLE ONLY quota
    ADD CONSTRAINT quota_pkey PRIMARY KEY (username, path);
ALTER TABLE ONLY vacation_notification
    ADD CONSTRAINT vacation_notification_pkey PRIMARY KEY (on_vacation, notified);
ALTER TABLE ONLY vacation
    ADD CONSTRAINT vacation_pkey PRIMARY KEY (email);
CREATE INDEX alias_address_active ON alias USING btree (address, active);
CREATE INDEX alias_domain_active ON alias_domain USING btree (alias_domain, active);
CREATE INDEX alias_domain_idx ON alias USING btree (domain);
CREATE INDEX domain_domain_active ON domain USING btree (domain, active);
CREATE INDEX mailbox_domain_idx ON mailbox USING btree (domain);
CREATE INDEX mailbox_username_active ON mailbox USING btree (username, active);
CREATE INDEX vacation_email_active ON vacation USING btree (email, active);
CREATE TRIGGER mergequota
    BEFORE INSERT ON quota
    FOR EACH ROW
    EXECUTE PROCEDURE merge_quota();
CREATE TRIGGER mergequota2
    BEFORE INSERT ON quota2
    FOR EACH ROW
    EXECUTE PROCEDURE merge_quota2();
CREATE TRIGGER mergedomain_quota
    BEFORE INSERT ON domain_quota
    FOR EACH ROW
    EXECUTE PROCEDURE merge_domain_quota();
ALTER TABLE ONLY alias_domain
    ADD CONSTRAINT alias_domain_alias_domain_fkey FOREIGN KEY (alias_domain) REFERENCES domain(domain) ON DELETE CASCADE;
ALTER TABLE ONLY alias
    ADD CONSTRAINT alias_domain_fkey FOREIGN KEY (domain) REFERENCES domain(domain);
ALTER TABLE ONLY alias_domain
    ADD CONSTRAINT alias_domain_target_domain_fkey FOREIGN KEY (target_domain) REFERENCES domain(domain) ON DELETE CASCADE;
ALTER TABLE ONLY domain_admins
    ADD CONSTRAINT domain_admins_domain_fkey FOREIGN KEY (domain) REFERENCES domain(domain);
ALTER TABLE ONLY mailbox
    ADD CONSTRAINT mailbox_domain_fkey1 FOREIGN KEY (domain) REFERENCES domain(domain);
ALTER TABLE ONLY vacation
    ADD CONSTRAINT vacation_domain_fkey1 FOREIGN KEY (domain) REFERENCES domain(domain);
ALTER TABLE ONLY vacation_notification
    ADD CONSTRAINT vacation_notification_on_vacation_fkey FOREIGN KEY (on_vacation) REFERENCES vacation(email) ON DELETE CASCADE;
 -- Preset Database Version
-- This is a bit of a farce since we adjusted a few of the tables, none the
-- less, it makes sure that postfixadmin is happy
INSERT INTO config (name, value) VALUES
('version', '740');

-- Vacation Support
-- Support newest vacation.pl (v4.0r1)
ALTER TABLE vacation
   ADD COLUMN interval_time integer DEFAULT 0 NOT NULL,
   ADD COLUMN activefrom timestamp DEFAULT now(),
   ADD COLUMN activeuntil timestamp DEFAULT NULL;
INSERT INTO domain (domain, description, transport) VALUES
('autoreply.%DOMAIN%', 'Vacation Auto-Reply', 'vacation:');

-- Add our domain
INSERT INTO domain (domain, description, transport) VALUES
('%DOMAIN%', '%DOMAIN%', 'dovecot:');
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
REVOKE ALL ON TABLE alias FROM PUBLIC;
REVOKE ALL ON TABLE alias FROM %PGRWUSER%;
GRANT ALL ON TABLE alias TO %PGRWUSER%;
GRANT SELECT ON TABLE alias TO %PGROUSER%;
REVOKE ALL ON TABLE alias_domain FROM PUBLIC;
REVOKE ALL ON TABLE alias_domain FROM %PGRWUSER%;
GRANT ALL ON TABLE alias_domain TO %PGRWUSER%;
GRANT SELECT ON TABLE alias_domain TO %PGROUSER%;
REVOKE ALL ON TABLE domain FROM PUBLIC;
REVOKE ALL ON TABLE domain FROM %PGRWUSER%;
GRANT ALL ON TABLE domain TO %PGRWUSER%;
GRANT SELECT ON TABLE domain TO %PGROUSER%;
REVOKE ALL ON TABLE mailbox FROM PUBLIC;
REVOKE ALL ON TABLE mailbox FROM %PGRWUSER%;
GRANT ALL ON TABLE mailbox TO %PGRWUSER%;
GRANT SELECT ON TABLE mailbox TO %PGROUSER%;
REVOKE ALL ON TABLE quota FROM PUBLIC;
REVOKE ALL ON TABLE quota FROM %PGRWUSER%;
GRANT ALL ON TABLE quota TO %PGRWUSER%;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE quota TO %PGROUSER%;
REVOKE ALL ON TABLE quota2 FROM PUBLIC;
REVOKE ALL ON TABLE quota2 FROM %PGRWUSER%;
GRANT ALL ON TABLE quota2 TO %PGRWUSER%;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE quota2 TO %PGROUSER%;
REVOKE ALL ON TABLE domain_quota FROM PUBLIC;
REVOKE ALL ON TABLE domain_quota FROM %PGRWUSER%;
GRANT ALL ON TABLE domain_quota TO %PGRWUSER%;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE domain_quota TO %PGROUSER%;
REVOKE ALL ON TABLE vacation FROM PUBLIC;
REVOKE ALL ON TABLE vacation FROM %PGRWUSER%;
GRANT ALL ON TABLE vacation TO %PGRWUSER%;
GRANT SELECT ON TABLE vacation TO %PGROUSER%;
REVOKE ALL ON TABLE vacation_notification FROM PUBLIC;
REVOKE ALL ON TABLE vacation_notification FROM %PGRWUSER%;
GRANT ALL ON TABLE vacation_notification TO %PGRWUSER%;
GRANT SELECT,DELETE,INSERT,UPDATE ON TABLE vacation_notification TO %PGROUSER%;
