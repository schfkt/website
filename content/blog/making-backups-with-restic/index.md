---
title: "Making backups in the cloud with restic"
date: 2020-08-25
---

I broke my iPhone recently, and the worst thing is that there were around 60GB of photos and videos inside... But, lucky me, I did a complete backup of it a month ago. You might ask: "Why don't you just upload your photos to iCloud? It's cheap, simple, and you get all of yout photos everywhere: on your mac, etc.". Yeah, it's good, simple and works well, until it doesn't. I had to recreate my whole iCloud Photo library twice, just because it stopped syncing data with no reason. And it happenned long time ago, when I just had around 20GB of data. Imagine recreating the library with 60GB of data...

<!--more-->

And it's not only about photos. I need to backup different kind of data. Books, configs, notes. And for safety and privacy reasons it must be encrypted.

Another thing is flexibility. Yes, you have to spend more time configuring stuff. But you can do whatever you want. You aren't limited by some closed API (I mean iCloud), for example. I personally prefer working on linux, so iCloud isn't really an option for me. Since it's not cross-platform.

# Research

There's a simple rule to keep your data safe: 3-2-1 backup rule. It says that you have to keep 3 copies of your data, 2 of them on a separate devices and 1 offsite. In my case, I've setup a samba share on my server, which I copy to an external HDD periodically and sync it to a cloud storage. 

First two parts of this setup are out of scope of this post (I may write about it later). So let's talk about the
latter. This is what I want to have:

+ Deduplicate data, so each snapshot doesn't contain same data twice
+ Store snapshots encrypted
+ Run backups automatically

There're a couple of cli apps that can do it. I've found the most details about duplicity, but the thing is that isn't actively maintaned anymore, sometimes break the snapshots so you have to start over. And then I found out about restic. It's actively maintaned, written in go (so it's portable: the only thing you need is a binary), can handle lots of data (some people on reddit did backups of terrabytes of data with it). Also it does deduplication, encrypts your data and supports a couple of cloud providers out of the box.

Then I tried to find a cloud provider to keep my data at. Dropbox looks nice, but I don't really need 1TB now. AWS is fucking expensive. Soo, meet Backblaze B2. [Their pricing page](https://www.backblaze.com/b2/cloud-storage-pricing.html) has comparisons with the other cloud providers: AWS, Google Cloud.

At the moment the prices are the following:

* 0.005$ to store each GB of data, first 10GB are free
* 0.01$ to download each GB of data, first 1GB per day is free

For me it's very flexible, since at the moment I don't have a lot of data to backup. Let's assume it's just 100GB, so to just store that amount, I'll have to pay: `100 * 0.005 = 0.5$` per month. To download that data I'll pay just: `100 * 0.01 = 1$`. Even if I upload 1000GB there, it'll cost me:

* `0.005 * 1000 = 5$` to store the data per month
* `0.01 * 1000 = 10$` to download all the data once

But, it's a bit more complex than that. They also charge you for the API calls (SURPRISE! Of course it's not shown on the comparison page). There're 3 kinds of API calls, they call it A, B, and C:

* A are completely free
* B cost `$0.004` per 10,000 with 2,500 free per day
* C cost `$0.004` per 1,000 with 2,500 free per day

I haven't reached these limis yet, but I upload my data in small chunks (5-10GB per day):

![b2-api-usage.png](images/b2-api-usage.png)

# Setup

I've written a couple of bash scripts to automate the backups. These scripts are executed by systemd timers periodically. And on each script run I get a notification via telegram with the result. So if anything fails, I'll notice that immediatelly.

## Scripts

First of all, you have to create a private bucket in B2 where you are going to store your data:

* Go to "My Account"
* Then "Buckets"
* Click "Create a Bucket"
* Pick a unique (across all the B2) bucket name
* Make sure it's **Private**

Now you need to create API keys:

* Go to "App Keys"
* Click "Add a New Application Key"
* Save ID and KEY values, you'll need them to use B2 as a backup backend

Then prepare a file with the configuration variable. That file is going to be sourced by the rest of the scripts, let's
call it `env.sh`:

```bash
export RESTIC_REPOSITORY="b2:<bucket-name>:<dst-path-in-the-bucket>"
export RESTIC_PASSWORD="<repository-encryption-password>"
export B2_ACCOUNT_ID=""
export B2_ACCOUNT_KEY=""
```

Then create a script to initialize your repository. I called it `init.sh`:

```bash
#!/bin/bash

set -e

source "/opt/restic/etc/env.sh"

/opt/restic/bin/restic init
```

This script is going to be executed only once, before you start making backups.

And now the most important script, the one that's going to make backups. I called it `backup.sh`:

```bash
#!/bin/bash

source "/opt/restic/etc/env.sh"

echo "Making a backup"
OUTPUT=`/opt/restic/bin/restic backup \
  --files-from "/opt/restic/etc/includes.txt" \
  --exclude-file "/opt/restic/etc/excludes.txt"`
STATUS=$?

echo "$OUTPUT"

echo "Notifying with telegram: STATUS=$STATUS"
if [ $STATUS == 0 ]; then
  /opt/telegram-alerts/bin/send.sh "SUCCESSFUL BACKUP\n$OUTPUT"
else
  /opt/telegram-alerts/bin/send.sh "FAILED BACKUP\n$OUTPUT"
fi

exit $STATUS
```

The script itself is pretty obvious: it makes a backup, stores the output in a variable. And pass it to another script that's responsible for telegram notifications.

The next script is used to cleanup the repository from outdated snapshots. For that specific case restic has a separate command: forget. It removes old snapshots and it's data (but only if you pass `--prune` flag).

You can either set specific snapshots to be removed by passing a snapshot id, or you can set retention policies by using `--keep-*` flags (`--keep-daily 7` for example). Refer to the documentation for more details: [Removing snapshots according to a policy](https://restic.readthedocs.io/en/latest/060_forget.html#removing-snapshots-according-to-a-policy)

```bash
#!/bin/bash

source "/opt/restic/etc/env.sh"

echo "Removing outdated snapshots and data"

OUTPUT=`/opt/restic/bin/restic forget \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 12 \
  --keep-yearly 4 \
  --prune`
STATUS=$?
echo "$OUTPUT"

echo "Notifying with telegram: STATUS=$STATUS"

if [ $STATUS == 0 ]; then
  /opt/telegram-alerts/bin/send.sh "SUCCESSFUL CLEANUP\n$OUTPUT"
else
  /opt/telegram-alerts/bin/send.sh "FAILED CLEANUP\n$OUTPUT"
fi

CHECK_OUTPUT=`/opt/restic/bin/restic check`
CHECK_STATUS=$?
echo "$CHECK_OUTPUT"

echo "Notifying with telegram: CHECK_STATUS=$CHECK_STATUS"

if [ $CHECK_STATUS == 0 ]; then
  /opt/telegram-alerts/bin/send.sh "SUCCESSFUL CONSISTENCY CHECK\n$CHECK_OUTPUT"
else
  /opt/telegram-alerts/bin/send.sh "FAILED CONSISTENCY CHECK\n$CHECK_OUTPUT"
fi
```

The following quote from the docs clearly explains how the policies work:

> Suppose you make daily backups for 100 years. Then forget --keep-daily 7 --keep-weekly 5
> --keep-monthly 12 --keep-yearly 75 will keep the most recent 7 daily snapshots, then 4 (remember, 7 dailies already
> include a week!) last-day-of-the-weeks and 11 or 12 last-day-of-the-months (11 or 12 depends if the 5 weeklies cross a
> month). And finally 75 last-day-of-the-year snapshots. All other snapshots are removed.

As you can see, the one I set up in the script (7 daily, 5 weekly, 12 monthly, 4 yearly) is almost the same as in the
example. Except my policy is going to keep only 4 yearly snapshots.

And the last script we need is the one you gonna use to restore the data. Try it once you do your the first backup to make sure the data isn't corrupted and the setup is correct:

```bash
#!/bin/bash

source "/opt/restic/etc/env.sh"

TARGET=$1
if [ -z "$TARGET" ]; then
  echo "TARGET is required"
  exit 1
fi

/opt/restic/bin/restic restore latest --target "$TARGET"
```

## Telegram notifications

All of the scripts above use a Telegram bot to send me notifications. For example, I get the complete output of restic command after a backup has finished.

Here's the script itself:

```bash
#!/bin/bash

source ./env.sh

HOST=$(hostname)
MESSAGE="$HOST: $1"
URL="https://api.telegram.org/bot$TELEGRAM_KEY/sendMessage"

curl -s -d "chat_id=$CHAT_ID&disable_web_page_preview=1&text=$MESSAGE" "$URL" > /dev/null
```

And this is the separate env file with all the configuration needed:

```bash
export TELEGRAM_KEY="<your-telegram-bot-api-key>"
export CHAT_ID="<id-of-a-chat-where-bot-sends-messages>"
```

## Dealing with permissions

In order to be able to backup any file on your system, you have two options.

The first one is to run restic as root, so there's no restrictions due to file permissions. But that doesn't look safe. Since we don't need all the root capabilities, just the ability to read all the files on the system.

The other option is to run restic by a non-root user, but enable a specific linux capability on the restic binary. In that case you get just what you need, nothing more.

I chose the second option. First, you have to add the capability:

```bash
# run this as root
setcap cap_dac_read_search=+ep /path/to/restic/binary
```

You can read more about linux capabilities at: `man capabilities 7`. TLDR for that specific one is:

```bash
       CAP_DAC_READ_SEARCH
              * Bypass file read permission checks and directory read and execute permission checks;
```

Check that the restic binary have the required capability set:

```bash
$ getcap restic
restic = cap_dac_read_search+ep
```

Also, make sure that the restic binary can only be executed by the user you're gonna use to make backups. This is very important, since the capability we've just added allows restic binary unrestricted read of any file in the system.

## Systemd

Running backup scripts manually is error-prone and tedious, so we're going to use systemd to automate that.

To be able to run systemd timers/services you have to first enable lingering for a user. It allows systemd services to run by specific user without that user being logged in to the system. Login as the user and run the following command:

```bash
loginctl enable-linger
```

Systemd timers are configured as two parts:

* The unit file: specifies the command to run
* The timer file: configures when that unit must be run

Names of these unit and timer files are important. For example, if you have a unit file named `restic-backup.service`, then the appropriate timer file must be named `restic-backup.timer`. So that systemd knows what timer file manages which unit, just a convention.

User-specific systemd files are located at: `~/.config/systemd/user`.

Here's the unit file for backup script `restic-backup.service`:

```systemd
[Unit]
Description=Backup with restic to Backblaze B2

[Service]
Type=simple
Nice=10
ExecStart=/opt/restic/bin/backup.sh
```

And the appropriate timer file `restic-backup.timer`:

```systemd
[Unit]
Description=Backup with restic on schedule

[Timer]
OnCalendar=*-*-1/2 01:00:00

[Install]
WantedBy=timers.target
```

It runs the backup script every two days at 01:00:00 starting from the first day of month.

Here're the unit and timer files for forget script. `restic-forget.service`:

```systemd
[Unit]
Description=Forget old restic backups

[Service]
Type=simple
Nice=10
ExecStart=/opt/restic/bin/forget.sh
```

`restic-forget.timer`:

```systemd
[Unit]
Description=Forget restic backups on schedule

[Timer]
OnCalendar=*-*-16 01:00:00

[Install]
WantedBy=timers.target
```

It's run once a month on 16th day at 01:00. So it doesn't overlap with the backup script, since the backup script is run on odd days of a month (1, 3, 5 etc.).

Now you have to enable and start timers:

```bash
systemctl --user enable --now restic-backup.timer
systemctl --user start --now restic-backup.timer

systemctl --user enable --now restic-forget.timer
systemctl --user start --now restic-forget.timer
```

You can check a timer's status with:

```bash
$ systemctl status --user restic-backup.timer
● restic-backup.timer - Backup with restic on schedule
   Loaded: loaded (/home/restic/.config/systemd/user/restic-backup.timer; enabled; vendor preset: enabled)
   Active: active (waiting) since Wed 2020-08-19 06:59:09 EEST; 4 days ago
  Trigger: Tue 2020-08-25 01:00:00 EEST; 1 day 5h left

Aug 19 06:59:09 server systemd[1597]: Started Backup with restic on schedule.
```

In case you run that command over ssh on a server, you'll have to do it this way instead:

```bash
XDG_RUNTIME_DIR=/run/user/$UID systemctl status --user restic-backup.timer
```

Otherwise systemd will complain that it can't connect to dbus.

And that's it. Now you have an automated backup system that keeps your data in the cloud, and, more importantly, it encrypts and deduplicates all the data.

# Update on April 2022

I've been using this setup on a couple of home servers for 1.5 years. There is around 240Gb stored at the moment, and it
costs me just 1.31 EUR (1.42 USD) per month. And it proved to be reliable too: I had to restore the whole data at least
once, and it went with no issues at all.

# Update on April 2023

Here are some stats after one more year of using this setup:

- 424Gb of data stored (the actual repository size at B2 is smaller thanks to deduplication: 402.5Gb)
- It took around 13 hours to restore (download speed was around 50Mbit/sec), restic used ~480Mb of RSS memory, and a bit of CPU (10-20%)
- Storage cost: 2.24 EUR / Month
- Restore cost: 4.13 EUR

There's one important thing that I noticed during this restore run. In order to restore not just files, but their
correct permissions and ownership information, `restic restore` has to be run as `root`. Otherwise, all the restored
files will be owned by a user who run the restore command.

# Update on April 2024

Another year, another update:

- 573Gb of data stored (+149Gb)
- Restic stats:
  - Repository size: 555Gb
  - Snapshots: 273
- Restore time: 18h25m (at ~100Mbps)
- Storage cost: 3.62 EUR / month
- Restore cost: free, since Backblaze recently made all egress traffic free! See [this
  blog post](https://www.backblaze.com/blog/2023-product-announcement/) for more details.
