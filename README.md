# GIT-Auto

## Git Create
Git Create handles the creation of environment specific tags. It follows the Git Flow workflow; i.e. develop and release branches are for QA, master is staging and production.
Using Git Create, one can create a git tag with <TAG-PREFIX><TAG-DELIM><DATE-TIMESTAMP>, or specify it's own tag.
On initial run, Git Create will ask some configuration questions.
*NOTE* Once tag is created, it gets pushed automatically to the remote repo.

### Available commands
- Create tag using date-timestamp `git-auto-create`
- Create user defined tag `git-auto-create <TAGNAME>`

## Git Deploy
Git Deploy handles deploying the code based on a given tag. If the tags are created following this format: <TAG-PREFIX>-<DATETIME_STAMP>, then it will deploy the code corresponding to the tag with the latest datetime stamp.
An additional option is the ability to run a script before and/or after deployment. This can be helpful in case of database migration, running code testing, etc..

### Available commands
- Deploy the latest code `git-auto-deploy`
- List all tags `git-auto-deploy l`
- Add script `git-auto-deploy add-script <args>`
    + Args can be: _before_ OR _after_
- For help `git-auto-deploy help`
