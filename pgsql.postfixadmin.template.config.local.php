<?php
//   Copyright 2014 Chris Caron <lead2gold@gmail.com>
//
//   This is free software: you can redistribute it and/or modify it under the
//   terms of the GNU General Public License as published by the Free Software
//   Foundation, either version 3 of the License, or (at your option) any later
//   version.
//
//   This file is distributed in the hope that it will be useful, but WITHOUT
//   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//   more details.
//
//   You should have received a copy of the GNU General Public License along
//   with this file. If not, see http://www.gnu.org/licenses/.
//#############################################################################
//
// This template prepares a simple email to send to mailbox owners who's mailbox
// is getting filled up.

// Dovecot always passes the percentage filled as the first parameter
// The user/email is always the second argument passed in.
//
// For more information visit http://nuxref.com
//
//? The simpliest way to use this template might be just doing the following
//? at the shell prompt:
//?
//?     # Define your variables
//?     DOMAIN=nuxref.com
//?     ADMIN=hostmaster@$DOMAIN
//?     PGHOST=localhost
//?     PGNAME=system_mail
//?     PGRWUSER=mailwriter
//?     PGRWPASS=mailwriter
//?
//?     sed -e "/^\/\/?/d" \
//?         -e "s/%DOMAIN%/$DOMAIN/g" \
//?         -e "s/%ADMIN%/$ADMIN/g" \
//?         -e "s/%PGHOST%/$PGHOST/g" \
//?         -e "s/%PGNAME%/$PGNAME/g" \
//?         -e "s/%PGRWUSER%/$PGRWUSER/g" \
//?         -e "s/%PGRWPASS%/$PGRWPASS/g" \
//?             pgsql.postfixadmin.template.config.local.php > \
//?                 /etc/postfixadmin/config.local.php
//?
//?     # Permissions
//?     chmod 640 /etc/postfixadmin/config.local.php
//?     chown root.apache /etc/postfixadmin/config.local.php

// If this is set to false, the entire website is not accessible
$CONF['configured'] = true;

// In order to setup Postfixadmin, you MUST specify a hashed password here.
// To create the hash, visit setup.php in a browser and type a password into the field,
// on submission it will be echoed out to you as a hashed value. The password below
// equates to  -----> 'admin' <-----------
// You change this later through the admin
$CONF['setup_password'] = 'c8ed6ceb9324091569dab303280bfd49:96f2aab8c1c0c3d2fff36f2c7ab9054eb8e77f5c';

// Database Information
$CONF['database_type'] = 'pgsql';
$CONF['database_host'] = '%PGHOST%';
$CONF['database_user'] = '%PGRWUSER%';
$CONF['database_password'] = '%PGRWUSER%';
$CONF['database_name'] = '%PGNAME%';

// Site Admin
$CONF['admin_email'] = '%ADMIN%';

// Encrypt Method
$CONF['encrypt'] = 'dovecot:CRAM-MD5';

// aliases
$CONF['default_aliases'] = array (
        'abuse' => 'abuse@%DOMAIN%',
        'hostmaster' => 'hostmaster@%DOMAIN%',
        'postmaster' => 'postmaster@%DOMAIN%',
        'webmaster' => 'webmaster@%DOMAIN%'
);

// Mailboxes
// If you want to store the mailboxes per domain set this to 'YES'.
// Examples:
//   YES: /usr/local/virtual/domain.tld/username@domain.tld
//   NO:  /usr/local/virtual/username@domain.tld
$CONF['domain_path'] = 'YES';
// If you don't want to have the domain in your mailbox set this to 'NO'.
// Examples:
//   YES: /usr/local/virtual/domain.tld/username@domain.tld
//   NO:  /usr/local/virtual/domain.tld/username
// Note: If $CONF['domain_path'] is set to NO, this setting will be forced to YES.
$CONF['domain_in_mailbox'] = 'NO';

// Default Domain Values
// Specify your default values below. Quota in MB.
$CONF['aliases'] = '100';
$CONF['mailboxes'] = '1000';
$CONF['maxquota'] = '1000';

// Transport
// If you want to define additional transport options for a domain set
// this to 'YES'. Read the transport file of the Postfix documentation.
$CONF['transport'] = 'YES';
// Transport options
// If you want to define additional transport options put them in array below.
$CONF['transport_options'] = array (
    'dovecot:',  // for local/virtual mail
    'vacation:', // for vacation auto-responses
    'relay:'     // for backup mx
);

// Transport default
// You should define default transport. It must be in array above.
$CONF['transport_default'] = 'dovecot:';

// Transport default
// You should define default transport. It must be in array above.
$CONF['transport_default'] = 'virtual';

// Quota
// When you want to enforce quota for your mailbox users set this to 'YES'.
$CONF['quota'] = 'YES';
// Quota Multiplier (either use '1024000' or '1048576')
$CONF['quota_multiplier'] = '1048576';
// Used Quotas
$CONF['used_quotas'] = 'YES';
// if you use dovecot >= 1.2, set this to yes.
// Note about dovecot config: table "quota" is for 1.0 & 1.1, table "quota2" is for dovecot 1.2 and newer
$CONF['new_quota_table'] = 'YES';
// Fetchmail
// If you don't want fetchmail tab set this to 'NO';
$CONF['fetchmail'] = 'NO';

// link to display under 'Main' menu when logged in as a user.
$CONF['user_footer_link'] = "http://%DOMAIN%";
$CONF['show_footer_pa_links'] = 'NO';
// Footer
// Below information will be on all pages.
// If you don't want the footer information to appear set this to 'NO'.
$CONF['show_footer_text'] = 'YES';
$CONF['footer_text'] = 'Return to %DOMAIN%';
$CONF['footer_link'] = 'http://%DOMAIN%';

// resolve domain
$CONF['emailcheck_resolve_domain'] = 'NO';

// Vacation Control
$CONF['vacation'] = 'YES';
$CONF['vacation_domain'] = 'autoreply.%DOMAIN%';

// Set Dovecot Admin PW
$CONF['dovecotpw'] = '/usr/bin/doveadm pw';
?>
