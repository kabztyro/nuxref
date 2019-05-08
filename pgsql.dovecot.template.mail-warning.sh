#!/bin/sh
#    Copyright 2014 Chris Caron <lead2gold@gmail.com>
#
#    This is free software: you can redistribute it and/or modify it under the
#    terms of the GNU General Public License as published by the Free Software
#    Foundation, either version 3 of the License, or (at your option) any later
#    version.
#
#    This file is distributed in the hope that it will be useful, but WITHOUT
#    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#    FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
#    more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this file. If not, see http://www.gnu.org/licenses/.
###############################################################################
#
# This template prepares a simple email to send to mailbox owners who's mailbox
# is getting filled up.

# Dovecot always passes the percentage filled as the first parameter
# The user/email is always the second argument passed in.
#
# For more information visit http://nuxref.com
#
#? The simpliest way to use this template might be just doing the following
#? at the shell prompt:
#?
#?     # Define your variables
#?     DOMAIN=nuxref.com
#?
#?     sed -e "/^#?/d" \
#?         -e "s/%DOMAIN%/$DOMAIN/g" \
#?             pgsql.dovecot.template.mail-warning.sh > \
#?                 /usr/libexec/dovecot/mail-warning.sh
#?
#?     # Permissions
#?     chmod 755 /usr/libexec/dovecot/mail-warning.sh
PERCENT=$1
USER=$2

# Pipe content via stdout to dovecot's deliver pipe
cat << EOF | /usr/libexec/dovecot/deliver -d $USER -o
"plugin/quota=maildir:User quota:noenforcing"
From: Support at %DOMAIN%
Subject: quota warning
 
Your mailbox is now $PERCENT% full.
Please remove some old mail, or ask for a larger quota.
EOF
