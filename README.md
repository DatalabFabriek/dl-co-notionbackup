# Backup Notion using a sane method
Many Notion backup implementations exist on Github. For example, 
[jckleiner/notion-backup](https://github.com/jckleiner/notion-backup) who uses Java to implement a fairly complete way
of backing up Notion and writing the backup files to Dropbox and other points. There's also the simpler approach by
[darobin/notion-backup](https://github.com/darobin/notion-backup) who uses Node.

The key problem with these implementations is that they are fairly heavy weight (Java) and/or that they keep a script
running in the background to check progress. This approach works well with small Notion installations that take a few
minutes to complete. When your Notion is (much) larger, it can take many hours to complete and therefore, there are
many hours in which your nice loop can fail (e.g. due to network issues).

The approach of this container is simpler: it enqueues a backup job and checks your Notion's inbox for newly completed
backup files. Much like you'd do in normal life (given that you have a large Notion environment). Moreover, we use basic
bash scripting, making it a very lightweight solution. Backup files are writting to a storage location of your choice.
There's also removal of old backup files that is slightly more intelligent than just deleting old files; it also keeps
a minimum number of most recent backup files so that if anything goes wrong with the backup script, you would still have
(older) backup files.

## Obtaining tokens
This is copied from [darobin/notion-backup](https://raw.githubusercontent.com/darobin/notion-backup/main/README.md).

Automatically downloading backups from Notion requires two unique authentication tokens and your individual space ID which must be obtained for the script to work.

1. Log into your Notion account in your browser of choice if you haven't done so already.
2. Open a new tab in your browser and open the development tools. This is usually easiest done by right-click and selecting `Inspect Element` (Chrome, Edge, Safari) or `Inspect` (Firefox). Switch to the Network tab.
3. Open https://notion.so/f/. You must use this specific subdirectory to obtain the right cookies.
4. Insert `getSpaces` into the search filter of the Network tab. This should give you one result. Click on it.
5. In the Preview tab, look for the key `space`. There you should find a list of all the workspaces you have access to. Unless you're part of shared workspaces there should only be one.
6. Copy the UUID of the workspace you want to backup (e.g. `6e560115-7a65-4f65-bb04-1825b43748f1`). This is your `NOTION_SPACE_ID`.
6. Switch to the Application (Chrome, Edge) or Storage (Firefox, Safari) tab on the top.
7. In the left sidebar, select `Cookies` -> `https://www.notion.so` (Chrome, Edge, Firefox) or `Cookies – https://www.notion.so` (Safari).
8. Copy the value of `token_v2` as your `NOTION_TOKEN`.
9. To obtain the `FILE_TOKEN`, copy and paste a download link to a backup .zip file and look at the cookies. For those zip files, you'll have, besides the `token_v2` a `file_token` as well.

**NOTE**: if you log out of your account or your session expires naturally, the `NOTION_TOKEN` and `NOTION_FILE_TOKEN` will get invalidated and the backup will fail. In this case you need to obtain new tokens by repeating this process. There is currently no practical way to automize this until Notion decide to add a backup endpoint to their official API, at which point this script will be able to use a proper authentication token.

## Installing the image on a VM
Please execute the following steps on a virtual machine, or anywhere else you want to run this.

1. Make a secrets for `notiontoken`, `filetoken`, `spaceid`: `echo "your token here" | docker secret create dl-co-notionbackup-notiontoken -` (execute this three times for each token).
2. Install the service, **make sure to check the volume, you might want to create a Docker volume for this or mount a host system folder**:

```sh
docker service create \
    --name "dl-co-notionbackup" \
    --with-registry-auth \
    --replicas 1 \
    --restart-max-attempts 500 \
    --restart-delay 15s \
    --restart-condition any \
    --mount type=bind,source=/mnt/bigstorage/notion,target=/dlstore \
    --secret dl-co-notionbackup-notiontoken \
    --secret dl-co-notionbackup-filetoken \
    --secret dl-co-notionbackup-spaceid \
    ghcr.io/datalabfabriek/dl-co-notionbackup:production
```

## License
Datalab uses a lot of open source software. As we care about the open source community, we'd like to contribute back by licensing this simple utility under the GNU General Public License v3.0 (GPL-3.0-only). Feel free to contribute by making a pull request. 

Feel free to open a pull request if you want to contribute. Any and all questions can be directe to [Harmen](mailto:harmen@datalab.nl).

## Previous work
Originally, we tried to build upon [jckleiner/notion-backup](https://github.com/jckleiner/notion-backup). None of the source code therein is present in this repo, so this code represents a new, original work.
